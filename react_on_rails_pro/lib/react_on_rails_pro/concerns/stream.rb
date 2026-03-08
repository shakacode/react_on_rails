# frozen_string_literal: true

require "English"

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
    # @param content_type [String, nil] Optional response content type. Set after rendering but before the first
    #   stream write, overriding any content type inferred from the template format. When using
    #   a non-HTML `formats:` value (for example `[:text]`), pass `content_type` too unless
    #   committing the format-derived MIME type is intentional.
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
    def stream_view_containing_react_components(
      template:, close_stream_at_end: true, content_type: nil, **render_options
    )
      require "async"
      require "async/barrier"
      require "async/limited_queue"
      warn_on_non_html_formats_without_content_type(render_options[:formats], content_type)

      Sync do |parent_task|
        # Initialize async primitives for concurrent component streaming
        @async_barrier = Async::Barrier.new
        buffer_size = ReactOnRailsPro.configuration.concurrent_component_streaming_buffer_size
        @main_output_queue = Async::LimitedQueue.new(buffer_size)

        # Render template - components will start streaming immediately.
        # If a shell error occurs, consumer_stream_async raises PrerenderError here
        # (BEFORE the response is committed), enabling a proper HTTP redirect.
        template_string = render_to_string(template: template, **render_options)
        # View may contain extra newlines, chunk already contains a newline
        # Having multiple newlines between chunks causes hydration errors
        # So we strip extra newlines from the template string and add a single newline
        # `formats: [:text]` causes render_to_string to set response.content_type
        # to `text/plain`; override it here before the first stream write, which
        # is when ActionController::Live commits headers. render_to_string itself
        # never writes to response.stream, so this assignment is always safe.
        response.content_type = content_type if content_type
        response.stream.write(template_string)

        drain_streams_concurrently(parent_task)
        # Do not close the response stream in an ensure block.
        # If an error occurs we may need the stream open to send diagnostic/error details
        # (for example, ApplicationController#rescue_from in the dummy app).
        response.stream.close if close_stream_at_end
      rescue StandardError
        # Stop all streaming tasks to prevent leaked async work.
        # For pre-commit errors (e.g., shell error raised during render_to_string),
        # the barrier may still have pending tasks that must be cancelled.
        # For post-commit errors (from drain_streams_concurrently), the barrier
        # is already stopped inside that method — stopping again is a no-op.
        @async_barrier&.stop
        raise
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
      writing_task = parent_task.async do
        # Drain all remaining chunks from the queue to the response stream
        while (chunk = @main_output_queue.dequeue)
          response.stream.write(chunk)
        end
      rescue IOError, Errno::EPIPE => e
        # Client disconnected - stop writing gracefully
        log_client_disconnect("writer", e)
      ensure
        # Cancel all producers when writer exits for ANY reason (normal completion,
        # client disconnect, or unexpected error). Prevents deadlock where producers
        # block on enqueue to a full queue that nobody is consuming.
        # Idempotent — no-op if barrier tasks already completed.
        @async_barrier.stop
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

      # Capture the primary exception (if any) BEFORE entering begin/rescue.
      # Inside a rescue block, $ERROR_INFO is always the caught exception,
      # so we must snapshot it here where it reflects the propagating exception.
      primary_exception = $ERROR_INFO

      # Wait for writing_task to finish. Wrap in rescue to avoid masking a primary
      # exception (e.g., producer error) with a secondary writing_task exception.
      begin
        writing_task.wait
      rescue StandardError
        raise unless primary_exception
      end
    end

    def log_client_disconnect(context, exception)
      return unless ReactOnRails.configuration.logging_on_server

      Rails.logger.debug do
        "[React on Rails Pro] Client disconnected during streaming (#{context}): #{exception.class}"
      end
    end

    def warn_on_non_html_formats_without_content_type(formats, content_type)
      return if content_type.present?

      requested_formats = Array(formats).compact.map(&:to_sym)
      return if requested_formats.empty? || requested_formats.all?(:html)

      Rails.logger.warn(
        "[React on Rails Pro] stream_view_containing_react_components received non-HTML formats " \
        "#{requested_formats.inspect} without `content_type:`. Rails will commit the format-derived " \
        "MIME type (for example `text/plain` for `:text`). Pass `content_type:` explicitly when " \
        "streaming non-HTML responses."
      )
    end
  end
end
