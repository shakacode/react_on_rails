# frozen_string_literal: true

require "stringio"
require "timeout"

module ReactOnRailsPro
  class CompressionMiddlewareGuard
    COMPATIBILITY_GUIDE_PATH =
      "https://reactonrails.com/docs/building-features/" \
      "streaming-server-rendering/#compression-middleware-compatibility"
    PROBLEMATIC_MIDDLEWARES = %w[Rack::Deflater Rack::Brotli].freeze
    PROBE_TIMEOUT_SECONDS = 1

    Finding = Struct.new(:middleware_name, :source_location, keyword_init: true)

    def initialize(middlewares:, logger: nil)
      @middlewares = normalize_middlewares(middlewares)
      @logger = logger
    end

    def findings
      @findings ||= @middlewares.filter_map do |middleware|
        next unless problematic_middleware?(middleware)

        condition = middleware_condition(middleware)
        next unless condition.respond_to?(:call)
        next unless destructively_iterates_stream?(condition)

        Finding.new(
          middleware_name: middleware_name(middleware),
          source_location: source_location_for(condition)
        )
      end
    end

    def warning_messages(root:)
      findings.map do |finding|
        "[React on Rails Pro] #{finding.middleware_name} has a custom `:if` callback" \
          "#{formatted_source_location(finding, root: root)} that calls `body.each`. " \
          "This is incompatible with streaming SSR/RSC and can deadlock `ActionController::Live` responses. " \
          "Remove the custom `:if`, or guard it with " \
          "`return true unless body.respond_to?(:to_ary)` before iterating. " \
          "See #{COMPATIBILITY_GUIDE_PATH}."
      end
    end

    private

    def normalize_middlewares(middlewares)
      if defined?(ActionDispatch::MiddlewareStack) && middlewares.is_a?(ActionDispatch::MiddlewareStack)
        return middlewares.middlewares
      end

      Array(middlewares)
    end

    def problematic_middleware?(middleware)
      PROBLEMATIC_MIDDLEWARES.include?(middleware_name(middleware))
    end

    def middleware_name(middleware)
      middleware.klass.respond_to?(:name) ? middleware.klass.name : middleware.klass.to_s
    end

    def middleware_condition(middleware)
      Array(middleware.args).filter_map do |arg|
        next unless arg.is_a?(Hash)

        arg[:if] || arg["if"]
      end.first
    end

    def destructively_iterates_stream?(condition)
      probe = StreamingBodyProbe.new

      Timeout.timeout(PROBE_TIMEOUT_SECONDS) do
        condition.call(probe_env, 200, probe_headers, probe)
      end
      probe.iterated?
    rescue StreamingBodyProbe::BodyIteratedError
      true
    rescue Timeout::Error => e
      return true if probe.iterated?

      log_probe_failure(condition, e, reason: "timed out after #{PROBE_TIMEOUT_SECONDS}s")
      false
    rescue StandardError => e
      return true if probe.iterated?

      log_probe_failure(condition, e)
      false
    end

    # Minimal Rack env used to probe `:if` callbacks.
    # Callbacks that depend on application-specific keys can still raise here;
    # those probe failures are logged at debug level and treated as non-findings.
    # Path-gated callbacks can bypass this probe and yield false negatives.
    def probe_env
      {
        "CONTENT_TYPE" => "text/html; charset=utf-8",
        "HTTP_ACCEPT" => "text/html",
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/__react_on_rails_pro_stream_probe__",
        "HTTP_ACCEPT_ENCODING" => "br, gzip, identity",
        "HTTP_HOST" => "example.test",
        "SERVER_NAME" => "example.test",
        "rack.url_scheme" => "https",
        "rack.errors" => StringIO.new,
        "rack.input" => StringIO.new
      }
    end

    def probe_headers
      {
        "Content-Type" => "text/html; charset=utf-8"
      }
    end

    def formatted_source_location(finding, root:)
      return "" unless finding.source_location

      path, line = finding.source_location
      root_prefix = "#{root}/"
      display_path = path.start_with?(root_prefix) ? path.delete_prefix(root_prefix) : path

      " (#{display_path}:#{line})"
    end

    def source_location_for(condition)
      condition.respond_to?(:source_location) ? condition.source_location : nil
    end

    def log_probe_failure(condition, error, reason: nil)
      return unless @logger.respond_to?(:debug)

      identifier = source_location_for(condition)&.join(":") || condition.class.name || condition.inspect
      backtrace_hint = error.backtrace&.first

      @logger.debug do
        message = "[React on Rails Pro] CompressionMiddlewareGuard could not probe `:if` callback " \
                  "(#{identifier}): "
        message += "#{reason}: " if reason
        message += "#{error.class}: #{error.message}"
        message += " (#{backtrace_hint})" if backtrace_hint
        message
      end
    end

    class StreamingBodyProbe
      include Enumerable

      class BodyIteratedError < StandardError; end

      def iterated?
        @iterated == true
      end

      def each
        @iterated = true
        raise BodyIteratedError, "Compression middleware `:if` callback called `body.each` on a streaming body."
      end
    end
  end
end
