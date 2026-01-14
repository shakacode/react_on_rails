# frozen_string_literal: true

#
# Debug test that reproduces the actual incremental rendering bug
#
# This loads the LOCAL httpx source with debug logging
#
# Run: bundle exec ruby test_real_incremental_debug.rb
#

# Load LOCAL httpx source BEFORE anything else
$LOAD_PATH.unshift("/mnt/ssd/open-source/httpx/lib")
require "httpx"

puts "HTTPX loaded from: #{HTTPX.method(:get).source_location[0]}"
puts "HTTPX version: #{HTTPX::VERSION}"

require "bundler/setup"
Bundler.require(:default)

require "rails"
require "action_controller/railtie"
require "json"
require "async"
require "async/barrier"

# Load the RoR Pro code
require_relative "../../lib/react_on_rails_pro"

# Load the httpx patch
require_relative "../../lib/react_on_rails_pro/httpx_stream_bidi_patch"

# Enable debug logging
ENV["HTTPX_DEBUG_STREAM"] = "1"

NODE_RENDERER_URL = "http://localhost:3800"
PROTOCOL_VERSION = ReactOnRailsPro::PROTOCOL_VERSION
RENDERER_PASSWORD = "myPassword1"

puts "=" * 70
puts "Real Incremental Rendering Debug Test"
puts "=" * 70
puts "Node Renderer URL: #{NODE_RENDERER_URL}"
puts "Protocol Version: #{PROTOCOL_VERSION}"
puts

# Minimal Rails app for testing
class TestApp < Rails::Application
  config.eager_load = false
  config.secret_key_base = "test_secret_key"
end
TestApp.initialize!

# Configure RoR Pro
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = NODE_RENDERER_URL
  config.renderer_password = RENDERER_PASSWORD
end

# Check if Node renderer is running
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

# The JS code that will be executed on the Node renderer
# This creates a simple component that uses async props
JS_CODE = <<~JS
  (function() {
    const ReactOnRails = global.ReactOnRails;
    const React = ReactOnRails.getReact();
    const ReactDOMServer = ReactOnRails.getReactDOMServer();

    // Simple component that outputs async prop values
    const TestComponent = (props) => {
      const { asyncPropsManager } = props;

      // Get async props (this will suspend if not yet available)
      let value1 = 'waiting...';
      let value2 = 'waiting...';

      try {
        if (asyncPropsManager) {
          // These will throw promises if values aren't ready yet
          value1 = asyncPropsManager.getProp('prop1');
          value2 = asyncPropsManager.getProp('prop2');
        }
      } catch (e) {
        // Promise thrown for suspense
        throw e;
      }

      return React.createElement('div', null,
        React.createElement('p', null, 'Prop1: ' + value1),
        React.createElement('p', null, 'Prop2: ' + value2)
      );
    };

    // Use renderToString for simplicity
    const html = ReactDOMServer.renderToString(
      React.createElement(TestComponent, {})
    );

    // Return as stream
    const { Readable } = require('stream');
    return Readable.from([
      JSON.stringify({ html: html, isComplete: true }) + '\\n'
    ]);
  })()
JS

def test_incremental_render(use_sleep:)
  label = use_sleep ? "WITH" : "WITHOUT"
  puts "\n" + "=" * 70
  puts "Test: #{label} sleep in async_props_block"
  puts "=" * 70

  # Reset connection to start fresh
  ReactOnRailsPro::Request.reset_connection

  response_chunks = []
  bundle_timestamp = "test-bundle-#{Time.now.to_i}"

  # Mimics the actual render_code_with_incremental_updates flow
  begin
    stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
      "/bundles/#{bundle_timestamp}/incremental-render/test123",
      JS_CODE,
      async_props_block: proc { |emitter|
        puts "  [Async Block] Started"

        if use_sleep
          puts "  [Async Block] Sleeping 0.1s..."
          sleep 0.1
        end

        puts "  [Async Block] Sending prop1..."
        emitter.call("prop1", "value1")

        puts "  [Async Block] Sending prop2..."
        emitter.call("prop2", "value2")

        puts "  [Async Block] Complete"
      },
      is_rsc_payload: false
    )

    puts "[Test] Got stream, about to iterate..."
    stream.each_chunk do |chunk|
      puts "[Test] GOT CHUNK: #{chunk.strip[0..100]}..."
      response_chunks << chunk
    end
    puts "[Test] Stream iteration complete"
  rescue => e
    puts "[Test] ERROR: #{e.class}: #{e.message}"
    puts e.backtrace.first(10).join("\n")
  end

  puts "\n[Result] Received #{response_chunks.size} chunks"
  response_chunks.each_with_index do |chunk, i|
    puts "  Chunk #{i}: #{chunk.strip[0..80]}..."
  end

  response_chunks.size
end

# Run tests
begin
  chunks_no_sleep = test_incremental_render(use_sleep: false)
rescue => e
  puts "Test WITHOUT sleep crashed: #{e.class}: #{e.message}"
  puts e.backtrace.first(10).join("\n")
  chunks_no_sleep = -1
end

puts "\n" + "-" * 70

begin
  chunks_with_sleep = test_incremental_render(use_sleep: true)
rescue => e
  puts "Test WITH sleep crashed: #{e.class}: #{e.message}"
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
  puts "Response chunks lost when async_props_block has no sleep!"
  exit 1
elsif chunks_no_sleep < 0 || chunks_with_sleep < 0
  puts "\nTests had errors"
  exit 2
elsif chunks_no_sleep < chunks_with_sleep
  puts "\n*** PARTIAL BUG: Fewer chunks without sleep ***"
  exit 1
else
  puts "\nNo bug detected"
  exit 0
end
