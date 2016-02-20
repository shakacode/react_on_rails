#include "Response.h"
#include "ErrorMessage.h"
#include <iostream>

Response::Response(bool success, QString message, QObject *parent) : QObject(parent) {
  m_success = success;
  m_message = message.toUtf8();
}

Response::Response(bool success, QByteArray message, QObject *parent) : QObject(parent) {
  m_success = success;
  m_message = message;
}

Response::Response(bool success, ErrorMessage *message, QObject *parent) : QObject(parent) {
  m_success = success;
  m_message = message->toString();
  message->deleteLater();
}

Response::Response(bool success, QObject *parent) : QObject(parent) {
  m_success = success;
}

bool Response::isSuccess() const {
  return m_success;
}

QByteArray Response::message() const {
  return m_message;
}

QString Response::toString() const {
  return QString(m_success ? "Success(" : "Failure(") + m_message + ")";
}
