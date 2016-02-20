#include "NetworkCookieJar.h"
#include "QtCore/qdatetime.h"

NetworkCookieJar::NetworkCookieJar(QObject *parent)
  : QNetworkCookieJar(parent)
{ }

QList<QNetworkCookie> NetworkCookieJar::getAllCookies() const
{
  return allCookies();
}

void NetworkCookieJar::clearCookies()
{
  setAllCookies(QList<QNetworkCookie>());
}

static inline bool isParentDomain(QString domain, QString reference)
{
  if (!reference.startsWith(QLatin1Char('.')))
    return domain == reference;

  return domain.endsWith(reference) || domain == reference.mid(1);
}

void NetworkCookieJar::overwriteCookies(const QList<QNetworkCookie>& cookieList)
{
  /* this function is basically a copy-and-paste of the original
     QNetworkCookieJar::setCookiesFromUrl with the domain and
     path validations removed */

  QString defaultPath(QLatin1Char('/'));
  QDateTime now = QDateTime::currentDateTime();
  QList<QNetworkCookie> newCookies = allCookies();

  foreach (QNetworkCookie cookie, cookieList) {
    bool isDeletion = (!cookie.isSessionCookie() &&
                       cookie.expirationDate() < now);

    // validate the cookie & set the defaults if unset
    if (cookie.path().isEmpty())
      cookie.setPath(defaultPath);

    // don't do path checking. See http://bugreports.qt.nokia.com/browse/QTBUG-5815
    //        else if (!isParentPath(pathAndFileName, cookie.path())) {
    //            continue;           // not accepted
    //        }

    if (cookie.domain().isEmpty()) {
      continue;
    } else {
      // Ensure the domain starts with a dot if its field was not empty
      // in the HTTP header. There are some servers that forget the
      // leading dot and this is actually forbidden according to RFC 2109,
      // but all browsers accept it anyway so we do that as well.
      if (!cookie.domain().startsWith(QLatin1Char('.')))
        cookie.setDomain(QLatin1Char('.') + cookie.domain());

      QString domain = cookie.domain();

      // the check for effective TLDs makes the "embedded dot" rule from RFC 2109 section 4.3.2
      // redundant; the "leading dot" rule has been relaxed anyway, see above
      // we remove the leading dot for this check
      /*
      if (QNetworkCookieJarPrivate::isEffectiveTLD(domain.remove(0, 1)))
        continue; // not accepted
      */
    }

    for (int i = 0; i < newCookies.size(); ++i) {
      // does this cookie already exist?
      const QNetworkCookie &current = newCookies.at(i);
      if (cookie.name() == current.name() &&
          cookie.domain() == current.domain() &&
          cookie.path() == current.path()) {
        // found a match
        newCookies.removeAt(i);
        break;
      }
    }

    // did not find a match
    if (!isDeletion) {
      int countForDomain = 0;
      for (int i = newCookies.size() - 1; i >= 0; --i) {
        // Start from the end and delete the oldest cookies to keep a maximum count of 50.
        const QNetworkCookie &current = newCookies.at(i);
        if (isParentDomain(cookie.domain(), current.domain())
            || isParentDomain(current.domain(), cookie.domain())) {
          if (countForDomain >= 49)
            newCookies.removeAt(i);
          else
            ++countForDomain;
        }
      }

      newCookies += cookie;
    }
  }
  setAllCookies(newCookies);
}
