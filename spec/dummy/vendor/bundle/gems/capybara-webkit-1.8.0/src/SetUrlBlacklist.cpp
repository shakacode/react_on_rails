
#include "SetUrlBlacklist.h"
#include "WebPageManager.h"
#include "WebPage.h"
#include "NetworkAccessManager.h"

SetUrlBlacklist::SetUrlBlacklist(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void SetUrlBlacklist::start() {
  manager()->setUrlBlacklist(arguments());
  finish(true);
}

