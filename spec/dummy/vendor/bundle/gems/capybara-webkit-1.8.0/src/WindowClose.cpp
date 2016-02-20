#include "WindowClose.h"
#include "WebPage.h"

WindowClose::WindowClose(WebPageManager *manager, QStringList &arguments, QObject *parent) : WindowCommand(manager, arguments, parent) {
}

void WindowClose::windowFound(WebPage *page) {
  page->remove();
  finish(true);
}
