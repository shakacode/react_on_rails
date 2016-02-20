#include "SocketCommand.h"

class Execute : public SocketCommand {
  Q_OBJECT

  public:
    Execute(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

