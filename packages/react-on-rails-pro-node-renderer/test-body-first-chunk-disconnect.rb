#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Test: body: "<first_chunk>" pattern with worker.disconnect()
#
# This tests the exact scenario:
# 1. First chunk in body: argument (sent immediately)
# 2. Server receives first chunk, triggers worker.disconnect()
# 3. Client sends more chunks via request << while reading response
#

require "httpx"
require "json"

puts "=" * 80
puts "[TEST] Body First Chunk + worker.disconnect() + request <<"
puts "=" * 80
puts ""

HTTPX::Plugins.load_plugin(:stream_bidi)

URL = "https://localhost:9999"

connection = HTTPX
  .plugin(:stream_bidi)
  .with(
    origin: URL,
    fallback_protocol: "h2",
    persistent: true,
    ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    timeout: {
      connect_timeout: 10,
      read_timeout: 60
    }
  )

# First chunk - triggers disconnect on server
first_chunk = {
  requestId: 1,
  chunk: 1,
  data: "FIRST CHUNK - TRIGGERS DISCONNECT",
  triggerDisconnect: true,  # Server will call worker.disconnect() when it sees this
  timestamp: Time.now.to_f
}
first_chunk_ndjson = "#{first_chunk.to_json}\n"

puts "[TEST] First chunk (in body) will trigger worker.disconnect()"
puts "[TEST] First chunk: #{first_chunk.to_json[0..80]}..."

# Build request with FIRST CHUNK in body
request = connection.build_request(
  "POST",
  "/incremental-render",
  headers: { "content-type" => "application/x-ndjson" },
  body: first_chunk_ndjson,  # FIRST CHUNK triggers disconnect
  stream: true
)

puts ""
puts "[TEST] Starting request (first chunk sent immediately with request)..."
response = connection.request(request, stream: true)
puts "[TEST] Response status: #{response.status}"
puts "[TEST] >>> At this point, server has received first chunk and called worker.disconnect()"

# Background thread sends more chunks via request <<
puts ""
puts "[TEST] Background thread will now send additional chunks..."

background_error = nil
background_done = false

background_thread = Thread.new do
  begin
    (2..5).each do |chunk_num|
      sleep 0.15  # Small delay between chunks
      chunk = {
        requestId: 1,
        chunk: chunk_num,
        data: "async prop #{chunk_num}",
        timestamp: Time.now.to_f
      }
      puts "[TEST] [BG] Sending chunk #{chunk_num} via request <<"
      request << "#{chunk.to_json}\n"
    end
    puts "[TEST] [BG] All chunks sent, closing request..."
    request.close
    puts "[TEST] [BG] Request closed successfully"
  rescue => e
    background_error = e
    puts "[TEST] [BG] ERROR: #{e.class}: #{e.message}"
  ensure
    background_done = true
  end
end

# Main thread reads response
chunks_received = []
main_error = nil

begin
  response.each do |chunk|
    chunks_received << chunk
    puts "[TEST] [MAIN] Received response chunk #{chunks_received.size}"
  end
  puts "[TEST] [MAIN] Response stream ended normally"
rescue HTTPX::Connection::HTTP2::GoawayError => e
  main_error = e
  puts ""
  puts "[TEST] [MAIN] *** GOAWAY ERROR ***: #{e.message}"
rescue => e
  main_error = e
  puts ""
  puts "[TEST] [MAIN] *** ERROR ***: #{e.class}: #{e.message}"
end

background_thread.join

puts ""
puts "=" * 80
puts "[SUMMARY]"
puts "  Response chunks received: #{chunks_received.size}"
puts "  Background error: #{background_error&.class}: #{background_error&.message}" if background_error
puts "  Main thread error: #{main_error&.class}: #{main_error&.message}" if main_error
puts ""
if main_error&.message&.include?("protocol_error")
  puts "  >>> PROTOCOL_ERROR DETECTED! This is the bug we're looking for."
elsif main_error.is_a?(HTTPX::Connection::HTTP2::GoawayError)
  puts "  >>> GOAWAY ERROR DETECTED!"
elsif main_error || background_error
  puts "  >>> Some error occurred, but not protocol_error"
else
  puts "  >>> SUCCESS: No errors during worker.disconnect()"
end
puts "=" * 80
