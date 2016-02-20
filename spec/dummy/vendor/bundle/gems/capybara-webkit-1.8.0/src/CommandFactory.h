#include <QObject>

class Command;
class WebPage;
class WebPageManager;

class CommandFactory : public QObject {
  Q_OBJECT

  public:
    CommandFactory(WebPageManager *, QObject *parent = 0);
    Command *createCommand(const char *name, QStringList &arguments);

  private:
    WebPageManager *m_manager;
};

