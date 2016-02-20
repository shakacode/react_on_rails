#include "BlockUrl.h"
#include "SocketCommand.h"
#include "WebPage.h"
#include "WebPageManager.h"

BlockUrl::BlockUrl(
  WebPageManager *manager,
  QStringList &arguments,
  QObject *parent
) : SocketCommand(manager, arguments, parent) {
}

void BlockUrl::start() {
  manager()->blockUrl(arguments()[0]);
  finish(true);
}
