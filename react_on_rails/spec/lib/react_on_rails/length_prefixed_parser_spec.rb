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

    # A single backslash, so "#{bs}ud83d" is the literal six-character JSON escape \ud83d
    # a JS renderer emits when a string is truncated mid-surrogate-pair. The lone surrogate
    # must not crash the render; the exact repair is covered in lenient_json_spec.rb. See #4710.
    bs = "\\"

    it "tolerates a lone surrogate in the metadata instead of failing the render" do
      raw_content = "<div>valid html</div>"
      metadata = %({"payloadType":"string","consoleReplayScript":"","note":"bad #{bs}ud83d"})
      payload = "#{metadata}\t#{raw_content.bytesize.to_s(16)}\n#{raw_content}"

      result = nil
      expect { result = described_class.parse_one_chunk_result(payload) }.not_to raise_error
      expect(result["html"]).to eq(raw_content)
      expect(result["note"]).to be_valid_encoding
    end

    it "tolerates a lone surrogate in an object payload instead of failing the render" do
      raw_content = %({"componentHtml":"a#{bs}ud83d b"})
      metadata = { "payloadType" => "object", "consoleReplayScript" => "" }.to_json
      payload = "#{metadata}\t#{raw_content.bytesize.to_s(16)}\n#{raw_content}"

      result = nil
      expect { result = described_class.parse_one_chunk_result(payload) }.not_to raise_error
      expect(result["html"]["componentHtml"]).to be_valid_encoding
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
end
