# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRailsPro
  RSpec.describe RendererCachePath do
    before do
      described_class.send(:reset_deprecation_warned!)
    end

    after do
      ENV.delete("RENDERER_SERVER_BUNDLE_CACHE_PATH")
      ENV.delete("RENDERER_BUNDLE_PATH")
      described_class.send(:reset_deprecation_warned!)
    end

    describe ".resolve" do
      it "returns RENDERER_SERVER_BUNDLE_CACHE_PATH verbatim, including surrounding whitespace" do
        ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] = "  /tmp/renderer-cache  "

        # Whitespace is preserved so the Rails pre-seed lands in the same path
        # the Node renderer reads (it consumes the env var verbatim in
        # configBuilder.ts).
        expected_warning = Regexp.escape(
          "RENDERER_SERVER_BUNDLE_CACHE_PATH has surrounding whitespace and will be used verbatim: " \
          '"  /tmp/renderer-cache  "'
        )
        expect { @result = described_class.resolve }
          .to output(/#{expected_warning}/).to_stderr
        expect(@result).to eq("  /tmp/renderer-cache  ")
      end

      it "does not warn when RENDERER_SERVER_BUNDLE_CACHE_PATH has no surrounding whitespace" do
        ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] = "/tmp/renderer-cache"

        expect { @result = described_class.resolve }.not_to output.to_stderr
        expect(@result).to eq("/tmp/renderer-cache")
      end

      it "returns RENDERER_BUNDLE_PATH verbatim when only the deprecated var is set" do
        ENV["RENDERER_BUNDLE_PATH"] = " /tmp/legacy-cache "

        # Lookahead-based match so the assertion is order-independent: both the
        # deprecation notice and the whitespace warning must appear, but either
        # may print first since they come from different code paths.
        whitespace_warning = Regexp.escape(
          'RENDERER_BUNDLE_PATH has surrounding whitespace and will be used verbatim: " /tmp/legacy-cache "'
        )
        expected_warning = Regexp.new(
          "(?=.*RENDERER_BUNDLE_PATH is deprecated)" \
          "(?=.*#{whitespace_warning})",
          Regexp::MULTILINE
        )
        expect { @result = described_class.resolve }
          .to output(expected_warning)
          .to_stderr
        expect(@result).to eq(" /tmp/legacy-cache ")
      end

      it "raises when the preferred env var is whitespace-only" do
        ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] = "  "
        ENV["RENDERER_BUNDLE_PATH"] = "/tmp/legacy-cache"

        expect { described_class.resolve }
          .to raise_error(ReactOnRailsPro::Error, /RENDERER_SERVER_BUNDLE_CACHE_PATH is whitespace-only/)
      end

      it "raises when the deprecated env var is whitespace-only" do
        ENV["RENDERER_BUNDLE_PATH"] = "\t\n"

        expect { described_class.resolve }
          .to raise_error(ReactOnRailsPro::Error, /RENDERER_BUNDLE_PATH is whitespace-only/)
      end

      it "returns the default cache dir when neither env var is set" do
        expect(described_class.resolve).to eq(Rails.root.join(".node-renderer-bundles").to_s)
      end
    end
  end
end
