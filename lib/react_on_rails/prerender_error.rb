# frozen_string_literal: true

# rubocop:disable: Layout/IndentHeredoc
module ReactOnRails
  class PrerenderError < RuntimeError
    # err might be nil if JS caught the error
    def initialize(component_name: nil, err: nil, props: nil,
                   js_code: nil, console_messages: nil)
      message = "ERROR in SERVER PRERENDERING\n".dup
      if err
        message << <<~MSG
          Encountered error: \"#{err}\"
        MSG
        backtrace = err.backtrace.join("\n")
      else
        backtrace = nil
      end
      message << <<~MSG
        when prerendering #{component_name} with props: #{props}
        js_code was:
        #{js_code}
      MSG

      if console_messages
        message << <<~MSG
          console messages:
          #{console_messages}
        MSG
      end

      super([message, backtrace].compact.join("\n"))
    end
  end
end
