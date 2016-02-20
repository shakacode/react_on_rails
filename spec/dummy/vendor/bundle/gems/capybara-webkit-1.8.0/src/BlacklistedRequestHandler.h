#include <QStringList>

#include "RequestHandler.h"

class BlacklistedRequestHandler : public RequestHandler {
  public:
    BlacklistedRequestHandler(RequestHandler *next, QObject *parent = 0);
    virtual QNetworkReply* handleRequest(
      NetworkAccessManager *,
      QNetworkAccessManager::Operation,
      QNetworkRequest &,
      QIODevice *
    );
    void setUrlBlacklist(QStringList urlBlacklist);
    void blockUrl(const QString &);
    void reset();

  private:
    RequestHandler *m_next;
    QStringList m_urlBlacklist;
    bool isBlacklisted(QUrl url);
};
