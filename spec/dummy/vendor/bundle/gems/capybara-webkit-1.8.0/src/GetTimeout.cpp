#include "GetTimeout.h"
#include "WebPageManager.h"

GetTimeout::GetTimeout(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void GetTimeout::start() {
  finish(true, QString::number(manager()->getTimeout()));
}
