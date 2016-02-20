#include "JavascriptAlertMessages.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "JsonSerializer.h"

JavascriptAlertMessages::JavascriptAlertMessages(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {}

void JavascriptAlertMessages::start()
{
  JsonSerializer serializer;
  QByteArray json = serializer.serialize(page()->alertMessages());
  finish(true, json);
}
