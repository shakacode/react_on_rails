module Capybara::Webkit
  class InvalidResponseError < StandardError
  end

  class NoResponseError < StandardError
  end

  class NodeNotAttachedError < Capybara::ElementNotFound
  end

  class ClickFailed < StandardError
  end

  class TimeoutError < Timeout::Error
  end

  class NoSuchWindowError < StandardError
  end

  class ConnectionError < StandardError
  end

  class ModalNotFound < StandardError
  end

  class CrashError < StandardError
  end

  class JsonError
    def initialize(response)
      error = JSON.parse response

      @class_name = error['class']
      @message = error['message']
    end

    def exception
      error_class.new @message
    end

    private

    def error_class
      Capybara::Webkit.const_get @class_name
    end
  end
end
