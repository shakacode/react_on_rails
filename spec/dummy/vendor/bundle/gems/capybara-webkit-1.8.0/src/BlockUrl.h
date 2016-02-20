#include "SocketCommand.h"

class BlockUrl : public SocketCommand {
  Q_OBJECT

  public:
    BlockUrl(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

