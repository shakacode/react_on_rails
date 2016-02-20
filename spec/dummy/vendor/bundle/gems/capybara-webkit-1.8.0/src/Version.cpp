#include "Version.h"
#include "WebPage.h"

Version::Version(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void Version::start() {
  QString result =
    QString("Qt: ") + QT_VERSION_STR +
    QString("\nWebKit: ") + qWebKitVersion() +
    QString("\nQtWebKit: ") + QTWEBKIT_VERSION_STR;
  finish(true, result);
}
