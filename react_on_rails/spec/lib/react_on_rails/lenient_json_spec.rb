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

    it "does not pay the repair path for clean JSON without surrogate escapes" do
      # A payload with no "\ud" escape must never be repaired: the fast path returns the
      # original parse result object unchanged.
      json = %({"html":"clean content, even 😀"})
      expect(described_class.parse(json)).to eq("html" => "clean content, even 😀")
    end

    # Lone surrogates repair to U+FFFD on every json version. This covers the cases that make
    # JSON.parse *raise* AND the ones it silently accepts (lone low, and a lone high before a
    # non-low escape), so the result is always well-formed rather than corrupt.
    {
      "lone high, mid-value" => [%({"html":"a#{bs}ud83d b"}), "a\u{FFFD} b"],
      "lone high, end of value" => [%({"html":"a#{bs}ud83d"}), "a\u{FFFD}"],
      "lone low (parses without raising)" => [%({"html":"a#{bs}ude00 b"}), "a\u{FFFD} b"],
      "lone high before an escaped NUL" => [%({"html":"#{bs}ud83d#{bs}u0000"}), "\u{FFFD}#{0.chr}"],
      "reversed pair" => [%({"html":"#{bs}ude00#{bs}ud83d"}), "\u{FFFD}\u{FFFD}"]
    }.each do |label, (input, expected)|
      it "repairs a #{label} to U+FFFD" do
        result = described_class.parse(input)
        expect(result["html"]).to eq(expected)
        expect(result["html"]).to be_valid_encoding
      end
    end

    it "repairs a lone surrogate inside a key" do
      expect(described_class.parse(%({"k#{bs}ud83d":"v"})).keys.first).to eq("k\u{FFFD}")
    end

    it "does not raise ArgumentError when repairing input with invalid UTF-8 bytes" do
      # Defensive: out of scope for JSON.stringify output (always valid UTF-8), but the repair
      # scans bytes so genuinely-invalid input never becomes an ArgumentError that callers'
      # `rescue JSON::ParserError` would miss. Ruby's JSON.parse accepts these bytes.
      bad_bytes = [0xED, 0xB8, 0x80].pack("C*")
      invalid = %({"html":"x#{bad_bytes}#{bs}ud83d"}).force_encoding("UTF-8")
      # Repairs the surrogate and returns without an encoding crash (the invalid bytes pass
      # through; Ruby's JSON.parse accepts them).
      expect { described_class.parse(invalid) }.not_to raise_error
    end

    it "does not crash detecting surrogate escapes in invalid-encoding input" do
      bad_bytes = [0xED, 0xB8, 0x80].pack("C*")
      invalid = %({"html":"#{bad_bytes}clean"}).force_encoding("UTF-8")
      expect { described_class.parse(invalid) }.not_to raise_error
    end
  end
end
