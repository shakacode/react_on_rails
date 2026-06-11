# frozen_string_literal: true

# THROWAWAY REPRO for issue #3885 abort-path audit (report-only).
#
# Uses the REAL ReactOnRailsPro::RendererHttpClient (the gem's HTTP client to
# the node renderer) to start a streaming request, then stops the consuming
# Async task mid-stream — exactly what ReactOnRailsPro::Stream does via
# `@async_barrier.stop` when the browser disconnects from Rails
# (react_on_rails_pro/lib/react_on_rails_pro/concerns/stream.rb:109-124) and
# what StreamRequest#stop_tasks does on transport errors.
#
# Run h2-instrumented-server.cjs first, then this script; the server's /events
# endpoint tells us whether an RST_STREAM (CANCEL) reached the server.

require "async"

# renderer_http_client.rb is standalone except for a constant lookup that only
# triggers when pool_size is nil — we always pass pool_size, so stub the module.
module ReactOnRailsPro; end

require_relative "../../react_on_rails_pro/lib/react_on_rails_pro/renderer_http_client"

port = ARGV[0] || "3899"
origin = "http://127.0.0.1:#{port}"

client = ReactOnRailsPro::RendererHttpClient.new(
  origin: origin,
  pool_size: 1,
  connect_timeout: 5,
  read_timeout: 30
)

chunks_seen = 0
Sync do |task|
  response = client.post("/stream", json: { audit: true }, stream: true)

  consumer = task.async do
    response.each do |chunk|
      chunks_seen += 1
      puts "[ruby] received chunk #{chunks_seen}: #{chunk.strip.inspect}"
    end
    puts "[ruby] response fully consumed (should NOT happen in this repro)"
  rescue StandardError => e
    puts "[ruby] consumer raised: #{e.class}: #{e.message}"
  end

  # Let a few ticks arrive, then stop the task — same mechanism as
  # @async_barrier.stop on browser disconnect.
  task.sleep(0.45)
  puts "[ruby] stopping consumer task (simulating barrier.stop on client disconnect)"
  consumer.stop
  consumer.wait
  puts "[ruby] consumer stopped after #{chunks_seen} chunks"

  # Give the server a moment, then read back its event log.
  task.sleep(0.5)
  events_response = client.post("/events", json: {})
  puts "[server events] #{events_response.body}"
end
