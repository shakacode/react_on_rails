#include "Evaluate.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "JsonSerializer.h"
#include <iostream>

Evaluate::Evaluate(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void Evaluate::start() {
  QVariant result = page()->currentFrame()->evaluateJavaScript(arguments()[0]);
  JsonSerializer serializer;
  finish(true, serializer.serialize(result));
}
