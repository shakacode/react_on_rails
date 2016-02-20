#include "CommandParser.h"
#include "CommandFactory.h"
#include "SocketCommand.h"

#include <QIODevice>

CommandParser::CommandParser(QIODevice *device, CommandFactory *commandFactory, QObject *parent) :
    QObject(parent) {
  m_device = device;
  m_expectingDataSize = -1;
  m_commandFactory = commandFactory;
  connect(m_device, SIGNAL(readyRead()), this, SLOT(checkNext()));
}

void CommandParser::checkNext() {
  if (m_expectingDataSize == -1) {
    if (m_device->canReadLine()) {
      readLine();
      checkNext();
    }
  } else {
    if (m_device->bytesAvailable() >= m_expectingDataSize) {
      readDataBlock();
      checkNext();
    }
  }
}

void CommandParser::readLine() {
  char buffer[128];
  qint64 lineLength = m_device->readLine(buffer, 128);
  if (lineLength != -1) {
    buffer[lineLength - 1] = 0;
    processNext(buffer);
  }
}

void CommandParser::readDataBlock() {
  char *buffer = new char[m_expectingDataSize + 1];
  m_device->read(buffer, m_expectingDataSize);
  buffer[m_expectingDataSize] = 0;
  processNext(buffer);
  m_expectingDataSize = -1;
  delete[] buffer;
}

void CommandParser::processNext(const char *data) {
  if (m_commandName.isNull()) {
    m_commandName = data;
    m_argumentsExpected = -1;
  } else {
    processArgument(data);
  }
}

void CommandParser::processArgument(const char *data) {
  if (m_argumentsExpected == -1) {
    m_argumentsExpected = QString(data).toInt();
  } else if (m_expectingDataSize == -1) {
    m_expectingDataSize = QString(data).toInt();
  } else {
    m_arguments.append(QString::fromUtf8(data));
  }

  if (m_arguments.length() == m_argumentsExpected) {
    Command *command = m_commandFactory->createCommand(m_commandName.toLatin1().constData(), m_arguments);
    emit commandReady(command);
    reset();
  }
}

void CommandParser::reset() {
  m_commandName = QString();
  m_arguments.clear();
  m_argumentsExpected = -1;
}
