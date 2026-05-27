# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/url_sanitizer"

module ReactOnRailsPro
  RSpec.describe UrlSanitizer do
    describe ".redact_password" do
      it "redacts the password from a URL with userinfo" do
        result = described_class.redact_password("https://user:supersecret@renderer:3800")
        expect(result).to eq("https://user:__REDACTED__@renderer:3800")
      end

      it "redacts the password when userinfo has only a password (no username)" do
        result = described_class.redact_password("https://:supersecret@renderer:3800")
        expect(result).to eq("https://:__REDACTED__@renderer:3800")
      end

      it "preserves the path, query, and fragment when redacting" do
        result = described_class.redact_password("https://:pw@renderer:3800/path?q=1#frag")
        expect(result).to eq("https://:__REDACTED__@renderer:3800/path?q=1#frag")
      end

      it "does not modify a URL without a password" do
        result = described_class.redact_password("https://renderer:3800")
        expect(result).to eq("https://renderer:3800")
      end

      it "does not modify a URL with only a username (no password)" do
        result = described_class.redact_password("https://user@renderer:3800")
        expect(result).to eq("https://user@renderer:3800")
      end

      it "returns nil for nil input" do
        expect(described_class.redact_password(nil)).to be_nil
      end

      it "returns empty string for empty input" do
        expect(described_class.redact_password("")).to eq("")
      end

      it "falls back to regex redaction for unparseable URLs" do
        # URIs with raw whitespace are typically rejected by URI.parse
        result = described_class.redact_password("https://:my password@renderer:3800")
        expect(result).not_to include("my password")
        expect(result).to include("__REDACTED__")
      end

      it "does not leak the password in the regex-redacted fallback" do
        sensitive_password = "topsecret_value_should_not_leak"
        # Force the URI parser into the fallback by constructing an obviously bad URL
        # that still contains the userinfo pattern
        result = described_class.redact_password("not a url://:#{sensitive_password}@host")
        expect(result).not_to include(sensitive_password)
      end
    end
  end
end
