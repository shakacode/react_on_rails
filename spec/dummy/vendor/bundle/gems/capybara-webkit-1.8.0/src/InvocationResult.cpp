#include "InvocationResult.h"
#include "ErrorMessage.h"

InvocationResult::InvocationResult(QVariant result, bool error) {
  m_result = result;
  m_error = error;
}

const QVariant &InvocationResult::result() const {
  return m_result;
}

bool InvocationResult::hasError() {
  return m_error;
}

ErrorMessage *InvocationResult::errorMessage() {
  if (!m_result.canConvert<QVariantMap>())
    return new ErrorMessage(m_result.toString());

  QVariantMap error = m_result.toMap();

  QString message = error["message"].toString();

  if (error["name"] == "Capybara.ClickFailed")
    return new ErrorMessage("ClickFailed", message);
  else if (error["name"] == "Capybara.NodeNotAttachedError")
    return new ErrorMessage("NodeNotAttachedError", message);
  else
    return new ErrorMessage(message);
}
