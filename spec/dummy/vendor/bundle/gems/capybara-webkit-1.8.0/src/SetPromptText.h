#include "SocketCommand.h"

class SetPromptText : public SocketCommand {
  Q_OBJECT;

 public:
  SetPromptText(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
