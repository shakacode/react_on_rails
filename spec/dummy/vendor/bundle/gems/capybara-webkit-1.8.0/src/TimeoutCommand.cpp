#include "TimeoutCommand.h"
#include "Command.h"
#include "WebPageManager.h"
#include "WebPage.h"
#include "ErrorMessage.h"
#include <QTimer>
#include <QApplication>

TimeoutCommand::TimeoutCommand(Command *command, WebPageManager *manager, QObject *parent) : Command(parent) {
  m_command = command;
  m_manager = manager;
  m_timer = new QTimer(this);
  m_timer->setSingleShot(true);
  m_command->setParent(this);
  connect(m_timer, SIGNAL(timeout()), this, SLOT(commandTimeout()));
  connect(m_manager, SIGNAL(loadStarted()), this, SLOT(pageLoadingFromCommand()));
}

void TimeoutCommand::start() {
  QApplication::processEvents();
  if (m_manager->isLoading()) {
    m_manager->logger() << this->toString() << "waiting for load to finish";
    connect(m_manager, SIGNAL(pageFinished(bool)), this, SLOT(pendingLoadFinished(bool)));
    startTimeout();
  } else {
    startCommand();
  }
}

void TimeoutCommand::startCommand() {
  connect(m_command, SIGNAL(finished(Response *)), this, SLOT(commandFinished(Response *)));
  m_command->start();
}

void TimeoutCommand::startTimeout() {
  int timeout = m_manager->getTimeout();
  if (timeout > 0) {
    m_timer->start(timeout * 1000);
  }
}

void TimeoutCommand::pendingLoadFinished(bool success) {
  disconnect(m_manager, SIGNAL(pageFinished(bool)), this, SLOT(pendingLoadFinished(bool)));
  if (success) {
    startCommand();
  } else {
    disconnect(m_timer, SIGNAL(timeout()), this, SLOT(commandTimeout()));
    disconnect(m_manager, SIGNAL(loadStarted()), this, SLOT(pageLoadingFromCommand()));
    finish(false, new ErrorMessage(m_manager->currentPage()->failureString()));
  }
}

void TimeoutCommand::pageLoadingFromCommand() {
  startTimeout();
}

void TimeoutCommand::commandTimeout() {
  disconnect(m_manager, SIGNAL(loadStarted()), this, SLOT(pageLoadingFromCommand()));
  disconnect(m_manager, SIGNAL(pageFinished(bool)), this, SLOT(pendingLoadFinished(bool)));
  disconnect(m_command, SIGNAL(finished(Response *)), this, SLOT(commandFinished(Response *)));
  m_manager->currentPage()->triggerAction(QWebPage::Stop);
  QString message = QString("Request timed out after %1 second(s)").arg(m_manager->getTimeout());
  finish(false, new ErrorMessage("TimeoutError", message));
}

void TimeoutCommand::commandFinished(Response *response) {
  disconnect(m_timer, SIGNAL(timeout()), this, SLOT(commandTimeout()));
  disconnect(m_manager, SIGNAL(loadStarted()), this, SLOT(pageLoadingFromCommand()));
  emit finished(response);
}

