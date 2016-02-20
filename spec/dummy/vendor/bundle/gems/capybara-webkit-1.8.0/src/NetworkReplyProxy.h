#ifndef _NETWORKREPLYPROXY_H
#define _NETWORKREPLYPROXY_H
/*
 * Copyright (C) 2009, 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2009, 2010 Holger Hans Peter Freyther
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <QObject>
#include <QtNetwork/QNetworkReply>

class NetworkReplyProxy : public QNetworkReply {
  Q_OBJECT

  public:
    NetworkReplyProxy(QNetworkReply* reply, QObject* parent);

    virtual void abort();
    virtual void close();
    virtual bool isSequential() const;

    virtual qint64 bytesAvailable() const;

    virtual qint64 readData(char* data, qint64 maxlen);

    QByteArray data();

  public slots:
    void ignoreSslErrors();
    void applyMetaData();
    void errorInternal(QNetworkReply::NetworkError _error);
    void handleReadyRead();
    void handleFinished();

  private:
    void readInternal();

    QNetworkReply* m_reply;
    QByteArray m_data;
    QByteArray m_buffer;
};

#endif
