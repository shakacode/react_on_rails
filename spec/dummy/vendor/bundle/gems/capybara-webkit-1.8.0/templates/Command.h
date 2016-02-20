#include "SocketCommand.h"

class NAME : public SocketCommand {
  Q_OBJECT

  public:
    NAME(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

