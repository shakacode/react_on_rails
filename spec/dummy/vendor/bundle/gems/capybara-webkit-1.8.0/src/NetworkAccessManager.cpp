#include "NetworkAccessManager.h"
#include "WebPage.h"
#include "NetworkReplyProxy.h"
#include "RequestHandler.h"

NetworkAccessManager::NetworkAccessManager(
  RequestHandler * requestHandler,
  QObject *parent
) : QNetworkAccessManager(parent) {
  m_requestHandler = requestHandler;
  connect(this, SIGNAL(authenticationRequired(QNetworkReply*,QAuthenticator*)), SLOT(provideAuthentication(QNetworkReply*,QAuthenticator*)));
  connect(this, SIGNAL(finished(QNetworkReply *)), this, SLOT(finished(QNetworkReply *)));
  disableKeyChainLookup();
}

QNetworkReply* NetworkAccessManager::sendRequest(
  QNetworkAccessManager::Operation operation,
  const QNetworkRequest &request,
  QIODevice * outgoingData
) {
  QNetworkReply *reply = new NetworkReplyProxy(
    QNetworkAccessManager::createRequest(operation,
      request,
      outgoingData
    ),
    this
  );

  QByteArray url = reply->request().url().toEncoded();
  emit requestCreated(url, reply);

  return reply;
}

QNetworkReply* NetworkAccessManager::createRequest(
  QNetworkAccessManager::Operation operation,
  const QNetworkRequest &unsafeRequest,
  QIODevice * outgoingData = 0
) {
  QNetworkRequest request(unsafeRequest);
  QNetworkReply *reply =
    m_requestHandler->handleRequest(this, operation, request, outgoingData);
  return reply;
};

void NetworkAccessManager::finished(QNetworkReply *reply) {
  QUrl redirectUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
  if (redirectUrl.isValid())
    m_redirectMappings[reply->url().resolved(redirectUrl)] = reply->url();
  else {
    QUrl requestedUrl = reply->url();
    while (m_redirectMappings.contains(requestedUrl))
      requestedUrl = m_redirectMappings.take(requestedUrl);
    emit finished(requestedUrl, reply);
  }
}

void NetworkAccessManager::reset() {
  m_userName = QString();
  m_password = QString();
}

void NetworkAccessManager::setUserName(const QString &userName) {
  m_userName = userName;
}

void NetworkAccessManager::setPassword(const QString &password) {
  m_password = password;
}

void NetworkAccessManager::provideAuthentication(QNetworkReply *reply, QAuthenticator *authenticator) {
  Q_UNUSED(reply);
  if (m_userName != authenticator->user())
    authenticator->setUser(m_userName);
  if (m_password != authenticator->password())
    authenticator->setPassword(m_password);
}

/*
 * This is a workaround for a Qt 5/OS X bug:
 * https://bugreports.qt-project.org/browse/QTBUG-30434
 */
void NetworkAccessManager::disableKeyChainLookup() {
  QNetworkProxy fixedProxy = proxy();
  fixedProxy.setHostName(" ");
  setProxy(fixedProxy);
}
