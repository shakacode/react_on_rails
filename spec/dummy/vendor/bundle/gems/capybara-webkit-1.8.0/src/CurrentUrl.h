#include "SocketCommand.h"

class CurrentUrl : public SocketCommand {
  Q_OBJECT

  public:
    CurrentUrl(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

