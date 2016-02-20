#include "SocketCommand.h"

class SetProxy : public SocketCommand {
  Q_OBJECT;

 public:
  SetProxy(WebPageManager *, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
