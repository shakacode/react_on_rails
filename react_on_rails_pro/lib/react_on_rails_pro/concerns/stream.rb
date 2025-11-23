# frozen_string_literal: true

module ReactOnRailsPro
  module Stream
    extend ActiveSupport::Concern

    included do
      include ActionController::Live
    end

    # Streams React components within a specified template to the client.
    #
    # @param template [String] The path to the template file to be streamed.
    # @param close_stream_at_end [Boolean] Whether to automatically close the stream after rendering (default: true).
    # @param render_options [Hash] Additional options to pass to `render_to_string`.
    #
    # components must be added to the view using the `stream_react_component` helper.
    #
    # @example
    #   stream_view_containing_react_components(template: 'path/to/your/template')
    #
    # @example
    #   stream_view_containing_react_components(
    #     template: 'path/to/your/template',
    #     close_stream_at_end: false,
    #     layout: false
    #   )
    #
    # @note The `stream_react_component` helper is defined in the react_on_rails gem.
    #       For more details, refer to `lib/react_on_rails/helper.rb` in the react_on_rails repository.
    #
    # @see ReactOnRails::Helper#stream_react_component
    def stream_view_containing_react_components(template:, close_stream_at_end: true, **render_options)
      require "async"
      require "async/barrier"
      require "async/limited_queue"

      Sync do
        # Initialize async primitives for concurrent component streaming
        @async_barrier = Async::Barrier.new
        buffer_size = ReactOnRailsPro.configuration.concurrent_component_streaming_buffer_size
        @main_output_queue = Async::LimitedQueue.new(buffer_size)

        # Render template - components will start streaming immediately
        template_string = render_to_string(template: template, **render_options)
        # View may contain extra newlines, chunk already contains a newline
        # Having multiple newlines between chunks causes hydration errors
        # So we strip extra newlines from the template string and add a single newline
        response.stream.write(template_string)

        begin
          drain_streams_concurrently
        ensure
          response.stream.close if close_stream_at_end
        end
      end
    end

    private

    def drain_streams_concurrently
      # Wait for all component streaming tasks to complete
      @async_barrier.wait

      # Close the queue to signal end of streaming
      @main_output_queue.close

      # Drain all remaining chunks from the queue to the response stream
      while (chunk = @main_output_queue.dequeue)
        response.stream.write(chunk)
      end
    end
  end
end
