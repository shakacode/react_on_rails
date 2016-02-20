#include <QTimer>
#include "NoOpReply.h"

NoOpReply::NoOpReply(const QNetworkRequest &request, QObject *parent) : QNetworkReply(parent) {
  open(ReadOnly | Unbuffered);
  setAttribute(QNetworkRequest::HttpStatusCodeAttribute, 200);
  setHeader(QNetworkRequest::ContentLengthHeader, QVariant(0));
  setHeader(QNetworkRequest::ContentTypeHeader, QVariant(QString("text/plain")));
  setUrl(request.url());

  QTimer::singleShot( 0, this, SIGNAL(readyRead()) );
  QTimer::singleShot( 0, this, SIGNAL(finished()) );
}

void NoOpReply::abort() {
  // NO-OP
}

qint64 NoOpReply::bytesAvailable() const {
  return 0;
}

bool NoOpReply::isSequential() const {
  return true;
}

qint64 NoOpReply::readData(char *data, qint64 maxSize) {
  Q_UNUSED(data);
  Q_UNUSED(maxSize);
  return 0;
}

