#include <QObject>

class WebPage;
class QNetworkReply;

class UnsupportedContentHandler : public QObject {
  Q_OBJECT

  public:
    UnsupportedContentHandler(WebPage *page, QNetworkReply *reply, QObject *parent = 0);
    void waitForReplyToFinish();
    void renderNonHtmlContent();

  public slots:
    void replyFinished();

  private:
    WebPage *m_page;
    QNetworkReply *m_reply;
};
