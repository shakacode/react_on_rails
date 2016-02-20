#include "SocketCommand.h"
#include "UnknownUrlHandler.h"

class SetUnknownUrlMode : public SocketCommand {
  Q_OBJECT

  public:
    SetUnknownUrlMode(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};
