#include "SocketCommand.h"

class ClearCookies : public SocketCommand {
  Q_OBJECT;

 public:
  ClearCookies(WebPageManager *, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
