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

      if ReactOnRailsPro.configuration.concurrent_stream_drain
        drain_streams_concurrently
      else
        drain_streams_sequentially
      end
      response.stream.close if close_stream_at_end
    end

    private

    def drain_streams_concurrently
      require "async"
      require "async/queue"
      require "async/semaphore"

      return if @rorp_rendering_fibers.empty?

      Sync do |parent|
        queue = Async::Queue.new
        capacity = ReactOnRailsPro.configuration.concurrent_stream_queue_capacity
        # Clamp capacity to minimum of 1 to prevent invalid semaphore initialization
        capacity = 1 if capacity && capacity < 1
        semaphore = Async::Semaphore.new(capacity || Configuration::DEFAULT_CONCURRENT_STREAM_QUEUE_CAPACITY)

        writer = build_writer_task(parent: parent, queue: queue, semaphore: semaphore)
        tasks = build_producer_tasks(parent: parent, queue: queue, semaphore: semaphore)

        begin
          tasks.each(&:wait)
        ensure
          # `close` signals end-of-stream; when writer tries to dequeue, it will get nil, so it will exit.
          queue.close
        end
        writer.wait
      end
    end

    def build_producer_tasks(parent:, queue:, semaphore:)
      @rorp_rendering_fibers.each_with_index.map do |fiber, idx|
        parent.async do
          while (chunk = fiber.resume)
            # We use `acquire` and not `async` to create backpressure.
            # A simple comparison:
            # - `acquire`: Blocks this fiber until a permit is free -> forces backpressure.
            # - `async`:   Schedules the work and continues immediately -> defeats backpressure
            #              by buffering all chunks in memory.
            semaphore.acquire { queue.enqueue([idx, chunk]) }
          end
        rescue StandardError => e
          error_msg = "<!-- stream error: #{e.class}: #{e.message} -->"
          semaphore.acquire { queue.enqueue([idx, error_msg]) } # minimal signal
        end
      end
    end

    def build_writer_task(parent:, queue:, semaphore:)
      parent.async do
        loop do
          pair = queue.dequeue
          break if pair.nil?
          idx_from_queue, item = pair
          log_stream_write(mode: :concurrent, idx: idx_from_queue, bytesize: safe_bytesize(item))
          begin
            response.stream.write(item)
          rescue IOError, ActionController::Live::ClientDisconnected
            break
          ensure
            semaphore.release
          end
        end
      end
    end

    def drain_streams_sequentially
      @rorp_rendering_fibers.each_with_index do |fiber, idx|
        loop do
          begin
            chunk = fiber.resume
          rescue FiberError
            break
          end
          break unless chunk

          log_stream_write(mode: :sequential, idx: idx, bytesize: safe_bytesize(chunk))
          response.stream.write(chunk)
        end
      end
    end

    def log_stream_write(mode:, idx:, bytesize:)
      return unless ReactOnRailsPro.configuration.tracing

      message = "[ReactOnRailsPro] stream write (mode=#{mode}) idx=#{idx} bytes=#{bytesize}"
      Rails.logger.info { message }
    end

    def safe_bytesize(obj)
      obj.respond_to?(:bytesize) ? obj.bytesize : obj.to_s.bytesize
    end
  end
end
