# frozen_string_literal: true

module ReactOnRailsPro
  # Emitter class for sending async props incrementally during streaming render
  # Used by stream_react_component_with_async_props helper
  class AsyncPropsEmitter
    def initialize(bundle_timestamp, request_stream)
      @bundle_timestamp = bundle_timestamp
      @request_stream = request_stream
    end

    # Public API: emit.call('propName', propValue)
    # Sends an update chunk to the node renderer to resolve an async prop
    def call(prop_name, prop_value)
      update_chunk = generate_update_chunk(prop_name, prop_value)
      @request_stream << "#{update_chunk.to_json}\n"
    rescue StandardError => e
      Rails.logger.error do
        "[ReactOnRailsPro] Failed to send async prop '#{prop_name}': #{e.message}"
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
          var asyncPropsManager = sharedExecutionContext.get("asyncPropsManager");
          asyncPropsManager.setProp(#{prop_name.to_json}, #{value.to_json});
        })()
      JS
    end

    def generate_end_stream_js
      <<~JS.strip
        (function(){
          var asyncPropsManager = sharedExecutionContext.get("asyncPropsManager");
          asyncPropsManager.endStream();
        })()
      JS
    end
  end
end
