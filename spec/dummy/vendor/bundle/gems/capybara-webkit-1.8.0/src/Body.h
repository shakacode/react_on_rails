#include "SocketCommand.h"

class Body : public SocketCommand {
  Q_OBJECT

  public:
    Body(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

