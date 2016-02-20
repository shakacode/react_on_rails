#include "WebPageManager.h"
#include "WebPage.h"
#include "NetworkCookieJar.h"
#include "NetworkAccessManager.h"
#include "BlacklistedRequestHandler.h"
#include "CustomHeadersRequestHandler.h"
#include "MissingContentHeaderRequestHandler.h"
#include "UnknownUrlHandler.h"
#include "NetworkRequestFactory.h"

WebPageManager::WebPageManager(QObject *parent) : QObject(parent) {
  m_ignoreSslErrors = false;
  m_cookieJar = new NetworkCookieJar(this);
  m_success = true;
  m_loggingEnabled = false;
  m_ignoredOutput = new QFile(this);
  m_timeout = -1;
  m_customHeadersRequestHandler = new CustomHeadersRequestHandler(
    new MissingContentHeaderRequestHandler(
      new NetworkRequestFactory(this),
      this
    ),
    this
  );
  m_unknownUrlHandler =
    new UnknownUrlHandler(m_customHeadersRequestHandler, this);
  m_blacklistedRequestHandler =
    new BlacklistedRequestHandler(m_unknownUrlHandler, this);
  m_networkAccessManager =
    new NetworkAccessManager(m_blacklistedRequestHandler, this);
  m_networkAccessManager->setCookieJar(m_cookieJar);

  createPage()->setFocus();
}

NetworkAccessManager *WebPageManager::networkAccessManager() {
  return m_networkAccessManager;
}

void WebPageManager::append(WebPage *value) {
  m_pages.append(value);
}

QList<WebPage *> WebPageManager::pages() const {
  return m_pages;
}

void WebPageManager::setCurrentPage(WebPage *page) {
  m_currentPage = page;
}

WebPage *WebPageManager::currentPage() const {
  return m_currentPage;
}

WebPage *WebPageManager::createPage() {
  WebPage *page = new WebPage(this);
  connect(page, SIGNAL(loadStarted()),
          this, SLOT(emitLoadStarted()));
  connect(page, SIGNAL(pageFinished(bool)),
          this, SLOT(setPageStatus(bool)));
  connect(page, SIGNAL(requestCreated(QByteArray &, QNetworkReply *)),
          this, SLOT(requestCreated(QByteArray &, QNetworkReply *)));
  append(page);
  return page;
}

void WebPageManager::removePage(WebPage *page) {
  m_pages.removeOne(page);
  page->deleteLater();
  if (m_pages.isEmpty())
    createPage()->setFocus();
  else if (page == m_currentPage)
    m_pages.first()->setFocus();
}

void WebPageManager::emitLoadStarted() {
  if (m_started.empty()) {
    logger() << "Load started";
    emit loadStarted();
  }
  m_started += qobject_cast<WebPage *>(sender());
}

void WebPageManager::requestCreated(QByteArray &url, QNetworkReply *reply) {
  logger() << "Started request to" << url;
  if (reply->isFinished())
    replyFinished(reply);
  else {
    m_pendingReplies.append(reply);
    connect(reply, SIGNAL(finished()), SLOT(handleReplyFinished()));
    connect(
      reply,
      SIGNAL(destroyed(QObject *)),
      SLOT(replyDestroyed(QObject *))
    );
  }
}

void WebPageManager::handleReplyFinished() {
  QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
  disconnect(reply, SIGNAL(finished()), this, SLOT(handleReplyFinished()));
  replyFinished(reply);
}

void WebPageManager::replyFinished(QNetworkReply *reply) {
  int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
  logger() << "Received" << status << "from" << reply->url().toString();
  m_pendingReplies.removeAll(reply);
}

void WebPageManager::replyDestroyed(QObject *reply) {
  m_pendingReplies.removeAll((QNetworkReply *) reply);
}

void WebPageManager::setPageStatus(bool success) {
  logger() << "Page finished with" << success;
  m_started.remove(qobject_cast<WebPage *>(sender()));
  m_success = success && m_success;
  if (m_started.empty()) {
    emitPageFinished();
  }
}

void WebPageManager::emitPageFinished() {
  logger() << "Load finished";
  emit pageFinished(m_success);
  m_success = true;
}

void WebPageManager::setIgnoreSslErrors(bool value) {
  m_ignoreSslErrors = value;
}

bool WebPageManager::ignoreSslErrors() {
  return m_ignoreSslErrors;
}

int WebPageManager::getTimeout() {
  return m_timeout;
}

void WebPageManager::setTimeout(int timeout) {
  m_timeout = timeout;
}

void WebPageManager::reset() {
  m_timeout = -1;
  m_cookieJar->clearCookies();
  m_networkAccessManager->reset();
  m_customHeadersRequestHandler->reset();
  m_currentPage->resetLocalStorage();
  m_blacklistedRequestHandler->reset();
  m_unknownUrlHandler->reset();

  foreach(QNetworkReply *reply, m_pendingReplies) {
    logger() << "Aborting request to" << reply->url().toString();
    reply->abort();
  }
  m_pendingReplies.clear();

  while (!m_pages.isEmpty()) {
    WebPage *page = m_pages.takeFirst();
    page->deleteLater();
  }

  qint64 size = QWebSettings::offlineWebApplicationCacheQuota();
  // No public function was found to wrap the empty() call to
  // WebCore::cacheStorage().empty()
  QWebSettings::setOfflineWebApplicationCacheQuota(size);

  createPage()->setFocus();
}

NetworkCookieJar *WebPageManager::cookieJar() {
  return m_cookieJar;
}

bool WebPageManager::isLoading() const {
  foreach(WebPage *page, pages()) {
    if (page->isLoading()) {
      return true;
    }
  }
  return false;
}

QDebug WebPageManager::logger() const {
  if (m_loggingEnabled) {
    return qCritical();
  } else {
    return QDebug(m_ignoredOutput);
  }
}

void WebPageManager::enableLogging() {
  m_loggingEnabled = true;
}

void WebPageManager::setUrlBlacklist(const QStringList &urls) {
  m_blacklistedRequestHandler->setUrlBlacklist(urls);
}

void WebPageManager::addHeader(QString key, QString value) {
  m_customHeadersRequestHandler->addHeader(key, value);
}

void WebPageManager::setUnknownUrlMode(UnknownUrlHandler::Mode mode) {
  m_unknownUrlHandler->setMode(mode);
}

void WebPageManager::allowUrl(const QString &url) {
  m_unknownUrlHandler->allowUrl(url);
}

void WebPageManager::blockUrl(const QString &url) {
  m_blacklistedRequestHandler->blockUrl(url);
}
