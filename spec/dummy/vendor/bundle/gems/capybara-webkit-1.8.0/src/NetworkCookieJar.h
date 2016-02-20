#include <QtNetwork/QNetworkCookieJar>
#include <QtNetwork/QNetworkCookie>

class NetworkCookieJar : public QNetworkCookieJar {

  Q_OBJECT;

 public:

  NetworkCookieJar(QObject *parent = 0);

  QList<QNetworkCookie> getAllCookies() const;
  void clearCookies();
  void overwriteCookies(const QList<QNetworkCookie>& cookieList);
};
