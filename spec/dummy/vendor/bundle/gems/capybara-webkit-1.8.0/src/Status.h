#include "SocketCommand.h"

class Status : public SocketCommand {
  Q_OBJECT

  public:
    Status(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

