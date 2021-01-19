/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
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

#ifndef QMEDIASERVICEPROVIDERPLUGIN_H
#define QMEDIASERVICEPROVIDERPLUGIN_H

#include <QtCore/qstringlist.h>
#include <QtCore/qplugin.h>
#include <QtMultimedia/qmultimedia.h>
#include <QtMultimedia/qtmultimediaglobal.h>
#include <QtMultimedia/qcamera.h>

#ifdef Q_MOC_RUN
# pragma Q_MOC_EXPAND_MACROS
#endif

QT_BEGIN_NAMESPACE

// Required for QDoc workaround
class QString;

class QMediaService;

// Required for QDoc workaround
class QString;

struct Q_MULTIMEDIA_EXPORT QMediaServiceProviderFactoryInterface
{
    virtual QMediaService* create(QString const& key) = 0;
    virtual void release(QMediaService *service) = 0;
    virtual ~QMediaServiceProviderFactoryInterface();
};

#define QMediaServiceProviderFactoryInterface_iid \
    "org.qt-project.qt.mediaserviceproviderfactory/5.0"
Q_DECLARE_INTERFACE(QMediaServiceProviderFactoryInterface, QMediaServiceProviderFactoryInterface_iid)

// Required for QDoc workaround
class QString;

struct Q_MULTIMEDIA_EXPORT QMediaServiceSupportedFormatsInterface
{
    virtual ~QMediaServiceSupportedFormatsInterface() {}
    virtual QMultimedia::SupportEstimate hasSupport(const QString &mimeType, const QStringList& codecs) const = 0;
    virtual QStringList supportedMimeTypes() const = 0;
};

#define QMediaServiceSupportedFormatsInterface_iid \
    "org.qt-project.qt.mediaservicesupportedformats/5.0"
Q_DECLARE_INTERFACE(QMediaServiceSupportedFormatsInterface, QMediaServiceSupportedFormatsInterface_iid)

// Required for QDoc workaround
class QString;

struct Q_MULTIMEDIA_EXPORT QMediaServiceSupportedDevicesInterface
{
    virtual ~QMediaServiceSupportedDevicesInterface() {}
    virtual QList<QByteArray> devices(const QByteArray &service) const = 0;
    virtual QString deviceDescription(const QByteArray &service, const QByteArray &device) = 0;
    virtual QByteArray defaultDevice(const QByteArray &service) const = 0;
};

#define QMediaServiceSupportedDevicesInterface_iid \
    "org.qt-project.qt.mediaservicesupporteddevices/5.0"
Q_DECLARE_INTERFACE(QMediaServiceSupportedDevicesInterface, QMediaServiceSupportedDevicesInterface_iid)

// Required for QDoc workaround
class QString;

class Q_MULTIMEDIA_EXPORT QMediaServiceProviderPlugin : public QObject, public QMediaServiceProviderFactoryInterface
{
    Q_OBJECT
    Q_INTERFACES(QMediaServiceProviderFactoryInterface)

public:
    QMediaService* create(const QString& key) override = 0;
    void release(QMediaService *service) override = 0;
};

/*!
    Service with support for media playback
    Required Controls: QMediaPlayerControl
    Optional Controls: QAudioDeviceControl
    Video Output Controls (used by QWideoWidget and QGraphicsVideoItem):
                        Required: QVideoOutputControl
                        Optional: QVideoWindowControl, QVideoRendererControl
*/
#define Q_MEDIASERVICE_MEDIAPLAYER "org.qt-project.qt.mediaplayer"

/*!
   Service with support for recording from audio sources
   Required Controls: QAudioDeviceControl
   Recording Controls (QMediaRecorder):
                        Required: QMediaRecorderControl
                        Recommended: QAudioEncoderSettingsControl
                        Optional: QMediaContainerControl
*/
#define Q_MEDIASERVICE_AUDIOSOURCE "org.qt-project.qt.audiosource"

/*!
    Service with support for camera use.
    Required Controls: QCameraControl
    Optional Controls: QCameraExposureControl, QCameraFocusControl, QCameraImageProcessingControl
    Still Capture Controls: QCameraImageCaptureControl
    Video Capture Controls (QMediaRecorder):
                        Required: QMediaRecorderControl
                        Recommended: QAudioEncoderSettingsControl, QVideoEncoderSettingsControl, QMediaContainerControl
    Viewfinder Video Output Controls (used by QCameraViewfinder and QGraphicsVideoItem):
                        Required: QVideoOutputControl
                        Optional: QVideoWindowControl, QVideoRendererControl
*/
#define Q_MEDIASERVICE_CAMERA "org.qt-project.qt.camera"

/*!
    Service with support for decoding audio.
    Required Controls: QAudioDecoderControl
    Optional: that streams control
*/
#define Q_MEDIASERVICE_AUDIODECODER "org.qt-project.qt.audiodecode"

QT_END_NAMESPACE

#endif  // QMEDIASERVICEPROVIDERPLUGIN_H
