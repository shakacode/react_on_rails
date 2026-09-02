# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/diagnostic_url_redactor"

RSpec.describe ReactOnRails::DiagnosticUrlRedactor do
  describe ".sanitize" do
    def sanitize_error(message, configured_url: nil)
      described_class.sanitize(message, configured_url:)
    end

    configured_url_cases = [
      [
        "valid HTTP userinfo",
        "http://synthetic-user:synthetic-secret@host/path",
        "http://host/path"
      ],
      [
        "whitespace in the HTTP scheme delimiter",
        "http ://synthetic-user:synthetic-secret@host/path",
        "http ://host/path"
      ],
      [
        "authority-relative userinfo",
        "//synthetic-user:synthetic-secret@host/path",
        "//host/path"
      ],
      [
        "ambiguous authority-relative userinfo",
        "//synthetic-user:synthetic-secret@credential-suffix@host/path",
        "//host/path"
      ],
      [
        "a prefix before authority-relative userinfo",
        "URL=//synthetic-user:synthetic-secret@host/path",
        "URL=//host/path"
      ],
      [
        "whitespace after a bare authority marker",
        "// synthetic-user:synthetic-secret@host/path",
        "//host/path"
      ],
      [
        "whitespace after a prefixed authority marker",
        "URL=// synthetic-user:synthetic-secret@host/path",
        "URL=//host/path"
      ],
      [
        "multiple at signs in malformed userinfo",
        "http://synthetic-user:secret-prefix@secret-suffix@bad host/path",
        "http://bad host/path"
      ],
      [
        "an unescaped slash in malformed userinfo",
        "http://synthetic-user:secret-prefix/secret-suffix@host/path",
        "http://host/path"
      ],
      [
        "whitespace in malformed userinfo",
        "http://synthetic-user:secret-prefix secret-suffix@host/path",
        "http://host/path"
      ],
      [
        "a delayed at sign in malformed userinfo",
        "http://synthetic-user secret-middle secret-final@host/path",
        "http://host/path"
      ],
      [
        "a quote before a delayed at sign",
        'http://synthetic-user" secret-middle secret-final@host/path',
        "http://host/path"
      ],
      [
        "another adjacent HTTP scheme",
        "http://outer.test/first;http://synthetic-user:synthetic-secret@host/path",
        "http://host/path"
      ],
      [
        "a nested non-HTTP URL",
        "http://outer.test/redirect?next=ftp://nested-user:nested-secret@nested.test/path",
        "http://outer.test/redirect?next=ftp://nested.test/path"
      ],
      [
        "an unresolved scheme before a credential URL",
        "http://synthetic-user:nonnumeric-prefixhttp://synthetic-secret@host/path",
        "http://host/path"
      ],
      [
        "a line break in malformed userinfo",
        "http://synthetic-user\nsynthetic-secret@host/path",
        "http://host/path"
      ],
      [
        "non-URL text before mixed-case HTTP userinfo",
        "URL=hTtPs://synthetic-user:synthetic-secret@host/path",
        "URL=https://host/path"
      ],
      [
        "an at sign only in the path",
        "http://host/path@example",
        "http://host/path@example"
      ],
      [
        "an at sign only in an authority-relative path",
        "//host/assets/component@2.js",
        "//host/assets/component@2.js"
      ],
      [
        "a local path with replacement metacharacters",
        %q(/tmp/\k<foo>-\1-\&-\0-literal\backslash/server-bundle.js),
        %q(/tmp/\k<foo>-\1-\&-\0-literal\backslash/server-bundle.js)
      ]
    ]

    configured_url_cases.each do |description, configured_url, expected|
      it "sanitizes configured userinfo with #{description}" do
        expect(described_class.sanitize(configured_url)).to eq(expected)
      end
    end

    encoded_nested_cases = [
      [
        "a fully encoded nested URL",
        "ftp%3A%2F%2Fnested-user%3Anested-secret%40nested.test%2Fpath",
        "ftp%3A%2F%2Fnested.test%2Fpath"
      ],
      [
        "an encoded scheme and authority marker",
        "ftp%3A%2F%2Fnested-user:nested-secret@nested.test/path",
        "ftp%3A%2F%2Fnested.test/path"
      ],
      [
        "a partially encoded scheme",
        "f%74p://nested-user:nested-secret@nested.test/path",
        "f%74p://nested.test/path"
      ],
      [
        "a partially encoded scheme and encoded at sign",
        "f%74p%3A%2F%2Fnested-user:nested-secret%40nested.test/path",
        "f%74p%3A%2F%2Fnested.test/path"
      ],
      [
        "an encoded at sign",
        "ftp://nested-user:nested-secret%40nested.test/path",
        "ftp://nested.test/path"
      ]
    ]

    encoded_nested_cases.each do |description, nested_url, sanitized_nested_url|
      it "sanitizes encoded nested configured userinfo with #{description}" do
        configured_url = "http://outer.test/redirect?next=#{nested_url}"

        expect(described_class.sanitize(configured_url))
          .to eq("http://outer.test/redirect?next=#{sanitized_nested_url}")
      end

      it "sanitizes diagnostic prose with #{description}" do
        message = "Failure loading http://outer.test/redirect?next=#{nested_url}"

        expect(sanitize_error(message))
          .to eq("Failure loading http://outer.test/redirect?next=#{sanitized_nested_url}")
      end
    end

    encoded_userinfo_delimiters = ["@", "%40"]

    [
      ["path", "ftp%3A%2F%2Fnested.test%2Fcomponent%402.js"],
      ["query", "ftp%3A%2F%2Fnested.test%3Fcontact%3Dsafe%40example.test"]
    ].each do |location, nested_url|
      it "preserves an encoded nested URL with an at sign only in its #{location}" do
        safe_url = "http://outer.test/redirect?next=#{nested_url}"

        expect(described_class.sanitize(safe_url)).to eq(safe_url)
        expect(sanitize_error("Failure loading #{safe_url}")).to eq("Failure loading #{safe_url}")
      end
    end

    [
      ["space", " "],
      ["double quote", '"'],
      ["single quote", "'"]
    ].each do |description, prose_delimiter|
      encoded_userinfo_delimiters.each do |userinfo_delimiter|
        it "fails closed across a #{description} before #{userinfo_delimiter} in a nested URL" do
          nested_url = "ftp://nested-user#{prose_delimiter}nested-secret#{userinfo_delimiter}nested.test/path"
          configured_url = "http://outer.test/redirect?next=#{nested_url}"
          message = "Failure loading #{configured_url}"

          aggregate_failures do
            expect(described_class.sanitize(configured_url)).not_to match(/nested-(?:user|secret)/)
            expect(described_class.sanitize(configured_url)).to include("nested.test/path")
            expect(sanitize_error(message)).not_to match(/nested-(?:user|secret)/)
            expect(sanitize_error(message)).to include("nested.test/path")
          end
        end
      end
    end

    diagnostic_cases = [
      [
        "an unquoted malformed HTTP URL",
        "Failure loading http://synthetic-user:prefix secret-final@host/path",
        "Failure loading http://host/path"
      ],
      [
        "a postgres URL",
        "Failure loading postgres://synthetic-user:synthetic-secret@host/path",
        "Failure loading postgres://host/path"
      ],
      [
        "a redis URL",
        "Failure loading redis://synthetic-user:synthetic-secret@host/path",
        "Failure loading redis://host/path"
      ],
      [
        "an ftp URL",
        "Failure loading ftp://synthetic-user:synthetic-secret@host/path",
        "Failure loading ftp://host/path"
      ],
      [
        "a mongodb URL",
        "Failure loading mongodb://synthetic-user:synthetic-secret@host/path",
        "Failure loading mongodb://host/path"
      ],
      [
        "malformed userinfo with a delayed at sign",
        "Failure loading http://synthetic-user secret-middle secret-final@host/path",
        "Failure loading http://host/path"
      ],
      [
        "malformed userinfo across a line break",
        "Failure loading http://synthetic-user\nsynthetic-secret@host/path",
        "Failure loading http://host/path"
      ],
      [
        "another adjacent HTTP scheme",
        "Failure loading http://outer.test/first;http://synthetic-user:synthetic-secret@host/path",
        "Failure loading http://outer.test/first;http://host/path"
      ],
      [
        "an unresolved scheme before a credential URL",
        "Failure loading http://synthetic-user:nonnumeric-prefixhttp://synthetic-secret@host/path",
        "Failure loading http://host/path"
      ],
      [
        "an invalid credential URL followed by a valid URL",
        "Failure loading http://synthetic-user secret-final@host/path http://healthy-host/path",
        "Failure loading http://host/path http://healthy-host/path"
      ],
      [
        "quoted malformed userinfo",
        'Failure loading "http://synthetic-user secret-final@host/path"',
        'Failure loading "http://host/path"'
      ],
      [
        "a double quote inside malformed userinfo",
        'Failure loading http://synthetic-user"secret-final@host/path',
        "Failure loading http://host/path"
      ],
      [
        "a single quote inside malformed userinfo",
        "Failure loading http://synthetic-user'secret-final@host/path",
        "Failure loading http://host/path"
      ],
      [
        "authority-relative userinfo",
        "Failure loading //synthetic-user:synthetic-secret@host/path",
        "Failure loading //host/path"
      ],
      [
        "authority-relative userinfo across whitespace",
        "Failure loading //synthetic-user synthetic-secret@host/path",
        "Failure loading //host/path"
      ],
      [
        "authority-relative userinfo across a quote",
        'Failure loading //synthetic-user" synthetic-secret@host/path',
        "Failure loading //host/path"
      ],
      [
        "authority-relative userinfo across a line break",
        "Failure loading //synthetic-user\nsynthetic-secret@host/path",
        "Failure loading //host/path"
      ],
      [
        "a nested non-HTTP URL",
        "Failure loading http://outer.test/redirect?next=ftp://nested-user:nested-secret@nested.test/path",
        "Failure loading http://outer.test/redirect?next=ftp://nested.test/path"
      ],
      [
        "an at sign only in a URL path",
        "Failure loading http://host/path@example",
        "Failure loading http://host/path@example"
      ],
      [
        "two safe URLs",
        "Failure loading http://first-host/path http://second-host/path@example",
        "Failure loading http://first-host/path http://second-host/path@example"
      ],
      [
        "non-URL double-slash text",
        "// contact dev@example",
        "// contact dev@example"
      ]
    ]

    diagnostic_cases.each do |description, message, expected|
      it "sanitizes diagnostic prose containing #{description}" do
        expect(sanitize_error(message)).to eq(expected)
      end
    end

    ["\n", "\r", "\r\n"].each do |boundary|
      it "fails closed when #{boundary.inspect} precedes an ambiguous email at sign" do
        message = "Failure loading http://host/path#{boundary}contact dev@example.com"

        expect(sanitize_error(message)).to eq("Failure loading http://example.com")
      end
    end

    it "keeps a later safe URL after redacting malformed multiline userinfo" do
      message = "Failure loading http://synthetic-user\nsynthetic-secret@host/path\n" \
                "hTtPs://healthy-host/path@example"

      expect(sanitize_error(message))
        .to eq("Failure loading http://host/path\nhTtPs://healthy-host/path@example")
    end

    it "fails closed before a later scheme while preserving the separate URL" do
      message = "Failure loading http://first-host/path\ncontact dev@example.com\n" \
                "HTTP://second-host/path"

      expect(sanitize_error(message))
        .to eq("Failure loading http://example.com\nHTTP://second-host/path")
    end

    it "discards an unresolved region before sanitizing the next credential URL" do
      message = "Failure loading http://synthetic-user:nonnumeric-prefix\nsynthetic-tail " \
                "HtTpS://synthetic-secret@host/path"

      expect(sanitize_error(message)).to eq("Failure loading https://host/path")
    end

    it "replaces raw and inspected spellings of the configured URL" do
      configured_url = "http://synthetic-user:synthetic-secret@host/path"
      message = "raw=#{configured_url} inspected=#{configured_url.inspect} repeated=#{configured_url}"

      expect(sanitize_error(message, configured_url:))
        .to eq('raw=http://host/path inspected="http://host/path" repeated=http://host/path')
    end

    it "scrubs invalidly encoded configured values before sanitizing them" do
      configured_url = "http://synthetic-user:synthetic-secret@host/path-\xFF".b.force_encoding(Encoding::UTF_8)

      sanitized = described_class.sanitize(configured_url)
      expect(sanitized).to start_with("http://host/path-")
      expect(sanitized).not_to match(/synthetic-(?:user|secret)/)
      expect(sanitized).to be_valid_encoding
    end

    it "falls back safely when URI parsing raises a URI::Error subtype" do
      configured_url = "http://synthetic-user:synthetic-secret@host/path"
      allow(URI).to receive(:parse).with(configured_url)
                                   .and_raise(URI::BadURIError, "bad URI for #{configured_url}")

      expect(described_class.sanitize(configured_url)).to eq("http://host/path")
    end

    it "falls back safely when URI parsing raises ArgumentError" do
      configured_url = "http://synthetic-user:synthetic-secret@host/path"
      allow(URI).to receive(:parse).with(configured_url)
                                   .and_raise(ArgumentError, "invalid byte sequence in UTF-8")

      expect(described_class.sanitize(configured_url)).to eq("http://host/path")
    end

    it "sanitizes a large diagnostic with many encoded nested URL starts" do
      safe_part = "part=ftp%3A%2F%2Fnested.test%2Fchunk"
      encoded_padding = Array.new(1_800, safe_part).join("&")
      nested_url = "ftp%3A%2F%2Fnested-user%3Anested-secret%40nested.test%2Fpath"
      message = "Failure loading http://outer.test/redirect?#{encoded_padding}&next=#{nested_url}"
      expect(message.bytesize).to be > 65_536

      sanitized = sanitize_error(message)
      expect(sanitized).not_to match(/nested-(?:user|secret)/)
      expect(sanitized).to include("next=ftp%3A%2F%2Fnested.test%2Fpath")
    end
  end
end
