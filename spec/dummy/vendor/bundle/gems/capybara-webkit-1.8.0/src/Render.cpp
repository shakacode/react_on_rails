#include "Render.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "ErrorMessage.h"

Render::Render(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void Render::start() {
  QString imagePath = arguments()[0];
  int width = arguments()[1].toInt();
  int height = arguments()[2].toInt();

  QSize size(width, height);

  bool result = page()->render( imagePath, size );

  if (result) {
    finish(true);
  } else {
    const QString failure = QString("Unable to save %1x%2 image to %3").
      arg(width).
      arg(height).
      arg(imagePath);
    finish(false, new ErrorMessage(failure));
  }
}
