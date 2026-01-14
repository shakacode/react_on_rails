# frozen_string_literal: true

#
# Minimal reproduction of stream_bidi race condition bug
#
# This demonstrates that when using httpx's stream_bidi plugin:
# - WITH sleep before request.close: response chunks are received
# - WITHOUT sleep before request.close: response chunks are LOST
#
# Run: bundle exec ruby stream_bidi_race_condition_demo.rb
#
# Expected output shows the bug:
#   WITHOUT sleep: Received 0 response chunks (BUG!)
#   WITH sleep:    Received N response chunks (works)
#

require "bundler/setup"
require "httpx"
require "json"
require "socket"
require "http/2"

puts "=" * 70
puts "HTTPX stream_bidi Race Condition Demo"
puts "=" * 70
puts

#
# Simple HTTP/2 server that echoes back received data as response chunks
#
class SimpleHTTP2Server
  attr_reader :port, :received_lines

  def initialize
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @received_lines = []
    @clients = []
    @connections = {}
    @running = true
  end

  def origin
    "http://127.0.0.1:#{@port}"
  end

  def start
    Thread.new { run }
    sleep 0.1 # Let server start
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
        if io == @server
          accept_client
        else
          read_client(io)
        end
      end
    end
  rescue IOError, Errno::EBADF
    # Server closed
  end

  def accept_client
    client = @server.accept_nonblock(exception: false)
    return if client == :wait_readable

    @clients << client
    conn = HTTP2::Server.new
    setup_connection(conn, client)
    @connections[client] = conn
  rescue StandardError => e
    puts "Accept error: #{e}"
  end

  def read_client(client)
    data = client.read_nonblock(16384, exception: false)
    case data
    when :wait_readable then return
    when nil then close_client(client)
    else @connections[client] << data
    end
  rescue StandardError => e
    puts "Read error: #{e}"
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
    request_body = +""
    headers_sent = false

    stream.on(:headers) do |_headers|
      # Send response headers immediately
      stream.headers({
        ":status" => "200",
        "content-type" => "application/x-ndjson"
      }, end_stream: false)
      headers_sent = true
    end

    stream.on(:data) do |chunk|
      request_body << chunk

      # Process complete lines
      while (idx = request_body.index("\n"))
        line = request_body.slice!(0, idx + 1).strip
        next if line.empty?

        @received_lines << line

        # Echo back each line as a response chunk
        response = JSON.generate({ echo: line, seq: @received_lines.size })
        stream.data("#{response}\n", end_stream: false)
      end
    end

    stream.on(:half_close) do
      # Client sent END_STREAM, send our END_STREAM
      # But first, send a final confirmation
      final = JSON.generate({ status: "complete", total: @received_lines.size })
      stream.data("#{final}\n", end_stream: true)
    end
  end

  def close_client(client)
    client.close rescue nil
    @clients.delete(client)
    @connections.delete(client)
  end
end

#
# Test function that demonstrates the race condition
#
def test_stream_bidi(server, use_sleep:)
  response_chunks = []

  session = HTTPX
    .plugin(:stream_bidi)
    .with(
      origin: server.origin,
      fallback_protocol: "h2",
      timeout: { connect_timeout: 5, read_timeout: 5 }
    )

  # Build a streaming request
  request = session.build_request(
    "POST",
    "/test",
    headers: { "content-type" => "application/x-ndjson" },
    body: [],
    stream: true
  )

  # Get the StreamResponse (HTTP request not sent yet!)
  response = session.request(request, stream: true)

  # Buffer the initial data
  request << JSON.generate({ type: "initial", data: "hello" }) + "\n"

  # Simulate sending more data from a separate thread (like barrier.async)
  sender = Thread.new do
    # This is key: with sleep, the HTTP connection has time to establish
    # Without sleep, we close the request before response reading starts
    sleep 0.05 if use_sleep

    3.times do |i|
      request << JSON.generate({ type: "update", index: i }) + "\n"
    end

    # Close the request (sends END_STREAM)
    request.close
  end

  # Now iterate over response - this triggers the actual HTTP request
  # The bug: if sender thread closes request too fast, response.each yields nothing
  response.each do |chunk|
    response_chunks << chunk
  end

  sender.join
  session.close

  response_chunks
end

# Run the tests
puts "Starting HTTP/2 server..."
server1 = SimpleHTTP2Server.new
server1.start

puts "Test 1: WITHOUT sleep (demonstrates the bug)"
puts "-" * 50
chunks_no_sleep = test_stream_bidi(server1, use_sleep: false)
puts "  Server received #{server1.received_lines.size} lines"
puts "  Client received #{chunks_no_sleep.size} response chunks"
chunks_no_sleep.each { |c| puts "    #{c.strip[0..60]}..." }
server1.stop

sleep 0.2

puts
puts "Test 2: WITH sleep (works correctly)"
puts "-" * 50
server2 = SimpleHTTP2Server.new
server2.start
chunks_with_sleep = test_stream_bidi(server2, use_sleep: true)
puts "  Server received #{server2.received_lines.size} lines"
puts "  Client received #{chunks_with_sleep.size} response chunks"
chunks_with_sleep.each { |c| puts "    #{c.strip[0..60]}..." }
server2.stop

# Summary
puts
puts "=" * 70
puts "RESULTS"
puts "=" * 70
puts "WITHOUT sleep: Server got #{server1.received_lines.size} lines, Client got #{chunks_no_sleep.size} chunks"
puts "WITH sleep:    Server got #{server2.received_lines.size} lines, Client got #{chunks_with_sleep.size} chunks"
puts

if chunks_no_sleep.size < chunks_with_sleep.size && chunks_no_sleep.empty?
  puts "*** BUG CONFIRMED: Response chunks lost when request.close is called"
  puts "*** before response iteration begins!"
  puts
  puts "Root cause: httpx stream_bidi doesn't properly wait for response"
  puts "when the request is closed during connection setup."
  exit 1
elsif chunks_no_sleep.size == chunks_with_sleep.size
  puts "No bug detected - both cases received the same number of chunks."
  puts "The bug may be environment-specific or timing-dependent."
  exit 0
else
  puts "Unexpected results - needs further investigation."
  exit 2
end
