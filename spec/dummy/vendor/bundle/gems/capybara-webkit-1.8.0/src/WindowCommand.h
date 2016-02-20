#ifndef WINDOW_COMMAND_H
#define WINDOW_COMMAND_H

#include "SocketCommand.h"

class WindowCommand : public SocketCommand {
  Q_OBJECT

  public:
    WindowCommand(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();

  protected:
    virtual void windowFound(WebPage *) = 0;

  private:
    void findWindow(QString);
    void windowNotFound();
};

#endif
