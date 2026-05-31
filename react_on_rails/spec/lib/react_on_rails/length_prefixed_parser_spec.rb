# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/length_prefixed_parser"

RSpec.describe ReactOnRails::LengthPrefixedParser do
  describe ".parse_one_chunk_result" do
    it "uses byte lengths for multibyte string payloads" do
      content = "caf\u00E9"
      metadata = { "payloadType" => "string", "consoleReplayScript" => "" }.to_json
      payload = "#{metadata}\t#{content.bytesize.to_s(16)}\n#{content}"

      expect(described_class.parse_one_chunk_result(payload)).to include(
        "consoleReplayScript" => "",
        "html" => content
      )
    end

    it "parses object payloads by JSON-decoding the content" do
      content = { "error" => "boom" }
      metadata = { "payloadType" => "object", "consoleReplayScript" => "" }.to_json
      json_content = content.to_json
      payload = "#{metadata}\t#{json_content.bytesize.to_s(16)}\n#{json_content}"

      expect(described_class.parse_one_chunk_result(payload)).to include(
        "consoleReplayScript" => "",
        "html" => content
      )
    end
  end
end
