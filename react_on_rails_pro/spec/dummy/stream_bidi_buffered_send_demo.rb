# frozen_string_literal: true

#
# Test: What happens when the entire request is buffered before HTTP connection starts
#
# Hypothesis: The bug occurs when:
# 1. StreamResponse is created (request + response objects exist but no HTTP yet)
# 2. ALL request data + close is buffered BEFORE @session.request(@request) in response.each
# 3. When response.each finally executes, it sends everything + END_STREAM immediately
# 4. Something in httpx doesn't properly handle response when request is already closed
#
# Run: bundle exec ruby stream_bidi_buffered_send_demo.rb
#

require "bundler/setup"
require "httpx"
require "json"
require "socket"
require "http/2"
require "async"
require "async/barrier"

puts "=" * 70
puts "Buffered Send Demo"
puts "=" * 70
puts
puts "Testing what happens when ALL data is buffered before HTTP starts"
puts

# Load httpx patch
require_relative "../../lib/react_on_rails_pro/httpx_stream_bidi_patch"

#
# HTTP/2 server that logs exact frame timing
#
class TimingHTTP2Server
  attr_reader :port, :frame_times, :response_sent

  def initialize
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @frame_times = []
    @response_sent = false
    @clients = []
    @connections = {}
    @running = true
    @start_time = nil
  end

  def origin
    "http://127.0.0.1:#{@port}"
  end

  def start
    @start_time = Time.now
    Thread.new { run }
    sleep 0.1
  end

  def stop
    @running = false
    @server.close rescue nil
    @clients.each { |c| c.close rescue nil }
  end

  private

  def elapsed
    ((Time.now - @start_time) * 1000).round(2)
  end

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
    puts "  [Server @#{elapsed}ms] Accept error: #{e}"
  end

  def read_client(client)
    data = client.read_nonblock(16384, exception: false)
    case data
    when :wait_readable then return
    when nil then close_client(client)
    else
      puts "  [Server @#{elapsed}ms] Received #{data.bytesize} bytes TCP data"
      @connections[client] << data
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
    request_lines = []
    end_stream_seen = false

    stream.on(:headers) do |headers|
      puts "  [Server @#{elapsed}ms] HEADERS frame received"
      @frame_times << [:headers, elapsed]

      # Send response headers
      stream.headers({ ":status" => "200", "content-type" => "application/x-ndjson" }, end_stream: false)
      puts "  [Server @#{elapsed}ms] Response HEADERS sent"
    end

    stream.on(:data) do |chunk|
      puts "  [Server @#{elapsed}ms] DATA frame: #{chunk.bytesize} bytes"
      @frame_times << [:data, elapsed, chunk.bytesize]

      request_body << chunk
      while (idx = request_body.index("\n"))
        line = request_body.slice!(0, idx + 1).strip
        next if line.empty?

        request_lines << line
        puts "  [Server @#{elapsed}ms] Parsed line #{request_lines.size}: #{line[0..50]}..."
      end
    end

    stream.on(:half_close) do
      end_stream_seen = true
      puts "  [Server @#{elapsed}ms] END_STREAM received"
      @frame_times << [:end_stream, elapsed]

      # Send responses for all received lines
      request_lines.each_with_index do |_, i|
        response = JSON.generate({ html: "<div>Response #{i + 1}</div>", seq: i + 1 })
        stream.data("#{response}\n", end_stream: false)
        puts "  [Server @#{elapsed}ms] Sent response #{i + 1}"
      end

      # Send final
      final = JSON.generate({ status: "complete", total: request_lines.size })
      stream.data("#{final}\n", end_stream: true)
      @response_sent = true
      puts "  [Server @#{elapsed}ms] Sent final response + END_STREAM"
    end
  end

  def close_client(client)
    client.close rescue nil
    @clients.delete(client)
    @connections.delete(client)
  end
end

