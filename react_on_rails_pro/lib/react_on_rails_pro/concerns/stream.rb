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

      Sync do |parent_task|
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
          drain_streams_concurrently(parent_task)
          # Do not close the response stream in an ensure block.
          # If an error occurs we may need the stream open to send diagnostic/error details
          # (for example, ApplicationController#rescue_from in the dummy app).
          response.stream.close if close_stream_at_end
        end
      end
    end

    private

    # Drains all streaming tasks concurrently using a producer-consumer pattern.
    #
    # Producer tasks: Created by consumer_stream_async in the helper, each streams
    # chunks from the renderer and enqueues them to @main_output_queue.
    #
    # Consumer task: Single writer dequeues chunks and writes to response stream.
    #
    # Client disconnect handling:
    # - If client disconnects (IOError/Errno::EPIPE), writer stops gracefully
    # - Barrier is stopped to cancel all producer tasks, preventing wasted work
    # - No exception propagates to the controller for client disconnects
    def drain_streams_concurrently(parent_task)
      client_disconnected = false

      writing_task = parent_task.async do
        # Drain all remaining chunks from the queue to the response stream
        while (chunk = @main_output_queue.dequeue)
          response.stream.write(chunk)
        end
      rescue IOError, Errno::EPIPE => e
        # Client disconnected - stop writing gracefully
        client_disconnected = true
        log_client_disconnect("writer", e)
      end

      # Wait for all component streaming tasks to complete
      begin
        @async_barrier.wait
      rescue StandardError => e
        @async_barrier.stop
        raise e
      end
    ensure
      # Close the queue first to unblock writing_task (it may be waiting on dequeue)
      @main_output_queue.close

      # Wait for writing_task to ensure client_disconnected flag is set
      # before we check it (fixes race condition where ensure runs before
      # writing_task's rescue block sets the flag)
      writing_task.wait

      # If client disconnected, stop all producer tasks to avoid wasted work
      @async_barrier.stop if client_disconnected
    end

    def log_client_disconnect(context, exception)
      return unless ReactOnRails.configuration.logging_on_server

      Rails.logger.debug do
        "[React on Rails Pro] Client disconnected during streaming (#{context}): #{exception.class}"
      end
    end
  end
end
