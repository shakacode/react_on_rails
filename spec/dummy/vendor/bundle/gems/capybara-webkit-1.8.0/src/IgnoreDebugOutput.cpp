#include "IgnoreDebugOutput.h"

#include <QtGlobal>
#include <QString>
#include <stdio.h>

void debugIgnoringMessageHandler(QtMsgType type, const char *msg);

#if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
  void debugIgnoringMessageHandlerQt5(QtMsgType type, const QMessageLogContext &context, const QString &message);
#endif

void debugIgnoringMessageHandler(QtMsgType type, const char *msg) {
  switch (type) {
    case QtDebugMsg:
    case QtWarningMsg:
      break;
    default:
      fprintf(stderr, "%s\n", msg);
      break;
  }
}

#if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
  void debugIgnoringMessageHandlerQt5(QtMsgType type, const QMessageLogContext &context, const QString &message) {
    Q_UNUSED(context);
    debugIgnoringMessageHandler(type, message.toLocal8Bit().data());
  }
#endif

void ignoreDebugOutput(void) {
#if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
  qInstallMessageHandler(debugIgnoringMessageHandlerQt5);
#else
  qInstallMsgHandler(debugIgnoringMessageHandler);
#endif
}
