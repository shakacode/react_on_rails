#include "SocketCommand.h"

class GetWindowHandles : public SocketCommand {
  Q_OBJECT

  public:
    GetWindowHandles(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

