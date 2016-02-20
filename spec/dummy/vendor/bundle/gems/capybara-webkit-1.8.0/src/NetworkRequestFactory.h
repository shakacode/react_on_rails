#include "RequestHandler.h"

class NetworkRequestFactory : public RequestHandler {
  public:
    NetworkRequestFactory(QObject *parent = 0);
    virtual QNetworkReply* handleRequest(
      NetworkAccessManager *,
      QNetworkAccessManager::Operation,
      QNetworkRequest &,
      QIODevice *
    );
};
