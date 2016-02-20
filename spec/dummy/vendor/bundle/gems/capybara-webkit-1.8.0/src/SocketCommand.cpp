#include "SocketCommand.h"
#include "WebPage.h"
#include "WebPageManager.h"

SocketCommand::SocketCommand(WebPageManager *manager, QStringList &arguments, QObject *parent) : Command(parent) {
  m_manager = manager;
  m_arguments = arguments;
}

WebPage *SocketCommand::page() const {
  return m_manager->currentPage();
}

const QStringList &SocketCommand::arguments() const {
  return m_arguments;
}

WebPageManager *SocketCommand::manager() const {
  return m_manager;
}

QString SocketCommand::toString() const {
  QString result;
  QTextStream(&result) << metaObject()->className() << QString("(") << m_arguments.join(", ") << QString(")");
  return result;
}

