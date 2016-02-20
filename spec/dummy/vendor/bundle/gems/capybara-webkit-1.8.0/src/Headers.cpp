#include "Headers.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "JsonSerializer.h"

Headers::Headers(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void Headers::start() {
  JsonSerializer serializer;
  QByteArray json = serializer.serialize(page()->pageHeaders());
  finish(true, json);
}

