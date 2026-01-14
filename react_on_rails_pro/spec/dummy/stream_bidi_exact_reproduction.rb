# frozen_string_literal: true

#
# EXACT reproduction of React on Rails Pro stream_bidi flow
#
# This mirrors the actual code path in:
# - ReactOnRailsPro::Request.render_code_with_incremental_updates
# - ReactOnRailsPro::StreamRequest#each_chunk
#
# The key difference from other demos is the EXACT order of operations
# and the fact that data is sent BEFORE response.each is called.
#
# Run: bundle exec ruby stream_bidi_exact_reproduction.rb
#

require "bundler/setup"
require "httpx"
require "json"
require "socket"
require "http/2"
require "async"
require "async/barrier"

puts "=" * 70
puts "EXACT React on Rails Pro Stream Flow Reproduction"
puts "=" * 70
puts

# Load the httpx patch that RoR Pro uses
require_relative "../../lib/react_on_rails_pro/httpx_stream_bidi_patch"

#
# HTTP/2 server that simulates Node renderer behavior
#
class NodeRendererSimulator
  attr_reader :port, :received_lines, :response_sent

  def initialize
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @received_lines = []
    @response_sent = false
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
    request_body = +""

    stream.on(:headers) do |headers|
      puts "  [Server] Received request headers"
      # Immediately send response headers (like Fastify does)
      stream.headers({ ":status" => "200", "content-type" => "application/x-ndjson" }, end_stream: false)
      puts "  [Server] Sent response headers"
    end

    stream.on(:data) do |chunk|
      puts "  [Server] Received data chunk: #{chunk.bytesize} bytes"
      request_body << chunk
      while (idx = request_body.index("\n"))
        line = request_body.slice!(0, idx + 1).strip
        next if line.empty?

        @received_lines << line
        puts "  [Server] Parsed line #{@received_lines.size}: #{line[0..50]}..."

        # Send response for each line (like React streaming)
        response = JSON.generate({ html: "<div>Chunk #{@received_lines.size}</div>", seq: @received_lines.size })
        stream.data("#{response}\n", end_stream: false)
        puts "  [Server] Sent response chunk #{@received_lines.size}"
      end
    end

    stream.on(:half_close) do
      puts "  [Server] Received END_STREAM from client"
      # Send final response
      final = JSON.generate({ html: "<div>Complete</div>", isComplete: true })
      stream.data("#{final}\n", end_stream: true)
      @response_sent = true
      puts "  [Server] Sent final response + END_STREAM"
    end
  end

  def close_client(client)
    client.close rescue nil
    @clients.delete(client)
    @connections.delete(client)
  end
end

#
# Simulates EXACTLY what happens in render_code_with_incremental_updates
#
def create_incremental_request(session, path, initial_data)
  request = session.build_request(
    "POST",
    path,
    headers: { "content-type" => "application/x-ndjson" },
    body: [],
    stream: true
  )

  # Get StreamResponse - HTTP request NOT sent yet
  response = session.request(request, stream: true)

  # Send initial data BEFORE returning
  puts "  [Client] Buffering initial data"
  request << "#{initial_data.to_json}\n"

  [request, response]
end

#
# Simulates EXACTLY what happens in StreamRequest#each_chunk + process_response_chunks
#
def iterate_response_with_barrier(request, response, async_block, use_sleep:)
  chunks = []

  Sync do
    barrier = Async::Barrier.new

    # This is EXACTLY like render_code_with_incremental_updates
    barrier.async do
      # KEY: this sleep simulates the difference between working and broken
      sleep 0.02 if use_sleep

      puts "  [Client] Async block: sending updates"
      async_block.call(request)

      puts "  [Client] Async block: closing request"
      request.close
    end

    # This is EXACTLY like loop_response_lines in stream_request.rb
    puts "  [Client] Starting to iterate response..."
    response.each do |chunk|
      puts "  [Client] Received chunk: #{chunk.strip[0..50]}..."
      chunks << chunk
    end
    puts "  [Client] Finished iterating response"

    barrier.wait
  end

  chunks
end

#
# Full test simulating the exact RoR Pro flow
#
def run_test(use_sleep:)
  label = use_sleep ? "WITH" : "WITHOUT"
  puts
  puts "Test: #{label} sleep in async block"
  puts "-" * 50

  server = NodeRendererSimulator.new
  server.start

  session = HTTPX
    .plugin(:stream_bidi)
    .with(
      origin: server.origin,
      fallback_protocol: "h2",
      timeout: { connect_timeout: 5, read_timeout: 5 }
    )

  initial_data = { renderingRequest: "test_code", type: "initial" }

  request, response = create_incremental_request(session, "/render", initial_data)

  async_block = ->(req) {
    3.times do |i|
      data = { type: "update", index: i }
      puts "  [Client] Async: sending update #{i}"
      req << "#{data.to_json}\n"
    end
  }

  chunks = iterate_response_with_barrier(request, response, async_block, use_sleep: use_sleep)

  session.close
  server.stop

  puts
  puts "  Results: Server received #{server.received_lines.size} lines"
  puts "  Results: Client received #{chunks.size} response chunks"

  [server.received_lines.size, chunks.size]
end

# Run tests
lines_no_sleep, chunks_no_sleep = run_test(use_sleep: false)
sleep 0.3
lines_with_sleep, chunks_with_sleep = run_test(use_sleep: true)

# Summary
puts
puts "=" * 70
puts "SUMMARY"
puts "=" * 70
puts "WITHOUT sleep: Server received #{lines_no_sleep} lines, Client received #{chunks_no_sleep} chunks"
puts "WITH sleep:    Server received #{lines_with_sleep} lines, Client received #{chunks_with_sleep} chunks"
puts

if chunks_no_sleep.zero? && chunks_with_sleep > 0
  puts "*** BUG CONFIRMED ***"
  puts "Response chunks lost when request.close is called immediately!"
  exit 1
elsif chunks_no_sleep < chunks_with_sleep
  puts "*** PARTIAL BUG: Fewer chunks received without sleep ***"
  exit 1
else
  puts "No bug detected in this environment."
  puts
  puts "The bug may require specific conditions:"
  puts "1. Actual Node.js HTTP/2 server (not Ruby simulator)"
  puts "2. Specific network latency patterns"
  puts "3. Specific version of httpx gem"
  puts
  puts "Try running the actual React on Rails Pro test case."
  exit 0
end
