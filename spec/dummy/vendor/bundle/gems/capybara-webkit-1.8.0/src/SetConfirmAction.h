#include "SocketCommand.h"

class SetConfirmAction : public SocketCommand {
  Q_OBJECT;

 public:
  SetConfirmAction(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
