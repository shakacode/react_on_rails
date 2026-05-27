# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/url_sanitizer"

module ReactOnRails
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

      it "redacts URLs with spaces in the password (unparseable by URI)" do
        result = described_class.redact_password("https://:my password@renderer:3800")
        expect(result).not_to include("my password")
        expect(result).to include("__REDACTED__")
        expect(result).to include("renderer:3800")
      end

      it "redacts URLs with newlines in the password" do
        sensitive = "secret\nleak"
        result = described_class.redact_password("https://:#{sensitive}@renderer:3800")
        expect(result).not_to include(sensitive)
        expect(result).not_to include("leak")
        expect(result).to include("__REDACTED__")
      end

      # Regex fallback edge cases that the original fallback missed.
      it "redacts passwords containing '@' through to the last '@' before the host" do
        result = described_class.redact_password("https://:p@ss@renderer:3800")
        expect(result).not_to include("p@ss")
        expect(result).not_to include("ss@renderer")
        expect(result).to eq("https://:__REDACTED__@renderer:3800")
      end

      it "redacts passwords containing '/' (fallback path)" do
        result = described_class.redact_password("https://:p/ass@renderer:3800")
        expect(result).not_to include("p/ass")
        expect(result).to include("__REDACTED__")
      end

      it "redacts passwords containing '?' (fallback path)" do
        result = described_class.redact_password("https://:p?ass@renderer:3800")
        expect(result).not_to include("p?ass")
        expect(result).to include("__REDACTED__")
      end

      it "redacts passwords containing '#' (fallback path)" do
        result = described_class.redact_password("https://:p#ass@renderer:3800")
        expect(result).not_to include("p#ass")
        expect(result).to include("__REDACTED__")
      end

      it "redacts a URL embedded in a longer string (e.g. inside an exception message)" do
        sensitive = "topsecret_value_should_not_leak"
        wrapped = "bad URI (is not URI?): \"https://:#{sensitive}@host:3800\""
        result = described_class.redact_password(wrapped)
        expect(result).not_to include(sensitive)
        expect(result).to include("__REDACTED__")
        expect(result).to include("host:3800")
      end

      # Email-as-username is malformed per RFC 3986 (raw '@' is reserved in
      # userinfo) but real users do this and don't percent-encode the '@'.
      it "redacts the password when the username itself contains a raw '@' (email-as-username)" do
        sensitive = "s3cr3t_password"
        result = described_class.redact_password("https://user@example.com:#{sensitive}@renderer:3800")
        expect(result).not_to include(sensitive)
        expect(result).to include("__REDACTED__")
        expect(result).to include("renderer:3800")
      end

      it "redacts email-as-username passwords for IPv6 hosts" do
        sensitive = "s3cr3t_password"
        result = described_class.redact_password("https://user@example.com:#{sensitive}@[::1]:3800")
        expect(result).not_to include(sensitive)
        expect(result).to include("__REDACTED__")
        expect(result).to include("[::1]:3800")
      end

      it "redacts passwords containing both '@' and ':' (multi-char-class fallback)" do
        sensitive = "p@d:w"
        result = described_class.redact_password("https://user:#{sensitive}@host:3800")
        expect(result).not_to include(sensitive)
        expect(result).to include("__REDACTED__")
      end

      # Regression: a parseable URL with no userinfo and an '@' in the query
      # or fragment must not be corrupted. The regex fallback used to match
      # 'renderer:3800/path?email=a' + '@' + 'b' and emit `:__REDACTED__@b`,
      # which is log corruption.
      it "does not corrupt parseable URLs with '@' in the query string" do
        input = "https://renderer:3800/path?email=a@b"
        expect(described_class.redact_password(input)).to eq(input)
      end

      it "does not corrupt parseable URLs with '@' in the fragment" do
        input = "https://renderer:3800/path#user@example.com"
        expect(described_class.redact_password(input)).to eq(input)
      end

      it "does not corrupt parseable URLs with multiple '@' in the query string" do
        input = "https://renderer:3800/render?cc=a@b.com&bcc=c@d.com"
        expect(described_class.redact_password(input)).to eq(input)
      end
    end
  end
end
