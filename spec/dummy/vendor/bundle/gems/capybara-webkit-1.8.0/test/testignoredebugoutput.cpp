#include <QtTest/QtTest>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include "../src/IgnoreDebugOutput.h"

#define MAX_LEN 40

class TestIgnoreDebugOutput: public QObject {
  Q_OBJECT

  private slots:
    void testIgnoreDebugOutput();
};

void TestIgnoreDebugOutput::testIgnoreDebugOutput() {
  char buffer[MAX_LEN+1] = {0};
  int out_pipe[2];
  int saved_stdout;

  saved_stdout = dup(STDOUT_FILENO);

  QVERIFY(pipe(out_pipe) == 0);

  dup2(out_pipe[1], STDOUT_FILENO);
  close(out_pipe[1]);

  long flags = fcntl(out_pipe[0], F_GETFL);
  flags |= O_NONBLOCK;
  fcntl(out_pipe[0], F_SETFL, flags);

  ignoreDebugOutput();

  qDebug() << "Message";
  fflush(stdout);

  read(out_pipe[0], buffer, MAX_LEN);

  dup2(saved_stdout, STDOUT_FILENO);

  QCOMPARE(QString(buffer), QString(""));
}

QTEST_MAIN(TestIgnoreDebugOutput)
#include "testignoredebugoutput.moc"
