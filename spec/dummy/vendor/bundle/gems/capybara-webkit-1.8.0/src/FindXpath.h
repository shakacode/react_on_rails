#include "JavascriptCommand.h"

class FindXpath : public JavascriptCommand {
  Q_OBJECT

  public:
    FindXpath(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};


