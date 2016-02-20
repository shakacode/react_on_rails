#include "SocketCommand.h"

class FindModal : public SocketCommand {
  Q_OBJECT

  public:
    FindModal(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();

  public slots:
    void handleModalReady();
};

