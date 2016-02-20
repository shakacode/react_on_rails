#include "WebPage.h"
#include "WebPageManager.h"
#include "JavascriptInvocation.h"
#include "NetworkAccessManager.h"
#include "NetworkCookieJar.h"
#include "UnsupportedContentHandler.h"
#include "InvocationResult.h"
#include "NetworkReplyProxy.h"
#include <QResource>
#include <iostream>
#include <QWebSettings>
#include <QUuid>
#include <QApplication>
#include <QWebView>
#include <QMainWindow>

WebPage::WebPage(WebPageManager *manager, QObject *parent) : QWebPage(parent) {
  m_loading = false;
  m_failed = false;
  m_manager = manager;
  m_uuid = QUuid::createUuid().toString();
  m_confirmAction = true;
  m_promptAction = false;

  setForwardUnsupportedContent(true);
  loadJavascript();
  setUserStylesheet();

  this->setCustomNetworkAccessManager();

  connect(this, SIGNAL(loadStarted()), this, SLOT(loadStarted()));
  connect(this, SIGNAL(loadFinished(bool)), this, SLOT(loadFinished(bool)));
  connect(this, SIGNAL(frameCreated(QWebFrame *)),
          this, SLOT(frameCreated(QWebFrame *)));
  connect(this, SIGNAL(unsupportedContent(QNetworkReply*)),
      this, SLOT(handleUnsupportedContent(QNetworkReply*)));
  connect(this, SIGNAL(windowCloseRequested()), this, SLOT(remove()));

  settings()->setAttribute(QWebSettings::JavascriptCanOpenWindows, true);
  settings()->setAttribute(QWebSettings::JavascriptCanCloseWindows, true);
  settings()->setAttribute(QWebSettings::LocalStorageDatabaseEnabled, true);

  if(QFileInfo("tmp").isDir()) {
    settings()->setAttribute(QWebSettings::OfflineWebApplicationCacheEnabled, true);
    settings()->setOfflineWebApplicationCachePath("tmp");
  }

  createWindow();
}

void WebPage::createWindow() {
  QSize size(1680, 1050);
  setViewportSize(size);
}

void WebPage::resize(int width, int height) {
  QSize size(width, height);
  setViewportSize(size);
}

void WebPage::resetLocalStorage() {
  this->currentFrame()->evaluateJavaScript("localStorage.clear()");
}

void WebPage::setCustomNetworkAccessManager() {
  setNetworkAccessManager(m_manager->networkAccessManager());
  connect(networkAccessManager(), SIGNAL(sslErrors(QNetworkReply *, QList<QSslError>)),
          SLOT(handleSslErrorsForReply(QNetworkReply *, QList<QSslError>)));
  connect(networkAccessManager(), SIGNAL(requestCreated(QByteArray &, QNetworkReply *)),
          SIGNAL(requestCreated(QByteArray &, QNetworkReply *)));
  connect(networkAccessManager(), SIGNAL(finished(QUrl &, QNetworkReply *)),
          SLOT(replyFinished(QUrl &, QNetworkReply *)));
}

void WebPage::replyFinished(QUrl &requestedUrl, QNetworkReply *reply) {
  NetworkReplyProxy *proxy = qobject_cast<NetworkReplyProxy *>(reply);
  setFrameProperties(mainFrame(), requestedUrl, proxy);
  foreach(QWebFrame *frame, mainFrame()->childFrames())
    setFrameProperties(frame, requestedUrl, proxy);
}

void WebPage::setFrameProperties(QWebFrame *frame, QUrl &requestedUrl, NetworkReplyProxy *reply) {
  if (frame->requestedUrl() == requestedUrl) {
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    frame->setProperty("statusCode", statusCode);
    if (statusCode != 304) {
      QVariantMap headers;
      foreach(QNetworkReply::RawHeaderPair header, reply->rawHeaderPairs())
        headers[header.first] = QString(header.second);
      frame->setProperty("headers", headers);
      frame->setProperty("body", reply->data());
      QVariant contentMimeType = reply->header(QNetworkRequest::ContentTypeHeader);
      frame->setProperty("contentType", contentMimeType);
    }
  }
}

