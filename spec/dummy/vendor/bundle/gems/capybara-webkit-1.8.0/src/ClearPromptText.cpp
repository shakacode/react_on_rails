#include "ClearPromptText.h"
#include "WebPage.h"
#include "WebPageManager.h"

ClearPromptText::ClearPromptText(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {}

void ClearPromptText::start()
{
  page()->setPromptText(QString());
  finish(true);
}
