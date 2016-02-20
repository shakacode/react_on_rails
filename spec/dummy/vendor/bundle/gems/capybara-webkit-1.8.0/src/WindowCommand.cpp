#include "WindowCommand.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "ErrorMessage.h"

WindowCommand::WindowCommand(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void WindowCommand::start() {
  findWindow(arguments()[0]);
}

void WindowCommand::findWindow(QString selector) {
  foreach(WebPage *page, manager()->pages()) {
    if (page->matchesWindowSelector(selector)) {
      windowFound(page);
      return;
    }
  }

  windowNotFound();
}

void WindowCommand::windowNotFound() {
  finish(false,
         new ErrorMessage("NoSuchWindowError", "Unable to locate window."));
}
