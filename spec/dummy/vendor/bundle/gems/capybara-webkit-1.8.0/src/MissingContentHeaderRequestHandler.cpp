#include "MissingContentHeaderRequestHandler.h"
#include "NetworkReplyProxy.h"
#include "NoOpReply.h"

MissingContentHeaderRequestHandler::MissingContentHeaderRequestHandler(
  RequestHandler *next,
  QObject *parent
) : RequestHandler(parent) {
  m_next = next;
}

QNetworkReply* MissingContentHeaderRequestHandler::handleRequest(
  NetworkAccessManager *manager,
  QNetworkAccessManager::Operation operation,
  QNetworkRequest &request,
  QIODevice *outgoingData
) {
  if (operation != QNetworkAccessManager::PostOperation && operation != QNetworkAccessManager::PutOperation) {
    request.setHeader(QNetworkRequest::ContentTypeHeader, QVariant());
  }

  return m_next->handleRequest(manager, operation, request, outgoingData);
}
