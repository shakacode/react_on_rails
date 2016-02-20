#include "SetTimeout.h"
#include "WebPageManager.h"
#include "ErrorMessage.h"

SetTimeout::SetTimeout(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void SetTimeout::start() {
  QString timeoutString = arguments()[0];
  bool ok;
  int timeout = timeoutString.toInt(&ok);

  if (ok) {
    manager()->setTimeout(timeout);
    finish(true);
  } else {
    finish(false, new ErrorMessage("Invalid value for timeout"));
  }
}

