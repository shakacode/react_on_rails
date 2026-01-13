# frozen_string_literal: true

module ReactOnRailsPro
  # Emitter class for sending async props incrementally during streaming render.
  # Used by stream_react_component_with_async_props helper.
  #
  # PROTOCOL:
  # Each call to `emit.call(prop_name, value)` sends an NDJSON line to the Node renderer:
  #   {"bundleTimestamp": "abc123", "updateChunk": "(function(){...})()"}
  #
  # The updateChunk JavaScript accesses the AsyncPropsManager via sharedExecutionContext
  # and resolves the promise for that prop, allowing React to continue rendering.
  #
  # WHY NOT USE GLOBAL VARIABLES?
  # Global variables in Node.js VM persist across requests, causing data leakage.
  # sharedExecutionContext is scoped to a single HTTP request (ExecutionContext).
  #
  # @example Usage in view
  #   stream_react_component_with_async_props("Dashboard") do |emit|
  #     emit.call("users", User.all.to_a)      # Sends immediately
  #     emit.call("posts", Post.recent.to_a)   # Sends when ready
  #   end
  class AsyncPropsEmitter
    def initialize(bundle_timestamp, request_stream)
      @bundle_timestamp = bundle_timestamp
      @request_stream = request_stream
    end

    # Sends an async prop to the Node renderer.
    # The prop value is JSON-serialized and sent as an NDJSON line.
    # On the Node side, this triggers asyncPropsManager.setProp(propName, value).
    def call(prop_name, prop_value)
      update_chunk = generate_update_chunk(prop_name, prop_value)
      @request_stream << "#{update_chunk.to_json}\n"
    rescue StandardError => e
      Rails.logger.error do
        backtrace = e.backtrace&.first(5)&.join("\n")
        "[ReactOnRailsPro::AsyncProps] FAILED to send prop '#{prop_name}': " \
          "#{e.class} - #{e.message}\n#{backtrace}"
      end
      # Continue - don't abort entire render because one prop failed
    end

    # Generates the chunk that should be executed when the request stream closes
    # This tells the asyncPropsManager to end the stream
    def end_stream_chunk
      {
        bundleTimestamp: @bundle_timestamp,
        updateChunk: generate_end_stream_js
      }
    end

    private

    def generate_update_chunk(prop_name, value)
      {
        bundleTimestamp: @bundle_timestamp,
        updateChunk: generate_set_prop_js(prop_name, value)
      }
    end

    def generate_set_prop_js(prop_name, value)
      <<~JS.strip
        (function(){
          var asyncPropsManager = ReactOnRails.getOrCreateAsyncPropsManager(sharedExecutionContext);
          asyncPropsManager.setProp(#{prop_name.to_json}, #{value.to_json});
        })()
      JS
    end

    def generate_end_stream_js
      <<~JS.strip
        (function(){
          var asyncPropsManager = ReactOnRails.getOrCreateAsyncPropsManager(sharedExecutionContext);
          asyncPropsManager.endStream();
        })()
      JS
    end
  end
end
