#include "SocketCommand.h"

class GoBack : public SocketCommand {
  Q_OBJECT

  public:
    GoBack(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

