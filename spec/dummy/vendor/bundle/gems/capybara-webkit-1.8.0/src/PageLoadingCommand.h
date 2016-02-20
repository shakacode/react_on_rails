#include <QObject>
#include <QStringList>
#include "Command.h"

class Response;
class WebPageManager;

/*
 * Decorates a Command by deferring the finished() signal until any pending
 * page loads are complete.
 *
 * If a Command starts a page load, no signal will be emitted until the page
 * load is finished.
 *
 * If a pending page load fails, the command's response will be discarded and a
 * failure response will be emitted instead.
 */
class PageLoadingCommand : public Command {
  Q_OBJECT

  public:
    PageLoadingCommand(Command *command, WebPageManager *page, QObject *parent = 0);
    virtual void start();

  public slots:
    void pageLoadingFromCommand();
    void pendingLoadFinished(bool success);
    void commandFinished(Response *response);

  private:
    WebPageManager *m_manager;
    Command *m_command;
    Response *m_pendingResponse;
    bool m_pageSuccess;
    bool m_pageLoadingFromCommand;
};

