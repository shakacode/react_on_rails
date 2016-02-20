#include "SocketCommand.h"

class GetWindowHandle : public SocketCommand {
  Q_OBJECT

  public:
    GetWindowHandle(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

