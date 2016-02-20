#include "SocketCommand.h"

class SetPromptAction : public SocketCommand {
  Q_OBJECT;

 public:
  SetPromptAction(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
