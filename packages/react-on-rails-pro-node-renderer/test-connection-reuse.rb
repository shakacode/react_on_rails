#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Test: Can we reproduce "stream 0 closed with error: protocol_error"
# by trying to reuse a connection after the server worker exits?
#

require "httpx"
require "json"

puts "=" * 80
puts "[TEST] Connection Reuse After Worker Exit"
puts "=" * 80
puts ""

HTTPX::Plugins.load_plugin(:stream_bidi)

URL = "https://localhost:9999"

def create_connection
  HTTPX
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
end

def run_bidi_request(connection, request_id, chunk_count, trigger_disconnect_on_chunk: nil)
  puts "[REQ #{request_id}] Starting bidirectional streaming request"

  request = connection.build_request(
    "POST",
    "/incremental-render",
    headers: { "content-type" => "application/x-ndjson" },
    body: [],
    stream: true
  )

  response = connection.request(request, stream: true)

  first_chunk = { requestId: request_id, chunk: 1, data: "initial" }
  request << "#{first_chunk.to_json}\n"

  background_thread = Thread.new do
    begin
      (2..chunk_count).each do |chunk_num|
        sleep 0.1

        chunk = {
          requestId: request_id,
          chunk: chunk_num,
          data: "async prop #{chunk_num}"
        }

        if trigger_disconnect_on_chunk == chunk_num
          chunk[:triggerDisconnect] = true
        end

        request << "#{chunk.to_json}\n"
      end
      request.close
    rescue => e
      puts "[REQ #{request_id}] [BG] ERROR: #{e.class}: #{e.message}"
    end
  end

  puts "[REQ #{request_id}] Response status: #{response.status}"
  response_chunks = []

  begin
    response.each do |chunk|
      response_chunks << chunk
      puts "[REQ #{request_id}] Received chunk #{response_chunks.size}"
    end
  rescue => e
    puts "[REQ #{request_id}] ERROR reading: #{e.class}: #{e.message}"
  end

  background_thread.join
  puts "[REQ #{request_id}] Completed with #{response_chunks.size} chunks"
  { request_id: request_id, status: :success, chunks: response_chunks.size }

rescue HTTPX::Connection::HTTP2::GoawayError => e
  puts "[REQ #{request_id}] *** GOAWAY ERROR ***: #{e.message}"
  { request_id: request_id, status: :goaway_error, error: e.message }

rescue => e
  puts "[REQ #{request_id}] *** ERROR ***: #{e.class}: #{e.message}"
  { request_id: request_id, status: :error, error: e.message }
end

# Create connection (will be reused)
connection = create_connection

# First request - trigger disconnect but complete successfully
puts ""
puts "[TEST] Request 1: Trigger worker.disconnect() on chunk 2"
result1 = run_bidi_request(connection, 1, 3, trigger_disconnect_on_chunk: 2)
puts "[TEST] Result: #{result1[:status]}"

# Close the connection to allow worker to exit
puts ""
puts "[TEST] Closing connection to allow worker to exit..."
begin
  connection.close
  puts "[TEST] Connection closed"
rescue => e
  puts "[TEST] Error closing connection: #{e.message}"
end

puts "[TEST] Waiting 3 seconds for worker to fully exit..."
sleep 3

# Second request - must create new connection since we closed the old one
puts "[TEST] Creating NEW connection for request 2..."
connection = create_connection

# Second request - try to connect to potentially dead worker
# This should either:
# a) Get connection refused (new connection)
# b) Get GOAWAY error (reused dead connection)
# c) Work (if server spawned new worker)
puts ""
puts "[TEST] Request 2: Attempting to REUSE connection"
result2 = run_bidi_request(connection, 2, 3)
puts "[TEST] Result: #{result2[:status]}"

puts ""
puts "=" * 80
puts "[SUMMARY]"
puts "  Request 1: #{result1[:status]}"
puts "  Request 2: #{result2[:status]}"
if result2[:status] == :goaway_error
  puts "  >>> GOAWAY ERROR DETECTED - This might be the source of protocol_error!"
end
puts "=" * 80
