#ifndef _WEBPAGEMANAGER_H
#define _WEBPAGEMANAGER_H
#include <QList>
#include <QSet>
#include <QObject>
#include <QNetworkReply>
#include <QDebug>
#include <QFile>

#include "UnknownUrlHandler.h"

class WebPage;
class NetworkCookieJar;
class NetworkAccessManager;
class BlacklistedRequestHandler;
class CustomHeadersRequestHandler;

class WebPageManager : public QObject {
  Q_OBJECT

  public:
    WebPageManager(QObject *parent = 0);
    void append(WebPage *value);
    QList<WebPage *> pages() const;
    void setCurrentPage(WebPage *);
    WebPage *currentPage() const;
    WebPage *createPage();
    void removePage(WebPage *);
    void setIgnoreSslErrors(bool);
    bool ignoreSslErrors();
    void setTimeout(int);
    int getTimeout();
    void reset();
    NetworkCookieJar *cookieJar();
    bool isLoading() const;
    QDebug logger() const;
    void enableLogging();
    void replyFinished(QNetworkReply *reply);
    NetworkAccessManager *networkAccessManager();
    void setUrlBlacklist(const QStringList &);
    void addHeader(QString, QString);
    void setUnknownUrlMode(UnknownUrlHandler::Mode);
    void allowUrl(const QString &);
    void blockUrl(const QString &);

  public slots:
    void emitLoadStarted();
    void setPageStatus(bool);
    void requestCreated(QByteArray &url, QNetworkReply *reply);
    void handleReplyFinished();
    void replyDestroyed(QObject *);

  signals:
    void pageFinished(bool);
    void loadStarted();

  private:
    void emitPageFinished();
    static void handleDebugMessage(QtMsgType type, const char *message);

    QList<WebPage *> m_pages;
    QList<QNetworkReply *> m_pendingReplies;
    WebPage *m_currentPage;
    bool m_ignoreSslErrors;
    NetworkCookieJar *m_cookieJar;
    QSet<WebPage *> m_started;
    bool m_success;
    bool m_loggingEnabled;
    QFile *m_ignoredOutput;
    int m_timeout;
    NetworkAccessManager *m_networkAccessManager;
    BlacklistedRequestHandler *m_blacklistedRequestHandler;
    CustomHeadersRequestHandler *m_customHeadersRequestHandler;
    UnknownUrlHandler *m_unknownUrlHandler;
};

#endif // _WEBPAGEMANAGER_H
