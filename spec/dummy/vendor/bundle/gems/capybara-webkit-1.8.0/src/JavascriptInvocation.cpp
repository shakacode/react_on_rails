#include "JavascriptInvocation.h"
#include "WebPage.h"
#include "InvocationResult.h"
#include <QApplication>
#include <QEvent>
#include <QContextMenuEvent>

JavascriptInvocation::JavascriptInvocation(const QString &functionName, bool allowUnattached, const QStringList &arguments, WebPage *page, QObject *parent) : QObject(parent) {
  m_functionName = functionName;
  m_allowUnattached = allowUnattached;
  m_arguments = arguments;
  m_page = page;
}

QString &JavascriptInvocation::functionName() {
  return m_functionName;
}

bool JavascriptInvocation::allowUnattached() {
  return m_allowUnattached;
}

QStringList &JavascriptInvocation::arguments() {
  return m_arguments;
}

QVariant JavascriptInvocation::getError() {
  return m_error;
}

void JavascriptInvocation::setError(QVariant error) {
  m_error = error;
}

InvocationResult JavascriptInvocation::invoke(QWebFrame *frame) {
  frame->addToJavaScriptWindowObject("CapybaraInvocation", this);
  QVariant result = frame->evaluateJavaScript("Capybara.invoke()");
  if (getError().isValid())
    return InvocationResult(getError(), true);
  else
    return InvocationResult(result);
}

void JavascriptInvocation::leftClick(int x, int y) {
  QPoint mousePos(x, y);

  m_page->mouseEvent(QEvent::MouseButtonPress, mousePos, Qt::LeftButton);
  m_page->mouseEvent(QEvent::MouseButtonRelease, mousePos, Qt::LeftButton);
}

void JavascriptInvocation::rightClick(int x, int y) {
  QPoint mousePos(x, y);

  m_page->mouseEvent(QEvent::MouseButtonPress, mousePos, Qt::RightButton);

  // swallowContextMenuEvent tries to fire contextmenu event in html page
  QContextMenuEvent *event = new QContextMenuEvent(QContextMenuEvent::Mouse, mousePos);
  m_page->swallowContextMenuEvent(event);

  m_page->mouseEvent(QEvent::MouseButtonRelease, mousePos, Qt::RightButton);
}

void JavascriptInvocation::doubleClick(int x, int y) {
  QPoint mousePos(x, y);

  m_page->mouseEvent(QEvent::MouseButtonDblClick, mousePos, Qt::LeftButton);
  m_page->mouseEvent(QEvent::MouseButtonRelease, mousePos, Qt::LeftButton);
}

bool JavascriptInvocation::clickTest(QWebElement element, int absoluteX, int absoluteY) {
  return m_page->clickTest(element, absoluteX, absoluteY);
}

QVariantMap JavascriptInvocation::clickPosition(QWebElement element, int left, int top, int width, int height) {
  QRect elementBox(left, top, width, height);
  QRect viewport(QPoint(0, 0), m_page->viewportSize());
  QRect boundedBox = elementBox.intersected(viewport);
  QPoint mousePos = boundedBox.center();

  QVariantMap m;
  m["relativeX"] = mousePos.x();
  m["relativeY"] = mousePos.y();

  QWebFrame *parent = element.webFrame();
  while (parent) {
    elementBox.translate(parent->geometry().topLeft());
    parent = parent->parentFrame();
  }

  boundedBox = elementBox.intersected(viewport);
  mousePos = boundedBox.center();

  m["absoluteX"] = mousePos.x();
  m["absoluteY"] = mousePos.y();

  return m;
}

void JavascriptInvocation::hover(int absoluteX, int absoluteY) {
  QPoint mousePos(absoluteX, absoluteY);
  hover(mousePos);
}

void JavascriptInvocation::hover(const QPoint &mousePos) {
  m_page->mouseEvent(QEvent::MouseMove, mousePos, Qt::NoButton);
}

int JavascriptInvocation::keyCodeFor(const QChar &key) {
  switch(key.unicode()) {
    case 0x18:
      return Qt::Key_Cancel;
    case 0x08:
      return Qt::Key_Backspace;
    case 0x09:
      return Qt::Key_Tab;
    case 0x0A:
      return Qt::Key_Return;
    case 0x1B:
      return Qt::Key_Escape;
    case 0x7F:
      return Qt::Key_Delete;
    default:
      int keyCode = key.toUpper().toLatin1();
      if (keyCode >= Qt::Key_Space || keyCode <= Qt::Key_AsciiTilde)
        return keyCode;
      else
        return Qt::Key_unknown;
  }
}

void JavascriptInvocation::keypress(QChar key) {
  int keyCode = keyCodeFor(key);
  QKeyEvent event(QKeyEvent::KeyPress, keyCode, Qt::NoModifier, key);
  QApplication::sendEvent(m_page, &event);
  event = QKeyEvent(QKeyEvent::KeyRelease, keyCode, Qt::NoModifier, key);
  QApplication::sendEvent(m_page, &event);
}

const QString JavascriptInvocation::render(void) {
  QString pathTemplate =
    QDir::temp().absoluteFilePath("./click_failed_XXXXXX.png");
  QTemporaryFile file(pathTemplate);
  file.open();
  file.setAutoRemove(false);
  QString path = file.fileName();
  m_page->render(path, QSize(1024, 768));
  return path;
}
