# frozen_string_literal: true

#
# Test against the ACTUAL Node renderer to reproduce the bug
#
# Prerequisites:
# 1. Start the Node renderer: cd react_on_rails_pro/spec/dummy && pnpm node-renderer
# 2. Make sure bundles are built: pnpm build
# 3. Run this test: bundle exec ruby test_actual_node_renderer.rb
#
# This script bypasses Rails and tests the stream_bidi interaction directly
# with the Node renderer, which should reproduce the actual bug.
#

require "bundler/setup"
require "httpx"
require "json"
require "digest"
require "async"
require "async/barrier"

# Load the RoR Pro httpx patch
require_relative "../../lib/react_on_rails_pro/httpx_stream_bidi_patch"

NODE_RENDERER_URL = ENV.fetch("NODE_RENDERER_URL", "http://localhost:3800")

puts "=" * 70
puts "Testing Against ACTUAL Node Renderer"
puts "=" * 70
puts "Node Renderer URL: #{NODE_RENDERER_URL}"
puts

# Check if Node renderer is running
def check_node_renderer
  session = HTTPX.with(
    origin: NODE_RENDERER_URL,
    timeout: { connect_timeout: 5 },
    fallback_protocol: "h2"
  )
  response = session.get("/info")

  if response.is_a?(HTTPX::ErrorResponse)
    puts "Cannot connect to Node renderer: #{response.error.message}"
    puts "Please start the Node renderer first:"
    puts "  cd react_on_rails_pro/spec/dummy && pnpm node-renderer"
    return false
  end

  if response.status == 200
    info = JSON.parse(response.body.to_s)
    puts "Node Renderer Info: #{info}"
    true
  else
    puts "Node Renderer returned status #{response.status}"
    false
  end
rescue => e
  puts "Cannot connect to Node renderer: #{e.message}"
  puts "Please start the Node renderer first:"
  puts "  cd react_on_rails_pro/spec/dummy && pnpm node-renderer"
  false
end

unless check_node_renderer
  exit 1
end

puts

# Generate a bundle hash (we'll use a fake one for testing)
BUNDLE_HASH = "test-#{Digest::MD5.hexdigest(Time.now.to_s)}"

# Simple JS code that just returns a stream with some data
SIMPLE_JS_CODE = <<~JS
  (function() {
    // Create a simple readable stream that sends some JSON chunks
    const { Readable } = require('stream');

    const chunks = [
      JSON.stringify({ html: '<div>Chunk 1</div>', seq: 1 }),
      JSON.stringify({ html: '<div>Chunk 2</div>', seq: 2 }),
      JSON.stringify({ html: '<div>Chunk 3</div>', seq: 3 }),
    ];

    let index = 0;
    const stream = new Readable({
      read() {
        if (index < chunks.length) {
          this.push(chunks[index] + '\\n');
          index++;
        } else {
          this.push(null);
        }
      }
    });

    return stream;
  })()
JS

def test_incremental_render(use_sleep:)
  label = use_sleep ? "WITH" : "WITHOUT"
  puts "Test: #{label} sleep"
  puts "-" * 50

  response_chunks = []

  Sync do
    barrier = Async::Barrier.new

    session = HTTPX
      .plugin(:stream_bidi)
      .with(
        origin: NODE_RENDERER_URL,
        fallback_protocol: "h2",
        timeout: { connect_timeout: 5, read_timeout: 10 }
      )

    # Build incremental render request
    path = "/bundles/#{BUNDLE_HASH}/incremental-render/test123"

    request = session.build_request(
      "POST",
      path,
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    # Get StreamResponse
    response = session.request(request, stream: true)

    # Initial request data (first NDJSON line)
    initial_data = {
      protocol_version: "2.0.0",
      auth: "secret", # Assuming no auth in test mode
      renderingRequest: SIMPLE_JS_CODE,
      onRequestClosedUpdateChunk: {
        bundleTimestamp: BUNDLE_HASH,
        updateChunk: "/* end stream */"
      }
    }

    puts "  Sending initial request..."
    request << "#{initial_data.to_json}\n"

    # Schedule async block to send updates and close
    barrier.async do
      sleep 0.05 if use_sleep

      # Send some update chunks
      3.times do |i|
        update = {
          bundleTimestamp: BUNDLE_HASH,
          updateChunk: "/* update #{i} */"
        }
        puts "  Sending update #{i}..."
        request << "#{update.to_json}\n"
      end

      puts "  Closing request..."
      request.close
    end

    # Iterate response
    puts "  Starting to iterate response..."
    begin
      response.each do |chunk|
        puts "  Received chunk: #{chunk.strip[0..60]}..."
        response_chunks << chunk
      end
    rescue => e
      puts "  ERROR during iteration: #{e.class}: #{e.message}"
    end
    puts "  Finished iterating response"

    barrier.wait
    session.close
  end

  puts "  Result: Received #{response_chunks.size} chunks"
  puts
  response_chunks.size
end

# Run tests
begin
  chunks_no_sleep = test_incremental_render(use_sleep: false)
rescue => e
  puts "  Test failed: #{e.class}: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  chunks_no_sleep = -1
end

sleep 0.5

begin
  chunks_with_sleep = test_incremental_render(use_sleep: true)
rescue => e
  puts "  Test failed: #{e.class}: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  chunks_with_sleep = -1
end

# Summary
puts "=" * 70
puts "RESULTS"
puts "=" * 70
puts "WITHOUT sleep: #{chunks_no_sleep} chunks"
puts "WITH sleep:    #{chunks_with_sleep} chunks"
puts

if chunks_no_sleep == 0 && chunks_with_sleep > 0
  puts "*** BUG CONFIRMED ***"
  puts "This proves the issue is in the httpx + Node renderer interaction!"
  exit 1
elsif chunks_no_sleep < 0 || chunks_with_sleep < 0
  puts "Tests failed - check error messages above"
  exit 2
elsif chunks_no_sleep < chunks_with_sleep
  puts "*** PARTIAL BUG: Fewer chunks without sleep ***"
  exit 1
else
  puts "No bug detected"
  exit 0
end
