# frozen_string_literal: true

require "json"

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

    # The six-character JSON escape for U+FFFD, emitted for a lone surrogate.
    # Kept as an ASCII escape (not a literal multibyte char) so sanitized output
    # stays valid regardless of the input string's encoding, which may be binary.
    REPLACEMENT_CHAR_ESCAPE = '\ufffd'
    FOUR_HEX_DIGITS = /\A[0-9a-fA-F]{4}\z/
    private_constant :REPLACEMENT_CHAR_ESCAPE, :FOUR_HEX_DIGITS

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

    # Parses JSON emitted by JavaScript's JSON.stringify, tolerating one Unicode
    # divergence that would otherwise crash SSR.
    #
    # JavaScript strings are UTF-16 and JSON.stringify happily emits unpaired
    # surrogate escapes (e.g. a lone high surrogate "\ud83d" from corrupted user
    # data, DB encoding issues, or API responses). Ruby's JSON.parse rejects a
    # lone HIGH surrogate with "incomplete surrogate pair", so JS output that the
    # browser would render fine (as U+FFFD) crashes the whole Ruby-side render.
    #
    # To keep React on Rails a general-purpose framework that passes content
    # through instead of crashing, we retry the parse ONCE with unpaired
    # surrogates replaced by the U+FFFD replacement character. The retry runs
    # only after a JSON::ParserError, so the happy path pays nothing. If the
    # sanitized string still fails to parse, the (second) JSON::ParserError
    # propagates so genuinely malformed JSON is still surfaced to callers.
    def self.parse_json_lenient(str)
      JSON.parse(str)
    rescue JSON::ParserError
      JSON.parse(sanitize_unpaired_surrogates(str))
    end

    # Replaces only genuinely LONE \uXXXX surrogate escapes with the U+FFFD
    # replacement escape, leaving everything else byte-for-byte intact.
    #
    # This walks the string left to right rather than using a global regex so it
    # gets three things right that a naive gsub does not:
    #   * Backslash parity — a "\u..." is a real escape only when the backslash
    #     before "u" is itself unescaped. In "\\uD83D" the backslash is escaped,
    #     so "uD83D" is literal text and must not be rewritten. Consuming "\\" as
    #     one unit makes the following "u" an ordinary character.
    #   * Pairing — a high surrogate (U+D800..U+DBFF) is kept only when it is
    #     immediately followed by a low surrogate (U+DC00..U+DFFF); the valid pair
    #     passes through untouched. A high surrogate followed by anything else, and
    #     a low surrogate not preceded by a high one, are lone and replaced.
    #   * No over-consumption — a non-surrogate escape (e.g. "A") is never
    #     swallowed as part of a pair.
    #
    # The replacement is an ASCII \u escape (not a literal multibyte char) so the
    # output stays valid regardless of the input string's encoding, which may be
    # binary. Best-effort recovery for already-malformed input, so it runs only on
    # the JSON::ParserError retry path and never on the happy path.
    def self.sanitize_unpaired_surrogates(str)
      out = String.new(encoding: str.encoding)
      index = 0
      length = str.length

      while index < length
        chunk, advance = next_sanitized_token(str, index, length)
        out << chunk
        index += advance
      end

      out
    end

    # Returns [text_to_emit, characters_consumed] for the token at +index+.
    def self.next_sanitized_token(str, index, length)
      code = unicode_escape_codepoint(str, index, length)
      return non_escape_token(str, index, length) if code.nil?
      return surrogate_token(str, index, length, code) if code.between?(0xD800, 0xDFFF)

      [str[index, 6], 6] # ordinary non-surrogate \uXXXX escape
    end
    private_class_method :next_sanitized_token

    # A "\X" escape is consumed as one unit so an escaped backslash can't be
    # misread as the start of a \u escape; any other character is verbatim.
    def self.non_escape_token(str, index, length)
      return [str[index, 2], 2] if str[index] == "\\" && index + 1 < length

      [str[index], 1]
    end
    private_class_method :non_escape_token

    # A high surrogate is kept only when immediately followed by a low surrogate;
    # otherwise it (or a lone low surrogate) becomes the U+FFFD replacement escape.
    def self.surrogate_token(str, index, length, code)
      if code.between?(0xD800, 0xDBFF)
        low = unicode_escape_codepoint(str, index + 6, length)
        return [str[index, 12], 12] if low&.between?(0xDC00, 0xDFFF)
      end

      [REPLACEMENT_CHAR_ESCAPE, 6]
    end
    private_class_method :surrogate_token

    # Returns the codepoint of a genuine six-character \uXXXX escape starting at
    # +index+, or nil when +index+ does not begin one. Callers reach this position
    # only after two-character "\X" escapes have been consumed as a unit, so a
    # leading backslash here is always unescaped (odd backslash parity).
    def self.unicode_escape_codepoint(str, index, length)
      return nil unless index + 6 <= length
      return nil unless str[index] == "\\" && str[index + 1] == "u"

      hex = str[index + 2, 4]
      return nil unless hex.match?(FOUR_HEX_DIGITS)

      hex.to_i(16)
    end
    private_class_method :unicode_escape_codepoint

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
        @metadata = self.class.parse_json_lenient(meta_json.force_encoding(Encoding::UTF_8))
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
      self.class.parse_json_lenient(raw_content)
    rescue JSON::ParserError
      raise ParseError, "Malformed length-prefixed object payload JSON", cause: nil
    end
  end
end
