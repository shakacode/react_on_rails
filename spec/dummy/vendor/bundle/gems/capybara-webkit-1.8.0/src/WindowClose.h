#include "WindowCommand.h"

class WindowClose : public WindowCommand {
  Q_OBJECT

  public:
    WindowClose(WebPageManager *, QStringList &arguments, QObject *parent = 0);

  protected:
    virtual void windowFound(WebPage *);
};

