#include "WindowResize.h"
#include "WebPage.h"
#include "WebPageManager.h"

WindowResize::WindowResize(WebPageManager *manager, QStringList &arguments, QObject *parent) : WindowCommand(manager, arguments, parent) {
}

void WindowResize::windowFound(WebPage *page) {
  int width = arguments()[1].toInt();
  int height = arguments()[2].toInt();

  page->resize(width, height);

  finish(true);
}

