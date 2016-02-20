#include "SocketCommand.h"

class ClearPromptText : public SocketCommand {
  Q_OBJECT;

 public:
  ClearPromptText(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
