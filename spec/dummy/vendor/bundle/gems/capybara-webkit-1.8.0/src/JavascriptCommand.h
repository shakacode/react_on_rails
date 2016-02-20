#ifndef JAVASCRIPT_COMMAND_H
#define JAVASCRIPT_COMMAND_H

#include <QObject>
#include <QStringList>
#include "SocketCommand.h"

class WebPage;
class WebPageManager;
class InvocationResult;

class JavascriptCommand : public SocketCommand {
  Q_OBJECT

  public:
    JavascriptCommand(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    void finish(InvocationResult *result);
};

#endif
