#include "EnableLogging.h"
#include "WebPageManager.h"

EnableLogging::EnableLogging(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void EnableLogging::start() {
  manager()->enableLogging();
  finish(true);
}
