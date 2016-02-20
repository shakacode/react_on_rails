#include <QObject>

class QTcpServer;

class Server : public QObject {
  Q_OBJECT

  public:
    Server(QObject *parent);
    bool start();
    quint16 server_port() const;

  public slots:
    void handleConnection();

  private:
    QTcpServer *m_tcp_server;
};

