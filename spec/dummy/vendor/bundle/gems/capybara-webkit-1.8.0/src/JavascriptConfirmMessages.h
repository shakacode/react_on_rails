#include "SocketCommand.h"

class JavascriptConfirmMessages : public SocketCommand {
  Q_OBJECT

  public:
    JavascriptConfirmMessages(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};
