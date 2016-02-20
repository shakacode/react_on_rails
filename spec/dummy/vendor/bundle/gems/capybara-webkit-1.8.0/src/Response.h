#ifndef RESPONSE_H
#define RESPONSE_H

#include <QObject>
#include <QString>
#include <QByteArray>

class ErrorMessage;

class Response : public QObject {
  Q_OBJECT

  public:
    Response(bool success, QString message, QObject *parent = 0);
    Response(bool success, QByteArray message, QObject *parent = 0);
    Response(bool success, ErrorMessage *message, QObject *parent = 0);
    Response(bool success, QObject *parent);
    bool isSuccess() const;
    QByteArray message() const;
    QString toString() const;

  protected:
    QByteArray m_message;

  private:
    bool m_success;
};

#endif

