# frozen_string_literal: true

require "zlib"

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
    # @param compress [Boolean] Enables gzip-compressed streaming when the client accepts gzip (default: false).
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
    def stream_view_containing_react_components(template:, close_stream_at_end: true, compress: false, **render_options)
      require "async"
      require "async/barrier"
      require "async/limited_queue"

      Sync do |parent_task|
        # Initialize async primitives for concurrent component streaming
        @async_barrier = Async::Barrier.new
        buffer_size = ReactOnRailsPro.configuration.concurrent_component_streaming_buffer_size
        @main_output_queue = Async::LimitedQueue.new(buffer_size)
        gzip_streaming_enabled = gzip_streaming_enabled?(compress)
        if gzip_streaming_enabled && !close_stream_at_end
          raise ArgumentError, "compress: true requires close_stream_at_end: true to finalize gzip footer"
        end

        # Render template - components will start streaming immediately.
        # If a shell error occurs, consumer_stream_async raises PrerenderError here
        # (BEFORE the response is committed), enabling a proper HTTP redirect.
        template_string = render_to_string(template: template, **render_options)
        output_stream = setup_output_stream(gzip_streaming_enabled: gzip_streaming_enabled)
        # View may contain extra newlines, chunk already contains a newline
        # Having multiple newlines between chunks causes hydration errors
        # So we strip extra newlines from the template string and add a single newline
        output_stream.write(template_string)

        drain_streams_concurrently(parent_task, output_stream: output_stream)
        # Do not close the response stream in an ensure block.
        # If an error occurs we may need the stream open to send diagnostic/error details
        # (for example, ApplicationController#rescue_from in the dummy app).
        output_stream.close if close_stream_at_end
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
    def drain_streams_concurrently(parent_task, output_stream:)
      client_disconnected = false

      writing_task = parent_task.async do
        # Drain all remaining chunks from the queue to the response stream
        while (chunk = @main_output_queue.dequeue)
          output_stream.write(chunk)
        end
      rescue IOError, Errno::EPIPE => e
        # Client disconnected - stop writing gracefully
        client_disconnected = true
        log_client_disconnect("writer", e)
        # `Async` does not yield between setting the flag and stopping the barrier.
        # This guarantees the rescue path can observe `client_disconnected == true`.
        @async_barrier.stop
      end

      # Wait for all component streaming tasks to complete
      begin
        @async_barrier.wait
      rescue StandardError => e
        @async_barrier.stop
        raise e unless client_disconnected

        log_client_disconnect("barrier", e, level: :warn)
        nil
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

    def log_client_disconnect(context, exception, level: :debug)
      return unless ReactOnRails.configuration.logging_on_server

      Rails.logger.public_send(level) do
        "[React on Rails Pro] Client disconnected during streaming (#{context}): " \
          "#{exception.class}: #{exception.message}"
      end
    end

    def setup_output_stream(gzip_streaming_enabled:)
      return response.stream unless gzip_streaming_enabled

      prepare_gzip_streaming_headers
      GzipOutputStream.new(response.stream)
    end

    def gzip_streaming_enabled?(compress)
      return false unless compress

      content_encoding = response.headers["Content-Encoding"].to_s
      content_encoding_values = content_encoding.split(",").map { |value| value.downcase.strip }.reject(&:blank?)
      return false if content_encoding_values.present? && content_encoding_values != ["identity"]
      return false unless request_accepts_gzip?

      true
    end

    def request_accepts_gzip?
      accept_encoding = request&.get_header("HTTP_ACCEPT_ENCODING").to_s
      return false if accept_encoding.blank?

      parsed_accept_encoding = parse_accept_encoding(accept_encoding)
      wildcard_quality = parsed_accept_encoding["*"]
      gzip_quality = parsed_accept_encoding.fetch("gzip", wildcard_quality || 0.0)
      identity_quality = parsed_accept_encoding.fetch("identity", wildcard_quality || 1.0)

      gzip_quality.positive? && gzip_quality >= identity_quality
    rescue ArgumentError
      false
    end

    def parse_accept_encoding(accept_encoding)
      accept_encoding.split(",").each_with_object({}) do |entry, parsed|
        token, quality = parse_accept_encoding_entry(entry)
        next if token.blank?

        parsed[token] ||= quality
      end
    end

    def parse_accept_encoding_entry(entry)
      token, *params = entry.split(";").map(&:strip)
      return ["", 1.0] if token.blank?

      [token.downcase, parse_accept_encoding_quality(params)]
    end

    def parse_accept_encoding_quality(params)
      params.each do |param|
        key, value = param.split("=", 2).map(&:strip)
        next unless key&.casecmp?("q")

        return Float(value)
      end

      1.0
    end

    def prepare_gzip_streaming_headers
      headers = response.headers
      headers["Content-Encoding"] = "gzip"
      headers.delete("Content-Length")

      vary_values = headers["Vary"].to_s.split(",").map(&:strip).reject(&:empty?)
      return if vary_values.include?("*") || vary_values.any? { |value| value.casecmp?("Accept-Encoding") }

      vary_values << "Accept-Encoding"
      headers["Vary"] = vary_values.join(", ")
    end

    class GzipOutputStream
      class WriterAdapter
        def initialize(stream)
          @stream = stream
        end

        def write(data)
          @stream.write(data)
          data.bytesize
        end

        def close; end
      end

      def initialize(stream)
        @stream = stream
        @gzip_writer = Zlib::GzipWriter.new(WriterAdapter.new(stream))
        @closed = false
      end

      def write(data)
        bytes_written = @gzip_writer.write(data)
        @gzip_writer.flush(Zlib::SYNC_FLUSH)
        bytes_written
      end

      def closed?
        @closed
      end

      def close
        return if @closed

        @closed = true

        begin
          @gzip_writer.close
        rescue IOError, Errno::EPIPE
          # Client disconnected while finalizing gzip footer.
        ensure
          begin
            @stream.close
          rescue IOError, Errno::EPIPE
            # Stream already disconnected.
          end
        end
      end
    end
  end
end
