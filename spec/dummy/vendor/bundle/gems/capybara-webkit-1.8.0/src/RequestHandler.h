#ifndef __REQUESTHANDLER_H
#define __REQUESTHANDLER_H

#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkReply>
#include <QStringList>

class NetworkAccessManager;

class RequestHandler : public QObject {
  Q_OBJECT

  public:
    RequestHandler(QObject *parent = 0);

    virtual QNetworkReply* handleRequest(
      NetworkAccessManager *,
      QNetworkAccessManager::Operation,
      QNetworkRequest &,
      QIODevice *
    ) = 0;
};

#endif
