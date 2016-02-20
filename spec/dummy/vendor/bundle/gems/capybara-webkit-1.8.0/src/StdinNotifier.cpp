#include "StdinNotifier.h"

#include <QTcpServer>
#include <QSocketNotifier>
#include <iostream>

StdinNotifier::StdinNotifier(QObject *parent) : QObject(parent) {
  m_notifier = new QSocketNotifier(fileno(stdin), QSocketNotifier::Read, this);
  connect(m_notifier, SIGNAL(activated(int)), this, SLOT(notifierActivated()));
}

void StdinNotifier::notifierActivated() {
  std::string line;
  std::getline(std::cin, line);
  if (std::cin.eof()) {
    emit eof();
  }
}
