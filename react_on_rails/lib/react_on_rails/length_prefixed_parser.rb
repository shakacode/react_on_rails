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
    # Parses a complete length-prefixed result string that must contain exactly one chunk.
    # Used by the non-streaming rendering path where ExecJS/node renderer returns a single result.
    # Returns a single Hash: { "html" => String|nil, "consoleReplayScript" => "...", ... }
    # Raises if the input contains zero or more than one chunk.
    def self.parse_one_chunk_result(str)
      parser = new
      results = []
      parser.feed(str.to_s.b) { |chunk| results << chunk }
      if results.empty?
        raise ReactOnRails::Error,
              "Malformed render result: expected exactly one length-prefixed chunk but found none"
      end
      if results.size > 1
        raise ReactOnRails::Error,
              "Malformed render result: expected exactly one length-prefixed chunk but found #{results.size}"
      end
      results.first
    end

    def initialize
      # Binary encoding so that `index` returns byte positions (not character positions).
      # Needed because `byteindex` requires Ruby 3.2+ and we support 3.0+.
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

    # Called when the stream ends. No-op — incomplete data is silently discarded.
    # Connection errors surface through HTTPX error handling, not the parser.
    def flush
      nil
    end

    # True if the parser encountered a protocol error.
    def error?
      @state == :error
    end

    private

    def try_parse_header
      idx = @buf.index("\n")
      return false unless idx

      header = @buf.byteslice(0, idx)
      @buf = @buf.byteslice(idx + 1, @buf.bytesize - idx - 1)

      tab_idx = header.index("\t")
      unless tab_idx
        raise ReactOnRails::Error,
              "Malformed length-prefixed header: missing tab separator in: #{header.force_encoding(Encoding::UTF_8).inspect}"
      end

      parse_length_prefixed_header(header, tab_idx)
      true
    end

    def parse_length_prefixed_header(header, tab_idx)
      meta_json = header.byteslice(0, tab_idx)
      len_hex = header.byteslice(tab_idx + 1, header.bytesize - tab_idx - 1)

      begin
        @content_len = Integer(len_hex, 16)
      rescue ArgumentError
        raise ReactOnRails::Error, "Invalid content length hex: #{len_hex.force_encoding(Encoding::UTF_8).inspect}"
      end

      begin
        @metadata = JSON.parse(meta_json.force_encoding(Encoding::UTF_8))
      rescue JSON::ParserError => e
        raise ReactOnRails::Error,
              "Malformed length-prefixed header: invalid metadata JSON: #{meta_json.force_encoding(Encoding::UTF_8).inspect} (#{e.message})"
      end

      @state = :content
    end

    def try_read_content
      return false if @buf.bytesize < @content_len

      raw_content = @buf.byteslice(0, @content_len).force_encoding(Encoding::UTF_8)
      @buf = @buf.byteslice(@content_len, @buf.bytesize - @content_len)

      # Reconstruct html type based on payloadType:
      #   "object" → JSON-serialized value (ServerRenderHash or null), needs JSON.parse
      #   "string" → raw HTML string, used as-is
      payload_type = @metadata.delete("payloadType")
      @metadata["html"] = payload_type == "object" ? JSON.parse(raw_content) : raw_content

      result = @metadata
      @metadata = nil
      @state = :header
      yield result
      true
    end
  end
end
