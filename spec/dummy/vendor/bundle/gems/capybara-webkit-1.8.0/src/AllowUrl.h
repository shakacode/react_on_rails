#include "SocketCommand.h"

class AllowUrl : public SocketCommand {
  Q_OBJECT

  public:
    AllowUrl(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

