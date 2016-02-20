#include "SocketCommand.h"
#include <QStringList>

class Render : public SocketCommand {
  Q_OBJECT

  public:
    Render(WebPageManager *page, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};
