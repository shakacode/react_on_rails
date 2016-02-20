#ifndef _WEBPAGE_H
#define _WEBPAGE_H
#include <QtGlobal>
#if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
#include <QtWebKitWidgets>
#else
#include <QtWebKit>
#endif
#include <QtNetwork>

class WebPageManager;
class InvocationResult;
class NetworkReplyProxy;
class QWebView;

class WebPage : public QWebPage {
  Q_OBJECT

  public:
    WebPage(WebPageManager *, QObject *parent = 0);
    InvocationResult invokeCapybaraFunction(const char *name, bool allowUnattached, const QStringList &arguments);
    InvocationResult invokeCapybaraFunction(QString &name, bool allowUnattached, const QStringList &arguments);
    QString failureString();
    QString userAgentForUrl(const QUrl &url ) const;
    void setUserAgent(QString userAgent);
    void setConfirmAction(QString action);
    QString setConfirmAction(QString action, QString message);
    QString setPromptAction(QString action, QString message, QString response);
    QString setPromptAction(QString action, QString message);
    void setPromptAction(QString action);
    void setPromptText(QString action);
    QString acceptAlert(QString);
    int getLastStatus();
    void setCustomNetworkAccessManager();
    bool render(const QString &fileName, const QSize &minimumSize);
    virtual bool extension (Extension extension, const ExtensionOption *option=0, ExtensionReturn *output=0);
    void setSkipImageLoading(bool skip);
    QVariantList consoleMessages();
    QVariantList alertMessages();
    QVariantList confirmMessages();
    QVariantList promptMessages();
    void createWindow();
    void resetLocalStorage();
    QWebPage *createWindow(WebWindowType type);
    QString uuid();
    QString getWindowName();
    bool matchesWindowSelector(QString);
    void setFocus();
    void unsupportedContentFinishedReply(QNetworkReply *reply);
    QVariantMap pageHeaders();
    QByteArray body();
    QString contentType();
    void mouseEvent(QEvent::Type type, const QPoint &position, Qt::MouseButton button);
    bool clickTest(QWebElement element, int absoluteX, int absoluteY);
    void resize(int, int);
    int modalCount();
    QString modalMessage();

  public slots:
    bool shouldInterruptJavaScript();
    void injectJavascriptHelpers();
    void loadStarted();
    void loadFinished(bool);
    bool isLoading() const;
    void frameCreated(QWebFrame *);
    void handleSslErrorsForReply(QNetworkReply *reply, const QList<QSslError> &);
    void handleUnsupportedContent(QNetworkReply *reply);
    void replyFinished(QUrl &, QNetworkReply *);
    void remove();

  signals:
    void pageFinished(bool);
    void requestCreated(QByteArray &url, QNetworkReply *reply);
    void replyFinished(QNetworkReply *reply);
    void modalReady();

  protected:
    virtual void javaScriptConsoleMessage(const QString &message, int lineNumber, const QString &sourceID);
    virtual void javaScriptAlert(QWebFrame *frame, const QString &message);
    virtual bool javaScriptConfirm(QWebFrame *frame, const QString &message);
    virtual bool javaScriptPrompt(QWebFrame *frame, const QString &message, const QString &defaultValue, QString *result);
    virtual QString chooseFile(QWebFrame * parentFrame, const QString &suggestedFile);
    virtual bool supportsExtension(Extension extension) const;

  private:
    QString m_capybaraJavascript;
    QString m_userAgent;
    bool m_loading;
    bool m_failed;
    QStringList getAttachedFileNames();
    void loadJavascript();
    void setUserStylesheet();
    bool m_confirmAction;
    bool m_promptAction;
    QVariantList m_consoleMessages;
    QVariantList m_alertMessages;
    QVariantList m_confirmMessages;
    QString m_prompt_text;
    QVariantList m_promptMessages;
    QString m_uuid;
    WebPageManager *m_manager;
    QString m_errorPageMessage;
    void setFrameProperties(QWebFrame *, QUrl &, NetworkReplyProxy *);
    QPoint m_mousePosition;
    QList<QVariantMap> m_modalResponses;
    QStringList m_modalMessages;
    void addModalMessage(bool, const QString &, const QRegExp &);
};

#endif //_WEBPAGE_H

