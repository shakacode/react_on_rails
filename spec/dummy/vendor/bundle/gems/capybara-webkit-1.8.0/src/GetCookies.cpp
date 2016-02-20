#include "GetCookies.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "NetworkCookieJar.h"

GetCookies::GetCookies(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent)
{
  m_buffer = "";
}

void GetCookies::start()
{
  NetworkCookieJar *jar = manager()->cookieJar();
  foreach (QNetworkCookie cookie, jar->getAllCookies()) {
    m_buffer.append(cookie.toRawForm());
    m_buffer.append("\n");
  }
  finish(true, m_buffer);
}
