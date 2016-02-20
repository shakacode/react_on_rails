#include "SocketCommand.h"

class AcceptAlert : public SocketCommand {
  Q_OBJECT

  public:
    AcceptAlert(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

