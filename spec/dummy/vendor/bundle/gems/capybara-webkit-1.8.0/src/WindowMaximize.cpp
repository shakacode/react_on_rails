#include <QDesktopWidget>
#include "WindowMaximize.h"
#include "WebPage.h"
#include "WebPageManager.h"

WindowMaximize::WindowMaximize(WebPageManager *manager, QStringList &arguments, QObject *parent) : WindowCommand(manager, arguments, parent) {
}

void WindowMaximize::windowFound(WebPage *page) {
  QDesktopWidget *desktop = QApplication::desktop();
  QRect area = desktop->availableGeometry();
  page->resize(area.width(), area.height());
  finish(true);
}
