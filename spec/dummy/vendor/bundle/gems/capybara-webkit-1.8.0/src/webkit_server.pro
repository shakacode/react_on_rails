TEMPLATE = app
TARGET = webkit_server
DESTDIR = .
PROJECT_DIR = $$_PRO_FILE_PWD_
BUILD_DIR = $${PROJECT_DIR}/build
PRECOMPILED_DIR = $${BUILD_DIR}
OBJECTS_DIR = $${BUILD_DIR}
MOC_DIR = $${BUILD_DIR}
HEADERS = \
  BlockUrl.h \
  AllowUrl.h \
  SetUnknownUrlMode.h \
  FindModal.h \
  AcceptAlert.h \
  GoForward.h \
  GoBack.h \
  WindowMaximize.h \
  WindowSize.h \
  WindowCommand.h \
  WindowOpen.h \
  WindowClose.h \
  Version.h \
  EnableLogging.h \
  Authenticate.h \
  SetConfirmAction.h \
  SetPromptAction.h \
  SetPromptText.h \
  ClearPromptText.h \
  JavascriptAlertMessages.h \
  JavascriptConfirmMessages.h \
  JavascriptPromptMessages.h \
  IgnoreSslErrors.h \
  WindowResize.h \
  CurrentUrl.h \
  ConsoleMessages.h \
  WebPage.h \
  Server.h \
  Connection.h \
  Command.h \
  SocketCommand.h \
  Visit.h \
  Reset.h \
  Node.h \
  JavascriptInvocation.h \
  Evaluate.h \
  Execute.h \
  FrameFocus.h \
  Response.h \
  NetworkAccessManager.h \
  NetworkCookieJar.h \
  Header.h \
  Render.h \
  Body.h \
  Status.h \
  Headers.h \
  UnsupportedContentHandler.h \
  SetCookie.h \
  ClearCookies.h \
  GetCookies.h \
  CommandParser.h \
  CommandFactory.h \
  SetProxy.h \
  NullCommand.h \
  PageLoadingCommand.h \
  SetSkipImageLoading.h \
  WebPageManager.h \
  WindowFocus.h \
  GetWindowHandles.h \
  GetWindowHandle.h \
  GetTimeout.h \
  SetTimeout.h \
  TimeoutCommand.h \
  SetUrlBlacklist.h \
  NoOpReply.h \
  JsonSerializer.h \
  InvocationResult.h \
  ErrorMessage.h \
  Title.h \
  FindCss.h \
  JavascriptCommand.h \
  FindXpath.h \
  NetworkReplyProxy.h \
  IgnoreDebugOutput.h \
  StdinNotifier.h \
  RequestHandler.h \
  BlacklistedRequestHandler.h \
  MissingContentHeaderRequestHandler.h \
  CustomHeadersRequestHandler.h \
  NetworkRequestFactory.h \
  UnknownUrlHandler.h

SOURCES = \
  BlockUrl.cpp \
  AllowUrl.cpp \
  SetUnknownUrlMode.cpp \
  FindModal.cpp \
  AcceptAlert.cpp \
  GoForward.cpp \
  GoBack.cpp \
  WindowMaximize.cpp \
  WindowSize.cpp \
  WindowCommand.cpp \
  WindowOpen.cpp \
  WindowClose.cpp \
  Version.cpp \
  EnableLogging.cpp \
  Authenticate.cpp \
  SetConfirmAction.cpp \
  SetPromptAction.cpp \
  SetPromptText.cpp \
  ClearPromptText.cpp \
  JavascriptAlertMessages.cpp \
  JavascriptConfirmMessages.cpp \
  JavascriptPromptMessages.cpp \
  IgnoreSslErrors.cpp \
  WindowResize.cpp \
  CurrentUrl.cpp \
  ConsoleMessages.cpp \
  main.cpp \
  WebPage.cpp \
  Server.cpp \
  Connection.cpp \
  Command.cpp \
  SocketCommand.cpp \
  Visit.cpp \
  Reset.cpp \
  Node.cpp \
  JavascriptInvocation.cpp \
  Evaluate.cpp \
  Execute.cpp \
  FrameFocus.cpp \
  Response.cpp \
  NetworkAccessManager.cpp \
  NetworkCookieJar.cpp \
  Header.cpp \
  Render.cpp \
  body.cpp \
  Status.cpp \
  Headers.cpp \
  UnsupportedContentHandler.cpp \
  SetCookie.cpp \
  ClearCookies.cpp \
  GetCookies.cpp \
  CommandParser.cpp \
  CommandFactory.cpp \
  SetProxy.cpp \
  NullCommand.cpp \
  PageLoadingCommand.cpp \
  SetTimeout.cpp \
  GetTimeout.cpp \
  SetSkipImageLoading.cpp \
  WebPageManager.cpp \
  WindowFocus.cpp \
  GetWindowHandles.cpp \
  GetWindowHandle.cpp \
  TimeoutCommand.cpp \
  SetUrlBlacklist.cpp \
  NoOpReply.cpp \
  JsonSerializer.cpp \
  InvocationResult.cpp \
  ErrorMessage.cpp \
  Title.cpp \
  FindCss.cpp \
  JavascriptCommand.cpp \
  FindXpath.cpp \
  NetworkReplyProxy.cpp \
  IgnoreDebugOutput.cpp \
  StdinNotifier.cpp \
  RequestHandler.cpp \
  BlacklistedRequestHandler.cpp \
  MissingContentHeaderRequestHandler.cpp \
  CustomHeadersRequestHandler.cpp \
  NetworkRequestFactory.cpp \
  UnknownUrlHandler.cpp

RESOURCES = webkit_server.qrc
QT += network
greaterThan(QT_MAJOR_VERSION, 4) {
  QT += webkitwidgets
} else {
  QT += webkit
}
lessThan(QT_MAJOR_VERSION, 5) {
  lessThan(QT_MINOR_VERSION, 8) {
    error(At least Qt 4.8.0 is required to run capybara-webkit.)
  }
}
CONFIG += console precompile_header
CONFIG -= app_bundle
PRECOMPILED_HEADER = stable.h

