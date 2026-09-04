# frozen_string_literal: true

require "json"
require "react_on_rails/lenient_json"

module ReactOnRails
  # Parses the length-prefixed wire format used between Node renderer and Ruby.
  #
  # Wire format per chunk:
  #   <metadata JSON>\t<content byte length hex>\n<raw content bytes>
  #
  # Used by both streaming (Pro) and non-streaming (OSS) paths.
  # Strict protocol parser — any format violation raises an error.
  class LengthPrefixedParser
    class ParseError < ReactOnRails::Error; end

    # Keep aligned with ReactOnRailsPro::StreamRequest::CONTROL_MESSAGE_TYPES,
    # which routes these same control frames during bidirectional streaming.
    # MIRROR VALUES OF: react_on_rails_pro/lib/react_on_rails_pro/stream_request.rb
    # MIRROR VALUES OF: packages/react-on-rails-pro-node-renderer/src/worker/streamingUtils.ts
    CONTROL_MESSAGE_TYPES = %w[propRequest renderComplete].freeze
    # MIRROR VALUES END
    private_constant :CONTROL_MESSAGE_TYPES

    # Parses a complete length-prefixed result string that must contain exactly one chunk.
    # Used by the non-streaming rendering path where ExecJS/node renderer returns a single result.
    # Returns a single Hash: { "html" => String|nil, "consoleReplayScript" => "...", ... }
    # Raises if the input contains zero or more than one chunk.
    def self.parse_one_chunk_result(str)
      parser = new
      results = []
      parser.feed(str.to_s.b) { |chunk| results << chunk }
      if results.empty?
        raise ParseError,
              "Malformed render result: expected exactly one length-prefixed chunk but found none"
      end
      if results.size > 1
        raise ParseError,
              "Malformed render result: expected exactly one length-prefixed chunk but found #{results.size}"
      end
      results.first
    end

    def initialize
      # Binary encoding ensures correct byte-position arithmetic regardless of payload encoding.
      # Now that Ruby 3.3+ is required, byteindex makes byte semantics explicit instead of
      # relying on binary-encoded index for positional equivalence.
      # force_encoding is O(1) (flips a flag, no copy). .b allocates a new object but
      # shares the byte buffer via copy-on-write for strings over ~23 bytes.
      @buf = "".b
      @state = :header
      @content_len = 0
      @metadata = nil
    end

    # Appends bytes to buffer and yields complete chunks as they become available.
    # Yields Hash: { "html" => content, ...metadata }
    # Raises on protocol errors (bad JSON, bad hex, missing tab).
    # After an error, the parser enters :error state and all subsequent calls are no-ops.
    def feed(chunk, &block)
      return if @state == :error

      @buf << (chunk.encoding == Encoding::BINARY ? chunk : chunk.b)

      loop do
        case @state
        when :header
          break unless try_parse_header(&block)
        when :content
          break unless try_read_content(&block)
        end
      end
    rescue StandardError
      @state = :error
      raise
    end

    # Called when the stream ends to detect truncated responses.
    # Logs a warning if the buffer still has unconsumed bytes (partial header or content).
    def flush
      return if @state == :header && @buf.empty?

      Rails.logger.warn(
        "[react_on_rails] Incomplete length-prefixed stream: " \
        "#{@buf.bytesize} bytes remaining in state :#{@state}"
      )
    end

    # True if the parser encountered a protocol error.
    def error?
      @state == :error
    end

    private

    def try_parse_header
      idx = @buf.byteindex("\n".b)
      return false unless idx

      header = @buf.byteslice(0, idx)
      @buf = @buf.byteslice(idx + 1, @buf.bytesize - idx - 1)

      tab_idx = header.byteindex("\t".b)
      raise ParseError, "Malformed length-prefixed header: missing tab separator" unless tab_idx

      parse_length_prefixed_header(header, tab_idx)
      true
    end

    def parse_length_prefixed_header(header, tab_idx)
      meta_json = header.byteslice(0, tab_idx)
      len_hex = header.byteslice(tab_idx + 1, header.bytesize - tab_idx - 1)

      begin
        @content_len = Integer(len_hex, 16)
      rescue ArgumentError
        raise ParseError, "Malformed length-prefixed header: invalid content length hex", cause: nil
      end
      raise ParseError, "Malformed length-prefixed header: negative content length" if @content_len.negative?

      begin
        # LenientJson tolerates lone UTF-16 surrogates that the JS renderer can emit
        # (e.g. from truncating a string mid-emoji) which stock JSON.parse rejects. See #4710.
        @metadata = LenientJson.parse(meta_json.force_encoding(Encoding::UTF_8))
      rescue JSON::ParserError
        raise ParseError, "Malformed length-prefixed header: invalid metadata JSON", cause: nil
      end
      raise ParseError, "Malformed length-prefixed header: metadata JSON must be an object" unless @metadata.is_a?(Hash)

      @state = :content
    end

    def try_read_content
      return false if @buf.bytesize < @content_len

      raw_content = @buf.byteslice(0, @content_len).force_encoding(Encoding::UTF_8)
      @buf = @buf.byteslice(@content_len, @buf.bytesize - @content_len)

      # Control messages (propRequest, renderComplete) have no HTML payload;
      # raw_content is therefore empty and intentionally unused. Those two
      # messageType values are reserved by the wire format. Other messageType
      # metadata is treated as ordinary chunk metadata so future tracing or
      # diagnostics annotations cannot be swallowed accidentally.
      if CONTROL_MESSAGE_TYPES.include?(@metadata["messageType"])
        @metadata.delete("payloadType")
        result = @metadata
        @metadata = nil
        @state = :header
        yield result
        return true
      end

      # Reconstruct html type based on payloadType:
      #   "object" → JSON-serialized value (ServerRenderHash or null), needs JSON.parse
      #   "string" → raw HTML string, used as-is
      payload_type = @metadata.delete("payloadType")
      @metadata["html"] = payload_type == "object" ? parse_object_payload(raw_content) : raw_content

      result = @metadata
      @metadata = nil
      @state = :header
      yield result
      true
    end

    def parse_object_payload(raw_content)
      # See the metadata parse above: LenientJson repairs lone-surrogate escapes (#4710).
      LenientJson.parse(raw_content)
    rescue JSON::ParserError
      raise ParseError, "Malformed length-prefixed object payload JSON", cause: nil
    end
  end
end
