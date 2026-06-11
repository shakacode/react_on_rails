# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe FontHelper do
    # Plain object that includes the helper module the way an ActionView context would.
    let(:view) { Class.new { include ReactOnRails::FontHelper }.new }

    # Documented Inter-over-Arial fallback metrics. See docs/oss/building-features/fonts.md
    # for how these are derived from @capsizecss/metrics.
    let(:inter_fallback) do
      {
        family: "Arial",
        size_adjust: "107.12%",
        ascent_override: "90.44%",
        descent_override: "22.52%",
        line_gap_override: "0.0%"
      }
    end

    describe "#react_on_rails_font_face" do
      subject(:markup) do
        view.react_on_rails_font_face(
          family: "Inter",
          src: "/assets/inter-latin-400-normal-abc123.woff2",
          weight: 400,
          fallback: inter_fallback
        )
      end

      it "returns html_safe markup so it can be placed in content_for(:head)" do
        expect(markup).to be_html_safe
      end

      it "emits a correct font preload link" do
        expect(markup).to include(
          '<link rel="preload" href="/assets/inter-latin-400-normal-abc123.woff2" ' \
          'as="font" type="font/woff2" crossorigin="anonymous">'
        )
      end

      it "emits an @font-face with font-display: swap" do
        expect(markup).to include("@font-face {")
        expect(markup).to include('font-family: "Inter";')
        expect(markup).to include('src: url("/assets/inter-latin-400-normal-abc123.woff2") format("woff2");')
        expect(markup).to include("font-weight: 400;")
        expect(markup).to include("font-display: swap;")
      end

      it "emits a metric-matched fallback @font-face with size-adjust and overrides" do
        expect(markup).to include('font-family: "Inter Fallback";')
        expect(markup).to include('src: local("Arial");')
        expect(markup).to include("size-adjust: 107.12%;")
        expect(markup).to include("ascent-override: 90.44%;")
        expect(markup).to include("descent-override: 22.52%;")
        expect(markup).to include("line-gap-override: 0.0%;")
      end
    end

    describe ".font_face_markup" do
      it "omits the preload link when preload: false" do
        markup = described_class.font_face_markup(
          family: "Inter", src: "/assets/inter.woff2", preload: false
        )
        expect(markup).not_to include("rel=\"preload\"")
        expect(markup).to include("@font-face {")
      end

      it "omits the fallback face when no fallback is given" do
        markup = described_class.font_face_markup(family: "Inter", src: "/assets/inter.woff2")
        expect(markup).to include('font-family: "Inter";')
        expect(markup).not_to include("size-adjust")
        expect(markup).not_to include("Fallback")
      end

      it "includes a unicode-range when given (subsetting guidance)" do
        markup = described_class.font_face_markup(
          family: "Inter", src: "/assets/inter.woff2",
          unicode_range: "U+0000-00FF"
        )
        expect(markup).to include("unicode-range: U+0000-00FF;")
      end

      it "supports a custom fallback face name and variable-font weight range" do
        markup = described_class.font_face_markup(
          family: "Inter", src: "/assets/inter.woff2", weight: "100 900",
          fallback: { family: "Arial", name: "Inter Variable Fallback", size_adjust: "107.12%" }
        )
        expect(markup).to include("font-weight: 100 900;")
        expect(markup).to include('font-family: "Inter Variable Fallback";')
      end

      it "defaults font-style to normal and font-display to swap" do
        markup = described_class.font_face_markup(family: "Inter", src: "/assets/inter.woff2")
        expect(markup).to include("font-style: normal;")
        expect(markup).to include("font-display: swap;")
      end

      it "raises if a fallback is given without a system :family to map to" do
        expect do
          described_class.font_face_markup(
            family: "Inter", src: "/assets/inter.woff2", fallback: { size_adjust: "107%" }
          )
        end.to raise_error(KeyError)
      end

      it "raises if a value contains markup-breaking characters" do
        expect do
          described_class.font_face_markup(
            family: 'Inter"></style><script>alert(1)</script>', src: "/assets/inter.woff2"
          )
        end.to raise_error(ArgumentError, /unsafe character/)
      end
    end
  end
end
