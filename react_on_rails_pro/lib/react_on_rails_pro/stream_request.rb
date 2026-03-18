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
    def initialize(&request_block)
      @request_executor = request_block
    end

    private_class_method :new

    def each_chunk(&block)
      return enum_for(:each_chunk) unless block

      Sync do
        barrier = Async::Barrier.new

        send_bundle = false
        error_body = +""
        loop do
          stream_response = @request_executor.call(send_bundle, barrier)

          # Chunks can be merged during streaming, so we separate them by newlines
          # Also, we check the status code inside the loop block because calling `status` outside the loop block
          # is blocking, it will wait for the response to be fully received
          # Look at the spec of `status` in `spec/react_on_rails_pro/stream_spec.rb` for more details
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

    private

    def process_response_chunks(stream_response, error_body)
      loop_response_chunks(stream_response) do |chunk|
        if response_has_error_status?(stream_response)
          error_body << chunk.to_s
          next
        end

        # Hashes (length-prefixed) are yielded as-is.
        # Strings (plain text from error or edge cases) are stripped and skipped if empty.
        if chunk.is_a?(String)
          stripped = chunk.strip
          yield stripped unless stripped.empty?
        else
          yield chunk
        end
      end
    end

    def response_has_error_status?(response)
      return true if response.is_a?(HTTPX::ErrorResponse)

      response.status >= 400
    rescue NoMethodError
      # HTTPX::StreamResponse can fail to delegate #status for non-streaming errors.
      true
    end

    def handle_http_error(error, error_body, send_bundle)
      response = error.response
      case response.status
      when ReactOnRailsPro::STATUS_SEND_BUNDLE
        # To prevent infinite loop
        ReactOnRailsPro::Error.raise_duplicate_bundle_upload_error if send_bundle

        true
      when ReactOnRailsPro::STATUS_INCOMPATIBLE
        raise ReactOnRailsPro::Error, error_body
      else
        raise ReactOnRailsPro::Error, "Unexpected response code from renderer: #{response.status}:\n#{error_body}"
      end
    end

    # Method to start the decoration
    def self.create(&request_block)
      StreamDecorator.new(new(&request_block))
    end

    # Reads streaming response chunks using the length-prefixed protocol.
    #
    # Wire format per chunk: <metadata JSON>\t<content byte length hex>\n<raw content bytes>
    # Yields Hash: { "html" => "<raw content>", "consoleReplayScript" => "...", ... }
    #
    # For error responses (plain text without \t), yields raw strings.
    #
    # The length-prefixed format avoids JSON.stringify on the HTML content (the bulk
    # of the data), eliminating ~30% escaping overhead for typical payloads.
    def loop_response_chunks(response, &block)
      return enum_for(__method__, response) unless block

      parser = LengthPrefixedParser.new
      response.each do |chunk|
        response.instance_variable_set(:@react_on_rails_received_first_chunk, true)
        parser.feed(chunk, &block)
      end
    ensure
      parser&.flush(&block)
    end

    # State machine parser for the length-prefixed streaming protocol.
    # Buffers incoming bytes and yields complete chunks (Hash for length-prefixed,
    # String for plain text error responses).
    class LengthPrefixedParser
      def initialize
        @buf = "".b
        @state = :header
        @content_len = 0
        @metadata = nil
      end

      def feed(chunk)
        @buf << chunk

        loop do
          case @state
          when :header
            break unless (result = try_parse_header)

            yield result if result.is_a?(String) # Plain text line (error response)
          when :content
            break unless (result = try_read_content)

            yield result
          end
        end
      end

      def flush
        case @state
        when :content
          # Stream ended mid-content — don't yield truncated HTML.
          # The missing bytes indicate a connection drop or renderer crash.
          # The error will surface via HTTPX error handling in each_chunk.
          nil
        when :header
          yield @buf.force_encoding("UTF-8") unless @buf.empty?
        end
      end

      private

      def try_parse_header
        idx = @buf.index("\n")
        return nil unless idx

        header = @buf.byteslice(0, idx)
        @buf = @buf.byteslice(idx + 1, @buf.bytesize - idx - 1) || "".b
        tab_idx = header.index("\t")

        if tab_idx
          parse_length_prefixed_header(header, tab_idx)
          true # Signal state changed to :content; no value to yield
        else
          line = header.force_encoding("UTF-8")
          line.strip.empty? ? true : line
        end
      end

      def parse_length_prefixed_header(header, tab_idx)
        meta_json = header.byteslice(0, tab_idx)
        len_hex = header.byteslice(tab_idx + 1, header.bytesize - tab_idx - 1)
        @metadata = JSON.parse(meta_json.force_encoding("UTF-8"))
        @content_len = len_hex.to_i(16)
        @state = :content
      end

      def try_read_content
        return nil if @buf.bytesize < @content_len

        # When content length is 0, set html to nil (preserves null semantics from JS)
        html = if @content_len.positive?
                 content = @buf.byteslice(0, @content_len)
                 @buf = @buf.byteslice(@content_len, @buf.bytesize - @content_len) || "".b
                 content.force_encoding("UTF-8")
               end
        result = { "html" => html }.merge!(@metadata)
        @metadata = nil
        @state = :header
        result
      end
    end
  end
end
