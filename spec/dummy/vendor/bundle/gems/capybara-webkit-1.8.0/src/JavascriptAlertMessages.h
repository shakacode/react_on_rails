#include "SocketCommand.h"

class JavascriptAlertMessages : public SocketCommand {
  Q_OBJECT

  public:
    JavascriptAlertMessages(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};
