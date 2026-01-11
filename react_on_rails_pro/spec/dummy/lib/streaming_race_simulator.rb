# frozen_string_literal: true

# StreamingRaceSimulator - Rack middleware for reproducing JSON parse race condition
#
# PURPOSE:
#   This middleware is used for TESTING PURPOSES ONLY to reliably reproduce a race
#   condition bug in React on Rails Pro's `immediate_hydration` feature.
#
# THE BUG (https://github.com/shakacode/react_on_rails/issues/2283):
#   When `immediate_hydration` is enabled (default for Pro users), React hydration
#   executes immediately when the async JS bundle loads, WITHOUT waiting for
#   DOMContentLoaded.
#
#   During HTML streaming on slow networks:
#   1. Browser receives: <script type="application/json" class="js-react-on-rails-component">{"items":[
#   2. The DOM element EXISTS (opening tag parsed), but content is INCOMPLETE
#   3. JS bundle finishes loading and executes immediately
#   4. el.textContent returns TRUNCATED JSON (only what's been received so far)
#   5. JSON.parse() fails with: "SyntaxError: Unterminated string in JSON at position X"
#
# HOW THIS MIDDLEWARE WORKS:
#   1. Buffers response chunks until the complete props <script> tag is found
#   2. Splits the props script content in the middle
#   3. Sends the first half, then DELAYS 300ms, then sends the second half
#   4. This delay creates a window where JS can execute while props are incomplete
#   5. After props are processed, remaining chunks pass through immediately
#
# USAGE:
#   Add `?simulate_streaming_props_delay=true` to any URL to trigger the simulation.
#   Example: http://localhost:3000/server_side_hello_world_hooks?simulate_streaming_props_delay=true
#
# NOTE:
#   This middleware is for development/testing only. It should NEVER be used in
#   production as it intentionally delays responses and can cause application errors.

class StreamingRaceSimulator
  def initialize(app)
    @app = app
  end

  def call(env)
    # Only activate when ?simulate_streaming_props_delay=true is in the query string
    return @app.call(env) unless env["QUERY_STRING"]&.include?("simulate_streaming_props_delay=true")

    status, headers, response = @app.call(env)

    # Convert headers to mutable hash and remove Content-Length
    # (we're modifying the response timing, so length may be reported incorrectly)
    headers = headers.to_hash
    headers.delete("Content-Length")

    [status, headers, DelayedPropsBody.new(response)]
  end
end

# Wraps the response body to intercept and delay the props script tag
class DelayedPropsBody
  # Regex to match the React on Rails props script tag
  # Example: <script type="application/json" class="js-react-on-rails-component"
  #          data-dom-id="...">{"props":...}</script>
  PROPS_SCRIPT_PATTERN = %r{<script[^>]*class="[^"]*js-react-on-rails-component[^"]*"[^>]*>.*?</script>}m

  # Delay in seconds between sending the two halves of the props script
  # This creates the race condition window where JS can read incomplete props
  RACE_CONDITION_DELAY = 1

  def initialize(source)
    @source = source
  end

  def each(&block)
    buffer = +""
    props_processed = false

    @source.each do |chunk|
      # Once props are processed, pass through all remaining chunks immediately
      if props_processed
        yield chunk
        next
      end

      # Buffer chunks until we find the complete props script
      buffer << chunk

      # Try to find the complete props script tag in the buffer
      next unless (match = buffer.match(PROPS_SCRIPT_PATTERN))

      # Process the matched props script with delay
      yield_props_with_delay(buffer, match, &block)
      props_processed = true
    end

    # If props script was never found, yield whatever we buffered
    yield buffer unless buffer.empty? || props_processed
  ensure
    @source.close if @source.respond_to?(:close)
  end

  def close
    @source.close if @source.respond_to?(:close)
  end

  private

  def yield_props_with_delay(buffer, match)
    before, props_script, after = extract_parts(buffer, match)
    first_half, second_half = split_props_script(props_script)

    # Send first half (contains opening tag + truncated JSON)
    yield before + first_half

    # DELAY - This is where the race condition happens!
    # JS bundle can load and execute during this window, reading incomplete props
    sleep RACE_CONDITION_DELAY

    # Send second half (rest of JSON + closing tag) + any content after
    yield second_half + after
  end

  def extract_parts(buffer, match)
    before = buffer[0...match.begin(0)]
    props_script = match[0]
    after = buffer[match.end(0)..]
    [before, props_script, after]
  end

  def split_props_script(props_script)
    # Find the JSON content boundaries (between opening tag and closing tag)
    # Opening tag ends at first '>' after '<script'
    opening_tag_end = props_script.index(">") + 1
    # Closing tag starts at '</script>'
    closing_tag_start = props_script.rindex("</script>")

    # Split in the middle of the JSON content (not in the tags)
    json_content_length = closing_tag_start - opening_tag_end
    split_point = opening_tag_end + (json_content_length / 2)

    [props_script[0...split_point], props_script[split_point..]]
  end
end
