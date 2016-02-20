#include "SocketCommand.h"

class GoForward : public SocketCommand {
  Q_OBJECT

  public:
    GoForward(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

