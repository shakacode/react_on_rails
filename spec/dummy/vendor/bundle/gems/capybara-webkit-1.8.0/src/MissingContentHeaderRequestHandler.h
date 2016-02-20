#include "RequestHandler.h"

class MissingContentHeaderRequestHandler : public RequestHandler {
  public:
    MissingContentHeaderRequestHandler(RequestHandler *next, QObject *parent = 0);
    virtual QNetworkReply* handleRequest(
      NetworkAccessManager *,
      QNetworkAccessManager::Operation,
      QNetworkRequest &,
      QIODevice *
    );

  private:
    RequestHandler *m_next;
};
