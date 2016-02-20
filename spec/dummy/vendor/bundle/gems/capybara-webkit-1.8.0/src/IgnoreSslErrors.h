#include "SocketCommand.h"

class IgnoreSslErrors : public SocketCommand {
  Q_OBJECT

  public:
    IgnoreSslErrors(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