void WebPage::unsupportedContentFinishedReply(QNetworkReply *reply) {
  m_manager->replyFinished(reply);
}

void WebPage::loadJavascript() {
  QResource javascript(":/capybara.js");
  if (javascript.isCompressed()) {
    QByteArray uncompressedBytes(qUncompress(javascript.data(), javascript.size()));
    m_capybaraJavascript = QString(uncompressedBytes);
  } else {
    char * javascriptString =  new char[javascript.size() + 1];
    strcpy(javascriptString, (const char *)javascript.data());
    javascriptString[javascript.size()] = 0;
    m_capybaraJavascript = javascriptString;
  }
}

void WebPage::setUserStylesheet() {
  QString data = QString("*, :before, :after { font-family: 'Arial' ! important; }").toUtf8().toBase64();
  QUrl url = QUrl(QString("data:text/css;charset=utf-8;base64,") + data);
  settings()->setUserStyleSheetUrl(url);
}

QString WebPage::userAgentForUrl(const QUrl &url ) const {
  if (!m_userAgent.isEmpty()) {
    return m_userAgent;
  } else {
    return QWebPage::userAgentForUrl(url);
  }
}

QVariantList WebPage::consoleMessages() {
  return m_consoleMessages;
}

QVariantList WebPage::alertMessages() {
  return m_alertMessages;
}

QVariantList WebPage::confirmMessages() {
  return m_confirmMessages;
}

QVariantList WebPage::promptMessages() {
  return m_promptMessages;
}

void WebPage::setUserAgent(QString userAgent) {
  m_userAgent = userAgent;
}

void WebPage::frameCreated(QWebFrame * frame) {
  connect(frame, SIGNAL(javaScriptWindowObjectCleared()),
          this,  SLOT(injectJavascriptHelpers()));
}

void WebPage::injectJavascriptHelpers() {
  QWebFrame* frame = qobject_cast<QWebFrame *>(QObject::sender());
  frame->evaluateJavaScript(m_capybaraJavascript);
}

bool WebPage::shouldInterruptJavaScript() {
  return false;
}

InvocationResult WebPage::invokeCapybaraFunction(const char *name, bool allowUnattached, const QStringList &arguments) {
  QString qname(name);
  JavascriptInvocation invocation(qname, allowUnattached, arguments, this);
  return invocation.invoke(currentFrame());
}

InvocationResult WebPage::invokeCapybaraFunction(QString &name, bool allowUnattached, const QStringList &arguments) {
  return invokeCapybaraFunction(name.toLatin1().data(), allowUnattached, arguments);
}

void WebPage::javaScriptConsoleMessage(const QString &message, int lineNumber, const QString &sourceID) {
  QVariantMap m;
  m["message"] = message;
  QString fullMessage = QString(message);
  if (!sourceID.isEmpty()) {
    fullMessage = sourceID + "|" + QString::number(lineNumber) + "|" + fullMessage;
    m["source"] = sourceID;
    m["line_number"] = lineNumber;
  }
  m_consoleMessages.append(m);
  m_manager->logger() << qPrintable(fullMessage);
}

void WebPage::javaScriptAlert(QWebFrame *frame, const QString &message) {
  Q_UNUSED(frame);
  m_alertMessages.append(message);

  if (m_modalResponses.isEmpty()) {
    m_modalMessages << QString();
  } else {
    QVariantMap alertResponse = m_modalResponses.takeLast();
    bool expectedType = alertResponse["type"].toString() == "alert";
    QRegExp expectedMessage = alertResponse["message"].toRegExp();

    addModalMessage(expectedType, message, expectedMessage);
  }

  m_manager->logger() << "ALERT:" << qPrintable(message);
}

bool WebPage::javaScriptConfirm(QWebFrame *frame, const QString &message) {
  Q_UNUSED(frame);
  m_confirmMessages.append(message);

  if (m_modalResponses.isEmpty()) {
    m_modalMessages << QString();
    return m_confirmAction;
  } else {
    QVariantMap confirmResponse = m_modalResponses.takeLast();
    bool expectedType = confirmResponse["type"].toString() == "confirm";
    QRegExp expectedMessage = confirmResponse["message"].toRegExp();

    addModalMessage(expectedType, message, expectedMessage);
    return expectedType &&
      confirmResponse["action"].toBool() &&
      message.contains(expectedMessage);
  }
}

