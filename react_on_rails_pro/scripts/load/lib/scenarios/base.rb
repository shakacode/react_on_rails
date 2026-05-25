# frozen_string_literal: true

require "json"
require "active_support/inflector"
require_relative "../request_result"

module RendererHarness
  module Scenarios
    # Abstract base class for all load-test scenarios.
    # Subclasses must implement +perform_request+, which must return a +RequestResult+.
    class Base
      LENGTH_PREFIX_HEX_WIDTH = 8
      MIX_PROPS_SIZES = { "small" => 200, "medium" => 10_000, "large" => 100_000 }.freeze
      RENDER_COMPONENT_JS_TEMPLATE = <<~JS
        (function(){
          var props = __PROPS__;
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
      end

      def name
        @name ||= ActiveSupport::Inflector.underscore(self.class.name.split("::").last).freeze
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

      def server_bundle_hash
        ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool.server_bundle_hash
      end

      def render_component_js
        props_json = filler_props.to_json
        RENDER_COMPONENT_JS_TEMPLATE.sub("__PROPS__") { props_json }
      end

      def stream_payload(stream, bytes_in:, bytes_out:, status: stream.http_status)
        ok = !status.nil? && !http_error_status?(status)
        {
          http_status: status,
          ok: ok,
          error: ok ? nil : stream_error_message(status),
          bytes_in: bytes_in,
          bytes_out: bytes_out
        }
      end

      def chunk_bytesize(chunk)
        return chunk.bytesize if chunk.respond_to?(:bytesize)
        return length_prefixed_chunk_bytesize(chunk) if chunk.is_a?(Hash) && chunk.key?("html")
        return JSON.generate(chunk).bytesize if chunk.is_a?(Hash)

        chunk.to_s.bytesize
      end

      def measure
        start_ms = monotonic_ms
        # Keep an absolute wall-clock timestamp for CSV correlation while using
        # a monotonic clock for latency so NTP or system-clock changes do not skew timings.
        t_started_ms = (Time.now.to_f * 1000)
        begin
          payload = yield
          payload_result(start_ms, t_started_ms, payload)
        rescue StandardError => e
          failure_result(start_ms, t_started_ms, e)
        end
      end

      def monotonic_ms
        Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000.0
      end

      private

      def length_prefixed_chunk_bytesize(chunk)
        html = chunk.fetch("html")
        metadata = chunk.except("html")
        payload_type = metadata.fetch("payloadType") { html.is_a?(String) ? "string" : "object" }
        metadata = metadata.merge("payloadType" => payload_type)
        html_body = payload_type == "object" ? JSON.generate(html) : html.to_s

        # Wire layout: <metadata JSON> \t <8-char hex content length> \n <html bytes>.
        JSON.generate(metadata).bytesize + 1 + LENGTH_PREFIX_HEX_WIDTH + 1 + html_body.bytesize
      end

      def payload_result(start_ms, t_started_ms, payload)
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

      def payload_ok?(_payload, http_status)
        !http_error_status?(http_status)
      end

      def payload_error_message(_payload, http_status)
        http_error_message(http_status)
      end

      def stream_error_message(status)
        return "Renderer stream status unavailable" if status.nil?

        http_error_message(status)
      end
    end
  end
end