#
# Test 1: Normal flow - data sent incrementally as it's written
#
def test_incremental_flow(server)
  puts "\n--- Test: Incremental Flow ---"
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
      "POST",
      "/test",
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    # Get StreamResponse - NO HTTP YET
    response = session.request(request, stream: true)
    puts "  [Client] StreamResponse created"

    # Send initial data
    request << JSON.generate({ type: "initial" }) + "\n"
    puts "  [Client] Initial data buffered"

    # Schedule async block
    barrier.async do
      # Small yield to let response.each start
      Async::Task.current.yield

      puts "  [Client] Async block: sending updates"
      3.times do |i|
        request << JSON.generate({ type: "update", i: i }) + "\n"
        puts "  [Client] Buffered update #{i}"
      end

      puts "  [Client] Async block: closing request"
      request.close
    end

    # Start response iteration - this triggers actual HTTP
    puts "  [Client] Starting response.each..."
    response.each do |chunk|
      puts "  [Client] Got chunk: #{chunk.strip[0..50]}..."
      chunks << chunk
    end
    puts "  [Client] response.each complete"

    barrier.wait
    session.close
  end

  chunks
end

#
# Test 2: Buffered flow - all data buffered BEFORE response.each
#
def test_buffered_flow(server)
  puts "\n--- Test: Buffered Flow (All Data Before HTTP) ---"
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
      "POST",
      "/test",
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    # Get StreamResponse - NO HTTP YET
    response = session.request(request, stream: true)
    puts "  [Client] StreamResponse created"

    # Send ALL data BEFORE response.each
    request << JSON.generate({ type: "initial" }) + "\n"
    puts "  [Client] Initial data buffered"

    3.times do |i|
      request << JSON.generate({ type: "update", i: i }) + "\n"
      puts "  [Client] Buffered update #{i}"
    end

    request.close
    puts "  [Client] Request closed (all data + END_STREAM buffered)"

    # NOW start response iteration
    puts "  [Client] Starting response.each..."
    response.each do |chunk|
      puts "  [Client] Got chunk: #{chunk.strip[0..50]}..."
      chunks << chunk
    end
    puts "  [Client] response.each complete"

    session.close
  end

  chunks
end

#
# Test 3: Barrier async flow - async block runs during IO.select
#
def test_barrier_async_flow(server, use_yield:)
  label = use_yield ? "with yield" : "no yield"
  puts "\n--- Test: Barrier Async Flow (#{label}) ---"
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
      "POST",
      "/test",
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    response = session.request(request, stream: true)
    puts "  [Client] StreamResponse created"

    request << JSON.generate({ type: "initial" }) + "\n"
    puts "  [Client] Initial data buffered"

    # Schedule async block - will run during IO.select yields
    barrier.async do
      Async::Task.current.yield if use_yield

      puts "  [Client] Async block executing..."
      3.times do |i|
        request << JSON.generate({ type: "update", i: i }) + "\n"
        puts "  [Client] Buffered update #{i}"
      end

      request.close
      puts "  [Client] Request closed from async block"
    end

    # Start response iteration
    puts "  [Client] Starting response.each..."
    response.each do |chunk|
      puts "  [Client] Got chunk: #{chunk.strip[0..50]}..."
      chunks << chunk
    end
    puts "  [Client] response.each complete"

    barrier.wait
    session.close
  end

  chunks
end

# Run tests
results = {}

server1 = TimingHTTP2Server.new
server1.start
results["Incremental"] = test_incremental_flow(server1).size
puts "  Frame times: #{server1.frame_times.inspect}"
server1.stop

sleep 0.3

server2 = TimingHTTP2Server.new
server2.start
results["Buffered (before HTTP)"] = test_buffered_flow(server2).size
puts "  Frame times: #{server2.frame_times.inspect}"
server2.stop

sleep 0.3

server3 = TimingHTTP2Server.new
server3.start
results["Barrier async (with yield)"] = test_barrier_async_flow(server3, use_yield: true).size
puts "  Frame times: #{server3.frame_times.inspect}"
server3.stop

sleep 0.3

server4 = TimingHTTP2Server.new
server4.start
results["Barrier async (no yield)"] = test_barrier_async_flow(server4, use_yield: false).size
puts "  Frame times: #{server4.frame_times.inspect}"
server4.stop

# Summary
puts
puts "=" * 70
puts "RESULTS"
puts "=" * 70
results.each do |name, count|
  status = count > 0 ? "OK (#{count} chunks)" : "*** BUG (0 chunks) ***"
  puts "#{name.ljust(30)}: #{status}"
end
puts

bug_found = results.values.any?(&:zero?)
if bug_found
  puts "BUG DETECTED: Some scenarios received 0 chunks"
  exit 1
else
  puts "No bug detected with Ruby HTTP/2 server"
  exit 0
end