bool WebPage::javaScriptPrompt(QWebFrame *frame, const QString &message, const QString &defaultValue, QString *result) {
  Q_UNUSED(frame)
  m_promptMessages.append(message);

  bool action = false;
  QString response;

  if (m_modalResponses.isEmpty()) {
    action = m_promptAction;
    response = m_prompt_text;
    m_modalMessages << QString();
  } else {
    QVariantMap promptResponse = m_modalResponses.takeLast();
    bool expectedType = promptResponse["type"].toString() == "prompt";
    QRegExp expectedMessage = promptResponse["message"].toRegExp();

    action = expectedType &&
      promptResponse["action"].toBool() &&
      message.contains(expectedMessage);
    response = promptResponse["response"].toString();
    addModalMessage(expectedType, message, expectedMessage);
  }

  if (action) {
    if (response.isNull()) {
      *result = defaultValue;
    } else {
      *result = response;
    }
  }

  return action;
}

void WebPage::loadStarted() {
  m_loading = true;
  m_errorPageMessage = QString();
}

void WebPage::loadFinished(bool success) {
  Q_UNUSED(success);
  m_loading = false;
  emit pageFinished(!m_failed);
  m_failed = false;
}

bool WebPage::isLoading() const {
  return m_loading;
}

QString WebPage::failureString() {
  QString message = QString("Unable to load URL: ") + currentFrame()->requestedUrl().toString();
  if (m_errorPageMessage.isEmpty())
    return message;
  else
    return message + m_errorPageMessage;
}

void WebPage::mouseEvent(QEvent::Type type, const QPoint &position, Qt::MouseButton button) {
  m_mousePosition = position;
  QMouseEvent event(type, position, button, button, Qt::NoModifier);
  QApplication::sendEvent(this, &event);
}

bool WebPage::clickTest(QWebElement element, int absoluteX, int absoluteY) {
  QPoint mousePos(absoluteX, absoluteY);
  m_mousePosition = mousePos;
  QWebHitTestResult res = mainFrame()->hitTestContent(mousePos);
  return res.frame() == element.webFrame();
}

bool WebPage::render(const QString &fileName, const QSize &minimumSize) {
  QFileInfo fileInfo(fileName);
  QDir dir;
  dir.mkpath(fileInfo.absolutePath());

  QSize viewportSize = this->viewportSize();
  this->setViewportSize(minimumSize);
  QSize pageSize = this->mainFrame()->contentsSize();
  if (pageSize.isEmpty()) {
    return false;
  }

  QImage buffer(pageSize, QImage::Format_ARGB32);
  buffer.fill(qRgba(255, 255, 255, 0));

  QPainter p(&buffer);
  p.setRenderHint( QPainter::Antialiasing,          true);
  p.setRenderHint( QPainter::TextAntialiasing,      true);
  p.setRenderHint( QPainter::SmoothPixmapTransform, true);

  this->setViewportSize(pageSize);
  this->mainFrame()->render(&p);

  QImage pointer = QImage(":/pointer.png");
  p.drawImage(m_mousePosition, pointer);

  p.end();
  this->setViewportSize(viewportSize);

  return buffer.save(fileName);
}

QString WebPage::chooseFile(QWebFrame *parentFrame, const QString &suggestedFile) {
  Q_UNUSED(parentFrame);
  Q_UNUSED(suggestedFile);

  return getAttachedFileNames().first();
}

bool WebPage::extension(Extension extension, const ExtensionOption *option, ExtensionReturn *output) {
  if (extension == ChooseMultipleFilesExtension) {
    static_cast<ChooseMultipleFilesExtensionReturn*>(output)->fileNames = getAttachedFileNames();
    return true;
  }
  else if (extension == QWebPage::ErrorPageExtension) {
    ErrorPageExtensionOption *errorOption = (ErrorPageExtensionOption*) option;
    m_errorPageMessage = " because of error loading " + errorOption->url.toString() + ": " + errorOption->errorString;
    m_failed = true;
    return false;
  }
  return false;
}

