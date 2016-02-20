#include "UnknownUrlHandler.h"
#include "NetworkReplyProxy.h"
#include "NoOpReply.h"

UnknownUrlHandler::UnknownUrlHandler(
  RequestHandler *next,
  QObject *parent
) : RequestHandler(parent) {
  m_next = next;
  allowDefaultUrls();
  m_mode = WARN;
}

QNetworkReply* UnknownUrlHandler::handleRequest(
  NetworkAccessManager *manager,
  QNetworkAccessManager::Operation operation,
  QNetworkRequest &request,
  QIODevice *outgoingData
) {
  QUrl url(request.url());
  if (this->isUnknown(url)) {
    switch(m_mode) {
      case WARN:
        QTextStream(stderr) <<
           "Request to unknown URL: " << url.toString() << endl <<
           "To block requests to unknown URLs:" << endl <<
           "  Capybara::Webkit.configure do |config|" << endl <<
           "    config.block_unknown_urls" << endl <<
           "  end" << endl <<
           "To allow just this URL:" << endl <<
           "  Capybara::Webkit.configure do |config|" << endl <<
           "    config.allow_url(\"" << url.toString() << "\")" << endl <<
           "  end" << endl <<
           "To allow requests to URLs from this host:" << endl <<
           "  Capybara::Webkit.configure do |config|" << endl <<
           "    config.allow_url(\"" << url.host() << "\")" << endl <<
           "  end" << endl;
        break;
      case BLOCK:
        return new NetworkReplyProxy(new NoOpReply(request), this);
    }
  }

  return m_next->handleRequest(manager, operation, request, outgoingData);
}

void UnknownUrlHandler::allowUrl(const QString &url) {
  m_allowedUrls << url;
}

void UnknownUrlHandler::setMode(Mode mode) {
  m_mode = mode;
}

bool UnknownUrlHandler::isUnknown(QUrl url) {
  QStringListIterator iterator(m_allowedUrls);
  QString urlString = url.toString();

  while (iterator.hasNext()) {
    QRegExp allowedUrl = QRegExp(iterator.next());
    allowedUrl.setPatternSyntax(QRegExp::Wildcard);

    if(urlString.contains(allowedUrl)) {
      return false;
    }
  }

  return true;
}

void UnknownUrlHandler::reset() {
  m_allowedUrls.clear();
  allowDefaultUrls();
}

void UnknownUrlHandler::allowDefaultUrls() {
  m_allowedUrls.append(QString("127.0.0.1"));
  m_allowedUrls.append(QString("localhost"));
  m_allowedUrls.append(QString("data:*,*"));
}
