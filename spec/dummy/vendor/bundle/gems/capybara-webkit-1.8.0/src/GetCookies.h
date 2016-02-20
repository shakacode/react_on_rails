#include "SocketCommand.h"

class GetCookies : public SocketCommand {
  Q_OBJECT;

 public:
  GetCookies(WebPageManager *, QStringList &arguments, QObject *parent = 0);
  virtual void start();

 private:
  QString m_buffer;
};
