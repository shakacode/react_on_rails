#include "SocketCommand.h"

class Header : public SocketCommand {
  Q_OBJECT

  public:
    Header(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};
