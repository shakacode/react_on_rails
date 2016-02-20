#include <QObject>
#include <QStringList>

class QIODevice;
class CommandFactory;
class Command;

class CommandParser : public QObject {
  Q_OBJECT

  public:
    CommandParser(QIODevice *device, CommandFactory *commandFactory, QObject *parent = 0);

  public slots:
    void checkNext();

  signals:
    void commandReady(Command *command);

  private:
    void readLine();
    void readDataBlock();
    void processNext(const char *line);
    void processArgument(const char *data);
    void reset();
    QIODevice *m_device;
    QString m_commandName;
    QStringList m_arguments;
    int m_argumentsExpected;
    int m_expectingDataSize;
    CommandFactory *m_commandFactory;
};

