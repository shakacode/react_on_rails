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
        require "async"
        require "async/queue"
        require "async/semaphore"

        Sync do |parent|
          queue = Async::Queue.new
          semaphore = Async::Semaphore.new(64)
          remaining = @rorp_rendering_fibers.size

          unless remaining.zero?
            tasks = []
            @rorp_rendering_fibers.each_with_index do |fiber, idx|
              tasks << parent.async do
                begin
                  while (chunk = fiber.resume)
                    semaphore.acquire { queue.enqueue([idx, chunk]) }
                  end
                rescue StandardError => e
                  semaphore.acquire { queue.enqueue([idx, "<!-- stream error: #{e.class}: #{e.message} -->"]) } # minimal signal
                ensure
                  queue.enqueue([idx, :__done__])
                end
              end
            end

            writer = parent.async do
              loop do
                _idx, item = queue.dequeue
                if item == :__done__
                  remaining -= 1
                  break if remaining.zero?
                  next
                end
                Rails.logger.info { "[ReactOnRailsPro] stream write (mode=concurrent) idx=#{_idx} bytes=#{item.bytesize}" } if ReactOnRailsPro.configuration.tracing
                begin
                  response.stream.write(item)
                rescue IOError, ActionController::Live::ClientDisconnected
                  # Client disconnected: stop early.
                  break
                ensure
                  semaphore.release
                end
              end
            end

            tasks.each(&:wait)
            writer.wait
          end
        end
        response.stream.close if close_stream_at_end
      else
        @rorp_rendering_fibers.each_with_index do |fiber, idx|
          loop do
            begin
              chunk = fiber.resume
            rescue FiberError
              break
            end
            break unless chunk
            Rails.logger.info { "[ReactOnRailsPro] stream write (mode=sequential) idx=#{idx} bytes=#{chunk.bytesize}" } if ReactOnRailsPro.configuration.tracing
            response.stream.write(chunk)
          end
        end
        response.stream.close if close_stream_at_end
      end
    end
  end
end
