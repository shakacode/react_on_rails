#include "WindowCommand.h"

class WindowResize : public WindowCommand {
  Q_OBJECT

  public:
    WindowResize(WebPageManager *, QStringList &arguments, QObject *parent = 0);

  protected:
    virtual void windowFound(WebPage *);
};

