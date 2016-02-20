#include <QVariant>

class ErrorMessage;

class InvocationResult {
  public:
    InvocationResult(QVariant result, bool error = false);
    const QVariant &result() const;
    bool hasError();
    ErrorMessage *errorMessage();

  private:
    QVariant m_result;
    bool m_error;
};

