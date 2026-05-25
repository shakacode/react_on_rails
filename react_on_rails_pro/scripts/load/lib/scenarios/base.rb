# frozen_string_literal: true

require_relative "../request_result"

module RendererHarness
  module Scenarios
    # Abstract base class for all load-test scenarios.
    # Subclasses must implement +perform_request+, which must return a +RequestResult+.
    class Base
      MIX_PROPS_SIZES = { "small" => 200, "medium" => 10_000, "large" => 100_000 }.freeze
      RENDER_COMPONENT_JS_TEMPLATE = <<~JS
        (function(){
          var props = %<props>s;
          return ReactOnRails.serverRenderReactComponent({
            name: 'HelloWorld',
            domNodeId: 'HelloWorld-react-component',
            props: props,
            trace: false,
            renderingReturnsPromises: false
          });
        })()
      JS

      attr_reader :config

      def initialize(config)
        @config = config
        @server_bundle_hash = nil
        @server_bundle_hash_mutex = Mutex.new
      end

      def name
        self.class.name.split("::").last.then do |s|
          s.gsub(/([A-Z])/) do
            "_#{Regexp.last_match(1).downcase}"
          end.sub(/^_/, "")
        end
      end

      def warmup(count)
        count.times { perform_request }
      end

      def perform_request
        raise NotImplementedError
      end

      def cleanup; end

      protected

      def filler_props
        size = MIX_PROPS_SIZES.fetch(config.mix)
        { "filler" => "x" * size }
      end

      def stream_status(stream)
        return stream.status if stream.respond_to?(:status)
        # Keep this fallback for stream-like test doubles or alternate transports
        # that expose an explicit http_status without using StreamDecorator.
        return stream.http_status if stream.respond_to?(:http_status)

        nil
      end

      def server_bundle_hash
        @server_bundle_hash_mutex.synchronize do
          @server_bundle_hash ||= ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool.server_bundle_hash
        end
      end

      def stream_payload(stream, bytes_in:, bytes_out:)
        status = stream_status(stream)
        {
          http_status: status,
          bytes_in: bytes_in,
          bytes_out: bytes_out,
          require_http_status: true
        }
      end

      def chunk_bytesize(chunk)
        return chunk.bytesize if chunk.respond_to?(:bytesize)
        return chunk["html"].to_s.bytesize if chunk.is_a?(Hash) && chunk.key?("html")
        if chunk.is_a?(Hash)
          return chunk.values.sum { |value| value.respond_to?(:bytesize) ? value.bytesize : value.to_s.bytesize }
        end

        chunk.to_s.bytesize
      end

      def measure
        start_ms = monotonic_ms
        # Keep an absolute wall-clock timestamp for CSV correlation while using
        # a monotonic clock for latency so NTP or system-clock changes do not skew timings.
        t_started_ms = (Time.now.to_f * 1000)
        begin
          payload = yield
          success_result(start_ms, t_started_ms, payload)
        rescue StandardError => e
          failure_result(start_ms, t_started_ms, e)
        end
      end

      def monotonic_ms
        Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000.0
      end

      private

      def success_result(start_ms, t_started_ms, payload)
        http_status = payload[:http_status]
        ok = payload.key?(:ok) ? payload[:ok] : payload_ok?(payload, http_status)
        error = payload[:error]
        error ||= payload_error_message(payload, http_status) unless ok
        RequestResult.new(
          latency_ms: monotonic_ms - start_ms,
          bytes_in: payload[:bytes_in] || 0,
          bytes_out: payload[:bytes_out] || 0,
          ok: ok,
          error: error,
          http_status: http_status,
          scenario: name,
          thread_id: Thread.current.object_id,
          t_started_ms: t_started_ms
        )
      end

      def failure_result(start_ms, t_started_ms, error)
        RequestResult.new(
          latency_ms: monotonic_ms - start_ms,
          bytes_in: 0,
          bytes_out: 0,
          ok: false,
          error: error.message,
          http_status: nil,
          scenario: name,
          thread_id: Thread.current.object_id,
          t_started_ms: t_started_ms
        )
      end

      def http_error_status?(status)
        status && status.to_i >= 400
      end

      def http_error_message(status)
        "Renderer returned #{status}" if http_error_status?(status)
      end

      def payload_ok?(payload, http_status)
        return false if payload[:require_http_status] && http_status.nil?

        !http_error_status?(http_status)
      end

      def payload_error_message(payload, http_status)
        return "Renderer stream status unavailable" if payload[:require_http_status] && http_status.nil?

        http_error_message(http_status)
      end
    end
  end
end
