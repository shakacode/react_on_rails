#include "GoBack.h"
#include "SocketCommand.h"
#include "WebPage.h"
#include "WebPageManager.h"

GoBack::GoBack(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void GoBack::start() {
  page()->triggerAction(QWebPage::Back);
  finish(true);
}
