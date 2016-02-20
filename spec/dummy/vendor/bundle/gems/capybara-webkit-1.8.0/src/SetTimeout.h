#include "SocketCommand.h"

class SetTimeout : public SocketCommand {
  Q_OBJECT

 public:
  SetTimeout(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
