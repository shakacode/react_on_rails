#include "WindowCommand.h"

class WindowSize : public WindowCommand {
  Q_OBJECT

  public:
    WindowSize(WebPageManager *, QStringList &arguments, QObject *parent = 0);

  protected:
    virtual void windowFound(WebPage *);
};

