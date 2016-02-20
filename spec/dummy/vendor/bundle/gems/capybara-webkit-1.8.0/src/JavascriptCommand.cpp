#include "JavascriptCommand.h"
#include "WebPageManager.h"
#include "InvocationResult.h"

JavascriptCommand::JavascriptCommand(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void JavascriptCommand::finish(InvocationResult *result) {
  if (result->hasError())
    SocketCommand::finish(false, result->errorMessage());
  else {
    QString message = result->result().toString();
    SocketCommand::finish(true, message);
  }
}
