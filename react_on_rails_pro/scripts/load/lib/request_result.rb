# frozen_string_literal: true

module RendererHarness
  RequestResult = Struct.new(
    :latency_ms,
    :bytes_in,
    :bytes_out,
    :ok,
    :error,
    :http_status,
    :scenario,
    :thread_id,
    :t_started_ms,
    keyword_init: true
  )
end