QStringList WebPage::getAttachedFileNames() {
  return currentFrame()->evaluateJavaScript(QString("Capybara.attachedFiles")).toStringList();
}

void WebPage::handleSslErrorsForReply(QNetworkReply *reply, const QList<QSslError> &errors) {
  Q_UNUSED(errors);
  if (m_manager->ignoreSslErrors())
    reply->ignoreSslErrors();
}

void WebPage::setSkipImageLoading(bool skip) {
  settings()->setAttribute(QWebSettings::AutoLoadImages, !skip);
}

int WebPage::getLastStatus() {
  return currentFrame()->property("statusCode").toInt();
}

QVariantMap WebPage::pageHeaders() {
  return currentFrame()->property("headers").toMap();
}

QByteArray WebPage::body() {
  return currentFrame()->property("body").toByteArray();
}

QString WebPage::contentType() {
  return currentFrame()->property("contentType").toString();
}

void WebPage::handleUnsupportedContent(QNetworkReply *reply) {
  QVariant contentMimeType = reply->header(QNetworkRequest::ContentTypeHeader);
  if(!contentMimeType.isNull()) {
    triggerAction(QWebPage::Stop);
    UnsupportedContentHandler *handler = new UnsupportedContentHandler(this, reply);
    if (reply->isFinished())
      handler->renderNonHtmlContent();
    else
      handler->waitForReplyToFinish();
  }
}

bool WebPage::supportsExtension(Extension extension) const {
  if (extension == ErrorPageExtension)
    return true;
  else if (extension == ChooseMultipleFilesExtension)
    return true;
  else
    return false;
}

QWebPage *WebPage::createWindow(WebWindowType type) {
  Q_UNUSED(type);
  return m_manager->createPage();
}

QString WebPage::uuid() {
  return m_uuid;
}

QString WebPage::getWindowName() {
  QVariant windowName = mainFrame()->evaluateJavaScript("window.name");

  if (windowName.isValid())
    return windowName.toString();
  else
    return "";
}

bool WebPage::matchesWindowSelector(QString selector) {
  return (selector == getWindowName()           ||
      selector == mainFrame()->title()          ||
      selector == mainFrame()->url().toString() ||
      selector == uuid());
}

void WebPage::setFocus() {
  m_manager->setCurrentPage(this);
}

void WebPage::remove() {
  m_manager->removePage(this);
}

QString WebPage::setConfirmAction(QString action, QString message) {
  QVariantMap confirmResponse;
  confirmResponse["type"] = "confirm";
  confirmResponse["action"] = (action=="Yes");
  confirmResponse["message"] = QRegExp(message);
  m_modalResponses << confirmResponse;
  return QString::number(m_modalResponses.length());
}

void WebPage::setConfirmAction(QString action) {
  m_confirmAction = (action == "Yes");
}

QString WebPage::setPromptAction(QString action, QString message, QString response) {
  QVariantMap promptResponse;
  promptResponse["type"] = "prompt";
  promptResponse["action"] = (action == "Yes");
  promptResponse["message"] = QRegExp(message);
  promptResponse["response"] = response;
  m_modalResponses << promptResponse;
  return QString::number(m_modalResponses.length());
}

QString WebPage::setPromptAction(QString action, QString message) {
  return setPromptAction(action, message, QString());
}

void WebPage::setPromptAction(QString action) {
  m_promptAction = (action == "Yes");
}

void WebPage::setPromptText(QString text) {
  m_prompt_text = text;
}

QString WebPage::acceptAlert(QString message) {
  QVariantMap alertResponse;
  alertResponse["type"] = "alert";
  alertResponse["message"] = QRegExp(message);
  m_modalResponses << alertResponse;
  return QString::number(m_modalResponses.length());
}

int WebPage::modalCount() {
  return m_modalMessages.length();
}

QString WebPage::modalMessage() {
  return m_modalMessages.takeFirst();
}

void WebPage::addModalMessage(bool expectedType, const QString &message, const QRegExp &expectedMessage) {
  if (expectedType && message.contains(expectedMessage))
    m_modalMessages << message;
  else
    m_modalMessages << QString();
  emit modalReady();
}
