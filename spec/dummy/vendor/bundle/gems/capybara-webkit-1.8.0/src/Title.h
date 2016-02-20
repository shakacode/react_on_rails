#include "SocketCommand.h"

class Title : public SocketCommand {
  Q_OBJECT

  public:
    Title(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};
