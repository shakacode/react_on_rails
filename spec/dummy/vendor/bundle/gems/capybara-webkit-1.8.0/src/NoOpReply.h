#include <QNetworkReply>
#include <QNetworkRequest>

class NoOpReply : public QNetworkReply {
  Q_OBJECT

  public: 
    NoOpReply(const QNetworkRequest &request, QObject *parent = 0);

    void abort();
    qint64 bytesAvailable() const;
    bool isSequential() const;

  protected:
    qint64 readData(char *data, qint64 maxSize);

};

