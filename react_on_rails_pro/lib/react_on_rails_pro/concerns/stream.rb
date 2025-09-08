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
      @rorp_rendering_fibers = []
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

    private

    def drain_streams_concurrently
      require "async"
      require "async/limited_queue"

      return if @rorp_rendering_fibers.empty?

      Sync do |parent|
        # To avoid memory bloat, we use a limited queue to buffer chunks in memory.
        buffer_size = ReactOnRailsPro.configuration.concurrent_component_streaming_buffer_size
        queue = Async::LimitedQueue.new(size: buffer_size)

        writer = build_writer_task(parent: parent, queue: queue)
        tasks = build_producer_tasks(parent: parent, queue: queue)

        # This structure ensures that even if a producer task fails, we always
        # signal the writer to stop and then wait for it to finish draining
        # any remaining items from the queue before propagating the error.
        begin
          tasks.each(&:wait)
        ensure
          # `close` signals end-of-stream; when writer tries to dequeue, it will get nil, so it will exit.
          queue.close
          writer.wait
        end
      end
    end

    def build_producer_tasks(parent:, queue:)
      @rorp_rendering_fibers.each_with_index.map do |fiber, idx|
        parent.async do
          loop do
            begin
              chunk = fiber.resume
            rescue FiberError
              break
            end
            break unless chunk

            # Will be blocked if the queue is full until a chunk is dequeued
            queue.enqueue([idx, chunk])
          end
        end
      end
    end

    def build_writer_task(parent:, queue:)
      parent.async do
        loop do
          pair = queue.dequeue
          break if pair.nil?

          _idx_from_queue, item = pair
          begin
            response.stream.write(item)
          rescue IOError, ActionController::Live::ClientDisconnected
            break
          end
        end
      end
    end
  end
end
