# frozen_string_literal: true

#
# Debug test for stream_bidi issue
#
# Run: bundle exec ruby test_stream_bidi_debug.rb
#

require "bundler/setup"
require "httpx"
require "json"
require "async"
require "async/barrier"

# Load the httpx patch and debug plugin
require_relative "../../lib/react_on_rails_pro/httpx_stream_bidi_patch"

# Add debug logging to stream_bidi
$: << "/mnt/ssd/open-source/httpx/lib"
require "httpx/plugins/stream_debug"

NODE_RENDERER_URL = ENV.fetch("NODE_RENDERER_URL", "http://localhost:3800")
PROTOCOL_VERSION = "2.0.0"
RENDERER_PASSWORD = "myPassword1" # Matches spec/dummy config

puts "=" * 70
puts "Stream Bidi Debug Test"
puts "=" * 70
puts "Node Renderer URL: #{NODE_RENDERER_URL}"
puts

# Simple render request that returns a stream
# This mimics what the actual RoR Pro code sends
SIMPLE_RENDER_REQUEST = <<~JS
  (function() {
    const ReactOnRails = global.ReactOnRails;
    const React = ReactOnRails.getReact();
    const ReactDOMServer = ReactOnRails.getReactDOMServer();

    // Simple component that renders immediately
    const SimpleComponent = () => {
      return React.createElement('div', null, 'Hello from Node Renderer!');
    };

    // Use renderToString for simplicity
    const html = ReactDOMServer.renderToString(React.createElement(SimpleComponent));

    // Return as a simple readable stream
    const { Readable } = require('stream');
    const stream = Readable.from([
      JSON.stringify({ html: html, isComplete: true }) + '\\n'
    ]);

    return stream;
  })()
JS

def test_incremental_render(use_sleep:)
  label = use_sleep ? "WITH" : "WITHOUT"
  puts "\n" + "=" * 70
  puts "Test: #{label} sleep"
  puts "=" * 70

  response_chunks = []
  # Use existing bundle that was uploaded by test_real_incremental_debug.rb
  bundle_timestamp = "test_incremental_bundle"
  rsc_bundle_timestamp = "test_incremental_rsc_bundle"

  Sync do
    barrier = Async::Barrier.new

    # Create session with debug plugin
    session = HTTPX
      .plugin(:stream_bidi)
      .plugin(:stream_debug)
      .with(
        origin: NODE_RENDERER_URL,
        fallback_protocol: "h2",
        timeout: { connect_timeout: 10, read_timeout: 30 }
      )

    # Build incremental render request
    path = "/bundles/#{bundle_timestamp}/incremental-render/test123"

    request = session.build_request(
      "POST",
      path,
      headers: { "content-type" => "application/x-ndjson" },
      body: [],
      stream: true
    )

    puts "[Test] Built request, about to get StreamResponse"

    # Get StreamResponse - NO HTTP yet
    response = session.request(request, stream: true)
    puts "[Test] Got StreamResponse (class=#{response.class})"

    # Initial request data (first NDJSON line) - matches RoR Pro protocol
    initial_data = {
      protocolVersion: PROTOCOL_VERSION,
      password: RENDERER_PASSWORD,
      renderingRequest: "ReactOnRails.getStreamValues()",
      dependencyBundleTimestamps: [rsc_bundle_timestamp],
      onRequestClosedUpdateChunk: {
        bundleTimestamp: rsc_bundle_timestamp,
        updateChunk: "ReactOnRails.endStream()"
      }
    }

    puts "[Test] Sending initial request data..."
    request << "#{initial_data.to_json}\n"
    puts "[Test] Initial request data sent (buffered)"

    # Schedule async block to send updates and close
    barrier.async do
      puts "[Test] Async block started"

      if use_sleep
        puts "[Test] Sleeping 0.1s..."
        sleep 0.1
      end

      # Send some update chunks that add values to the stream
      2.times do |i|
        update = {
          bundleTimestamp: rsc_bundle_timestamp,
          updateChunk: "ReactOnRails.addStreamValue('value#{i}\\n')"
        }
        puts "[Test] Sending update #{i}..."
        request << "#{update.to_json}\n"
      end

      puts "[Test] Closing request..."
      request.close
      puts "[Test] Request closed"
    end

    # Iterate response - this triggers actual HTTP
    puts "[Test] About to call response.each..."
    begin
      response.each do |chunk|
        puts "[Test] GOT CHUNK: #{chunk.strip[0..100]}..."
        response_chunks << chunk
      end
    rescue => e
      puts "[Test] ERROR during iteration: #{e.class}: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
    puts "[Test] response.each complete"

    barrier.wait
    puts "[Test] barrier.wait complete"
    session.close
  end

  puts "\n[Result] Received #{response_chunks.size} chunks"
  response_chunks.each_with_index do |chunk, i|
    puts "  Chunk #{i}: #{chunk.strip[0..80]}..."
  end

  response_chunks.size
end

# Check if Node renderer is running first
def check_renderer
  session = HTTPX.with(
    origin: NODE_RENDERER_URL,
    timeout: { connect_timeout: 5 },
    fallback_protocol: "h2"
  )
  response = session.get("/info")

  if response.is_a?(HTTPX::ErrorResponse)
    puts "Cannot connect to Node renderer: #{response.error.message}"
    return false
  end

  if response.status == 200
    puts "Node Renderer: #{response.body}"
    true
  else
    puts "Node Renderer returned status #{response.status}"
    false
  end
rescue => e
  puts "Error checking renderer: #{e.message}"
  false
end

unless check_renderer
  puts "\nPlease start the Node renderer:"
  puts "  cd react_on_rails_pro/spec/dummy && pnpm node-renderer"
  exit 1
end

puts

# Run tests
begin
  chunks_no_sleep = test_incremental_render(use_sleep: false)
rescue => e
  puts "Test WITHOUT sleep failed: #{e.class}: #{e.message}"
  puts e.backtrace.first(10).join("\n")
  chunks_no_sleep = -1
end

puts "\n" + "-" * 70

begin
  chunks_with_sleep = test_incremental_render(use_sleep: true)
rescue => e
  puts "Test WITH sleep failed: #{e.class}: #{e.message}"
  puts e.backtrace.first(10).join("\n")
  chunks_with_sleep = -1
end

# Summary
puts "\n" + "=" * 70
puts "SUMMARY"
puts "=" * 70
puts "WITHOUT sleep: #{chunks_no_sleep} chunks"
puts "WITH sleep:    #{chunks_with_sleep} chunks"

if chunks_no_sleep == 0 && chunks_with_sleep > 0
  puts "\n*** BUG CONFIRMED ***"
  puts "Response chunks lost when request.close is called immediately!"
  exit 1
elsif chunks_no_sleep < 0 || chunks_with_sleep < 0
  puts "\nTests failed with errors"
  exit 2
elsif chunks_no_sleep < chunks_with_sleep
  puts "\n*** PARTIAL BUG: Fewer chunks without sleep ***"
  exit 1
else
  puts "\nNo bug detected"
  exit 0
end
