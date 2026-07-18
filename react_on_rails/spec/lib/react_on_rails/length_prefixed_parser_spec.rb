# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/length_prefixed_parser"

RSpec.describe ReactOnRails::LengthPrefixedParser do
  def length_prefixed_payload(content, payload_type: "string", metadata: {})
    raw_content = payload_type == "object" ? content.to_json : content
    metadata = { "payloadType" => payload_type, "consoleReplayScript" => "" }.merge(metadata).to_json

    "#{metadata}\t#{raw_content.bytesize.to_s(16)}\n#{raw_content}"
  end

  def length_prefixed_parts(content, payload_type: "string")
    payload = length_prefixed_payload(content, payload_type:)
    newline_idx = payload.byteindex("\n")
    raise "Test fixture missing newline" unless newline_idx

    header_end = newline_idx + 1

    [payload.byteslice(0, header_end), payload.byteslice(header_end, payload.bytesize - header_end)]
  end

  describe ".parse_one_chunk_result" do
    it "parses ASCII-only string payloads" do
      content = "hello world"

      expect(described_class.parse_one_chunk_result(length_prefixed_payload(content))).to include(
        "consoleReplayScript" => "",
        "html" => content
      )
    end

    it "uses byte lengths for multibyte string payloads" do
      content = "caf\u00E9"

      expect(described_class.parse_one_chunk_result(length_prefixed_payload(content))).to include(
        "consoleReplayScript" => "",
        "html" => content
      )
    end

    it "parses object payloads by JSON-decoding the content" do
      content = { "error" => "boom" }

      payload = length_prefixed_payload(content, payload_type: "object")

      expect(described_class.parse_one_chunk_result(payload)).to include(
        "consoleReplayScript" => "",
        "html" => content
      )
    end

    it "raises on a missing tab separator in the header" do
      bad_payload = "header-format-secret\n<content>"

      expect { described_class.parse_one_chunk_result(bad_payload) }.to raise_error(
        described_class::ParseError,
        /missing tab/
      ) { |error| expect(error.message).not_to include("header-format-secret") }
    end

    it "raises on an invalid hex length" do
      metadata = { "payloadType" => "string" }.to_json
      bad_payload = "#{metadata}\tZZZZ\ncontent"

      expect { described_class.parse_one_chunk_result(bad_payload) }.to raise_error(
        described_class::ParseError,
        /invalid content length/
      ) { |error| expect(error.cause).to be_nil }
    end

    it "raises on a negative content length" do
      metadata = { "payloadType" => "string" }.to_json
      bad_payload = "#{metadata}\t-1\n"

      expect { described_class.parse_one_chunk_result(bad_payload) }.to raise_error(
        described_class::ParseError,
        /negative content length/
      )
    end

    it "classifies invalid metadata JSON as a parser error" do
      bad_payload = "metadata-json-secret\t5\nhello"

      expect { described_class.parse_one_chunk_result(bad_payload) }.to raise_error(
        described_class::ParseError,
        /invalid metadata JSON/
      ) do |error|
        expect(error.message).not_to include("metadata-json-secret")
        expect(error.cause).to be_nil
      end
    end

    it "rejects metadata JSON that is not an object" do
      bad_payload = "[]\t0\n"

      expect { described_class.parse_one_chunk_result(bad_payload) }.to raise_error(
        described_class::ParseError,
        /metadata JSON must be an object/
      )
    end

    it "classifies invalid object payload JSON as a parser error" do
      raw_content = '{"secret":"object-json-secret"'
      metadata = { "payloadType" => "object" }.to_json
      bad_payload = "#{metadata}\t#{raw_content.bytesize.to_s(16)}\n#{raw_content}"

      expect { described_class.parse_one_chunk_result(bad_payload) }.to raise_error(
        described_class::ParseError,
        /object payload JSON/
      ) do |error|
        expect(error.message).not_to include("object-json-secret")
        expect(error.cause).to be_nil
      end
    end

    it "raises when the input contains more than one chunk" do
      chunk = length_prefixed_payload("hello")
      two_chunks = chunk + chunk

      expect { described_class.parse_one_chunk_result(two_chunks) }.to raise_error(
        described_class::ParseError,
        /expected exactly one length-prefixed chunk but found 2/
      )
    end
  end

  describe "control messages (messageType)" do
    def control_message_payload(metadata, include_payload_type: true)
      metadata_with_type = include_payload_type ? metadata.merge("payloadType" => "string") : metadata
      meta_json = metadata_with_type.to_json
      "#{meta_json}\t0\n"
    end

    it "yields metadata with messageType but without html or payloadType keys" do
      payload = control_message_payload({ "messageType" => "propRequest", "propName" => "users" })
      result = []
      parser = described_class.new
      parser.feed(payload) { |chunk| result << chunk }

      expect(result.size).to eq(1)
      expect(result.first).to include("messageType" => "propRequest", "propName" => "users")
      expect(result.first).not_to have_key("html")
      expect(result.first).not_to have_key("payloadType")
    end

    it "handles production control messages without payloadType" do
      payload = control_message_payload(
        { "messageType" => "propRequest", "propName" => "users" },
        include_payload_type: false
      )
      result = []
      parser = described_class.new
      parser.feed(payload) { |chunk| result << chunk }

      expect(result.size).to eq(1)
      expect(result.first).to eq("messageType" => "propRequest", "propName" => "users")
    end

    it "handles renderComplete control messages" do
      payload = control_message_payload({ "messageType" => "renderComplete" })
      result = []
      parser = described_class.new
      parser.feed(payload) { |chunk| result << chunk }

      expect(result.size).to eq(1)
      expect(result.first).to eq("messageType" => "renderComplete")
    end

    it "correctly interleaves control messages with normal HTML chunks" do
      html_chunk = length_prefixed_payload("<div>Hello</div>")
      control_chunk = control_message_payload({ "messageType" => "propRequest", "propName" => "settings" })
      html_chunk2 = length_prefixed_payload("<p>World</p>")

      parser = described_class.new
      results = []
      parser.feed(html_chunk + control_chunk + html_chunk2) { |chunk| results << chunk }

      expect(results.size).to eq(3)
      expect(results[0]).to include("html" => "<div>Hello</div>")
      expect(results[1]).to include("messageType" => "propRequest", "propName" => "settings")
      expect(results[1]).not_to have_key("html")
      expect(results[2]).to include("html" => "<p>World</p>")
    end

    it "treats unsupported messageType metadata as a normal chunk" do
      payload = length_prefixed_payload("<div>traceable</div>", metadata: { "messageType" => "trace" })
      result = []
      parser = described_class.new
      parser.feed(payload) { |chunk| result << chunk }

      expect(result).to contain_exactly(
        include(
          "messageType" => "trace",
          "html" => "<div>traceable</div>"
        )
      )
    end
  end

  describe "#feed" do
    it "parses multibyte payloads split across streaming chunks" do
      content = "\u3053\u3093\u306B\u3061\u306F"
      payload = length_prefixed_payload(content).b
      parser = described_class.new
      results = []

      parser.feed(payload.byteslice(0, 10)) { |chunk| results << chunk }
      expect(results).to be_empty

      parser.feed(payload.byteslice(10, payload.bytesize - 10)) { |chunk| results << chunk }
      expect(results).to contain_exactly(
        include(
          "consoleReplayScript" => "",
          "html" => content
        )
      )
    end

    it "waits for a multibyte body after receiving a complete header chunk" do
      content = "\u4F60\u597D"
      header, body = length_prefixed_parts(content)
      parser = described_class.new
      results = []

      parser.feed(header.b) { |chunk| results << chunk }
      expect(results).to be_empty

      parser.feed(body.b) { |chunk| results << chunk }
      expect(results).to contain_exactly(
        include(
          "consoleReplayScript" => "",
          "html" => content
        )
      )
    end
  end

  # Regression coverage for GitHub issue #4710: JavaScript's JSON.stringify can
  # emit unpaired UTF-16 surrogate escapes (e.g. a lone high surrogate "\ud83d")
  # that Ruby's JSON.parse rejects with "incomplete surrogate pair". SSR must
  # pass such content through (as U+FFFD) instead of crashing.
  describe ".parse_json_lenient" do
    it "parses ordinary JSON unchanged" do
      expect(described_class.parse_json_lenient('{"html":"<div>ok</div>","n":1}')).to eq(
        "html" => "<div>ok</div>", "n" => 1
      )
    end

    it "never crashes on a lone high surrogate and yields valid UTF-8" do
      # Whether the underlying JSON.parse raises "incomplete surrogate pair"
      # (older json gems / the client's scenario) or silently substitutes
      # (newer json gems have their own lenient handling), parse_json_lenient
      # must return valid, renderable content instead of propagating a crash.
      %w[
        {"html":"\uD83D"}
        {"html":"Hello\uD83Dworld"}
        {"html":"\uD83DA"}
      ].each do |json|
        result = nil
        expect { result = described_class.parse_json_lenient(json) }.not_to raise_error
        expect(result["html"].valid_encoding?).to be(true)
      end
    end

    it "decodes a sanitized lone high surrogate to U+FFFD" do
      # Deterministic across json versions: run the recovery pipeline directly
      # (sanitize then parse) so the produced replacement char is asserted
      # regardless of whether the raw JSON.parse would have raised.
      raw = '{"html":"Hello \uD83D world"}'
      recovered = JSON.parse(described_class.sanitize_unpaired_surrogates(raw))
      expect(recovered["html"]).to eq("Hello � world")
    end

    it "preserves valid surrogate pairs" do
      json = '{"html":"Hi 😀"}'
      expect(described_class.parse_json_lenient(json)).to eq("html" => "Hi \u{1F600}")
    end

    it "re-raises for genuinely malformed JSON that is not a surrogate issue" do
      expect { described_class.parse_json_lenient('{"html":}') }.to raise_error(JSON::ParserError)
    end
  end

  describe ".sanitize_unpaired_surrogates" do
    it "leaves valid surrogate pairs and non-surrogate escapes untouched" do
      json = '{"a":"😀","b":"A"}'
      expect(described_class.sanitize_unpaired_surrogates(json)).to eq(json)
    end

    it "replaces a lone high surrogate escape with the U+FFFD escape" do
      # Returns the raw JSON string with the escape rewritten (not yet parsed):
      # the 8-character literal "�", which JSON.parse then decodes to U+FFFD.
      expect(described_class.sanitize_unpaired_surrogates('"\uD83D"')).to eq('"\ufffd"')
    end

    it "replaces a lone high surrogate followed by a non-surrogate escape" do
      expect(described_class.sanitize_unpaired_surrogates('"\uD83DA"')).to eq('"\ufffdA"')
    end

    it "produces ASCII-only output so encoding stays safe for binary input" do
      out = described_class.sanitize_unpaired_surrogates('"\uD83D"'.b)
      expect(out).to eq('"\ufffd"')
      expect(out.ascii_only?).to be(true)
    end
  end

  describe "lone surrogates in an object payload" do
    it "does not crash and yields valid, renderable content" do
      raw_content = '{"html":"Hello \uD83D world","consoleReplayScript":""}'
      metadata = { "payloadType" => "object" }.to_json
      payload = "#{metadata}\t#{raw_content.bytesize.to_s(16)}\n#{raw_content}"

      result = nil
      expect { result = described_class.parse_one_chunk_result(payload) }.not_to raise_error
      expect(result["html"]).to be_a(Hash)
      expect(result["html"]["html"].valid_encoding?).to be(true)
    end
  end
end
