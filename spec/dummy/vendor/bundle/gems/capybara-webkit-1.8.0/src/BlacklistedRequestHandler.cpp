#include "BlacklistedRequestHandler.h"
#include "NetworkReplyProxy.h"
#include "NoOpReply.h"

BlacklistedRequestHandler::BlacklistedRequestHandler(
  RequestHandler *next,
  QObject *parent
) : RequestHandler(parent) {
  m_next = next;
}

QNetworkReply* BlacklistedRequestHandler::handleRequest(
  NetworkAccessManager *manager,
  QNetworkAccessManager::Operation operation,
  QNetworkRequest &request,
  QIODevice *outgoingData
) {
  if (this->isBlacklisted(request.url())) {
    return new NetworkReplyProxy(new NoOpReply(request), this);
  } else {
    return m_next->handleRequest(manager, operation, request, outgoingData);
  }
}

void BlacklistedRequestHandler::setUrlBlacklist(QStringList urlBlacklist) {
  m_urlBlacklist.clear();

  QStringListIterator iter(urlBlacklist);
  while (iter.hasNext()) {
    m_urlBlacklist << iter.next();
  }
}

bool BlacklistedRequestHandler::isBlacklisted(QUrl url) {
  QString urlString = url.toString();
  QStringListIterator iter(m_urlBlacklist);

  while (iter.hasNext()) {
    QRegExp blacklisted = QRegExp(iter.next());
    blacklisted.setPatternSyntax(QRegExp::Wildcard);

    if(urlString.contains(blacklisted)) {
      return true;
    }
  }

  return false;
}

void BlacklistedRequestHandler::blockUrl(const QString &url) {
  m_urlBlacklist.append(url);
}

void BlacklistedRequestHandler::reset() {
  m_urlBlacklist.clear();
}
