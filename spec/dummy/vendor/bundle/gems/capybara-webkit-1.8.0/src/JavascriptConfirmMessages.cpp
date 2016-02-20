#include "JavascriptConfirmMessages.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "JsonSerializer.h"

JavascriptConfirmMessages::JavascriptConfirmMessages(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {}

void JavascriptConfirmMessages::start()
{
  JsonSerializer serializer;
  QByteArray json = serializer.serialize(page()->confirmMessages());
  finish(true, json);
}
