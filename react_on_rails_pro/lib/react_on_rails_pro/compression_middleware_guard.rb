# frozen_string_literal: true

require "stringio"

module ReactOnRailsPro
  class CompressionMiddlewareGuard
    COMPATIBILITY_GUIDE_PATH =
      "docs/building-features/streaming-server-rendering.md#compression-middleware-compatibility"
    PROBLEMATIC_MIDDLEWARES = %w[Rack::Deflater Rack::Brotli].freeze

    Finding = Struct.new(:middleware_name, :source_location, keyword_init: true)

    def initialize(middlewares:)
      @middlewares = normalize_middlewares(middlewares)
    end

    def findings
      @findings ||= @middlewares.filter_map do |middleware|
        next unless problematic_middleware?(middleware)

        condition = middleware_condition(middleware)
        next unless condition.respond_to?(:call)
        next unless destructively_iterates_stream?(condition)

        Finding.new(
          middleware_name: middleware_name(middleware),
          source_location: condition.source_location
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
      return middlewares.middlewares if middlewares.respond_to?(:middlewares)
      return middlewares.to_a if middlewares.respond_to?(:to_a)

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
      condition.call(probe_env, 200, probe_headers, StreamingBodyProbe.new)
      false
    rescue StreamingBodyProbe::BodyIteratedError
      true
    rescue StandardError
      false
    end

    def probe_env
      {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/__react_on_rails_pro_stream_probe__",
        "HTTP_ACCEPT_ENCODING" => "gzip,identity",
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

    class StreamingBodyProbe
      class BodyIteratedError < StandardError; end

      def each
        raise BodyIteratedError, "Compression middleware `:if` callback called `body.each` on a streaming body."
      end
    end
  end
end
