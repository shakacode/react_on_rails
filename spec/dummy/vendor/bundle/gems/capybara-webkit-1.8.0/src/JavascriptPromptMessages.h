#include "SocketCommand.h"

class JavascriptPromptMessages : public SocketCommand {
  Q_OBJECT

  public:
    JavascriptPromptMessages(WebPageManager *manager, QStringList &arguments, QObject *parent = 0);
    virtual void start();
};
