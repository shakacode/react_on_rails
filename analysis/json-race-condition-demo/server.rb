#!/usr/bin/env ruby
# Minimal demo server to reproduce JSON parsing race condition
# Run: ruby server.rb
# Then open http://localhost:4567 in browser with Network throttling set to "Slow 3G"

require 'webrick'
require 'json'

# Generate ~500KB of JSON data
def generate_large_json
  items = (0..2000).map do |i|
    {
      id: i,
      name: "Item #{i} with a long name to increase payload size",
      description: "Description " * 50,
      metadata: {
        tags: %w[tag1 tag2 tag3 tag4 tag5],
        nested: (0..10).map { |j| { nested_id: j, value: "value_#{i}_#{j}" * 10 } }
      }
    }
  end
  { componentId: 1, items: items }.to_json
end

LARGE_JSON = generate_large_json
puts "Generated JSON size: #{LARGE_JSON.length / 1024}KB"

server = WEBrick::HTTPServer.new(Port: 4567)

server.mount_proc '/' do |req, res|
  res['Content-Type'] = 'text/html'

  # The key: we send the JavaScript BEFORE the complete JSON
  # This simulates what happens with async script loading
  html = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>JSON Race Condition Demo</title>
    </head>
    <body>
      <h1>JSON Race Condition Demo</h1>
      <p>Open DevTools → Network → Throttle to "Slow 3G" and refresh</p>
      <div id="result">Waiting...</div>

      <!-- Component placeholder -->
      <div id="MyComponent"></div>

      <!--
        IMPORTANT: This script runs IMMEDIATELY when parsed.
        On slow networks, it may execute BEFORE the JSON script tag below is fully received.
      -->
      <script>
        // Simulate what React on Rails "immediate hydration" does
        function tryParseProps() {
          const scriptEl = document.getElementById('component-props');

          if (!scriptEl) {
            document.getElementById('result').innerHTML =
              '<span style="color: orange">Script tag not found yet, retrying...</span>';
            setTimeout(tryParseProps, 10);
            return;
          }

          const textContent = scriptEl.textContent;
          const resultEl = document.getElementById('result');

          try {
            const props = JSON.parse(textContent);
            resultEl.innerHTML =
              '<span style="color: green">✓ SUCCESS: Parsed ' + props.items.length + ' items</span>';
          } catch (e) {
            resultEl.innerHTML =
              '<span style="color: red">✗ ERROR: ' + e.message + '</span><br>' +
              '<small>textContent length: ' + textContent.length + '</small><br>' +
              '<small>Last 100 chars: <code>' + textContent.slice(-100) + '</code></small>';
            console.error('JSON Parse Error:', e);
            console.log('textContent length:', textContent.length);
            console.log('Last 100 chars:', textContent.slice(-100));
          }
        }

        // Run immediately (like immediate_hydration does)
        tryParseProps();
      </script>

      <!-- The JSON props - this comes AFTER the script that tries to read it -->
      <script type="application/json" id="component-props">
        #{LARGE_JSON}
      </script>

      <hr>
      <h3>What's happening:</h3>
      <ol>
        <li>Server sends HTML with a large JSON payload (~#{LARGE_JSON.length / 1024}KB)</li>
        <li>The JavaScript that parses JSON is placed BEFORE the JSON script tag</li>
        <li>On slow networks, JS executes before the JSON is fully received</li>
        <li>textContent returns incomplete/truncated JSON</li>
        <li>JSON.parse() fails with "Unterminated string"</li>
      </ol>
    </body>
    </html>
  HTML

  res.body = html
end

trap('INT') { server.shutdown }
puts "Demo server running at http://localhost:4567"
puts "Open in browser with Network throttling set to 'Slow 3G' to reproduce the bug"
server.start
