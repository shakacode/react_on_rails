#include "SocketCommand.h"

class WebPageManager;

class GetTimeout : public SocketCommand {
  Q_OBJECT;

 public:
  GetTimeout(WebPageManager *page, QStringList &arguments, QObject *parent = 0);
  virtual void start();
};
