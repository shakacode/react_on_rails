#include "GetWindowHandles.h"
#include "WebPageManager.h"
#include "CommandFactory.h"
#include "WebPage.h"
#include "JsonSerializer.h"
#include <QStringList>

GetWindowHandles::GetWindowHandles(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void GetWindowHandles::start() {
  QVariantList handles;

  foreach(WebPage *page, manager()->pages())
    handles << page->uuid();

  JsonSerializer serializer;
  QByteArray json = serializer.serialize(handles);

  finish(true, json);
}
