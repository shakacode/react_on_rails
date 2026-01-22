#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Accurate simulation of React on Rails Pro bidirectional streaming pattern:
# 1. Create request with empty body []
# 2. Start request immediately - response begins streaming
# 3. Send first chunk via request <<
# 4. Background thread sends additional chunks via request <<
# 5. Main thread reads response while background sends
# 6. Background thread calls request.close when done
#

require "httpx"
require "json"

puts "=" * 80
puts "[CLIENT] TRUE Bidirectional Streaming Test (React on Rails Pro pattern)"
puts "=" * 80
puts ""

# Load stream_bidi plugin (required for bidirectional streaming)
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
  puts ""
  puts "[REQ #{request_id}] Starting bidirectional streaming request"

  # Build request with EMPTY body - just like React on Rails Pro
  request = connection.build_request(
    "POST",
    "/incremental-render",
    headers: { "content-type" => "application/x-ndjson" },
    body: [],  # EMPTY - we'll send data via request <<
    stream: true
  )

  # Start the request - response begins streaming IMMEDIATELY
  puts "[REQ #{request_id}] Starting request (response will stream back)"
  response = connection.request(request, stream: true)

  # Send the FIRST chunk immediately (like the initial render request)
  first_chunk = { requestId: request_id, chunk: 1, data: "initial render request", timestamp: Time.now.to_f }
  puts "[REQ #{request_id}] Sending first chunk (initial render request)"
  request << "#{first_chunk.to_json}\n"

  # Track errors from background thread
  background_error = nil
  background_done = false

  # Background thread sends additional chunks (like async props emitter)
  background_thread = Thread.new do
    begin
      (2..chunk_count).each do |chunk_num|
        sleep 0.3  # Simulate async prop resolution delay

        chunk = {
          requestId: request_id,
          chunk: chunk_num,
          data: "async prop #{chunk_num}",
          timestamp: Time.now.to_f
        }

        # Check if this chunk should trigger disconnect
        if trigger_disconnect_on_chunk == chunk_num
          chunk[:triggerDisconnect] = true
          puts "[REQ #{request_id}] [BG] Chunk #{chunk_num} will TRIGGER DISCONNECT"
        end

        puts "[REQ #{request_id}] [BG] Sending chunk #{chunk_num}"
        request << "#{chunk.to_json}\n"
      end

      puts "[REQ #{request_id}] [BG] All chunks sent, closing request"
      request.close  # Send END_STREAM flag
    rescue => e
      background_error = e
      puts "[REQ #{request_id}] [BG] ERROR: #{e.class}: #{e.message}"
    ensure
      background_done = true
    end
  end

  # Main thread reads response while background sends
  puts "[REQ #{request_id}] Response status: #{response.status}"
  response_chunks = []

  begin
    response.each do |chunk|
      response_chunks << chunk
      puts "[REQ #{request_id}] [MAIN] Received response chunk #{response_chunks.size}: #{chunk.strip[0..50]}..."
    end
  rescue => e
    puts "[REQ #{request_id}] [MAIN] ERROR reading response: #{e.class}: #{e.message}"
    raise
  end

  # Wait for background thread
  background_thread.join

  if background_error
    puts "[REQ #{request_id}] Background thread had error: #{background_error.message}"
  end

  puts "[REQ #{request_id}] ✓ Completed with #{response_chunks.size} response chunks"
  { request_id: request_id, status: :success, chunks: response_chunks.size }

rescue HTTPX::Connection::HTTP2::GoawayError => e
  puts ""
  puts "[REQ #{request_id}] *** GOAWAY ERROR ***"
  puts "[REQ #{request_id}] #{e.message}"
  { request_id: request_id, status: :goaway_error, error: e.message }

rescue HTTP2::Error => e
  puts ""
  puts "[REQ #{request_id}] *** HTTP/2 ERROR ***"
  puts "[REQ #{request_id}] #{e.class}: #{e.message}"
  { request_id: request_id, status: :http2_error, error: e.message }

rescue => e
  puts ""
  puts "[REQ #{request_id}] *** ERROR ***"
  puts "[REQ #{request_id}] #{e.class}: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  { request_id: request_id, status: :error, error: e.message }
end

# Run test with multiple concurrent bidirectional requests
def run_test(request_count:, chunks_per_request:, disconnect_on_request:, disconnect_on_chunk:)
  puts ""
  puts "=" * 80
  puts "[TEST] #{request_count} concurrent bidi requests"
  puts "[TEST] Each sends #{chunks_per_request} chunks"
  puts "[TEST] Request #{disconnect_on_request} triggers disconnect on chunk #{disconnect_on_chunk}"
  puts "=" * 80

  connection = create_connection
  results = []
  threads = []

  request_count.times do |i|
    request_id = i + 1
    trigger = (request_id == disconnect_on_request) ? disconnect_on_chunk : nil

    threads << Thread.new do
      sleep(0.05 * i)  # Stagger starts slightly
      run_bidi_request(connection, request_id, chunks_per_request, trigger_disconnect_on_chunk: trigger)
    end
  end

  threads.each { |t| results << t.value }

  puts ""
  puts "=" * 80
  puts "[RESULTS]"
  results.each do |r|
    status = r[:status] == :success ? "✓" : "✗"
    error = r[:error] ? " - #{r[:error]}" : ""
    puts "  #{status} Request #{r[:request_id]}: #{r[:status]}#{error}"
  end

  goaway_errors = results.select { |r| r[:status] == :goaway_error }
  http2_errors = results.select { |r| r[:status] == :http2_error }
  other_errors = results.select { |r| ![:success, :goaway_error, :http2_error].include?(r[:status]) }

  puts ""
  puts "[SUMMARY]"
  puts "  Success: #{results.count { |r| r[:status] == :success }}"
  puts "  GOAWAY errors: #{goaway_errors.size}"
  puts "  HTTP/2 errors: #{http2_errors.size}"
  puts "  Other errors: #{other_errors.size}"
  puts "=" * 80

  results
end

# Test 1: Single request that triggers disconnect
puts "\n#{'#' * 80}"
puts "# TEST 1: Single request, disconnect on chunk 2"
puts "#{'#' * 80}"
run_test(
  request_count: 1,
  chunks_per_request: 5,
  disconnect_on_request: 1,
  disconnect_on_chunk: 2
)

sleep 2

# Test 2: Multiple concurrent requests, one triggers disconnect
puts "\n#{'#' * 80}"
puts "# TEST 2: 3 concurrent requests, request 2 triggers disconnect on chunk 2"
puts "#{'#' * 80}"

# Restart connection since server worker was disconnected
puts "[CLIENT] Creating fresh connection for test 2..."
begin
  run_test(
    request_count: 3,
    chunks_per_request: 5,
    disconnect_on_request: 2,
    disconnect_on_chunk: 2
  )
rescue => e
  puts "[CLIENT] Test 2 failed: #{e.message}"
end

puts ""
puts "[CLIENT] Done"
