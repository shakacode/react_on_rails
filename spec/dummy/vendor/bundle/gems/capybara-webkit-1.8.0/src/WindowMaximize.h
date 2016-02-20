#include "WindowCommand.h"

class WindowMaximize : public WindowCommand {
  Q_OBJECT

  public:
    WindowMaximize(WebPageManager *, QStringList &arguments, QObject *parent = 0);

  protected:
    virtual void windowFound(WebPage *);
};

