# frozen_string_literal: true

#
# Test: Does connection reuse cause the stream_bidi issue?
#
# RoR Pro reuses a single HTTPX session for all requests.
# This test checks if that causes problems.
#
# Run: bundle exec ruby test_stream_bidi_reuse.rb
#

require "bundler/setup"
require "httpx"
require "json"
require "socket"
require "http/2"
require "async"
require "async/barrier"

puts "=" * 70
puts "Stream Bidi Connection Reuse Test"
puts "=" * 70
puts

# Load httpx patch
require_relative "../../lib/react_on_rails_pro/httpx_stream_bidi_patch"

#
# HTTP/2 server that responds with streaming data
#
class StreamingHTTP2Server
  attr_reader :port, :request_count

  def initialize
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @request_count = 0
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
    @request_count += 1
    request_num = @request_count
    request_body = +""
    lines_received = []

    stream.on(:headers) do |_|
      puts "  [Server] Request ##{request_num}: HEADERS received"
      stream.headers({ ":status" => "200", "content-type" => "application/x-ndjson" }, end_stream: false)
    end

    stream.on(:data) do |chunk|
      request_body << chunk
      while (idx = request_body.index("\n"))
        line = request_body.slice!(0, idx + 1).strip
        next if line.empty?

        lines_received << line
        puts "  [Server] Request ##{request_num}: Received line #{lines_received.size}"
      end
    end

    stream.on(:half_close) do
      puts "  [Server] Request ##{request_num}: END_STREAM received"

      # Send response chunks
      lines_received.each_with_index do |_, i|
        chunk = JSON.generate({ html: "<div>Response #{i + 1}</div>", seq: i + 1 })
        stream.data("#{chunk}\n", end_stream: false)
      end

      # Send final
      final = JSON.generate({ complete: true, total: lines_received.size })
      stream.data("#{final}\n", end_stream: true)
      puts "  [Server] Request ##{request_num}: Response complete"
    end
  end

  def close_client(client)
    client.close rescue nil
    @clients.delete(client)
    @connections.delete(client)
  end
end

#
# Shared session (like RoR Pro uses)
#
def create_shared_session(server)
  HTTPX
    .plugin(:stream_bidi)
    .with(
      origin: server.origin,
      fallback_protocol: "h2",
      timeout: { connect_timeout: 5, read_timeout: 5 }
    )
end

def perform_request(session, path, use_sleep:)
  chunks = []

  Sync do
    barrier = Async::Barrier.new

    request = session.build_request(
      "POST",
      path,
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    response = session.request(request, stream: true)
    request << JSON.generate({ type: "initial" }) + "\n"

    barrier.async do
      sleep 0.02 if use_sleep

      2.times do |i|
        request << JSON.generate({ type: "update", i: i }) + "\n"
      end
      request.close
    end

    response.each do |chunk|
      chunks << chunk
    end

    barrier.wait
  end

  chunks
end

# Run test with connection reuse
server = StreamingHTTP2Server.new
server.start

# Create ONE shared session (like RoR Pro)
shared_session = create_shared_session(server)

puts "Test: Multiple requests with SAME session (connection reuse)"
puts "=" * 60

results = {}

# Test 1: Without sleep
puts "\n--- Request 1: WITHOUT sleep ---"
chunks1 = perform_request(shared_session, "/test1", use_sleep: false)
results["Req 1 (no sleep)"] = chunks1.size
puts "  Result: #{chunks1.size} chunks"

sleep 0.1

# Test 2: With sleep
puts "\n--- Request 2: WITH sleep ---"
chunks2 = perform_request(shared_session, "/test2", use_sleep: true)
results["Req 2 (sleep)"] = chunks2.size
puts "  Result: #{chunks2.size} chunks"

sleep 0.1

# Test 3: Without sleep again (after connection is warmed up)
puts "\n--- Request 3: WITHOUT sleep (after warmup) ---"
chunks3 = perform_request(shared_session, "/test3", use_sleep: false)
results["Req 3 (no sleep)"] = chunks3.size
puts "  Result: #{chunks3.size} chunks"

sleep 0.1

# Test 4: Without sleep immediately after
puts "\n--- Request 4: WITHOUT sleep (immediately after) ---"
chunks4 = perform_request(shared_session, "/test4", use_sleep: false)
results["Req 4 (no sleep)"] = chunks4.size
puts "  Result: #{chunks4.size} chunks"

shared_session.close
server.stop

# Summary
puts "\n" + "=" * 60
puts "SUMMARY"
puts "=" * 60
puts "Server handled #{server.request_count} requests"

bug_found = false
results.each do |name, count|
  status = count > 0 ? "OK (#{count})" : "*** BUG (0) ***"
  bug_found = true if count == 0
  puts "#{name.ljust(25)}: #{status}"
end

puts
if bug_found
  puts "BUG DETECTED: Some requests received 0 chunks!"
  exit 1
else
  puts "All requests received chunks correctly"
  exit 0
end
