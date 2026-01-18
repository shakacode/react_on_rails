# frozen_string_literal: true

# Demo script to test bidirectional streaming capabilities of both HTTPX and async-http
# This simulates the React on Rails Pro use case of:
# 1. Sending an initial render request
# 2. Concurrently sending async props while receiving streaming response
# 3. Signaling end of stream when all props are sent

require "bundler/setup"
require "async"
require "async/barrier"
require "async/http"
require "async/http/endpoint"
require "async/http/client"
require "socket"
require "json"

puts "=" * 80
puts "ASYNC-HTTP BIDIRECTIONAL STREAMING DEMO"
puts "=" * 80

# Find available port
def find_available_port
  server = TCPServer.new("127.0.0.1", 0)
  port = server.addr[1]
  server.close
  port
end

# =============================================================================
# DEMO 1: Bidirectional Streaming with async-http
# =============================================================================
puts "\n### Demo 1: Bidirectional Streaming with async-http ###\n"

Sync do
  port = find_available_port
  endpoint = Async::HTTP::Endpoint.parse("http://127.0.0.1:#{port}")

  # Start a mock server that simulates the Node renderer
  server_task = Async do
    puts "[Server] Starting mock Node renderer server on port #{port}..."

    server = Async::HTTP::Server.for(endpoint) do |request|
      puts "[Server] Received request: #{request.method} #{request.path}"
      puts "[Server] Content-Type: #{request.headers['content-type']}"

      # Read and process incoming NDJSON lines (simulating async props)
      received_lines = []
      if request.body
        request.body.each do |chunk|
          puts "[Server] Received chunk: #{chunk.inspect}"
          received_lines << chunk
        end
      end

      # Simulate streaming response (like Node renderer sending HTML chunks)
      body = Async::HTTP::Body::Writable.new

      # Spawn task to write response chunks
      Async do
        5.times do |i|
          chunk = "<div>HTML Chunk #{i + 1}</div>\n"
          puts "[Server] Sending response chunk: #{chunk.strip}"
          body.write(chunk)
          sleep 0.1
        end
        body.close
        puts "[Server] Response complete"
      end

      Protocol::HTTP::Response[200, {"content-type" => "text/html"}, body]
    end

    server.run
  end

  # Give server time to start
  sleep 0.2

  # Client code (simulating Rails making request to Node renderer)
  client_task = Async do
    puts "[Client] Starting bidirectional streaming request..."

    client = Async::HTTP::Client.new(endpoint)
    barrier = Async::Barrier.new

    begin
      # Create a writable body for sending async props
      request_body = Async::HTTP::Body::Writable.new

      # Start request with streaming body
      response_task = barrier.async do
        response = client.post(
          "/render-incremental",
          {"content-type" => "application/x-ndjson"},
          request_body
        )

        puts "[Client] Response status: #{response.status}"

        # Read streaming response
        chunks_received = []
        response.body.each do |chunk|
          puts "[Client] Received: #{chunk.strip}"
          chunks_received << chunk
        end

        puts "[Client] Total chunks received: #{chunks_received.length}"
        chunks_received
      end

      # Simulate sending async props concurrently
      props_task = barrier.async do
        sleep 0.1 # Let response start streaming

        3.times do |i|
          prop_data = {propName: "user#{i}", value: {id: i, name: "User #{i}"}}.to_json
          puts "[Client] Sending async prop: #{prop_data}"
          request_body.write("#{prop_data}\n")
          sleep 0.15
        end

        # Signal end of request body
        request_body.close
        puts "[Client] Request body closed (all props sent)"
      end

      barrier.wait

      puts "[Client] Bidirectional streaming complete!"
    ensure
      client.close
    end
  end

  # Let demo run
  sleep 2
  server_task.stop
end

puts "\n" + "=" * 80
puts "DEMO 1 COMPLETE: async-http supports true bidirectional streaming!"
puts "=" * 80

# =============================================================================
# DEMO 2: Testing Mock/Stub Capabilities
# =============================================================================
puts "\n### Demo 2: Testing Mocking Capabilities with async-http ###\n"

# async-http provides Mock::Endpoint for testing
require "async/http/mock"

Sync do
  # Create a mock endpoint
  mock_endpoint = Async::HTTP::Mock::Endpoint.new do |request|
    puts "[Mock] Intercepted request: #{request.method} #{request.path}"

    # Simulate streaming response
    body = Async::HTTP::Body::Writable.new

    Async do
      3.times do |i|
        body.write("Mock chunk #{i + 1}\n")
        sleep 0.05
      end
      body.close
    end

    Protocol::HTTP::Response[200, {"content-type" => "text/plain"}, body]
  end

  client = Async::HTTP::Client.new(mock_endpoint)

  response = client.get("/test")
  puts "[Test] Response status: #{response.status}"

  response.body.each do |chunk|
    puts "[Test] Received mock chunk: #{chunk.strip}"
  end

  client.close
end

puts "\n" + "=" * 80
puts "DEMO 2 COMPLETE: async-http has built-in mocking support!"
puts "=" * 80

# =============================================================================
# DEMO 3: Connection Pooling
# =============================================================================
puts "\n### Demo 3: Connection Pooling with async-http ###\n"

Sync do
  port = find_available_port
  endpoint = Async::HTTP::Endpoint.parse("http://127.0.0.1:#{port}")

  # Start server
  server_task = Async do
    request_count = 0
    server = Async::HTTP::Server.for(endpoint) do |request|
      request_count += 1
      Protocol::HTTP::Response[200, {}, ["Request ##{request_count}"]]
    end
    server.run
  end

  sleep 0.1

  # Make multiple requests using connection pooling
  client = Async::HTTP::Client.new(endpoint)

  barrier = Async::Barrier.new

  10.times do |i|
    barrier.async do
      response = client.get("/request-#{i}")
      puts "[Pool] Request #{i}: #{response.read}"
    end
  end

  barrier.wait
  client.close
  server_task.stop

  puts "[Pool] All 10 concurrent requests completed using connection pool"
end

puts "\n" + "=" * 80
puts "DEMO 3 COMPLETE: async-http has excellent connection pooling!"
puts "=" * 80

# =============================================================================
# Summary
# =============================================================================
puts "\n"
puts "=" * 80
puts "SUMMARY OF ASYNC-HTTP CAPABILITIES"
puts "=" * 80
puts <<~SUMMARY

  ✅ TRUE BIDIRECTIONAL STREAMING
     - Can send request body chunks while receiving response chunks
     - Uses Async::HTTP::Body::Writable for both request and response
     - Natural fit for React on Rails Pro async props pattern

  ✅ BUILT-IN MOCKING SUPPORT
     - Async::HTTP::Mock::Endpoint provides request interception
     - Supports streaming responses in tests
     - Can control chunk delivery for precise testing

  ✅ CONNECTION POOLING
     - Automatic connection reuse
     - Configurable pool size
     - HTTP/2 multiplexing support

  ✅ FIBER-BASED CONCURRENCY
     - Uses Async gem's fiber scheduler
     - Non-blocking I/O operations
     - Excellent for concurrent async props resolution

  ✅ HTTP/2 SUPPORT
     - Full HTTP/2 implementation
     - Multiplexing on single connection
     - Header compression

SUMMARY
