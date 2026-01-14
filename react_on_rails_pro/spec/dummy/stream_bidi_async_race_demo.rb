# frozen_string_literal: true

#
# Minimal reproduction of stream_bidi race condition with Async Ruby
#
# This demonstrates the ACTUAL bug in React on Rails Pro:
# The race condition occurs when using Async Ruby's fiber scheduler
# with httpx's stream_bidi plugin.
#
# Run: bundle exec ruby stream_bidi_async_race_demo.rb
#

require "bundler/setup"
require "httpx"
require "json"
require "socket"
require "http/2"
require "async"
require "async/barrier"

puts "=" * 70
puts "HTTPX stream_bidi + Async Ruby Race Condition Demo"
puts "=" * 70
puts

#
# Simple HTTP/2 server
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

    stream.on(:headers) do |_|
      stream.headers({ ":status" => "200", "content-type" => "application/x-ndjson" }, end_stream: false)
    end

    stream.on(:data) do |chunk|
      request_body << chunk
      while (idx = request_body.index("\n"))
        line = request_body.slice!(0, idx + 1).strip
        next if line.empty?

        @received_lines << line
        response = JSON.generate({ echo: line, seq: @received_lines.size })
        stream.data("#{response}\n", end_stream: false)
      end
    end

    stream.on(:half_close) do
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
# Simulates the React on Rails Pro flow with Async Ruby
#
def test_with_async(server, use_sleep:)
  response_chunks = []

  # This mirrors StreamRequest#each_chunk which wraps everything in Sync do
  Sync do
    barrier = Async::Barrier.new

    session = HTTPX
      .plugin(:stream_bidi)
      .with(
        origin: server.origin,
        fallback_protocol: "h2",
        timeout: { connect_timeout: 5, read_timeout: 5 }
      )

    # Build streaming request (mirrors render_code_with_incremental_updates)
    request = session.build_request(
      "POST",
      "/test",
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    # Get StreamResponse - HTTP not sent yet!
    response = session.request(request, stream: true)

    # Buffer initial data
    request << JSON.generate({ type: "initial" }) + "\n"

    # Schedule async task (mirrors barrier.async in render_code_with_incremental_updates)
    # This task runs during fiber yields in response.each
    barrier.async do
      # KEY: With sleep, HTTP connection establishes before we close
      # Without sleep, we close during connection setup
      sleep 0.05 if use_sleep

      3.times do |i|
        request << JSON.generate({ type: "update", index: i }) + "\n"
      end

      request.close
    end

    # Iterate response - THIS triggers the actual HTTP request
    # The barrier.async task runs during I/O waits here
    response.each do |chunk|
      response_chunks << chunk
    end

    barrier.wait
    session.close
  end

  response_chunks
end

# Run tests
puts "Starting HTTP/2 server..."

server1 = SimpleHTTP2Server.new
server1.start
puts "Test 1: WITHOUT sleep (Async Ruby fiber scheduler)"
puts "-" * 50
begin
  chunks_no_sleep = test_with_async(server1, use_sleep: false)
  puts "  Server received #{server1.received_lines.size} lines"
  puts "  Client received #{chunks_no_sleep.size} response chunks"
  chunks_no_sleep.each { |c| puts "    #{c.strip[0..60]}..." }
rescue => e
  puts "  ERROR: #{e.class}: #{e.message}"
  chunks_no_sleep = []
end
server1.stop

sleep 0.3

server2 = SimpleHTTP2Server.new
server2.start
puts
puts "Test 2: WITH sleep (Async Ruby fiber scheduler)"
puts "-" * 50
begin
  chunks_with_sleep = test_with_async(server2, use_sleep: true)
  puts "  Server received #{server2.received_lines.size} lines"
  puts "  Client received #{chunks_with_sleep.size} response chunks"
  chunks_with_sleep.each { |c| puts "    #{c.strip[0..60]}..." }
rescue => e
  puts "  ERROR: #{e.class}: #{e.message}"
  chunks_with_sleep = []
end
server2.stop

# Summary
puts
puts "=" * 70
puts "RESULTS"
puts "=" * 70
puts "WITHOUT sleep: Server got #{server1.received_lines.size} lines, Client got #{chunks_no_sleep.size} chunks"
puts "WITH sleep:    Server got #{server2.received_lines.size} lines, Client got #{chunks_with_sleep.size} chunks"
puts

if chunks_no_sleep.empty? && chunks_with_sleep.any?
  puts "*** BUG CONFIRMED ***"
  puts "Response chunks lost when request.close is called before"
  puts "response iteration begins in Async Ruby context!"
  exit 1
elsif chunks_no_sleep.size < chunks_with_sleep.size
  puts "*** PARTIAL BUG: Fewer chunks received without sleep ***"
  exit 1
else
  puts "No bug detected in this run (timing-dependent)."
  exit 0
end
