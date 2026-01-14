# frozen_string_literal: true

#
# Reproduction attempt: Server sends response AFTER client END_STREAM
#
# Hypothesis: The bug occurs when the server delays sending response
# until AFTER receiving END_STREAM from the client. In this case,
# httpx's stream_bidi might not correctly wait for the response.
#
# This simulates what happens in the Node renderer when:
# 1. Client sends all data very fast (no sleep)
# 2. Server receives END_STREAM before starting to send response
# 3. Server then sends response
#
# Run: bundle exec ruby stream_bidi_late_response_demo.rb
#

require "bundler/setup"
require "httpx"
require "json"
require "socket"
require "http/2"
require "async"
require "async/barrier"

puts "=" * 70
puts "Late Response Server Demo"
puts "=" * 70
puts
puts "Testing if httpx handles response sent AFTER client END_STREAM"
puts

#
# Server that waits for END_STREAM before sending ANY response
#
class LateResponseServer
  attr_reader :port, :received_chunks

  def initialize(delay_headers:, delay_body:)
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @received_chunks = []
    @delay_headers = delay_headers  # Delay sending response headers
    @delay_body = delay_body        # Delay sending response body
    @clients = []
    @connections = {}
    @running = true
  end

  def origin
    "http://127.0.0.1:#{@port}"
  end

  def start
    Thread.new { run }
    sleep 0.1
  end

  def stop
    @running = false
    @server.close rescue nil
    @clients.each { |c| c.close rescue nil }
  end

  private

  def run
    while @running
      readable, = IO.select([@server, *@clients], nil, nil, 0.1)
      next unless readable

      readable.each do |io|
        io == @server ? accept_client : read_client(io)
      end
    end
  rescue IOError, Errno::EBADF
  end

  def accept_client
    client = @server.accept_nonblock(exception: false)
    return if client == :wait_readable

    @clients << client
    conn = HTTP2::Server.new
    setup_connection(conn, client)
    @connections[client] = conn
  rescue StandardError => e
    puts "  [Server] Accept error: #{e}"
  end

  def read_client(client)
    data = client.read_nonblock(16384, exception: false)
    case data
    when :wait_readable then return
    when nil then close_client(client)
    else @connections[client] << data
    end
  rescue StandardError
    close_client(client)
  end

  def setup_connection(conn, client)
    conn.on(:frame) do |bytes|
      client.write(bytes)
      client.flush
    end
    conn.on(:goaway) { close_client(client) }
    conn.on(:stream) { |stream| setup_stream(stream) }
  end

  def setup_stream(stream)
    received_data = []
    headers_received = false
    end_stream_received = false

    stream.on(:headers) do |headers|
      headers_received = true
      puts "  [Server] Received request headers"

      unless @delay_headers
        # Send response headers immediately (normal behavior)
        stream.headers({ ":status" => "200", "content-type" => "application/x-ndjson" }, end_stream: false)
        puts "  [Server] Sent response headers immediately"
      end
    end

    stream.on(:data) do |chunk|
      puts "  [Server] Received #{chunk.bytesize} bytes of data"
      received_data << chunk
      @received_chunks << chunk
    end

    stream.on(:half_close) do
      end_stream_received = true
      puts "  [Server] Received END_STREAM from client"
      puts "  [Server] Total data received: #{received_data.join.bytesize} bytes"

      # Now that we've received END_STREAM, send our response
      Thread.new do
        if @delay_headers
          # Delay sending headers until after END_STREAM
          puts "  [Server] Sending DELAYED response headers..."
          stream.headers({ ":status" => "200", "content-type" => "application/x-ndjson" }, end_stream: false)
        end

        if @delay_body
          # Small delay to simulate async processing
          sleep 0.01
        end

        # Send response body
        puts "  [Server] Sending response body..."
        3.times do |i|
          chunk = JSON.generate({ html: "<div>Response #{i + 1}</div>", seq: i + 1 })
          stream.data("#{chunk}\n", end_stream: false)
          puts "  [Server] Sent chunk #{i + 1}"
        end

        # Send END_STREAM
        final = JSON.generate({ complete: true, received: received_data.size })
        stream.data("#{final}\n", end_stream: true)
        puts "  [Server] Sent END_STREAM"
      end
    end
  end

  def close_client(client)
    client.close rescue nil
    @clients.delete(client)
    @connections.delete(client)
  end
end

def test_client(server, use_sleep:)
  chunks = []

  Sync do
    barrier = Async::Barrier.new

    session = HTTPX
      .plugin(:stream_bidi)
      .with(
        origin: server.origin,
        fallback_protocol: "h2",
        timeout: { connect_timeout: 5, read_timeout: 5 }
      )

    request = session.build_request(
      "POST", "/test",
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    response = session.request(request, stream: true)
    request << JSON.generate({ type: "initial" }) + "\n"

    barrier.async do
      sleep 0.02 if use_sleep

      3.times do |i|
        request << JSON.generate({ type: "update", i: i }) + "\n"
      end
      request.close
    end

    puts "  [Client] Starting response iteration..."
    response.each do |chunk|
      puts "  [Client] Got chunk: #{chunk.strip[0..50]}..."
      chunks << chunk
    end
    puts "  [Client] Response iteration complete"

    barrier.wait
    session.close
  end

  chunks
end

def run_test(label, delay_headers:, delay_body:)
  puts
  puts "=" * 70
  puts "TEST: #{label}"
  puts "  delay_headers=#{delay_headers}, delay_body=#{delay_body}"
  puts "=" * 70

  # Test without sleep
  puts "\n--- Without client sleep ---"
  server1 = LateResponseServer.new(delay_headers: delay_headers, delay_body: delay_body)
  server1.start
  chunks_no_sleep = test_client(server1, use_sleep: false)
  server1.stop
  puts "  Result: #{chunks_no_sleep.size} chunks"

  sleep 0.2

  # Test with sleep
  puts "\n--- With client sleep ---"
  server2 = LateResponseServer.new(delay_headers: delay_headers, delay_body: delay_body)
  server2.start
  chunks_with_sleep = test_client(server2, use_sleep: true)
  server2.stop
  puts "  Result: #{chunks_with_sleep.size} chunks"

  [chunks_no_sleep.size, chunks_with_sleep.size]
end

results = {}

# Test 1: Normal behavior (headers sent immediately)
results["Normal"] = run_test("Normal (headers immediate)", delay_headers: false, delay_body: false)

# Test 2: Delayed headers (sent after END_STREAM)
results["Delayed Headers"] = run_test("Delayed headers (after END_STREAM)", delay_headers: true, delay_body: false)

# Test 3: Delayed body
results["Delayed Body"] = run_test("Delayed body", delay_headers: false, delay_body: true)

# Test 4: Both delayed
results["Both Delayed"] = run_test("Both delayed", delay_headers: true, delay_body: true)

# Summary
puts
puts "=" * 70
puts "SUMMARY"
puts "=" * 70
puts "#{"Scenario".ljust(25)} | No Sleep | With Sleep | Bug?"
puts "-" * 60

bug_found = false
results.each do |name, (no_sleep, with_sleep)|
  is_bug = no_sleep < with_sleep || no_sleep == 0
  bug_found ||= is_bug
  status = is_bug ? "*** BUG ***" : "OK"
  puts "#{name.ljust(25)} | #{no_sleep.to_s.rjust(8)} | #{with_sleep.to_s.rjust(10)} | #{status}"
end

puts
if bug_found
  puts "BUG REPRODUCED! The issue is related to response timing."
  exit 1
else
  puts "No bug detected with these server configurations."
  exit 0
end
