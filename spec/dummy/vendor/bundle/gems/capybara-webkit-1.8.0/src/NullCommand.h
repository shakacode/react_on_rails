#include "Command.h"

class NullCommand : public Command {
  Q_OBJECT

  public:
    NullCommand(QString name, QObject *parent = 0);
    virtual void start();

  private:
    QString m_name;
};
