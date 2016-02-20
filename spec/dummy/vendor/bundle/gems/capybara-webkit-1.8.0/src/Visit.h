#include "SocketCommand.h"

class Visit : public SocketCommand {
  Q_OBJECT

  public:
    Visit(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

