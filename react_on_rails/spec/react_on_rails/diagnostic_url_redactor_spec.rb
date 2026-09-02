# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/diagnostic_url_redactor"
require "timeout"

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
        "a percent-encoded authority delimiter",
        "http://bundle-user:synthetic-password%40host/bundle.js",
        "http://host/bundle.js"
      ],
      [
        "fully encoded HTTP authority separators",
        "http:%2F%2Fbundle-user:synthetic-password%40host/bundle.js",
        "http:%2F%2Fhost/bundle.js"
      ],
      [
        "an encoded authority terminator before an encoded userinfo delimiter",
        "http:%2F%2Fbundle-user:synthetic-password%2Fsegment%40host/bundle.js",
        "http:%2F%2Fhost/bundle.js"
      ],
      [
        "a fully encoded authority-relative start",
        "%2F%2Fbundle-user:synthetic-password%40host/bundle.js",
        "%2F%2Fhost/bundle.js"
      ],
      [
        "a mixed literal and encoded authority-relative start",
        "/%2Fbundle-user:synthetic-password%40host/bundle.js",
        "/%2Fhost/bundle.js"
      ],
      [
        "an encoded authority-relative start after a prefix",
        "URL= %2F%2Fbundle-user:synthetic-password%40host/bundle.js",
        "URL= %2F%2Fhost/bundle.js"
      ],
      [
        "fully encoded outer and nested URL credentials",
        "http%3A%2F%2Fouter-user%3Aouter-secret%40outer.test%2Fredirect%3Fnext%3D" \
        "ftp%3A%2F%2Fnested-user%3Anested-secret%40nested.test%2Fpath",
        "http%3A%2F%2Fouter.test%2Fredirect%3Fnext%3Dftp%3A%2F%2Fnested.test%2Fpath"
      ],
      [
        "literal outer and encoded nested authority separators",
        "http%3A//bundle-user%3Asynthetic-password%40outer.test%2Fnext%3D" \
        "ftp%3A%2F%2Fnested-user%3Anested-secret%40inner.test/path",
        "http%3A//outer.test%2Fnext%3Dftp%3A%2F%2Finner.test/path"
      ],
      [
        "authority-relative outer and encoded nested URL credentials",
        "//bundle-user%3Asynthetic-password%40outer.test/path?next=" \
        "ftp%3A%2F%2Fnested-user%3Anested-secret%40inner.test/path",
        "//outer.test/path?next=ftp%3A%2F%2Finner.test/path"
      ],
      [
        "a fully encoded chain of three credential URLs",
        "http%3A%2F%2Fouter-user%3Aouter-secret%40outer.test%2Fnext%3D" \
        "ftp%3A%2F%2Ffirst-user%3Afirst-secret%40first.test%2Fnext%3D" \
        "redis%3A%2F%2Flast-user%3Alast-secret%40last.test%2Fpath",
        "http%3A%2F%2Fouter.test%2Fnext%3Dftp%3A%2F%2Ffirst.test%2Fnext%3D" \
        "redis%3A%2F%2Flast.test%2Fpath"
      ],
      [
        "encoded outer and nested credentials with whitespace between authority separators",
        "http %3A%2F %2Fouter-user%3Aouter-secret%40outer.test%2Fnext%3D" \
        "ftp%3A%2F %2Fnested-user%3Anested-secret%40nested.test%2Fpath",
        "http %3A%2F %2Fouter.test%2Fnext%3Dftp%3A%2F %2Fnested.test%2Fpath"
      ],
      [
        "an internal HTTP scheme after an encoded boundary in an outer URL",
        "http://outer.test/path?next=%61%20http %3A%2F%2Fnested-user:nested-secret%40nested.test/path",
        "http://outer.test/path?next=%61%20http %3A%2F%2Fnested.test/path"
      ],
      [
        "mixed encoded and literal authority delimiters",
        "http://synthetic-user%40mail:synthetic-secret@host/path",
        "http://host/path"
      ],
      [
        "whitespace in the HTTP scheme delimiter",
        "http ://synthetic-user:synthetic-secret@host/path",
        "http ://host/path"
      ],
      [
        "whitespace around a literal colon before encoded authority separators",
        "http : %2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "http : %2F%2Fhost/path"
      ],
      [
        "whitespace before an encoded colon and encoded authority separators",
        "http %3A%2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "http %3A%2F%2Fhost/path"
      ],
      [
        "a partially encoded HTTP scheme before a whitespace-delimited encoded colon",
        "h%74tp %3A%2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "h%74tp %3A%2F%2Fhost/path"
      ],
      [
        "an encoded whitespace token before an internal HTTP scheme",
        "%20http %3A%2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "%20http %3A%2F%2Fhost/path"
      ],
      [
        "whitespace before fully encoded authority separators",
        "http: %2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "http: %2F%2Fhost/path"
      ],
      [
        "whitespace before a literal and encoded authority separator",
        "http: /%2Fsynthetic-user:synthetic-secret%40host/path",
        "http: /%2Fhost/path"
      ],
      [
        "whitespace before an encoded and literal authority separator",
        "http: %2F/synthetic-user:synthetic-secret%40host/path",
        "http: %2F/host/path"
      ],
      [
        "whitespace between encoded authority separators",
        "http:%2F %2Fsynthetic-user:synthetic-secret%40host/path",
        "http:%2F %2Fhost/path"
      ],
      [
        "encoded whitespace before encoded authority separators",
        "http:%20%2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "http:%20%2F%2Fhost/path"
      ],
      [
        "encoded whitespace between encoded authority separators",
        "http:%2F%20%2Fsynthetic-user:synthetic-secret%40host/path",
        "http:%2F%20%2Fhost/path"
      ],
      [
        "mixed literal and encoded whitespace around mixed authority separators",
        "h%74tp \t%20%3A%0A/%09%2Fsynthetic-user:synthetic-secret%40host/path",
        "h%74tp \t%20%3A%0A/%09%2Fhost/path"
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
        "userinfo after an earlier authority-relative URL",
        "URL= //safe/path//bundle-user:synthetic-password@host/bundle.js",
        "URL= //safe/path//host/bundle.js"
      ],
      [
        "userinfo spanning a later authority marker",
        "URL= //bundle-user:synthetic-password//suffix@host/bundle.js",
        "URL= //host/bundle.js"
      ],
      [
        "encoded userinfo after an earlier authority-relative URL",
        "URL= //safe/path//bundle-user:synthetic-password%40host/bundle.js",
        "URL= //safe/path//host/bundle.js"
      ],
      [
        "encoded userinfo spanning a later authority marker",
        "URL= //bundle-user:synthetic-password//suffix%40host/bundle.js",
        "URL= //host/bundle.js"
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
        "credential-like text before a later HTTP URL",
        "user:pass@host http://actual-host/path",
        "host http://actual-host/path"
      ],
      [
        "an at sign only in the path",
        "http://host/path@example",
        "http://host/path@example"
      ],
      [
        "a percent-encoded at sign only in the path",
        "http://host/assets/component%402.js",
        "http://host/assets/component%402.js"
      ],
      [
        "a percent-encoded at sign only in the query",
        "http://host/bundle.js?contact=safe%40example.test",
        "http://host/bundle.js?contact=safe%40example.test"
      ],
      [
        "an encoded at sign only in a fully encoded HTTP path",
        "http:%2F%2Fhost%2Fassets%2Fcomponent%402.js",
        "http:%2F%2Fhost%2Fassets%2Fcomponent%402.js"
      ],
      [
        "an encoded at sign only in a fully encoded HTTP query",
        "http:%2F%2Fhost%3Fcontact%3Dsafe%40example.test",
        "http:%2F%2Fhost%3Fcontact%3Dsafe%40example.test"
      ],
      [
        "an encoded at sign only in a fully encoded HTTP fragment",
        "http:%2F%2Fhost%23contact-safe%40example.test",
        "http:%2F%2Fhost%23contact-safe%40example.test"
      ],
      [
        "an encoded at sign only in a whitespace-delimited encoded HTTP path",
        "http: %2F%2Fhost%2Fassets%2Fcomponent%402.js",
        "http: %2F%2Fhost%2Fassets%2Fcomponent%402.js"
      ],
      [
        "an at sign only after a whitespace-delimited mixed HTTP query terminator",
        "http: /%2Fhost?contact=safe@example.test",
        "http: /%2Fhost?contact=safe@example.test"
      ],
      [
        "an encoded at sign only in a whitespace-delimited mixed HTTP fragment",
        "http: %2F/host%23contact-safe%40example.test",
        "http: %2F/host%23contact-safe%40example.test"
      ],
      [
        "an encoded at sign only in a path after whitespace between encoded authority separators",
        "http:%2F %2Fhost/path%40asset",
        "http:%2F %2Fhost/path%40asset"
      ],
      [
        "an at sign only in a query after whitespace between encoded authority separators",
        "http:%2F %2Fhost/path?contact=safe@example.test",
        "http:%2F %2Fhost/path?contact=safe@example.test"
      ],
      [
        "an encoded at sign only in a fragment after whitespace between encoded authority separators",
        "http:%2F %2Fhost/path#safe%40example.test",
        "http:%2F %2Fhost/path#safe%40example.test"
      ],
      [
        "no userinfo after whitespace before an encoded colon",
        "http %3A%2F%2Fhost/path",
        "http %3A%2F%2Fhost/path"
      ],
      [
        "no userinfo after whitespace between encoded authority separators",
        "http:%2F %2Fhost/path",
        "http:%2F %2Fhost/path"
      ],
      [
        "an encoded path at sign after encoded whitespace between authority separators",
        "http:%2F%20%2Fhost/path%40asset",
        "http:%2F%20%2Fhost/path%40asset"
      ],
      [
        "an at sign after a literal path terminator in an encoded HTTP URL",
        "http:%2F%2Fhost/assets/component@2.js",
        "http:%2F%2Fhost/assets/component@2.js"
      ],
      [
        "an at sign after a literal query terminator in an encoded HTTP URL",
        "http:%2F%2Fhost?contact=safe@example.test",
        "http:%2F%2Fhost?contact=safe@example.test"
      ],
      [
        "an at sign after a literal fragment terminator in an encoded HTTP URL",
        "http:%2F%2Fhost#contact-safe@example.test",
        "http:%2F%2Fhost#contact-safe@example.test"
      ],
      [
        "an at sign only in an authority-relative path",
        "//host/assets/component@2.js",
        "//host/assets/component@2.js"
      ],
      [
        "a percent-encoded at sign only in an authority-relative path",
        "//host/assets/component%402.js",
        "//host/assets/component%402.js"
      ],
      [
        "multiple authority-relative URLs without userinfo",
        "URL= //safe/path//cdn.test/bundle.js",
        "URL= //safe/path//cdn.test/bundle.js"
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

    it "sanitizes literal and encoded HTTP separator compositions across ASCII whitespace spellings" do
      schemes = ["http", "HTTP", "https", "HTTPS", "h%74tp", "%68ttp", "h%74tps", "%68%74%74%70",
                 "%48%54%54%50%53"]
      separators = [":", "%3A", "%3a"]
      slashes = ["/", "%2F", "%2f"]
      whitespace_spellings = ["\t", "\n", "\v", "\f", "\r", " ", "%09", "%0A", "%0a", "%0B", "%0b",
                              "%0C", "%0c", "%0D", "%0d", "%20"]
      gap_profiles = [["", "", ""]]
      whitespace_spellings.each do |whitespace|
        gap_profiles.push([whitespace, "", ""], ["", whitespace, ""], ["", "", whitespace],
                          [whitespace, whitespace, whitespace])
      end

      schemes.product(separators, slashes, slashes, gap_profiles).each do |scheme, colon, first_slash, second_slash,
                                                                         gaps|
        before_colon, after_colon, between_slashes = gaps
        prefix = "#{scheme}#{before_colon}#{colon}#{after_colon}#{first_slash}#{between_slashes}#{second_slash}"
        configured_url = "#{prefix}synthetic-user:synthetic-secret%40host/path"
        expected_url = "#{prefix}host/path"

        expect(described_class.sanitize(configured_url)).to eq(expected_url)
        expect(sanitize_error("Failure loading #{configured_url}")).to eq("Failure loading #{expected_url}")
      end
    end

    it "sanitizes ordered literal and encoded whitespace sequences before an HTTP colon" do
      schemes = ["http", "HTTPS", "h%74tp", "%68%74%74%70%73"]
      separators = [":", "%3A", "%3a"]
      whitespace_pairs = [["\t", "%09"], ["\n", "%0A"], ["\v", "%0B"], ["\f", "%0C"],
                          ["\r", "%0D"], [" ", "%20"]]

      schemes.product(separators, whitespace_pairs).each do |scheme, separator, whitespace_pair|
        literal_whitespace, encoded_whitespace = whitespace_pair
        gaps = [
          "#{literal_whitespace}#{encoded_whitespace}",
          "#{encoded_whitespace}#{literal_whitespace}",
          "#{literal_whitespace}#{encoded_whitespace}#{literal_whitespace}",
          "#{encoded_whitespace}#{literal_whitespace}#{encoded_whitespace}"
        ]

        gaps.each do |gap|
          prefix = "#{scheme}#{gap}#{separator}%2F%2F"
          configured_url = "#{prefix}synthetic-user:synthetic-secret%40host/path"
          expected_url = "#{prefix}host/path"

          expect(described_class.sanitize(configured_url)).to eq(expected_url)
          expect(sanitize_error("Failure loading #{configured_url}")).to eq("Failure loading #{expected_url}")
        end
      end

      safe_values = [
        "nothttp%20 :%2F%2Fhost/path?mail=safe@example.test",
        "httpish%20 :%2F%2Fhost/path?mail=safe@example.test",
        "%61http%20 :%2F%2Fhost/path?mail=safe@example.test",
        "http%20 :%2F%2Fhost/path%40asset",
        "http%20 :%2F%2Fhost/path?mail=safe@example.test",
        "http%20 :%2F%2Fhost/path%23safe%40example.test"
      ]
      safe_values.each do |safe_value|
        expect(described_class.sanitize(safe_value)).to eq(safe_value)
        expect(sanitize_error("Failure loading #{safe_value}")).to eq("Failure loading #{safe_value}")
      end

      # A rejected scheme leaves an encoded bare authority, which fails closed exactly like the
      # literal spelling rather than escaping redaction because its slashes are encoded.
      rejected_scheme_authorities = [
        ["nothttp%20 :%2F%2Fsynthetic-user%40host/path", "nothttp%20 :%2F%2Fhost/path"],
        ["httpish%20 :%2F%2Fsynthetic-user%40host/path", "httpish%20 :%2F%2Fhost/path"],
        ["%61http%20 :%2F%2Fsynthetic-user%40host/path", "%61http%20 :%2F%2Fhost/path"]
      ]
      rejected_scheme_authorities.each do |configured_url, expected_url|
        expect(described_class.sanitize(configured_url)).to eq(expected_url)
      end
    end

    it "restarts an internal HTTP candidate only after an encoded non-scheme byte" do
      schemes = ["http", "https", "h%74tp", "%68%74%74%70", "%48%54%54%50%53"]
      scheme_continuation_bytes = (48..57).to_a + (65..90).to_a + (97..122).to_a + [43, 45, 46]

      (0..255).each do |byte|
        encoded_prefix = format("%%%02X", byte)
        schemes.each do |scheme|
          if scheme_continuation_bytes.include?(byte)
            safe_value = "#{encoded_prefix}#{scheme} %3A%2F%2Fhost/path?mail=safe@example.test"
            expect(described_class.sanitize(safe_value)).to eq(safe_value)
            expect(sanitize_error("Failure loading #{safe_value}")).to eq("Failure loading #{safe_value}")
          else
            configured_url =
              "#{encoded_prefix}#{scheme} %3A%2F%2Fsynthetic-user:synthetic-secret%40host/path"
            expected_url = "#{encoded_prefix}#{scheme} %3A%2F%2Fhost/path"

            expect(described_class.sanitize(configured_url)).to eq(expected_url)
            expect(sanitize_error("Failure loading #{configured_url}")).to eq("Failure loading #{expected_url}")
          end
        end
      end

      invalid_percent_controls = ["%GGhttp", "%61http", "%61%2Dhttp", "a%20nothttp", "a%20httpish"]
      invalid_percent_controls.each do |prefix|
        safe_value = "#{prefix} %3A%2F%2Fhost/path?mail=safe@example.test"
        expect(described_class.sanitize(safe_value)).to eq(safe_value)
        expect(sanitize_error("Failure loading #{safe_value}")).to eq("Failure loading #{safe_value}")

        # The rejected scheme still leaves an encoded bare authority, which fails closed.
        expect(described_class.sanitize("#{prefix} %3A%2F%2Fsynthetic-user%40host/path"))
          .to eq("#{prefix} %3A%2F%2Fhost/path")
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
        "whitespace before fully encoded authority separators",
        "Failure loading http: %2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading http: %2F%2Fhost/path"
      ],
      [
        "whitespace around a literal colon before encoded authority separators",
        "Failure loading http : %2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading http : %2F%2Fhost/path"
      ],
      [
        "whitespace before an encoded colon and encoded authority separators",
        "Failure loading http %3A%2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading http %3A%2F%2Fhost/path"
      ],
      [
        "a partially encoded HTTP scheme before a whitespace-delimited encoded colon",
        "Failure loading h%74tp %3A%2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading h%74tp %3A%2F%2Fhost/path"
      ],
      [
        "an encoded whitespace token before an internal HTTP scheme",
        "Failure loading %20http %3A%2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading %20http %3A%2F%2Fhost/path"
      ],
      [
        "whitespace before a literal and encoded authority separator",
        "Failure loading http: /%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading http: /%2Fhost/path"
      ],
      [
        "whitespace before an encoded and literal authority separator",
        "Failure loading http: %2F/synthetic-user:synthetic-secret%40host/path",
        "Failure loading http: %2F/host/path"
      ],
      [
        "whitespace between encoded authority separators",
        "Failure loading http:%2F %2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading http:%2F %2Fhost/path"
      ],
      [
        "encoded whitespace before encoded authority separators",
        "Failure loading http:%20%2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading http:%20%2F%2Fhost/path"
      ],
      [
        "encoded whitespace between encoded authority separators",
        "Failure loading http:%2F%20%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading http:%2F%20%2Fhost/path"
      ],
      [
        "mixed literal and encoded whitespace around mixed authority separators",
        "Failure loading h%74tp \t%20%3A%0A/%09%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading h%74tp \t%20%3A%0A/%09%2Fhost/path"
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
      ],
      [
        "non-URL prose with whitespace before a colon and double slash",
        "Contact support : // contact safe@example.test",
        "Contact support : // contact safe@example.test"
      ],
      [
        "non-URL prose with encoded separators",
        "Contact support %3A %2F %2Fsafe@example.test",
        "Contact support %3A %2F %2Fsafe@example.test"
      ],
      [
        "a non-HTTP word before encoded separators",
        "Contact nothttp %3A%2F%2Fhost/path?mail=safe@example.test",
        "Contact nothttp %3A%2F%2Fhost/path?mail=safe@example.test"
      ],
      [
        "an encoded bare authority after a non-HTTP word",
        "Contact nothttp %3A%2F%2Fsynthetic-user%40host/path",
        "Contact nothttp %3A%2F%2Fhost/path"
      ],
      [
        "an encoded bare authority in prose",
        "Failure loading %2F%2Fsynthetic-user:synthetic-secret%40host/path",
        "Failure loading %2F%2Fhost/path"
      ],
      [
        "a mixed-slash bare authority in prose",
        "Failure loading /%2Fsynthetic-user:synthetic-secret@host/path",
        "Failure loading /%2Fhost/path"
      ],
      [
        "an HTTP-prefixed word before encoded separators",
        "Contact httpish %3A%2F%2Fhost/path?mail=safe@example.test",
        "Contact httpish %3A%2F%2Fhost/path?mail=safe@example.test"
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

    it "sanitizes an authority-relative credential inside a discarded unresolved region" do
      message = "//synthetic-admin:synthetic-secret@internal.host then " \
                "http://synthetic-user:nonnumeric-prefix\nsynthetic-tail " \
                "HtTpS://synthetic-other@host/path"

      expect(sanitize_error(message)).to eq("//internal.host then https://host/path")
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

    it "preserves a large diagnostic with many incomplete HTTP URL starts" do
      message = "Failure loading #{'http://' * 10_000}host/path@example.test"
      expect(message.bytesize).to be > 65_536

      expect(sanitize_error(message)).to eq(message)
    end

    it "processes a large multibyte diagnostic with many incomplete HTTP URL starts in bounded time" do
      message = "éhttp://" * 16_000
      expect(message.bytesize).to be > 131_072

      sanitized = Timeout.timeout(1) { sanitize_error(message) }
      expect(sanitized).to eq(message)
    end

    it "processes a long encoded-authority near-match in bounded time" do
      configured_url = "é#{'a' * 32_000}:/"
      message = "Failure loading #{configured_url}"

      sanitized_url, sanitized_message = Timeout.timeout(1) do
        [described_class.sanitize(configured_url), sanitize_error(message, configured_url:)]
      end
      expect(sanitized_url).to eq(configured_url)
      expect(sanitized_message).to eq(message)
    end

    it "redacts a long whitespace-delimited encoded authority in bounded time" do
      whitespace = " " * 32_000
      configured_url = "http:#{whitespace}%2F%2Fbundle-user:synthetic-password%40host/path"
      expected_url = "http:#{whitespace}%2F%2Fhost/path"

      sanitized_url = Timeout.timeout(1) { described_class.sanitize(configured_url) }
      expect(sanitized_url).to eq(expected_url)
    end

    it "redacts long whitespace before an encoded colon and between encoded slashes in bounded time" do
      whitespace = " " * 32_000
      configured_url = "h%74tp#{whitespace}%3A%2F#{whitespace}%2Fbundle-user:synthetic-password%40host/path"
      expected_url = "h%74tp#{whitespace}%3A%2F#{whitespace}%2Fhost/path"

      sanitized_url = Timeout.timeout(1) { described_class.sanitize(configured_url) }

      expect(sanitized_url).to eq(expected_url)
    end

    it "redacts long encoded whitespace around encoded authority separators in bounded time" do
      whitespace = "%20" * 16_000
      configured_url = "http:#{whitespace}%2F#{whitespace}%2Fbundle-user:synthetic-password%40host/path"
      expected_url = "http:#{whitespace}%2F#{whitespace}%2Fhost/path"

      sanitized_url = Timeout.timeout(1) { described_class.sanitize(configured_url) }

      expect(sanitized_url).to eq(expected_url)
    end

    it "redacts a long mixed whitespace sequence before an encoded colon in bounded time" do
      whitespace = "%20 " * 16_000
      configured_url = "h%74tp#{whitespace}%3A%2F%2Fbundle-user:synthetic-password%40host/path"
      expected_url = "h%74tp#{whitespace}%3A%2F%2Fhost/path"

      sanitized_url = Timeout.timeout(1) { described_class.sanitize(configured_url) }

      expect(sanitized_url).to eq(expected_url)
    end

    it "redacts an internal HTTP URL after a long encoded boundary prefix in bounded time" do
      prefix = "%61%20" * 16_000
      configured_url = "#{prefix}http %3A%2F%2Fbundle-user:synthetic-password%40host/path"
      expected_url = "#{prefix}http %3A%2F%2Fhost/path"

      sanitized_url = Timeout.timeout(1) { described_class.sanitize(configured_url) }

      expect(sanitized_url).to eq(expected_url)
    end

    it "redacts after repeated fully encoded authority separators in bounded time" do
      [2, 4_000].each do |count|
        prefix = "a%3A%2F%2F" * count
        configured_url = "#{prefix}bundle-user:synthetic-password%40host/path"
        expected_url = "#{prefix}host/path"

        sanitized_url = Timeout.timeout(1) { described_class.sanitize(configured_url) }
        expect(sanitized_url).to eq(expected_url)
      end
    end

    it "redacts repeated bare authority markers without a scheme in bounded time" do
      [2, 4_000].each do |count|
        message = %(prefix //a "b '#{'//segment "gap \'tail ' * count}//user:synthetic-secret@host/path)

        sanitized = Timeout.timeout(1) { sanitize_error(message) }
        expect(sanitized).not_to include("synthetic-secret")
      end
    end
  end
end
