/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd and/or its subsidiary(-ies).
** Contact: https://www.qt.io/licensing/
**
** This file is part of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl-3.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or (at your option) the GNU General
** Public license version 3 or any later version approved by the KDE Free
** Qt Foundation. The licenses are as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-2.0.html and
** https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "avfmetadata_p.h"
#include <private/qdarwinformatsinfo_p.h>

#include <QtCore/qbuffer.h>
#include <QtCore/qiodevice.h>
#include <QtCore/qdatetime.h>
#include <QtCore/qlocale.h>
#include <QtCore/qurl.h>
#include <QImage>

#if QT_HAS_INCLUDE(<AppKit/AppKit.h>)
#include <AppKit/AppKit.h>
#endif

#include <CoreFoundation/CoreFoundation.h>

QT_USE_NAMESPACE

struct AVMetadataIDs {
    AVMetadataIdentifier common;
    AVMetadataIdentifier iTunes;
    AVMetadataIdentifier quickTime;
    AVMetadataIdentifier ID3;
};

const AVMetadataIDs keyToAVMetaDataID[] = {
    // Title
    { AVMetadataCommonIdentifierTitle, AVMetadataIdentifieriTunesMetadataSongName,
      AVMetadataIdentifierQuickTimeMetadataTitle,
      AVMetadataIdentifierID3MetadataTitleDescription },
    // Author
    { AVMetadataCommonIdentifierAuthor,AVMetadataIdentifieriTunesMetadataAuthor,
      AVMetadataIdentifierQuickTimeMetadataAuthor, nil },
    // Comment
    { nil, AVMetadataIdentifieriTunesMetadataUserComment,
      AVMetadataIdentifierQuickTimeMetadataComment, AVMetadataIdentifierID3MetadataComments },
    // Description
    { AVMetadataCommonIdentifierDescription,AVMetadataIdentifieriTunesMetadataDescription,
      AVMetadataIdentifierQuickTimeMetadataDescription, nil },
    // Genre
    { nil, AVMetadataIdentifieriTunesMetadataUserGenre,
      AVMetadataIdentifierQuickTimeMetadataGenre, nil },
    // Date
    { AVMetadataCommonIdentifierCreationDate, AVMetadataIdentifieriTunesMetadataReleaseDate,
      AVMetadataIdentifierQuickTimeMetadataCreationDate, AVMetadataIdentifierID3MetadataDate },
    // Language
    { AVMetadataCommonIdentifierLanguage, nil, nil, AVMetadataIdentifierID3MetadataLanguage },
    // Publisher
    { AVMetadataCommonIdentifierPublisher, AVMetadataIdentifieriTunesMetadataPublisher,
      AVMetadataIdentifierQuickTimeMetadataPublisher, AVMetadataIdentifierID3MetadataPublisher },
    // Copyright
    { AVMetadataCommonIdentifierCopyrights, AVMetadataIdentifieriTunesMetadataCopyright,
      AVMetadataIdentifierQuickTimeMetadataCopyright, AVMetadataIdentifierID3MetadataCopyright },
    // Url
    { nil, nil, nil, AVMetadataIdentifierID3MetadataOfficialAudioSourceWebpage },
    // Duration
    { nil, nil, nil, AVMetadataIdentifierID3MetadataLength },
    // MediaType
    { AVMetadataCommonIdentifierType, nil, nil, AVMetadataIdentifierID3MetadataContentType },
    // FileFormat
    { nil, nil, nil, AVMetadataIdentifierID3MetadataFileType },
    // AudioBitRate
    { nil, nil, nil, nil },
    // AudioCodec
    { nil, nil, nil, nil },
    // VideoBitRate
    { nil, nil, nil, nil },
    // VideoCodec
    { nil, nil, nil, nil },
    // VideoFrameRate
    { nil, nil, AVMetadataIdentifierQuickTimeMetadataCameraFrameReadoutTime, nil },
    // AlbumTitle
    { AVMetadataCommonIdentifierAlbumName, AVMetadataIdentifieriTunesMetadataAlbum,
      AVMetadataIdentifierQuickTimeMetadataAlbum, AVMetadataIdentifierID3MetadataAlbumTitle },
    // AlbumArtist
    { nil, AVMetadataIdentifieriTunesMetadataAlbumArtist, nil, nil },
    // ContributingArtist
    { AVMetadataCommonIdentifierArtist, AVMetadataIdentifieriTunesMetadataArtist,
      AVMetadataIdentifierQuickTimeMetadataArtist, nil },
    // TrackNumber
    { nil, AVMetadataIdentifieriTunesMetadataTrackNumber,
      nil, AVMetadataIdentifierID3MetadataTrackNumber },
    // Composer
    { nil, AVMetadataIdentifieriTunesMetadataComposer,
      AVMetadataIdentifierQuickTimeMetadataComposer, AVMetadataIdentifierID3MetadataComposer },
    // LeadPerformer
    { nil, AVMetadataIdentifieriTunesMetadataPerformer,
      AVMetadataIdentifierQuickTimeMetadataPerformer, AVMetadataIdentifierID3MetadataLeadPerformer },
    // ThumbnailImage
    { nil, nil, nil, AVMetadataIdentifierID3MetadataAttachedPicture},
    // CoverArtImage
    { AVMetadataCommonIdentifierArtwork, AVMetadataIdentifieriTunesMetadataCoverArt,
      AVMetadataIdentifierQuickTimeMetadataArtwork, nil },
    // Orientation
    { nil, nil, AVMetadataIdentifierQuickTimeMetadataDirectionFacing, nil },
    // Resolution
    { nil, nil, nil, nil }
};

