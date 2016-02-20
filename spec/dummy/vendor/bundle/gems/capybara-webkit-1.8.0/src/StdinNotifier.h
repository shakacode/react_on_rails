#include <QObject>

class QSocketNotifier;

class StdinNotifier : public QObject {
  Q_OBJECT

  public:
    StdinNotifier(QObject *parent = 0);

  public slots:
    void notifierActivated();

  signals:
    void eof();

  private:
    QSocketNotifier *m_notifier;
};

