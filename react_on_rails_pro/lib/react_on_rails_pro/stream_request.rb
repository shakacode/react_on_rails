# frozen_string_literal: true

require "async"
require "async/barrier"

module ReactOnRailsPro
  class StreamDecorator
    def initialize(component)
      @component = component
      # @type [Array[Proc]]
      # Proc receives 2 arguments: chunk, position
      # @param chunk [String] The chunk to be processed
      # @param position [Symbol] The position of the chunk in the stream (:first, :middle, or :last)
      # The position parameter is used by actions that add content to the beginning or end of the stream
      @actions = [] # List to store all actions
      @rescue_blocks = []
    end

    def status
      http_status
    end

    def http_status
      return @component.http_status if @component.respond_to?(:http_status)
      return @component.status if @component.respond_to?(:status)

      nil
    end

    def http_status_recorded?
      return @component.http_status_recorded? if @component.respond_to?(:http_status_recorded?)
      return @component.status_recorded? if @component.respond_to?(:status_recorded?)

      # Cached/decorated stream components may expose only #each_chunk; their
      # status is unknown until they opt into the status metadata API.
      return false unless @component.respond_to?(:http_status) || @component.respond_to?(:status)

      !http_status.nil?
    end

    alias status_recorded? http_status_recorded?

    # Add a prepend action
    def prepend
      @actions << ->(chunk, position) { position == :first ? "#{yield}#{chunk}" : chunk }
      self # Return self to allow chaining
    end

    # Add a transformation action
    def transform
      @actions << lambda { |chunk, position|
        if position == :last && chunk.empty?
          # Return the empty chunk without modification for the last chunk
          # This is related to the `handleChunk(:last, "")` call which gets all the appended content
          # We don't want to make an extra call to the transformer block if there is no content appended
          chunk
        else
          yield(chunk)
        end
      }
      self # Return self to allow chaining
    end

    # Add an append action
    def append
      @actions << ->(chunk, position) { position == :last ? "#{chunk}#{yield}" : chunk }
      self # Return self to allow chaining
    end

    def rescue(&block)
      @rescue_blocks << block
      self # Return self to allow chaining
    end

    def handle_chunk(chunk, position)
      @actions.reduce(chunk) do |acc, action|
        action.call(acc, position)
      end
    end

    def each_chunk(&block) # rubocop:disable Metrics/CyclomaticComplexity
      return enum_for(:each_chunk) unless block

      first_chunk = true
      @component.each_chunk do |chunk|
        position = first_chunk ? :first : :middle
        modified_chunk = handle_chunk(chunk, position)
        yield(modified_chunk)
        first_chunk = false
      end

      # The last chunk contains the append content after the transformation
      # All transformations are applied to the append content
      last_chunk = handle_chunk("", :last)
      yield(last_chunk) unless last_chunk.empty?
    rescue StandardError => e
      current_error = e
      rescue_block_index = 0
      while current_error.present? && (rescue_block_index < @rescue_blocks.size)
        begin
          @rescue_blocks[rescue_block_index].call(current_error, &block)
          current_error = nil
        rescue StandardError => inner_error
          current_error = inner_error
        end
        rescue_block_index += 1
      end
      raise current_error if current_error.present?
    end
  end

  class StreamRequest
    HTTPX_STATUS_ARGUMENT_ERROR_MAX_VERSION = Gem::Version.new("1.7.0")

    # nil means either no response has been read yet or HTTPX could not expose
    # the status; use http_status_recorded? to distinguish those states.
    def http_status
      @status
    end

    def http_status_recorded?
      @status_recorded
    end

    alias status http_status
    alias status_recorded? http_status_recorded?

    def initialize(&request_block)
      @request_executor = request_block
      @status = nil
      @status_recorded = false
    end

    private_class_method :new

    def each_chunk(&block)
      return enum_for(:each_chunk) unless block

      Sync do
        barrier = Async::Barrier.new

        send_bundle = false
        error_body = +""
        loop do
          # Reset before request_executor.call as well as before parsing, since
          # transport failures can happen before a response object exists.
          reset_response_attempt!(error_body)
          stream_response = @request_executor.call(send_bundle, barrier)

          # The Node renderer always emits the length-prefixed wire format
          # (`<metadata JSON>\t<content byte length hex>\n<raw content bytes>`)
          # for every response chunk — both the one-shot streaming path and the
          # incremental-rendering path. We read the status once after the first
          # chunk to avoid blocking before streaming starts. Empty-body responses
          # are handled after iteration so callers can still inspect the status.
          process_response_chunks(stream_response, error_body, &block)
          break
        rescue HTTPX::HTTPError => e
          send_bundle = handle_http_error(e, error_body, send_bundle)
        rescue HTTPX::ReadTimeoutError => e
          raise ReactOnRailsPro::Error, "Time out error while server side render streaming a component.\n" \
                                        "Original error:\n#{e}\n#{e.backtrace}"
        end

        barrier.wait
      end
    end

    # Method to start the decoration
    def self.create(&request_block)
      StreamDecorator.new(new(&request_block))
    end

    private

    def process_response_chunks(stream_response, error_body, &block)
      parser = ReactOnRails::LengthPrefixedParser.new
      reset_response_attempt!(error_body)
      status_read_for_attempt = false
      stream_response.each do |chunk|
        stream_response.instance_variable_set(:@react_on_rails_received_first_chunk, true)
        unless status_read_for_attempt
          record_status(stream_response)
          status_read_for_attempt = true
        end

        if response_has_error_status?
          error_body << chunk
          next
        end

        parser.feed(chunk, &block)
      end
      # Empty-body responses record status after the stream is drained; specs
      # assert that status is read only after the response has yielded no chunks.
      record_status(stream_response) unless status_read_for_attempt
      # If status is nil, every chunk went to error_body via response_has_error_status?,
      # so the parser has not received data and flushing it would be a no-op.
      raise_unreadable_stream_response!(error_body)
      parser.flush
    end

    def reset_response_attempt!(error_body)
      # Each streaming response attempt owns its status; a 410 retry must not
      # reuse the previous attempt's recorded state.
      # Error bodies are attempt-local too, so unreadable-status diagnostics do
      # not report bytes buffered by an earlier failed attempt.
      @status = nil
      @status_recorded = false
      error_body.clear
    end

    # StreamRequest is consumed sequentially. Status intentionally reflects the
    # latest response attempt, so a 410 retry replaces the pre-retry status.
    def record_status(response)
      # reset_response_attempt! pre-clears @status to nil. If extract_status
      # raises, this assignment does not complete and the attempt remains
      # recorded with nil status.
      @status = extract_status(response)
    ensure
      # If status extraction itself fails, callers should treat the unknown
      # status as an error response rather than as "status was never read."
      @status_recorded = true
    end

    # Missing or unreadable status is treated as an error so callers do not
    # parse an unknown response body as LPP data.
    def response_has_error_status?
      # Guard: status must be recorded before any body chunk is parsed.
      return true unless @status_recorded

      @status.nil? || @status >= 400
    end

    def extract_status(response)
      return nil if response.is_a?(HTTPX::ErrorResponse)

      response.status
    rescue NoMethodError => e
      # NoMethodError: HTTPX::StreamResponse can fail to delegate #status before
      # request.response is available for non-streaming errors.
      warn_status_read_failure("ignoring error while reading stream response status", e)
      nil
    rescue ArgumentError => e
      warning_context = httpx_stream_status_argument_error_context(response)
      raise unless warning_context

      # ArgumentError: HTTPX 1.7.0 can raise while materializing status from a
      # partially-consumed StreamResponse; transport-level HTTPX::Error still
      # propagates. The nil fallback buffers this attempt as error_body instead
      # of parsing LPP, so verify 200-response behavior before removing it.
      # TODO: remove ArgumentError rescue once the minimum HTTPX version is
      # greater than 1.7.0 and status reads from partially-consumed stream
      # responses are verified not to raise ArgumentError.
      warn_status_read_failure(warning_context, e)
      nil
    end

    def handle_http_error(error, error_body, send_bundle)
      response = error.response
      # Public status intentionally reflects the HTTP error response that ended
      # this attempt, not any intermediate streaming status from a prior attempt.
      @status = nil
      @status_recorded = false
      begin
        record_status(response)
      rescue StandardError => e
        # response#status adapters can still raise unexpected StandardError
        # subclasses; specs cover RuntimeError. Keep the renderer body attached
        # to that failure instead of continuing with stale or unreadable status.
        warn_status_read_failure(
          "ignoring unexpected error while reading HTTP error response status",
          e
        )
        body_context = error_body.empty? ? "" : ":\n#{error_body}"
        raise ReactOnRailsPro::Error,
              "Renderer returned an unreadable HTTP error response (#{e.class}: #{e.message})#{body_context}"
      end
      case @status
      when ReactOnRailsPro::STATUS_SEND_BUNDLE
        # To prevent infinite loop
        ReactOnRailsPro::Error.raise_duplicate_bundle_upload_error if send_bundle

        true
      when ReactOnRailsPro::STATUS_BAD_REQUEST
        raise ReactOnRailsPro::Error,
              "Renderer rejected malformed request or hit an unhandled VM error: " \
              "#{@status}:\n#{error_body}"
      when ReactOnRailsPro::STATUS_INCOMPATIBLE
        raise ReactOnRailsPro::Error, error_body
      else
        status_label = @status || "unknown"
        raise ReactOnRailsPro::Error, "Unexpected response code from renderer: #{status_label}:\n#{error_body}"
      end
    end

    def warn_status_read_failure(context, error)
      message = "[ReactOnRailsPro] #{context}: #{error.class}: #{error.message}"
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger.warn(message)
      else
        warn(message)
      end
    end

    def raise_unreadable_stream_response!(error_body)
      return unless @status_recorded && @status.nil? && !error_body.empty?

      raise ReactOnRailsPro::Error,
            "Renderer returned an unreadable stream response status after buffering #{error_body.bytesize} bytes"
    end

    def httpx_stream_status_argument_error_context(response)
      return unless defined?(HTTPX::StreamResponse) && response.is_a?(HTTPX::StreamResponse)

      httpx_spec = Gem.loaded_specs["httpx"]
      unless httpx_spec
        return "ignoring error while reading stream response status because loaded httpx version is unavailable"
      end

      return unless httpx_spec.version <= HTTPX_STATUS_ARGUMENT_ERROR_MAX_VERSION

      "ignoring error while reading stream response status"
    end
  end
end
