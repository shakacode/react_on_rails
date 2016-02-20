#include "JavascriptCommand.h"

class FindCss : public JavascriptCommand {
  Q_OBJECT

  public:
    FindCss(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};


