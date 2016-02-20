#ifndef SOCKET_COMMAND_H
#define SOCKET_COMMAND_H

#include <QObject>
#include <QStringList>
#include "Command.h"

class WebPage;
class WebPageManager;
class Response;

class SocketCommand : public Command {
  Q_OBJECT

  public:
    SocketCommand(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual QString toString() const;

  protected:
    WebPage *page() const;
    const QStringList &arguments() const;
    WebPageManager *manager() const;

  private:
    QStringList m_arguments;
    WebPageManager *m_manager;

};

#endif