static AVMetadataIdentifier toIdentifier(QMediaMetaData::Key key, AVMetadataKeySpace keySpace)
{
    static_assert(sizeof(keyToAVMetaDataID)/sizeof(AVMetadataIDs) == QMediaMetaData::Key::Resolution + 1);

    AVMetadataIdentifier identifier = nil;
    if ([keySpace isEqualToString:AVMetadataKeySpaceiTunes]) {
        identifier = keyToAVMetaDataID[key].iTunes;
    } else if ([keySpace isEqualToString:AVMetadataKeySpaceID3]) {
        identifier = keyToAVMetaDataID[key].ID3;
    } else if ([keySpace isEqualToString:AVMetadataKeySpaceQuickTimeMetadata]) {
        identifier = keyToAVMetaDataID[key].quickTime;
    } else  {
        identifier = keyToAVMetaDataID[key].common;
    }
    return identifier;
}

static std::optional<QMediaMetaData::Key> toKey(AVMetadataItem *item)
{
    static_assert(sizeof(keyToAVMetaDataID)/sizeof(AVMetadataIDs) == QMediaMetaData::Key::Resolution + 1);

    // The item identifier may be different than the ones we support,
    // so check by common key first, as it will get the metadata
    // irrespective of the format.
    AVMetadataKey commonKey = item.commonKey;
    if (commonKey.length != 0) {
        if ([commonKey isEqualToString:AVMetadataCommonKeyTitle]) {
            return QMediaMetaData::Title;
        } else if ([commonKey isEqualToString:AVMetadataCommonKeyDescription]) {
            return QMediaMetaData::Description;
        } else if ([commonKey isEqualToString:AVMetadataCommonKeyPublisher]) {
            return QMediaMetaData::Publisher;
        } else if ([commonKey isEqualToString:AVMetadataCommonKeyCreationDate]) {
            return QMediaMetaData::Date;
        } else if ([commonKey isEqualToString:AVMetadataCommonKeyType]) {
            return QMediaMetaData::MediaType;
        } else if ([commonKey isEqualToString:AVMetadataCommonKeyLanguage]) {
            return QMediaMetaData::Language;
        } else if ([commonKey isEqualToString:AVMetadataCommonKeyCopyrights]) {
            return QMediaMetaData::Copyright;
        } else if ([commonKey isEqualToString:AVMetadataCommonKeyAlbumName]) {
            return QMediaMetaData::AlbumTitle;
        } else if ([commonKey isEqualToString:AVMetadataCommonKeyAuthor]) {
            return QMediaMetaData::Author;
        } else if ([commonKey isEqualToString:AVMetadataCommonKeyArtist]) {
            return QMediaMetaData::ContributingArtist;
        }
    }

    // Check by identifier if no common key found
    // No need to check for the common keySpace since there's no common key
    enum keySpaces { iTunes, QuickTime, ID3, Other } itemKeySpace;
    itemKeySpace = Other;
    AVMetadataKeySpace keySpace = [item keySpace];
    AVMetadataIdentifier identifier = [item identifier];

    if ([keySpace isEqualToString:AVMetadataKeySpaceiTunes]) {
        itemKeySpace = iTunes;
    } else if ([keySpace isEqualToString:AVMetadataKeySpaceQuickTimeMetadata]) {
        itemKeySpace = QuickTime;
    } else if (([keySpace isEqualToString:AVMetadataKeySpaceID3])) {
        itemKeySpace = ID3;
    }

    for (int key = 0; key < QMediaMetaData::Resolution + 1; key++) {
        AVMetadataIdentifier idForKey = nil;
        switch (itemKeySpace) {
        case iTunes:
            idForKey = keyToAVMetaDataID[key].iTunes;
            break;
        case QuickTime:
            idForKey = keyToAVMetaDataID[key].quickTime;
            break;
        case ID3:
            idForKey = keyToAVMetaDataID[key].ID3;
            break;
        default:
            break;
        }

        if ([identifier isEqualToString:idForKey])
            return QMediaMetaData::Key(key);
    }

    return std::nullopt;
}

