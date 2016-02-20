#include "Body.h"
#include "WebPage.h"
#include "WebPageManager.h"

Body::Body(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void Body::start() {
  if (page()->contentType().contains("html"))
    finish(true, page()->currentFrame()->toHtml());
  else
    finish(true, page()->body());
}
