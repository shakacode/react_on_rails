# frozen_string_literal: true

# rubocop:disable: Layout/IndentHeredoc
module ReactOnRails
  class PrerenderError < ::ReactOnRails::Error
    attr_reader :component_name, :err, :props, :js_code, :console_messages

    # err might be nil if JS caught the error
    def initialize(component_name: nil, err: nil, props: nil,
                   js_code: nil, console_messages: nil)
      @component_name = component_name
      @err = err
      @props = props
      @js_code = js_code
      @console_messages = console_messages

      backtrace, message = calc_message(component_name, console_messages, err, js_code, props)

      super([message, backtrace].compact.join("\n"))
    end

    def to_honeybadger_context
      to_error_context
    end

    def raven_context
      to_error_context
    end

    def to_error_context
      result = {
        component_name: component_name,
        err: err,
        props: props,
        js_code: js_code,
        console_messages: console_messages
      }

      result.merge!(err.to_error_context) if err.respond_to?(:to_error_context)
      result
    end

    private

    def calc_message(component_name, console_messages, err, js_code, props)
      message = "ERROR in SERVER PRERENDERING\n".dup
      if err
        # rubocop:disable Layout/IndentHeredoc
        message << <<-MSG
Encountered error: \"#{err}\"
        MSG
        # rubocop:enable Layout/IndentHeredoc
        backtrace = err.backtrace.join("\n")
      else
        backtrace = nil
      end
      # rubocop:disable Layout/IndentHeredoc
      message << <<-MSG
when prerendering #{component_name} with props: #{props}
js_code was:
#{js_code}
      MSG
      # rubocop:enable Layout/IndentHeredoc

      if console_messages
        # rubocop:disable Layout/IndentHeredoc
        message << <<-MSG
console messages:
#{console_messages}
        MSG
        # rubocop:enable Layout/IndentHeredoc
      end
      [backtrace, message]
    end
  end
end
