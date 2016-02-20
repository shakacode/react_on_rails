#include "SocketCommand.h"

class SetSkipImageLoading : public SocketCommand {
  Q_OBJECT

  public:
    SetSkipImageLoading(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};
