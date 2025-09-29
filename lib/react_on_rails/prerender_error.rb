# frozen_string_literal: true

require "rainbow"

# rubocop:disable: Layout/IndentHeredoc
module ReactOnRails
  class PrerenderError < ::ReactOnRails::Error
    MAX_ERROR_SNIPPET_TO_LOG = 1000
    # TODO: Consider remove providing original `err` as already have access to `self.cause`
    # http://blog.honeybadger.io/nested-errors-in-ruby-with-exception-cause/
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

    # rubocop:disable Metrics/AbcSize
    def calc_message(component_name, console_messages, err, js_code, props)
      header = Rainbow("❌ React on Rails Server Rendering Error").red.bright
      message = +"#{header}\n\n"

      message << Rainbow("Component: #{component_name}").yellow << "\n\n"

      if err
        message << Rainbow("Error Details:").red.bright << "\n"
        message << <<~MSG
          #{err.inspect}

        MSG

        backtrace = if Utils.full_text_errors_enabled?
                      err.backtrace.join("\n")
                    else
                      "#{Rails.backtrace_cleaner.clean(err.backtrace).join("\n")}\n" +
                        Rainbow("💡 Tip: Set FULL_TEXT_ERRORS=true to see the full backtrace").yellow
                    end
      else
        backtrace = nil
      end

      # Add props information
      message << Rainbow("Props:").blue.bright << "\n"
      message << "#{Utils.smart_trim(props, MAX_ERROR_SNIPPET_TO_LOG)}\n\n"

      # Add code snippet
      message << Rainbow("JavaScript Code:").blue.bright << "\n"
      message << "#{Utils.smart_trim(js_code, MAX_ERROR_SNIPPET_TO_LOG)}\n\n"

      if console_messages && console_messages.strip.present?
        message << Rainbow("Console Output:").magenta.bright << "\n"
        message << "#{console_messages}\n\n"
      end

      # Add actionable suggestions
      message << Rainbow("💡 Troubleshooting Steps:").yellow.bright << "\n"
      message << build_troubleshooting_suggestions(component_name, err, console_messages)

      # Add help and support information
      message << "\n#{Utils.default_troubleshooting_section}\n"

      [backtrace, message]
      # rubocop:enable Metrics/AbcSize
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def build_troubleshooting_suggestions(component_name, err, console_messages)
      suggestions = []

      # Check for common error patterns
      if err&.message&.include?("window is not defined") || console_messages&.include?("window is not defined")
        suggestions << <<~SUGGESTION
          1. Browser API used on server - wrap with client-side check:
             #{Rainbow("if (typeof window !== 'undefined') { ... }").cyan}
        SUGGESTION
      end

      if err&.message&.include?("document is not defined") || console_messages&.include?("document is not defined")
        suggestions << <<~SUGGESTION
          1. DOM API used on server - use React refs or useEffect:
             #{Rainbow('useEffect(() => { /* DOM operations here */ }, [])').cyan}
        SUGGESTION
      end

      if err&.message&.include?("Cannot read") || err&.message&.include?("undefined")
        suggestions << <<~SUGGESTION
          1. Check for null/undefined values in props
          2. Add default props or use optional chaining:
             #{Rainbow("props.data?.value || 'default'").cyan}
        SUGGESTION
      end

      if err&.message&.include?("Hydration") || console_messages&.include?("Hydration")
        suggestions << <<~SUGGESTION
          1. Server and client render mismatch - ensure consistent:
             - Random values (use seed from props)
             - Date/time values (pass from server)
             - User agent checks (avoid or use props)
        SUGGESTION
      end

      # Generic suggestions
      suggestions << <<~SUGGESTION
        • Temporarily disable SSR to isolate the issue:
          #{Rainbow('prerender: false').cyan} in your view helper
        • Check server logs for detailed errors:
          #{Rainbow('tail -f log/development.log').cyan}
        • Verify component registration:
          #{Rainbow("ReactOnRails.register({ #{component_name}: #{component_name} })").cyan}
        • Ensure server bundle is up to date:
          #{Rainbow('bin/shakapacker').cyan} or #{Rainbow('yarn run build:server').cyan}
      SUGGESTION

      suggestions.join("\n")
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
  end
end
