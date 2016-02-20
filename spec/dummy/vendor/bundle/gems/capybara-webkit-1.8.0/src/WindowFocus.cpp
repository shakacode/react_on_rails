#include "WindowFocus.h"
#include "WebPage.h"

WindowFocus::WindowFocus(WebPageManager *manager, QStringList &arguments, QObject *parent) : WindowCommand(manager, arguments, parent) {
}

void WindowFocus::windowFound(WebPage *page) {
  page->setFocus();
  finish(true);
}
