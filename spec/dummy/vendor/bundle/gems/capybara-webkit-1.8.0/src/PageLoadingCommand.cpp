#include "PageLoadingCommand.h"
#include "SocketCommand.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "ErrorMessage.h"

PageLoadingCommand::PageLoadingCommand(Command *command, WebPageManager *manager, QObject *parent) : Command(parent) {
  m_manager = manager;
  m_command = command;
  m_pageLoadingFromCommand = false;
  m_pageSuccess = true;
  m_pendingResponse = NULL;
  m_command->setParent(this);
}

void PageLoadingCommand::start() {
  m_manager->logger() << "Started" << m_command->toString();
  connect(m_command, SIGNAL(finished(Response *)), this, SLOT(commandFinished(Response *)));
  connect(m_manager, SIGNAL(loadStarted()), this, SLOT(pageLoadingFromCommand()));
  connect(m_manager, SIGNAL(pageFinished(bool)), this, SLOT(pendingLoadFinished(bool)));
  m_command->start();
};

void PageLoadingCommand::pendingLoadFinished(bool success) {
  m_pageSuccess = success;
  if (m_pageLoadingFromCommand) {
    m_pageLoadingFromCommand = false;
    if (m_pendingResponse) {
      m_manager->logger() << "Page load from command finished";
      if (m_pageSuccess) {
        emit finished(m_pendingResponse);
      } else {
        QString message = m_manager->currentPage()->failureString();
        finish(false, new ErrorMessage(message));
      }
    }
  }
}

void PageLoadingCommand::pageLoadingFromCommand() {
  m_manager->logger() << m_command->toString() << "started page load";
  m_pageLoadingFromCommand = true;
}

void PageLoadingCommand::commandFinished(Response *response) {
  disconnect(m_manager, SIGNAL(loadStarted()), this, SLOT(pageLoadingFromCommand()));
  m_manager->logger() << "Finished" << m_command->toString() << "with response" << response->toString();

  if (m_pageLoadingFromCommand)
    m_pendingResponse = response;
  else
    emit finished(response);
}
