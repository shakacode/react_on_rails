#include "CurrentUrl.h"
#include "WebPage.h"
#include "WebPageManager.h"

CurrentUrl::CurrentUrl(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void CurrentUrl::start() {
  QStringList arguments;
  QVariant result = page()->currentFrame()->evaluateJavaScript("window.location.toString()");
  QString url = result.toString();
  finish(true, url);
}

