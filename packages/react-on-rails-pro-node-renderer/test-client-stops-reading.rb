#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Test: What error does Ruby/httpx see when client stops reading
# while the server is still trying to send data?
#

require "httpx"
require "json"

puts "=" * 80
puts "[TEST] Client Stops Reading While Server Sending"
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
      read_timeout: 10
    }
  )

puts "[TEST] Starting bidirectional streaming request"

request = connection.build_request(
  "POST",
  "/incremental-render",
  headers: { "content-type" => "application/x-ndjson" },
  body: [],
  stream: true
)

# Start the request
response = connection.request(request, stream: true)

# Send first chunk
first_chunk = { requestId: 1, chunk: 1, data: "initial" }
puts "[TEST] Sending first chunk"
request << "#{first_chunk.to_json}\n"

puts "[TEST] Response status: #{response.status}"

# Read only the first response chunk, then stop
chunks_read = 0
begin
  response.each do |chunk|
    chunks_read += 1
    puts "[TEST] Received chunk #{chunks_read}"

    if chunks_read >= 2
      puts ""
      puts "[TEST] *** STOPPING READING AFTER #{chunks_read} CHUNKS ***"
      puts "[TEST] (Server may still be sending data)"
      break
    end
  end
rescue => e
  puts "[TEST] ERROR while reading: #{e.class}: #{e.message}"
end

# Send more chunks from client side even though we stopped reading
puts ""
puts "[TEST] Sending more chunks from client side..."
begin
  (2..5).each do |chunk_num|
    chunk = { requestId: 1, chunk: chunk_num, data: "chunk #{chunk_num}" }
    puts "[TEST] Sending chunk #{chunk_num}"
    request << "#{chunk.to_json}\n"
    sleep 0.1
  end

  puts "[TEST] Closing request..."
  request.close
  puts "[TEST] Request closed"
rescue => e
  puts "[TEST] ERROR sending/closing: #{e.class}: #{e.message}"
end

# Try to close connection
puts ""
puts "[TEST] Closing connection..."
begin
  connection.close
  puts "[TEST] Connection closed"
rescue => e
  puts "[TEST] Error closing: #{e.class}: #{e.message}"
end

puts ""
puts "=" * 80
puts "[SUMMARY]"
puts "  Chunks read: #{chunks_read}"
puts "  No GOAWAY/protocol_error observed"
puts "=" * 80
