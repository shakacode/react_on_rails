#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to verify httpx handles HEADERS arriving after END_STREAM is sent
#
# This creates an HTTP/2 server that:
# 1. Receives a bidirectional streaming request
# 2. Waits for the client to close the request (send END_STREAM)
# 3. Delays BEFORE sending response HEADERS
# 4. Then sends HEADERS and DATA
#
# If httpx has a bug where it ignores HEADERS after sending END_STREAM,
# this test will fail (empty response or timeout).

require "socket"
require "openssl"
require "http/2"
require "httpx"
require "async"
require "async/barrier"

# Generate self-signed certificate for TLS
def generate_self_signed_cert
  key = OpenSSL::PKey::RSA.new(2048)
  cert = OpenSSL::X509::Certificate.new
  cert.version = 2
  cert.serial = 1
  cert.subject = OpenSSL::X509::Name.parse("/CN=localhost")
  cert.issuer = cert.subject
  cert.public_key = key.public_key
  cert.not_before = Time.now
  cert.not_after = Time.now + 3600

  # Add subjectAltName extension for localhost
  ef = OpenSSL::X509::ExtensionFactory.new
  ef.subject_certificate = cert
  ef.issuer_certificate = cert
  cert.add_extension(ef.create_extension("subjectAltName", "DNS:localhost,IP:127.0.0.1"))
  cert.add_extension(ef.create_extension("basicConstraints", "CA:FALSE"))

  cert.sign(key, OpenSSL::Digest.new("SHA256"))
  [cert, key]
end

class HTTP2Server
  ALPN_PROTOCOL = "h2"

  def initialize(port)
    @port = port
    @cert, @key = generate_self_signed_cert
    @server = nil
    @running = false
  end

  def start
    @server = TCPServer.new("127.0.0.1", @port)
    @running = true

    puts "[SERVER] Started on port #{@port}"

    Thread.new do
      while @running
        begin
          client = @server.accept_nonblock
          Thread.new(client) { |c| handle_connection(c) }
        rescue IO::WaitReadable
          IO.select([@server], nil, nil, 0.1)
        rescue IOError
          break
        end
      end
    end
  end

  def stop
    @running = false
    @server&.close
  end

  private

  def handle_connection(tcp_socket)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.cert = @cert
    ssl_context.key = @key
    ssl_context.alpn_protocols = [ALPN_PROTOCOL]
    ssl_context.alpn_select_cb = lambda { |protocols|
      ALPN_PROTOCOL if protocols.include?(ALPN_PROTOCOL)
    }

    ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
    ssl_socket.sync_close = true
    ssl_socket.accept

    puts "[SERVER] Client connected, ALPN: #{ssl_socket.alpn_protocol}"

    conn = HTTP2::Server.new
    request_end_stream_received = false
    stream_for_response = nil
    received_data = []

    conn.on(:frame) do |bytes|
      ssl_socket.write(bytes)
    end

    conn.on(:stream) do |stream|
      stream_for_response = stream
      request_headers = nil

      stream.on(:headers) do |headers|
        request_headers = headers.to_h
        puts "[SERVER] Received request headers: #{request_headers[":method"]} #{request_headers[":path"]}"
      end

      stream.on(:data) do |data|
        received_data << data
        puts "[SERVER] Received data chunk: #{data.bytesize} bytes"
      end

      stream.on(:half_close) do
        # Client has sent END_STREAM - request body is complete
        request_end_stream_received = true
        puts "[SERVER] Client sent END_STREAM (request complete)"
        puts "[SERVER] Total data received: #{received_data.join.bytesize} bytes"

        # NOW we delay before sending headers - this is the critical test!
        puts "[SERVER] Waiting 2 seconds BEFORE sending response headers..."
        puts "[SERVER] (simulating the bug scenario where headers are delayed)"
        sleep(2)

        puts "[SERVER] NOW sending response headers (after client already closed request)"
        stream.headers({
          ":status" => "200",
          "content-type" => "application/json"
        })

        # Send response data
        response_body = { message: "Success! Headers sent after client END_STREAM", data_received: received_data.join }.to_json
        puts "[SERVER] Sending response body: #{response_body.bytesize} bytes"
        stream.data(response_body, end_stream: true)
        puts "[SERVER] Response complete"
      end
    end

    # Read and process incoming data
    while !ssl_socket.closed? && !ssl_socket.eof?
      begin
        data = ssl_socket.read_nonblock(16384)
        conn << data
      rescue IO::WaitReadable
        IO.select([ssl_socket], nil, nil, 0.5)
      rescue EOFError, IOError
        break
      end
    end

    puts "[SERVER] Connection closed"
  rescue StandardError => e
    puts "[SERVER] Error: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  ensure
    ssl_socket&.close rescue nil
    tcp_socket&.close rescue nil
  end
end

def run_httpx_client(port)
  puts "\n[CLIENT] Starting httpx client with stream_bidi plugin..."

  # Create httpx session with stream_bidi plugin (same as React on Rails Pro)
  session = HTTPX
    .plugin(:stream_bidi)
    .with(
      ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE }, # Accept self-signed cert
      timeout: { connect_timeout: 5, read_timeout: 10 }
    )

  result = false

  Sync do
    barrier = Async::Barrier.new

    # Build bidirectional streaming request
    request = session.build_request(
      "POST",
      "https://localhost:#{port}/test",
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    puts "[CLIENT] Starting request..."
    response = session.request(request, stream: true)

    # Send initial data
    initial_data = { type: "initial", timestamp: Time.now.to_i }.to_json
    puts "[CLIENT] Sending initial data: #{initial_data}"
    request << "#{initial_data}\n"

    # Simulate async props block in separate fiber (like React on Rails Pro)
    barrier.async do
      puts "[CLIENT] Async fiber: sending additional data..."
      request << { type: "async_data", value: "test" }.to_json + "\n"

      puts "[CLIENT] Async fiber: closing request (sending END_STREAM)..."
      request.close
      puts "[CLIENT] Async fiber: request closed, END_STREAM sent"
    end

    # Collect response
    puts "[CLIENT] Waiting for response (headers should arrive after we sent END_STREAM)..."

    response_chunks = []
    response.each do |chunk|
      puts "[CLIENT] Received chunk: #{chunk.bytesize} bytes"
      response_chunks << chunk.dup
    end
    response_body = response_chunks.join

    barrier.wait

    puts "\n[CLIENT] === RESULTS ==="
    puts "[CLIENT] Response status: #{response.status}"
    puts "[CLIENT] Response body: #{response_body}"
    puts "[CLIENT] Response body size: #{response_body.bytesize} bytes"

    if response_body.empty?
      puts "\n[RESULT] FAILED - Empty response! httpx has a bug with late headers."
      result = false
    else
      puts "\n[RESULT] SUCCESS - httpx correctly received headers after sending END_STREAM!"
      result = true
    end
  end

  result
rescue StandardError => e
  puts "[CLIENT] Error: #{e.message}"
  puts e.backtrace.first(10).join("\n")
  false
ensure
  session&.close
end

# Main test execution
puts "=" * 70
puts "Testing: Does httpx handle HEADERS arriving after client sends END_STREAM?"
puts "=" * 70

port = 9443
server = HTTP2Server.new(port)
server.start

sleep(0.5) # Give server time to start

begin
  success = run_httpx_client(port)
  exit(success ? 0 : 1)
ensure
  server.stop
end
