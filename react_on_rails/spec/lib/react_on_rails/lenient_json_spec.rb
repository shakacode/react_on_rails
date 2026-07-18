# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/lenient_json"

RSpec.describe ReactOnRails::LenientJson do
  # A single backslash, used to build JSON text containing literal \uXXXX escapes without
  # fighting Ruby string-escaping. "#{BS}ud83d" is the six characters \ u d 8 3 d.
  bs = "\\"
  fffd = "\u{FFFD}" # the replacement character a lone surrogate is repaired to

  # repair_lone_surrogates is pure text manipulation, so its behavior is identical across
  # every json gem version. These assert the exact repaired output.
  describe ".repair_lone_surrogates" do
    it "replaces a lone high surrogate with U+FFFD" do
      expect(described_class.repair_lone_surrogates(%({"h":"a#{bs}ud83d b"}))).to eq(%({"h":"a#{fffd} b"}))
    end

    it "replaces a lone low surrogate with U+FFFD" do
      expect(described_class.repair_lone_surrogates(%({"h":"a#{bs}ude00 b"}))).to eq(%({"h":"a#{fffd} b"}))
    end

    it "replaces both halves of a reversed pair" do
      expect(described_class.repair_lone_surrogates(%({"h":"#{bs}ude00#{bs}ud83d"}))).to eq(%({"h":"#{fffd}#{fffd}"}))
    end

    it "repairs a lone surrogate inside a key" do
      expect(described_class.repair_lone_surrogates(%({"k#{bs}ud83d":"v"}))).to eq(%({"k#{fffd}":"v"}))
    end

    it "preserves a valid surrogate pair written as escapes" do
      text = %({"h":"#{bs}ud83d#{bs}ude00"})
      expect(described_class.repair_lone_surrogates(text)).to eq(text)
    end

    it "leaves literal backslash text that only looks like an escape untouched" do
      # In JSON, \\ud83d is an escaped backslash followed by the letters "ud83d".
      text = %({"h":"#{bs}#{bs}ud83d"})
      expect(described_class.repair_lone_surrogates(text)).to eq(text)
    end

    it "is a no-op when there are no surrogate escapes" do
      text = %({"h":"plain content, even 😀 raw"})
      expect(described_class.repair_lone_surrogates(text)).to eq(text)
    end
  end

  describe ".parse" do
    it "parses clean JSON unchanged" do
      expect(described_class.parse(%({"html":"<div>hi</div>"}))).to eq("html" => "<div>hi</div>")
    end

    it "leaves a valid astral character (raw UTF-8) untouched" do
      expect(described_class.parse(%({"html":"#{[0x1F600].pack('U')}"}))).to eq("html" => "😀")
    end

    it "re-raises the original error for genuinely malformed JSON" do
      expect { described_class.parse(%({"html":})) }.to raise_error(JSON::ParserError)
    end

    # Behavioral guarantee across json versions: a lone surrogate never crashes the render,
    # and the result is valid UTF-8. Whether the underlying JSON.parse raises (and is then
    # repaired) or silently degrades depends on the json version and surrounding bytes; either
    # way LenientJson returns cleanly. (A lone *low* surrogate is excluded: see the class docs.)
    {
      "lone high, mid-value" => %({"html":"a#{bs}ud83d b"}),
      "lone high, end of value" => %({"html":"a#{bs}ud83d"}),
      "lone high in a key" => %({"a#{bs}ud83d":"v"}),
      "reversed pair" => %({"html":"#{bs}ude00#{bs}ud83d"})
    }.each do |label, input|
      it "does not crash and returns valid UTF-8 for a #{label}" do
        result = nil
        expect { result = described_class.parse(input) }.not_to raise_error
        result.each { |k, v| expect([k, v].grep(String)).to all(be_valid_encoding) }
      end
    end
  end
end
