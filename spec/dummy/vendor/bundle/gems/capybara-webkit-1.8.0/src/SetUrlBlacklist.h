#include "SocketCommand.h"

class SetUrlBlacklist : public SocketCommand {
  Q_OBJECT

 public:
  SetUrlBlacklist(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
