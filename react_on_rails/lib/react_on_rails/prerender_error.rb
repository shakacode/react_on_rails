# frozen_string_literal: true

require "rainbow"

# rubocop:disable: Layout/IndentHeredoc
module ReactOnRails
  class PrerenderError < ::ReactOnRails::Error
    REDACTED_VALUE = "[REDACTED]"
    SENSITIVE_CONTEXT_KEYS = %w[props js_code json].freeze
    # TODO: Consider remove providing original `err` as already have access to `self.cause`
    # http://blog.honeybadger.io/nested-errors-in-ruby-with-exception-cause/
    attr_reader :component_name, :err, :props, :js_code, :console_messages

    # err might be nil if JS caught the error
    def initialize(component_name: nil, err: nil, props: nil,
                   js_code: nil, console_messages: nil)
      @component_name = component_name
      @err = err
      @props = redacted_value(props)
      @js_code = redacted_value(js_code)
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
        component_name:,
        err: error_context_value(err),
        props:,
        js_code:,
        console_messages:
      }

      if err.respond_to?(:to_error_context)
        nested_context = err.to_error_context.reject { |key, _value| sensitive_nested_context_key?(key) }
        result.merge!(nested_context)
      end
      result
    end

    private

    def renderer_parse_error?(error)
      json_parse_error = defined?(JsonParseError) && error.is_a?(JsonParseError)
      length_prefixed_parse_error = defined?(LengthPrefixedParser::ParseError) &&
                                    error.is_a?(LengthPrefixedParser::ParseError)
      json_parse_error || length_prefixed_parse_error
    end

    def safe_error_details(error)
      return error.inspect unless renderer_parse_error?(error)

      "#{error.class}: Renderer response could not be parsed"
    end

    def error_context_value(error)
      renderer_parse_error?(error) ? safe_error_details(error) : error
    end

    def sensitive_nested_context_key?(key)
      SENSITIVE_CONTEXT_KEYS.include?(key.to_s) ||
        (renderer_parse_error?(err) && key.to_s == "original_error")
    end

    # rubocop:disable Metrics/AbcSize
    def calc_message(component_name, console_messages, err, js_code, props)
      header = Rainbow("❌ React on Rails Server Rendering Error").red.bright
      message = +"#{header}\n\n"

      message << Rainbow("Component: #{component_name}").yellow << "\n\n"

      if err
        message << Rainbow("Error Details:").red.bright << "\n"
        message << <<~MSG
          #{safe_error_details(err)}

        MSG

        backtrace = formatted_backtrace(err)
      else
        backtrace = nil
      end

      # Add props information
      message << Rainbow("Props:").blue.bright << "\n"
      message << "#{redacted_value(props)}\n\n"

      # Add code snippet
      message << Rainbow("JavaScript Code:").blue.bright << "\n"
      message << "#{redacted_value(js_code)}\n\n"

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

    def redacted_value(value)
      value.nil? ? nil : REDACTED_VALUE
    end

    # Formats `err.backtrace` for display, or returns nil when there are no frames.
    def formatted_backtrace(err)
      error_backtrace = err.backtrace
      # JS-originated errors (e.g. an RSC renderingError carrying a message but no parseable
      # stack) have no Ruby backtrace. Skip it rather than crashing on `nil.join` /
      # `Rails.backtrace_cleaner.clean(nil)`.
      return nil if error_backtrace.nil? || error_backtrace.empty?
      return error_backtrace.join("\n") if Utils.full_text_errors_enabled?

      "#{Rails.backtrace_cleaner.clean(error_backtrace).join("\n")}\n" +
        Rainbow("💡 Tip: Set FULL_TEXT_ERRORS=true to see the full backtrace").yellow
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
