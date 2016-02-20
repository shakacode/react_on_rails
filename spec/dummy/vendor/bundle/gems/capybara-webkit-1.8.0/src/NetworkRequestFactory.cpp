#include "NetworkRequestFactory.h"
#include "NetworkAccessManager.h"

NetworkRequestFactory::NetworkRequestFactory(QObject *parent) :
  RequestHandler(parent) {
}

QNetworkReply* NetworkRequestFactory::handleRequest(
  NetworkAccessManager *manager,
  QNetworkAccessManager::Operation operation,
  QNetworkRequest &request,
  QIODevice *outgoingData
) {
  return manager->sendRequest(operation, request, outgoingData);
}
