# frozen_string_literal: true

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
    def initialize(first_chunk_warn_callback: nil, &request_block)
      @request_executor = request_block
      @first_chunk_warn_callback = first_chunk_warn_callback
    end

    private_class_method :new

    # Method to start the decoration
    def self.create(first_chunk_warn_callback: nil, &request_block)
      StreamDecorator.new(new(first_chunk_warn_callback: first_chunk_warn_callback, &request_block))
    end

    def each_chunk(&block)
      return enum_for(:each_chunk) unless block

      send_bundle = false
      loop do
        error_body = +""
        stream_response = @request_executor.call(send_bundle)

        # The renderer emits the length-prefixed wire format documented in
        # ReactOnRails::LengthPrefixedParser; process_response_chunks feeds chunks
        # to that parser and yields the parsed Hash chunks downstream.
        process_response_chunks(stream_response, error_body, &block)
        break
      rescue ReactOnRailsPro::RendererHttpClient::HTTPError => e
        send_bundle = handle_http_error(e, error_body, send_bundle)
      rescue ReactOnRailsPro::RendererHttpClient::TimeoutError => e
        raise ReactOnRailsPro::Error, "Time out error while server side render streaming a component.\n" \
                                      "Original error:\n#{e}\n#{e.backtrace&.join("\n")}"
      rescue ReactOnRailsPro::RendererHttpClient::ConnectionError => e
        raise ReactOnRailsPro::Error, "An error happened during server side render streaming " \
                                      "of a component.\nOriginal error:\n#{e}\n#{e.backtrace&.join("\n")}"
      end
    end

    private

    def process_response_chunks(stream_response, error_body, &block)
      first_chunk_start_time = Time.now
      first_chunk_seen = false
      parser = ReactOnRails::LengthPrefixedParser.new

      stream_response.each do |chunk|
        unless first_chunk_seen
          @first_chunk_warn_callback&.call(Time.now - first_chunk_start_time)
          first_chunk_seen = true
        end

        if response_has_error_status?(stream_response)
          error_body << chunk
          next
        end

        parser.feed(chunk, &block)
      end
      parser.flush
    end

    def response_has_error_status?(response)
      return response.error? if response.respond_to?(:error?)

      # Future adapters without Response#error? must expose Response#status.
      unless response.respond_to?(:status)
        raise NotImplementedError, "#{response.class} must implement #error? or #status"
      end

      status = response.status
      !status.nil? && status >= 400
    end

    def handle_http_error(error, error_body, send_bundle)
      response = error.response
      case response.status
      when ReactOnRailsPro::STATUS_SEND_BUNDLE
        # To prevent infinite loop
        ReactOnRailsPro::Error.raise_duplicate_bundle_upload_error if send_bundle

        true
      when ReactOnRailsPro::STATUS_BAD_REQUEST
        raise ReactOnRailsPro::Error,
              "Renderer rejected malformed request or hit an unhandled VM error: " \
              "#{response.status}:\n#{error_body}"
      when ReactOnRailsPro::STATUS_INCOMPATIBLE
        raise ReactOnRailsPro::Error, error_body
      else
        raise ReactOnRailsPro::Error, "Unexpected response code from renderer: #{response.status}:\n#{error_body}"
      end
    end
  end
end
