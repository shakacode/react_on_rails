#include "IgnoreSslErrors.h"
#include "WebPage.h"
#include "WebPageManager.h"

IgnoreSslErrors::IgnoreSslErrors(WebPageManager *manager, QStringList &arguments, QObject *parent) :
  SocketCommand(manager, arguments, parent) {
}

void IgnoreSslErrors::start() {
  manager()->setIgnoreSslErrors(true);
  finish(true);
}

