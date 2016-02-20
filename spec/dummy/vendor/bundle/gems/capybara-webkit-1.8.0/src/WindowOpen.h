#include "SocketCommand.h"

class WindowOpen : public SocketCommand {
  Q_OBJECT

  public:
    WindowOpen(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

