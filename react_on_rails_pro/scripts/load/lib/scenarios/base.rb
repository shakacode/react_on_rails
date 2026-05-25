# frozen_string_literal: true

require "request_result"

module RendererHarness
  module Scenarios
    # Abstract base class for all load-test scenarios.
    # Subclasses must implement +perform_request+, which must return a +RequestResult+.
    class Base
      MIX_PROPS_SIZES = { "small" => 200, "medium" => 10_000, "large" => 100_000 }.freeze

      attr_reader :config

      def initialize(config)
        @config = config
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
        return stream.http_status if stream.respond_to?(:http_status)

        nil
      end

      def measure
        start_ms = monotonic_ms
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
        ok = payload.key?(:ok) ? payload[:ok] : !http_error_status?(http_status)
        error = payload[:error]
        error ||= http_error_message(http_status) unless ok
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
    end
  end
end
