#include "Header.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "NetworkAccessManager.h"

Header::Header(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void Header::start() {
  QString key = arguments()[0];
  QString value = arguments()[1];
  if (key.toLower().replace("-", "_") == "user_agent") {
    page()->setUserAgent(value);
  } else {
    manager()->addHeader(key, value);
  }
  finish(true);
}
