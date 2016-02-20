#include "FindModal.h"
#include "SocketCommand.h"
#include "WebPage.h"
#include "WebPageManager.h"
#include "ErrorMessage.h"

FindModal::FindModal(WebPageManager *manager, QStringList &arguments, QObject *parent) : SocketCommand(manager, arguments, parent) {
}

void FindModal::start() {
  if (page()->modalCount() == 0) {
    connect(page(), SIGNAL(modalReady()), SLOT(handleModalReady()));
  } else {
    handleModalReady();
  }
}

void FindModal::handleModalReady() {
  sender()->disconnect(SIGNAL(modalReady()), this, SLOT(handleModalReady()));
  QString message = page()->modalMessage();
  if (message.isNull()) {
    finish(false, new ErrorMessage("ModalNotFound", ""));
  } else {
    finish(true, message);
  }
}
