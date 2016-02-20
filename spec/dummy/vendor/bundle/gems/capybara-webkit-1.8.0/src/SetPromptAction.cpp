#include "SetPromptAction.h"
#include "WebPage.h"
#include "WebPageManager.h"

SetPromptAction::SetPromptAction(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {}

void SetPromptAction::start()
{
  QString index;
  switch (arguments().length()) {
    case 3:
      index = page()->setPromptAction(arguments()[0], arguments()[1], arguments()[2]);
      break;
    case 2:
      index = page()->setPromptAction(arguments()[0], arguments()[1]);
      break;
    default:
      page()->setPromptAction(arguments()[0]);
  }

  finish(true, index);
}
