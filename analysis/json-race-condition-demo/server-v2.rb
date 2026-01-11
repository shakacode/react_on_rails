#!/usr/bin/env ruby
# Accurate demo of JSON parsing race condition
#
# This demo correctly reproduces the React on Rails architecture:
# 1. External async script in <head>
# 2. JSON script tag in <body>
# 3. Server streams HTML in chunks with delays
#
# Run: ruby server-v2.rb
# Open: http://localhost:4567 (no throttling needed - server simulates slow streaming)

require 'socket'
require 'json'

PORT = 4568

# Generate large JSON (~500KB)
def generate_large_json
  items = (0..2000).map do |i|
    {
      id: i,
      name: "Item #{i} with a reasonably long name to increase size",
      description: "Detailed description for item #{i}. " * 20,
      metadata: {
        tags: %w[tag1 tag2 tag3 tag4 tag5],
        nested: (0..10).map { |j| { nested_id: j, value: "nested_value_#{i}_#{j}" * 5 } }
      }
    }
  end
  { componentId: 1, items: items }.to_json
end

LARGE_JSON = generate_large_json
puts "Generated JSON size: #{(LARGE_JSON.length / 1024.0).round(2)}KB"

# The external JavaScript (simulates client-bundle.js with immediate_hydration)
BUNDLE_JS = <<~JS
  // This simulates React on Rails Pro's immediate hydration behavior
  console.log('[Bundle] Script loaded and executing');

  function hydrateComponents() {
    console.log('[Bundle] Looking for components to hydrate...');

    const scriptEl = document.querySelector('.js-react-on-rails-component');

    if (!scriptEl) {
      console.log('[Bundle] No component script tags found yet');
      document.getElementById('result').innerHTML =
        '<span style="color: orange">Component script tag not in DOM yet</span>';
      return;
    }

    console.log('[Bundle] Found script tag, reading textContent...');
    const textContent = scriptEl.textContent;
    console.log('[Bundle] textContent length:', textContent.length);

    try {
      const props = JSON.parse(textContent);
      console.log('[Bundle] SUCCESS - parsed', props.items?.length, 'items');
      document.getElementById('result').innerHTML =
        '<span style="color: green">✓ SUCCESS: Parsed ' + props.items.length + ' items</span><br>' +
        '<small>JSON size: ' + textContent.length + ' bytes</small>';
    } catch (e) {
      console.error('[Bundle] JSON PARSE ERROR:', e.message);
      console.log('[Bundle] Last 100 chars:', textContent.slice(-100));

      document.getElementById('result').innerHTML =
        '<span style="color: red; font-size: 1.5em">✗ BUG REPRODUCED!</span><br><br>' +
        '<strong>Error:</strong> ' + e.message + '<br>' +
        '<strong>textContent length:</strong> ' + textContent.length + ' bytes<br>' +
        '<strong>Last 100 chars:</strong><br><code>' +
        textContent.slice(-100).replace(/</g, '&lt;') + '</code><br><br>' +
        '<em>The JSON was truncated because the script tag content was still streaming!</em>';
    }
  }

  // Execute IMMEDIATELY - this is what immediate_hydration does
  // It doesn't wait for DOMContentLoaded
  hydrateComponents();
JS

server = TCPServer.new('0.0.0.0', PORT)
puts "Demo server running at http://localhost:#{PORT}"
puts "Open in browser - no throttling needed, server simulates slow streaming"
puts "Press Ctrl+C to stop"

loop do
  client = server.accept

  request = ""
  while (line = client.gets) && line != "\r\n"
    request += line
  end

  path = request.split(' ')[1]

  if path == '/bundle.js'
    # Serve the JavaScript bundle
    response = "HTTP/1.1 200 OK\r\n"
    response += "Content-Type: application/javascript\r\n"
    response += "Content-Length: #{BUNDLE_JS.length}\r\n"
    response += "Connection: close\r\n"
    response += "\r\n"
    response += BUNDLE_JS
    client.print response
    client.close
    next
  end

  # Main page - stream HTML in chunks with delays
  puts "\n[Server] New request - streaming HTML in chunks..."

  # Send headers with chunked transfer encoding
  headers = "HTTP/1.1 200 OK\r\n"
  headers += "Content-Type: text/html; charset=utf-8\r\n"
  headers += "Transfer-Encoding: chunked\r\n"
  headers += "Connection: close\r\n"
  headers += "\r\n"
  client.print headers

  def send_chunk(client, data)
    client.print "#{data.bytesize.to_s(16)}\r\n#{data}\r\n"
    client.flush
  end

  # CHUNK 1: Head with async script
  chunk1 = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>JSON Race Condition Demo (Accurate)</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 900px; margin: 40px auto; padding: 0 20px; }
        code { background: #f4f4f4; padding: 2px 6px; }
        #result { padding: 20px; border: 2px solid #ccc; margin: 20px 0; border-radius: 8px; min-height: 100px; }
      </style>
      <!--
        CRITICAL: This async script will download and execute as soon as ready.
        It may execute BEFORE the JSON script tag below is fully received!
      -->
      <script src="/bundle.js" async></script>
    </head>
    <body>
      <h1>JSON Race Condition Demo</h1>
      <p><strong>How this works:</strong> Server streams HTML in chunks with delays. The async JS bundle
      loads and executes mid-stream, reading incomplete JSON.</p>

      <div id="result">
        <span style="color: gray">Waiting for bundle.js to execute...</span>
      </div>

      <h3>Streaming Progress:</h3>
      <div id="progress"></div>

      <hr>
      <h3>Component Placeholder</h3>
      <div id="MyComponent-react-component-0"></div>

      <!-- JSON script tag starts here, content streams in chunks below -->
      <script type="application/json"
              class="js-react-on-rails-component"
              id="js-react-on-rails-component-0"
              data-component-name="MyComponent"
              data-dom-id="MyComponent-react-component-0">
  HTML

  puts "[Server] Sending chunk 1 (head + start of JSON tag)..."
  send_chunk(client, chunk1)

  # Small delay to let bundle.js potentially load and execute
  sleep 0.1

  # CHUNK 2-N: Stream JSON in pieces
  json_chunks = LARGE_JSON.chars.each_slice(50_000).map(&:join)

  json_chunks.each_with_index do |json_part, i|
    puts "[Server] Sending JSON chunk #{i + 1}/#{json_chunks.length} (#{json_part.length} bytes)..."
    send_chunk(client, json_part)
    # Delay between chunks - this creates the race window
    sleep 0.15
  end

  # FINAL CHUNK: Close tags
  final_chunk = <<~HTML
      </script>

      <script>
        document.getElementById('progress').innerHTML =
          '<span style="color: green">✓ HTML fully loaded</span>';
      </script>

      <hr>
      <h3>What happened:</h3>
      <ol>
        <li>Server sent &lt;head&gt; with <code>&lt;script src="/bundle.js" async&gt;</code></li>
        <li>Browser started downloading bundle.js</li>
        <li>Server streamed the JSON content in #{json_chunks.length} chunks with delays</li>
        <li>bundle.js likely executed mid-stream and read incomplete textContent</li>
      </ol>
    </body>
    </html>
  HTML

  puts "[Server] Sending final chunk..."
  send_chunk(client, final_chunk)

  # End chunked response
  client.print "0\r\n\r\n"
  client.close
  puts "[Server] Response complete"
end
