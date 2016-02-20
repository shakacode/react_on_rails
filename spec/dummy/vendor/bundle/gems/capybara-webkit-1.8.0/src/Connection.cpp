#include "Connection.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "CommandParser.h"
#include "CommandFactory.h"
#include "PageLoadingCommand.h"
#include "TimeoutCommand.h"
#include "SocketCommand.h"
#include "ErrorMessage.h"

#include <QTcpSocket>

Connection::Connection(QTcpSocket *socket, WebPageManager *manager, QObject *parent) :
    QObject(parent) {
  m_socket = socket;
  m_manager = manager;
  m_commandFactory = new CommandFactory(m_manager, this);
  m_commandParser = new CommandParser(socket, m_commandFactory, this);
  m_pageSuccess = true;
  m_pendingCommand = NULL;
  connect(m_socket, SIGNAL(readyRead()), m_commandParser, SLOT(checkNext()));
  connect(m_commandParser, SIGNAL(commandReady(Command *)), this, SLOT(commandReady(Command *)));
  connect(m_manager, SIGNAL(pageFinished(bool)), this, SLOT(pendingLoadFinished(bool)));
}

void Connection::commandReady(Command *command) {
  m_manager->logger() << "Received" << command->toString();
  startCommand(command);
}

void Connection::startCommand(Command *command) {
  if (m_pendingCommand) {
    m_pendingCommand->deleteLater();
  }
  if (m_pageSuccess) {
    m_pendingCommand = new TimeoutCommand(new PageLoadingCommand(command, m_manager, this), m_manager, this);
    connect(m_pendingCommand, SIGNAL(finished(Response *)), this, SLOT(finishCommand(Response *)));
    m_pendingCommand->start();
  } else {
    writePageLoadFailure();
  }
}

void Connection::pendingLoadFinished(bool success) {
  m_pageSuccess = m_pageSuccess && success;
}

void Connection::writePageLoadFailure() {
  m_pageSuccess = true;
  QString message = currentPage()->failureString();
  Response response(false, new ErrorMessage(message));
  writeResponse(&response);
}

void Connection::finishCommand(Response *response) {
  m_pageSuccess = true;
  writeResponse(response);
  sender()->deleteLater();
  m_pendingCommand = NULL;
}

void Connection::writeResponse(Response *response) {
  if (response->isSuccess())
    m_socket->write("ok\n");
  else
    m_socket->write("failure\n");

  m_manager->logger() << "Wrote response" << response->isSuccess() << response->message();

  QByteArray messageUtf8 = response->message();
  QString messageLength = QString::number(messageUtf8.size()) + "\n";
  m_socket->write(messageLength.toLatin1());
  m_socket->write(messageUtf8);
}

WebPage *Connection::currentPage() {
  return m_manager->currentPage();
}
