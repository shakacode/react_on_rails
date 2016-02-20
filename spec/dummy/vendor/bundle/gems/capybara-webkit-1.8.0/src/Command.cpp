#include "Command.h"
#include "ErrorMessage.h"

Command::Command(QObject *parent) : QObject(parent) {
}

QString Command::toString() const {
  return metaObject()->className();
}

void Command::finish(bool success) {
  emit finished(new Response(success, this));
}

void Command::finish(bool success, QString message) {
  emit finished(new Response(success, message, this));
}

void Command::finish(bool success, QByteArray message) {
  emit finished(new Response(success, message, this));
}

void Command::finish(bool success, ErrorMessage *message) {
  emit finished(new Response(success, message, this));
}
