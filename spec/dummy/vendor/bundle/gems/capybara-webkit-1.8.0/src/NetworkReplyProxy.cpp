#include "NetworkReplyProxy.h"

NetworkReplyProxy::NetworkReplyProxy(QNetworkReply* reply, QObject* parent)
  : QNetworkReply(parent)
  , m_reply(reply)
{
  m_reply->setParent(this);

  setOperation(m_reply->operation());
  setRequest(m_reply->request());
  setUrl(m_reply->url());

  if (m_reply->isFinished()) {
    readInternal();
    setFinished(true);
  }

  applyMetaData();

  connect(m_reply, SIGNAL(metaDataChanged()), SLOT(applyMetaData()));
  connect(m_reply, SIGNAL(readyRead()), SLOT(handleReadyRead()));
  connect(m_reply, SIGNAL(error(QNetworkReply::NetworkError)), SLOT(errorInternal(QNetworkReply::NetworkError)));
  connect(m_reply, SIGNAL(finished()), SLOT(handleFinished()));

  connect(m_reply, SIGNAL(uploadProgress(qint64,qint64)), SIGNAL(uploadProgress(qint64,qint64)));
  connect(m_reply, SIGNAL(downloadProgress(qint64,qint64)), SIGNAL(downloadProgress(qint64,qint64)));
  connect(m_reply, SIGNAL(sslErrors(const QList<QSslError> &)), SIGNAL(sslErrors(const QList<QSslError> &)));

  setOpenMode(ReadOnly);
}

void NetworkReplyProxy::abort() { m_reply->abort(); }
void NetworkReplyProxy::close() { m_reply->close(); }
bool NetworkReplyProxy::isSequential() const { return m_reply->isSequential(); }

void NetworkReplyProxy::handleFinished() {
  setFinished(true);
  emit finished();
}

qint64 NetworkReplyProxy::bytesAvailable() const
{
  return m_buffer.size() + QIODevice::bytesAvailable();
}

qint64 NetworkReplyProxy::readData(char* data, qint64 maxlen)
{
  qint64 size = qMin(maxlen, qint64(m_buffer.size()));
  memcpy(data, m_buffer.constData(), size);
  m_buffer.remove(0, size);
  return size;
}

void NetworkReplyProxy::ignoreSslErrors() { m_reply->ignoreSslErrors(); }
void NetworkReplyProxy::applyMetaData() {
  foreach(QNetworkReply::RawHeaderPair header, m_reply->rawHeaderPairs())
    setRawHeader(header.first, header.second);

  setAttribute(QNetworkRequest::HttpStatusCodeAttribute, m_reply->attribute(QNetworkRequest::HttpStatusCodeAttribute));
  setAttribute(QNetworkRequest::HttpReasonPhraseAttribute, m_reply->attribute(QNetworkRequest::HttpReasonPhraseAttribute));
  setAttribute(QNetworkRequest::RedirectionTargetAttribute, m_reply->attribute(QNetworkRequest::RedirectionTargetAttribute));
  setAttribute(QNetworkRequest::ConnectionEncryptedAttribute, m_reply->attribute(QNetworkRequest::ConnectionEncryptedAttribute));
  setAttribute(QNetworkRequest::CacheLoadControlAttribute, m_reply->attribute(QNetworkRequest::CacheLoadControlAttribute));
  setAttribute(QNetworkRequest::CacheSaveControlAttribute, m_reply->attribute(QNetworkRequest::CacheSaveControlAttribute));
  setAttribute(QNetworkRequest::SourceIsFromCacheAttribute, m_reply->attribute(QNetworkRequest::SourceIsFromCacheAttribute));
  setAttribute(QNetworkRequest::DoNotBufferUploadDataAttribute, m_reply->attribute(QNetworkRequest::DoNotBufferUploadDataAttribute));
  emit metaDataChanged();
}

void NetworkReplyProxy::errorInternal(QNetworkReply::NetworkError _error)
{
  setError(_error, errorString());
  emit error(_error);
}

void NetworkReplyProxy::readInternal() {
  QByteArray data = m_reply->readAll();
  m_data += data;
  m_buffer += data;
}

void NetworkReplyProxy::handleReadyRead()
{
  readInternal();
  emit readyRead();
}

QByteArray NetworkReplyProxy::data() {
  return m_data;
}

