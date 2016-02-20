#ifndef __NETWORKACCESSMANAGER_H
#define __NETWORKACCESSMANAGER_H
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkReply>

class RequestHandler;

class NetworkAccessManager : public QNetworkAccessManager {
  Q_OBJECT

  public:
    NetworkAccessManager(RequestHandler *, QObject *parent = 0);
    void reset();
    void setUserName(const QString &userName);
    void setPassword(const QString &password);
    QNetworkReply* sendRequest(
      QNetworkAccessManager::Operation,
      const QNetworkRequest &,
      QIODevice *
    );

  protected:
    QNetworkReply* createRequest(
      QNetworkAccessManager::Operation,
      const QNetworkRequest &,
      QIODevice *
    );
    QString m_userName;
    QString m_password;

  private:
    void disableKeyChainLookup();

    QHash<QUrl, QUrl> m_redirectMappings;
    RequestHandler * m_requestHandler;

  private slots:
    void provideAuthentication(QNetworkReply *reply, QAuthenticator *authenticator);
    void finished(QNetworkReply *);

  signals:
    void requestCreated(QByteArray &url, QNetworkReply *reply);
    void finished(QUrl &, QNetworkReply *);
};
#endif
