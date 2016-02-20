#include "Title.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "NetworkAccessManager.h"

Title::Title(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void Title::start() {
  finish(true, page()->currentFrame()->title());
}
