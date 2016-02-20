#include "JavascriptCommand.h"
#include <QStringList>

class Node : public JavascriptCommand {
  Q_OBJECT

  public:
    Node(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
    virtual void start();
    virtual QString toString() const;
};