static QMediaMetaData fromAVMetadata(NSArray *metadataItems)
{
    QMediaMetaData metadata;

    for (AVMetadataItem* item in metadataItems) {
        auto key = toKey(item);
        if (!key)
            continue;

        const QString value = QString::fromNSString([item stringValue]);
        if (!value.isNull())
            metadata.insert(*key, value);
    }
    return metadata;
}

QMediaMetaData AVFMetaData::fromAsset(AVAsset *asset)
{
#ifdef QT_DEBUG_AVF
    qDebug() << Q_FUNC_INFO;
#endif
    QMediaMetaData metadata = fromAVMetadata([asset metadata]);

    // add duration
    const CMTime time = [asset duration];
    const qint64 duration =  static_cast<qint64>(float(time.value) / float(time.timescale) * 1000.0f);
    metadata.insert(QMediaMetaData::Duration, duration);

    return metadata;
}

QMediaMetaData AVFMetaData::fromAssetTrack(AVAssetTrack *asset)
{
    QMediaMetaData metadata = fromAVMetadata([asset metadata]);
    if (metadata.value(QMediaMetaData::Language).isNull()) {
        auto *lang = asset.languageCode;
        if (lang)
            metadata.insert(QMediaMetaData::Language, QString::fromNSString(lang));
    }
    return metadata;
}

static AVMutableMetadataItem *setAVMetadataItemForKey(QMediaMetaData::Key key, const QVariant &value,
                                                      AVMetadataKeySpace keySpace = AVMetadataKeySpaceCommon)
{
    AVMetadataIdentifier identifier = toIdentifier(key, keySpace);
    if (!identifier.length)
        return nil;

    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.keySpace = keySpace;
    item.identifier = identifier;

    switch (key) {
    case QMediaMetaData::ThumbnailImage:
    case QMediaMetaData::CoverArtImage: {
#if defined(Q_OS_MACOS)
        QImage img = value.value<QImage>();
        if (!img.isNull()) {
            QByteArray arr;
            QBuffer buffer(&arr);
            buffer.open(QIODevice::WriteOnly);
            img.save(&buffer);
            NSData *data = arr.toNSData();
            NSImage *nsImg = [[NSImage alloc] initWithData:data];
            item.value = nsImg;
            [nsImg release];
        }
#endif
        break;
    }
    case QMediaMetaData::FileFormat: {
        QMediaFormat::FileFormat qtFormat = value.value<QMediaFormat::FileFormat>();
        AVFileType avFormat = QDarwinFormatInfo::avFileTypeForContainerFormat(qtFormat);
        item.value = avFormat;
        break;
    }
    case QMediaMetaData::Language: {
        QString lang = QLocale::languageToCode(value.value<QLocale::Language>());
        if (!lang.isEmpty())
            item.value = lang.toNSString();
        break;
    }
    default: {
        switch (value.typeId()) {
        case QMetaType::QString: {
            item.value = value.toString().toNSString();
            break;
        }
        case QMetaType::Int: {
            item.value = [NSNumber numberWithInt:value.toInt()];
            break;
        }
        case QMetaType::LongLong: {
            item.value = [NSNumber numberWithLongLong:value.toLongLong()];
            break;
        }
        case QMetaType::Double: {
            item.value = [NSNumber numberWithDouble:value.toDouble()];
            break;
        }
        case QMetaType::QDate:
        case QMetaType::QDateTime: {
            item.value = value.toDateTime().toNSDate();
            break;
        }
        case QMetaType::QUrl: {
            item.value = value.toUrl().toNSURL();
            break;
        }
        default:
            break;
        }
    }
    }

    return item;
}

NSMutableArray<AVMetadataItem *> *AVFMetaData::toAVMetadataForFormat(QMediaMetaData metadata, AVFileType format)
{
    NSMutableArray<AVMetadataKeySpace> *keySpaces = [NSMutableArray<AVMetadataKeySpace> array];
    if (format == AVFileTypeAppleM4A) {
        [keySpaces addObject:AVMetadataKeySpaceiTunes];
    } else if (format == AVFileTypeMPEGLayer3) {
        [keySpaces addObject:AVMetadataKeySpaceID3];
        [keySpaces addObject:AVMetadataKeySpaceiTunes];
    } else if (format == AVFileTypeQuickTimeMovie) {
        [keySpaces addObject:AVMetadataKeySpaceQuickTimeMetadata];
    } else {
        [keySpaces addObject:AVMetadataKeySpaceCommon];
    }
    NSMutableArray<AVMetadataItem *> *avMetaDataArr = [NSMutableArray array];
    for (const auto &key : metadata.keys()) {
        for (NSUInteger i = 0; i < [keySpaces count]; i++) {
            const QVariant &value = metadata.value(key);
            // set format-specific metadata
            AVMetadataItem *item = setAVMetadataItemForKey(key, value, keySpaces[i]);
            if (item)
                [avMetaDataArr addObject:item];
        }
    }
    return avMetaDataArr;
}

