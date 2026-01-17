#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Ruby HTTPX client for testing worker.disconnect() behavior
#
# Uses bidirectional HTTP/2 streaming exactly like React on Rails Pro:
# - Build request with empty body
# - Start request, get response stream
# - Write chunks in a separate thread using `request << chunk`
# - Read response chunks concurrently
#
# Usage: ruby test-disconnect-chunks-ruby-client.rb
#

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "httpx"
end

require "httpx"
require "json"

PORT = 9876
CHUNK_COUNT = 10
CHUNK_DELAY_SECONDS = 0.2

puts "=" * 70
puts "Ruby HTTPX HTTP/2 Client - Bidirectional Streaming"
puts "Sending #{CHUNK_COUNT} chunks with #{CHUNK_DELAY_SECONDS}s delays"
puts "=" * 70
puts

# Create HTTPX connection with HTTP/2 prior knowledge (like React on Rails Pro)
http = HTTPX
         .plugin(:stream_bidi)
         .with(
           origin: "http://localhost:#{PORT}",
           fallback_protocol: "h2", # HTTP/2 prior knowledge
           timeout: {
             connect_timeout: 10,
             read_timeout: 30
           }
         )

puts "[RUBY CLIENT] Connecting via HTTP/2 (h2 prior knowledge)..."
puts "[RUBY CLIENT] Using HTTPX :stream_bidi plugin for bidirectional streaming"
puts

begin
  # Build request with EMPTY body - we'll write chunks later
  # This is exactly how request.rb does it:
  #   request = connection.build_request("POST", path, headers: {...}, body: [], stream: true)
  request = http.build_request(
    "POST",
    "/test-chunks",
    headers: { "content-type" => "application/x-ndjson" },
    body: [],
    stream: true
  )

  # Start the request - response begins streaming immediately
  # This is non-blocking; we can now write to request while reading response
  response = http.request(request, stream: true)

  # Thread to write chunks to the request body
  writer_thread = Thread.new do
    CHUNK_COUNT.times do |i|
      chunk_num = i + 1
      chunk_data = { chunk: chunk_num, data: "chunk-#{chunk_num}-data" }.to_json + "\n"

      puts "[RUBY CLIENT] Sending chunk ##{chunk_num}"

      # Write chunk to the HTTP/2 stream (like: request << "#{data.to_json}\n")
      request << chunk_data

      # Delay between chunks
      sleep(CHUNK_DELAY_SECONDS) if chunk_num < CHUNK_COUNT
    end

    puts "[RUBY CLIENT] Finished sending all chunks, closing request..."
    # Close the request to send END_STREAM flag
    # This triggers Node's handleRequestClosed
    request.close
  end

  # Read response chunks (this happens concurrently with writing)
  puts "[RUBY CLIENT] Reading response stream..."
  response_body = +""

  response.each do |chunk|
    puts "[RUBY CLIENT] Received response chunk: #{chunk.bytesize} bytes"
    response_body << chunk
  end

  # Wait for writer thread to finish
  writer_thread.join

  puts
  puts "[RUBY CLIENT] Response status: #{response.status}"
  puts "[RUBY CLIENT] Response body: #{response_body}"

rescue StandardError => e
  puts "[RUBY CLIENT] Error: #{e.class}: #{e.message}"
  puts e.backtrace.first(10).join("\n")
end

puts
puts "=" * 70
puts "Ruby client finished"
puts "=" * 70
