#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Test: Can we use body: "<first_chunk>" AND request << for subsequent chunks?
# This pattern ensures the first chunk is sent immediately with the request.
#

require "httpx"
require "json"

puts "=" * 80
puts "[TEST] Body with First Chunk + request << for rest"
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

# First chunk data
first_chunk = { requestId: 1, chunk: 1, data: "FIRST CHUNK IN BODY", timestamp: Time.now.to_f }
first_chunk_ndjson = "#{first_chunk.to_json}\n"

puts "[TEST] Building request with body: '<first_chunk>'"
puts "[TEST] First chunk: #{first_chunk_ndjson.strip}"

# Build request with FIRST CHUNK in body (not empty [])
request = connection.build_request(
  "POST",
  "/incremental-render",
  headers: { "content-type" => "application/x-ndjson" },
  body: first_chunk_ndjson,  # FIRST CHUNK IN BODY
  stream: true
)

puts "[TEST] Starting request..."
response = connection.request(request, stream: true)
puts "[TEST] Response status: #{response.status}"

# Now try to send MORE chunks via request <<
puts ""
puts "[TEST] Attempting to send additional chunks via request <<"

background_error = nil
background_thread = Thread.new do
  begin
    (2..5).each do |chunk_num|
      sleep 0.2
      chunk = { requestId: 1, chunk: chunk_num, data: "async prop #{chunk_num}", timestamp: Time.now.to_f }
      puts "[TEST] [BG] Sending chunk #{chunk_num} via request <<"
      request << "#{chunk.to_json}\n"
    end
    puts "[TEST] [BG] Closing request..."
    request.close
    puts "[TEST] [BG] Request closed"
  rescue => e
    background_error = e
    puts "[TEST] [BG] ERROR: #{e.class}: #{e.message}"
    puts e.backtrace.first(3).join("\n")
  end
end

# Read response chunks
puts ""
chunks_received = []
begin
  response.each do |chunk|
    chunks_received << chunk
    puts "[TEST] [MAIN] Received chunk #{chunks_received.size}: #{chunk.strip[0..60]}..."
  end
rescue => e
  puts "[TEST] [MAIN] ERROR reading: #{e.class}: #{e.message}"
end

background_thread.join

puts ""
puts "=" * 80
puts "[SUMMARY]"
puts "  Response chunks received: #{chunks_received.size}"
puts "  Background error: #{background_error&.message || 'none'}"
if chunks_received.size >= 5
  puts "  SUCCESS: body: '<first_chunk>' + request << works!"
else
  puts "  FAILED: Could not send additional chunks after body"
end
puts "=" * 80
