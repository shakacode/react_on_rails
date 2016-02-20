#include <QHash>
#include <QString>

#include "RequestHandler.h"

class CustomHeadersRequestHandler : public RequestHandler {
  public:
    CustomHeadersRequestHandler(RequestHandler *next, QObject *parent = 0);
    virtual QNetworkReply* handleRequest(
      NetworkAccessManager *,
      QNetworkAccessManager::Operation,
      QNetworkRequest &,
      QIODevice *
    );
    void addHeader(QString, QString);
    virtual void reset();

  private:
    RequestHandler *m_next;
    QHash<QString, QString> m_headers;
};
