#include "SocketCommand.h"

class QWebFrame;

class FrameFocus : public SocketCommand {
  Q_OBJECT

  public:
    FrameFocus(WebPageManager *, QStringList &arguments, QObject *parent = 0);
    virtual void start();

  private:
    void findFrames();

    void focusParent();

    void focusIndex(int index);
    bool isFrameAtIndex(int index);

    void focusId(QString id);

    void success();
    void frameNotFound();

    QList<QWebFrame *> frames;
};

