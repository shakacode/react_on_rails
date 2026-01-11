#!/usr/bin/env ruby
# Minimal demo proving DOM returns partial content during streaming
#
# Run: ruby minimal-demo.rb
# Open: http://localhost:4569
#
# This demo proves: when you query a DOM element while HTML is streaming,
# textContent returns whatever bytes have been received so far.

require 'socket'

PORT = 4569

server = TCPServer.new('0.0.0.0', PORT)
puts "Minimal DOM streaming demo: http://localhost:#{PORT}"
puts "Press Ctrl+C to stop"

loop do
  client = server.accept

  # Skip reading request for simplicity
  client.gets until client.gets == "\r\n"

  # Use chunked transfer encoding to stream HTML
  client.print "HTTP/1.1 200 OK\r\n"
  client.print "Content-Type: text/html\r\n"
  client.print "Transfer-Encoding: chunked\r\n"
  client.print "\r\n"

  def send_chunk(client, data)
    client.print "#{data.bytesize.to_s(16)}\r\n#{data}\r\n"
    client.flush
  end

  # CHUNK 1: HTML with inline script that reads the target element
  chunk1 = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Minimal DOM Streaming Demo</title>
      <script>
        // This script runs IMMEDIATELY when parsed
        // It will try to read the div below before it's complete
        setTimeout(function() {
          var el = document.getElementById('streaming-content');
          if (el) {
            var content = el.textContent;
            document.getElementById('result').innerHTML =
              '<strong>Content length:</strong> ' + content.length + ' chars<br>' +
              '<strong>Content ends with:</strong> <code>' + content.slice(-50) + '</code><br>' +
              '<strong>Is complete?</strong> ' + (content.endsWith('END_MARKER') ? 'YES' : 'NO - TRUNCATED!');
          } else {
            document.getElementById('result').innerHTML = 'Element not found yet';
          }
        }, 100); // 100ms delay - element exists but content incomplete
      </script>
    </head>
    <body>
      <h1>Minimal DOM Streaming Demo</h1>
      <p>This proves that <code>el.textContent</code> returns partial content during streaming.</p>
      <div id="result" style="padding:20px; border:2px solid #333; margin:20px 0;">
        Waiting for script to execute...
      </div>
      <hr>
      <h3>The streaming content (should end with END_MARKER):</h3>
      <div id="streaming-content" style="max-height:200px; overflow:auto; background:#f5f5f5; padding:10px;">
  HTML

  puts "[Server] Sending chunk 1 (head + start of div)..."
  send_chunk(client, chunk1)

  # Wait to create the race condition
  sleep 0.2

  # CHUNK 2-4: Stream content slowly
  3.times do |i|
    content = "CHUNK_#{i + 1}_" + ("X" * 10000) + "_"
    puts "[Server] Sending content chunk #{i + 1}..."
    send_chunk(client, content)
    sleep 0.15
  end

  # FINAL CHUNK: Close div with marker
  final = <<~HTML
    END_MARKER</div>
      <script>
        // This runs after everything is loaded
        var el = document.getElementById('streaming-content');
        document.getElementById('final-result').innerHTML =
          '<strong>Final length:</strong> ' + el.textContent.length + ' chars<br>' +
          '<strong>Ends with END_MARKER?</strong> ' + el.textContent.endsWith('END_MARKER');
      </script>
      <div id="final-result" style="padding:20px; border:2px solid green; margin:20px 0;"></div>
    </body>
    </html>
  HTML

  puts "[Server] Sending final chunk..."
  send_chunk(client, final)

  client.print "0\r\n\r\n"
  client.close
  puts "[Server] Done\n\n"
end
