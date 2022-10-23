// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

#ifndef QWASMMEDIAINTEGRATION_H
#define QWASMMEDIAINTEGRATION_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API. It exists purely as an
// implementation detail. This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <private/qplatformmediaintegration_p.h>

QT_BEGIN_NAMESPACE

class QWasmMediaDevices;

class QWasmMediaIntegration : public QPlatformMediaIntegration
{
public:
    QWasmMediaIntegration();
    ~QWasmMediaIntegration() override;

    QPlatformMediaFormatInfo *formatInfo() override;

    QPlatformMediaFormatInfo *m_formatInfo = nullptr;

    QMaybe<QPlatformMediaPlayer *> createPlayer(QMediaPlayer *player) override;
    QMaybe<QPlatformVideoSink *> createVideoSink(QVideoSink *sink) override;

    QMaybe<QPlatformAudioInput *> createAudioInput(QAudioInput *audioInput) override;
    QMaybe<QPlatformAudioOutput *> createAudioOutput(QAudioOutput *q) override;
};

QT_END_NAMESPACE

#endif // QWASMMEDIAINTEGRATION_H
