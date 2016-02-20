#include "SocketCommand.h"

class ConsoleMessages : public SocketCommand {
  Q_OBJECT

  public:
    ConsoleMessages(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

