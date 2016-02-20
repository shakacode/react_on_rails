#include "FindXpath.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "InvocationResult.h"

FindXpath::FindXpath(WebPageManager *manager, QStringList &arguments, QObject *parent) : JavascriptCommand(manager, arguments, parent) {
}

void FindXpath::start() {
  InvocationResult result = page()->invokeCapybaraFunction("findXpath", true, arguments());
  finish(&result);
}

