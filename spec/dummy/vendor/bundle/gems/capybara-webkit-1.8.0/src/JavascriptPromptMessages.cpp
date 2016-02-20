#include "JavascriptPromptMessages.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "JsonSerializer.h"

JavascriptPromptMessages::JavascriptPromptMessages(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {}

void JavascriptPromptMessages::start()
{
  JsonSerializer serializer;
  QByteArray json = serializer.serialize(page()->promptMessages());
  finish(true, json);
}
