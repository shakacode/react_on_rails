#include "Authenticate.h"
#include "WebPage.h"
#include "NetworkAccessManager.h"
#include "WebPageManager.h"

Authenticate::Authenticate(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void Authenticate::start() {
  QString username = arguments()[0];
  QString password = arguments()[1];

  NetworkAccessManager* networkAccessManager = manager()->networkAccessManager();
  #if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
    //Reset Authentication cache
    networkAccessManager->clearAccessCache();
  #endif
  networkAccessManager->setUserName(username);
  networkAccessManager->setPassword(password);

  finish(true);
}

