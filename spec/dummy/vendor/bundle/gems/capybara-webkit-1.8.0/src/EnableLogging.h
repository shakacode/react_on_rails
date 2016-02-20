#include "SocketCommand.h"

class WebPageManager;

class EnableLogging : public SocketCommand {
  Q_OBJECT

  public:
    EnableLogging(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

