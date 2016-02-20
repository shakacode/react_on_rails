#ifndef __ERROR_MESSAGE_H
#define __ERROR_MESSAGE_H

#include <QObject>
#include <QString>
#include <QByteArray>

class ErrorMessage : public QObject {
  Q_OBJECT

  public:
    ErrorMessage(QString message, QObject *parent = 0);
    ErrorMessage(QString type, QString message, QObject *parent = 0);
    QByteArray toString();

  private:
    QString m_type;
    QString m_message;
};

#endif
