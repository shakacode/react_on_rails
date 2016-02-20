#include "SetUnknownUrlMode.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "ErrorMessage.h"

SetUnknownUrlMode::SetUnknownUrlMode(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void SetUnknownUrlMode::start() {
  QString modeString = arguments()[0];
  QStringList modes;
  modes << "warn" << "block";

  switch(modes.indexOf(modeString)) {
    case 0:
      manager()->setUnknownUrlMode(UnknownUrlHandler::WARN);
      finish(true);
      break;
    case 1:
      manager()->setUnknownUrlMode(UnknownUrlHandler::BLOCK);
      finish(true);
      break;
    default:
      QString error = QString("Invalid mode string:") + modeString;
      finish(false, new ErrorMessage(error));
  }
}
