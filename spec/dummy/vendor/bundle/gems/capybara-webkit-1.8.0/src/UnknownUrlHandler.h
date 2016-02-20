#ifndef _REQUESTHANDLER_H
#define _REQUESTHANDLER_H

#include "RequestHandler.h"

class UnknownUrlHandler : public RequestHandler {
  public:
    enum Mode { WARN, BLOCK };

    UnknownUrlHandler(RequestHandler *next, QObject *parent = 0);
    virtual QNetworkReply* handleRequest(
      NetworkAccessManager *,
      QNetworkAccessManager::Operation,
      QNetworkRequest &,
      QIODevice *
    );
    void allowUrl(const QString &);
    void setMode(Mode);
    void reset();

  private:
    QStringList m_allowedUrls;
    bool isUnknown(QUrl);
    Mode m_mode;
    RequestHandler *m_next;
    void allowDefaultUrls();
};

#endif
