#include "SocketCommand.h"

class Headers : public SocketCommand {
  Q_OBJECT

  public:
    Headers(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

