#include "SetSkipImageLoading.h"
#include "WebPage.h"
#include "WebPageManager.h"

SetSkipImageLoading::SetSkipImageLoading(WebPageManager *manager, QStringList &arguments, QObject *parent) :
  SocketCommand(manager, arguments, parent) {
}

void SetSkipImageLoading::start() {
  page()->setSkipImageLoading(arguments().contains("true"));
  finish(true);
}
