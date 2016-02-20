#include "SocketCommand.h"

class SetCookie : public SocketCommand {
  Q_OBJECT;

 public:
  SetCookie(WebPageManager *, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
