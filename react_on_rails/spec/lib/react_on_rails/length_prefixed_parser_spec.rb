# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/length_prefixed_parser"

RSpec.describe ReactOnRails::LengthPrefixedParser do
  describe ".parse_one_chunk_result" do
    def length_prefixed_payload(content, payload_type: "string")
      raw_content = payload_type == "object" ? content.to_json : content
      metadata = { "payloadType" => payload_type, "consoleReplayScript" => "" }.to_json

      "#{metadata}\t#{raw_content.bytesize.to_s(16)}\n#{raw_content}"
    end

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
      bad_payload = "{\"payloadType\":\"string\"}\n<content>"

      expect { described_class.parse_one_chunk_result(bad_payload) }.to raise_error(
        ReactOnRails::Error,
        /missing tab/
      )
    end

    it "raises on an invalid hex length" do
      metadata = { "payloadType" => "string" }.to_json
      bad_payload = "#{metadata}\tZZZZ\ncontent"

      expect { described_class.parse_one_chunk_result(bad_payload) }.to raise_error(
        ReactOnRails::Error,
        /Invalid content length/
      )
    end
  end

  describe "#feed" do
    def length_prefixed_payload(content)
      metadata = { "payloadType" => "string", "consoleReplayScript" => "" }.to_json

      "#{metadata}\t#{content.bytesize.to_s(16)}\n#{content}"
    end

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
  end
end
