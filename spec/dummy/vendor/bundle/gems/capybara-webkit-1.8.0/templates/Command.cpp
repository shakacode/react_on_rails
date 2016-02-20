#include "NAME.h"
#include "SocketCommand.h"
#include "WebPage.h"
#include "WebPageManager.h"

NAME::NAME(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void NAME::start() {
}
