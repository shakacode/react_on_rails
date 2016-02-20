#include "SocketCommand.h"

#include <QVariantList>

class Evaluate : public SocketCommand {
  Q_OBJECT

  public:
    Evaluate(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};

