#include "SocketCommand.h"

class Version : public SocketCommand {
  Q_OBJECT

  public:
    Version(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

