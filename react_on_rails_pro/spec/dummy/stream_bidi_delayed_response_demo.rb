# frozen_string_literal: true

#
# Reproduction of stream_bidi bug with delayed server response
#
# This simulates the ACTUAL React on Rails Pro scenario:
# 1. Client sends initial request
# 2. Server starts processing (React rendering - takes time)
# 3. Client immediately sends all update chunks and closes request (no sleep)
# 4. Server finishes processing and sends response
# 5. BUG: Client may not receive response if request was closed too early
#
# Run: bundle exec ruby stream_bidi_delayed_response_demo.rb
#

require "bundler/setup"
require "httpx"
require "json"
require "socket"
require "http/2"
require "async"
require "async/barrier"

puts "=" * 70
puts "HTTPX stream_bidi Delayed Response Demo"
puts "=" * 70
puts

#
# HTTP/2 server that delays response (simulating React SSR processing time)
#
class DelayedHTTP2Server
  attr_reader :port, :received_lines

  def initialize(response_delay:)
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @received_lines = []
    @response_delay = response_delay
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
    request_body = +""
    all_lines = []
    headers_sent = false

    stream.on(:headers) do |_|
      # Send response headers immediately (like Fastify does)
      stream.headers({ ":status" => "200", "content-type" => "application/x-ndjson" }, end_stream: false)
      headers_sent = true
    end

    stream.on(:data) do |chunk|
      request_body << chunk
      while (idx = request_body.index("\n"))
        line = request_body.slice!(0, idx + 1).strip
        next if line.empty?

        @received_lines << line
        all_lines << line
      end
    end

    stream.on(:half_close) do
      # Client sent END_STREAM - now we "process" and respond
      # This simulates React rendering taking some time
      Thread.new do
        sleep @response_delay if @response_delay > 0

        # Now send all response chunks
        all_lines.each_with_index do |line, i|
          response = JSON.generate({ echo: line, seq: i + 1 })
          stream.data("#{response}\n", end_stream: false)
        end

        final = JSON.generate({ status: "complete", total: all_lines.size })
        stream.data("#{final}\n", end_stream: true)
      end
    end
  end

  def close_client(client)
    client.close rescue nil
    @clients.delete(client)
    @connections.delete(client)
  end
end

#
# Test function
#
def test_stream(server, use_sleep_before_close:)
  response_chunks = []

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
      "POST",
      "/test",
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    response = session.request(request, stream: true)
    request << JSON.generate({ type: "initial" }) + "\n"

    # Async task that sends data and closes request
    barrier.async do
      sleep 0.05 if use_sleep_before_close

      3.times do |i|
        request << JSON.generate({ type: "update", index: i }) + "\n"
      end

      request.close
    end

    # Iterate response
    response.each do |chunk|
      response_chunks << chunk
    end

    barrier.wait
    session.close
  end

  response_chunks
end

#
# Test 1: Server responds immediately (no delay)
#
puts "Scenario 1: Server responds IMMEDIATELY (no processing delay)"
puts "=" * 70

server1a = DelayedHTTP2Server.new(response_delay: 0)
server1a.start
chunks1a = test_stream(server1a, use_sleep_before_close: false)
puts "  WITHOUT client sleep: Server got #{server1a.received_lines.size}, Client got #{chunks1a.size} chunks"
server1a.stop

sleep 0.2

server1b = DelayedHTTP2Server.new(response_delay: 0)
server1b.start
chunks1b = test_stream(server1b, use_sleep_before_close: true)
puts "  WITH client sleep:    Server got #{server1b.received_lines.size}, Client got #{chunks1b.size} chunks"
server1b.stop

#
# Test 2: Server has processing delay (like React SSR)
#
puts
puts "Scenario 2: Server has 50ms DELAY (simulating React SSR)"
puts "=" * 70

sleep 0.2

server2a = DelayedHTTP2Server.new(response_delay: 0.05)
server2a.start
chunks2a = test_stream(server2a, use_sleep_before_close: false)
puts "  WITHOUT client sleep: Server got #{server2a.received_lines.size}, Client got #{chunks2a.size} chunks"
server2a.stop

sleep 0.2

server2b = DelayedHTTP2Server.new(response_delay: 0.05)
server2b.start
chunks2b = test_stream(server2b, use_sleep_before_close: true)
puts "  WITH client sleep:    Server got #{server2b.received_lines.size}, Client got #{chunks2b.size} chunks"
server2b.stop

#
# Test 3: Longer server delay
#
puts
puts "Scenario 3: Server has 100ms DELAY"
puts "=" * 70

sleep 0.2

server3a = DelayedHTTP2Server.new(response_delay: 0.1)
server3a.start
chunks3a = test_stream(server3a, use_sleep_before_close: false)
puts "  WITHOUT client sleep: Server got #{server3a.received_lines.size}, Client got #{chunks3a.size} chunks"
server3a.stop

sleep 0.2

server3b = DelayedHTTP2Server.new(response_delay: 0.1)
server3b.start
chunks3b = test_stream(server3b, use_sleep_before_close: true)
puts "  WITH client sleep:    Server got #{server3b.received_lines.size}, Client got #{chunks3b.size} chunks"
server3b.stop

# Summary
puts
puts "=" * 70
puts "SUMMARY"
puts "=" * 70

has_bug = false
[[chunks1a, chunks1b, "No delay"], [chunks2a, chunks2b, "50ms delay"], [chunks3a, chunks3b, "100ms delay"]].each do |no_sleep, with_sleep, label|
  status = if no_sleep.empty? && with_sleep.any?
    has_bug = true
    "*** BUG ***"
  elsif no_sleep.size < with_sleep.size
    has_bug = true
    "PARTIAL BUG"
  else
    "OK"
  end
  puts "#{label}: #{no_sleep.size} vs #{with_sleep.size} chunks - #{status}"
end

exit(has_bug ? 1 : 0)
