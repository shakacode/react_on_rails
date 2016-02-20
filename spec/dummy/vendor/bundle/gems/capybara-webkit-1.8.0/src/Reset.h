#include "SocketCommand.h"

class Reset : public SocketCommand {
  Q_OBJECT

  public:
    Reset(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

