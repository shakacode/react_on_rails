#include "Server.h"
#include "IgnoreDebugOutput.h"
#include "StdinNotifier.h"
#include <QApplication>
#include <iostream>
#ifdef Q_OS_UNIX
  #include <unistd.h>
#endif

int main(int argc, char **argv) {
#ifdef Q_OS_UNIX
  if (setpgid(0, 0) < 0) {
    std::cerr << "Unable to set new process group." << std::endl;
    return 1;
  }
#endif

  QApplication app(argc, argv);
  app.setApplicationName("capybara-webkit");
  app.setOrganizationName("thoughtbot, inc");
  app.setOrganizationDomain("thoughtbot.com");

  StdinNotifier notifier;
  QObject::connect(&notifier, SIGNAL(eof()), &app, SLOT(quit()));

  ignoreDebugOutput();
  Server server(0);

  if (server.start()) {
    std::cout << "Capybara-webkit server started, listening on port: " << server.server_port() << std::endl;
    return app.exec();
  } else {
    std::cerr << "Couldn't start capybara-webkit server" << std::endl;
    return 1;
  }
}
