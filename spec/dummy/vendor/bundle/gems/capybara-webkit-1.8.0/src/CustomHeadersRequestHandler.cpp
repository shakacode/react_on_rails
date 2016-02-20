#include "CustomHeadersRequestHandler.h"
#include "NetworkReplyProxy.h"
#include "NoOpReply.h"

CustomHeadersRequestHandler::CustomHeadersRequestHandler(
  RequestHandler *next,
  QObject *parent
) : RequestHandler(parent) {
  m_next = next;
}

QNetworkReply* CustomHeadersRequestHandler::handleRequest(
  NetworkAccessManager *manager,
  QNetworkAccessManager::Operation operation,
  QNetworkRequest &request,
  QIODevice *outgoingData
) {
  Q_UNUSED(manager)
  Q_UNUSED(operation)
  Q_UNUSED(outgoingData)

  QHashIterator<QString, QString> item(m_headers);
  while (item.hasNext()) {
    item.next();
    request.setRawHeader(item.key().toLatin1(), item.value().toLatin1());
  }

  return m_next->handleRequest(manager, operation, request, outgoingData);
}

void CustomHeadersRequestHandler::addHeader(QString key, QString value) {
  m_headers.insert(key, value);
}

void CustomHeadersRequestHandler::reset() {
  m_headers.clear();
}
