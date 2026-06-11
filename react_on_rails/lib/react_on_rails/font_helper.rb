# frozen_string_literal: true

require "active_support/concern"

module ReactOnRails
  # First-party font optimization helper, a `next/font/local` analog for Rails.
  #
  # Given a self-hosted (committed + fingerprinted) `.woff2` file already served by
  # your asset pipeline, this returns the markup an ERB view should place in the
  # document `<head>`:
  #
  #   1. `<link rel="preload" as="font" type="font/woff2" crossorigin>` so the
  #      browser fetches the font in parallel with the first paint;
  #   2. an `@font-face` rule with `font-display: swap` so text renders immediately
  #      with a fallback and swaps in the web font when ready;
  #   3. an optional metric-matched fallback `@font-face` (`size-adjust` plus
  #      `ascent-override` / `descent-override` / `line-gap-override`) so the system
  #      fallback occupies the same space as the web font, eliminating the layout
  #      shift (CLS) that normally happens on the swap.
  #
  # It mirrors the `<head>`-injection convention used by `react_component_hash`
  # (see `ReactOnRails::Helper`): the caller wraps the return value in
  # `content_for :head`, and the layout yields it inside `<head>`.
  #
  # Example (ERB view):
  #
  #   <% content_for :head do %>
  #     <%= react_on_rails_font_face(
  #           family: "Inter",
  #           src: asset_path("inter-latin-400-normal.woff2"),
  #           weight: 400,
  #           fallback: {
  #             family: "Arial",
  #             size_adjust: "107.12%",
  #             ascent_override: "90.44%",
  #             descent_override: "22.52%",
  #             line_gap_override: "0.0%"
  #           }
  #         ) %>
  #   <% end %>
  #
  # Then set the CSS font stack to the web font followed by its fallback face, e.g.
  # `font-family: "Inter", "Inter Fallback", sans-serif;`.
  module FontHelper
    extend ActiveSupport::Concern

    # CSS/HTML metacharacters that would let an argument break out of the
    # `<style>` / `<link>` context this helper emits.
    UNSAFE_TOKEN = /[<>"\r\n]/

    # Emits the preload `<link>`, the primary `@font-face`, and (when `fallback:`
    # is supplied) a metric-matched fallback `@font-face`.
    #
    # @param family [String] CSS font-family name for the web font (e.g. "Inter").
    # @param src [String] URL/path to the `.woff2` (typically `asset_path(...)`).
    # @param weight [Integer, String] `font-weight` (default 400). A range like
    #   "100 900" is valid for variable fonts.
    # @param style [String] `font-style` (default "normal").
    # @param display [String] `font-display` (default "swap").
    # @param unicode_range [String, nil] optional `unicode-range` to subset the face.
    # @param preload [Boolean] emit the preload `<link>` (default true).
    # @param fallback [Hash, nil] metric-matched fallback face. Keys:
    #   :family (required, the local system font, e.g. "Arial"),
    #   :name (the generated face name, default "#{family} Fallback"),
    #   :size_adjust, :ascent_override, :descent_override, :line_gap_override.
    # @return [ActiveSupport::SafeBuffer] head markup, ready for `content_for :head`.
    #
    # @note SECURITY: arguments are interpolated verbatim into the trusted CSS/HTML
    #   emitted into `<head>` and the result is marked `html_safe`. Pass only
    #   developer-controlled values (font names, asset paths), never end-user input.
    #   Values containing `<`, `>`, `"`, or a newline raise `ArgumentError`.
    def react_on_rails_font_face(family:, src:, weight: 400, style: "normal", display: "swap",
                                 unicode_range: nil, preload: true, fallback: nil)
      ReactOnRails::FontHelper.font_face_markup(
        family:, src:, weight:, style:, display:,
        unicode_range:, preload:, fallback:
      ).html_safe
    end

    # Pure-string builder so the markup can be unit-tested without a view context.
    # Returns a plain (not html_safe) String.
    def self.font_face_markup(family:, src:, weight: 400, style: "normal", display: "swap",
                              unicode_range: nil, preload: true, fallback: nil)
      ensure_safe!("family", family)
      ensure_safe!("src", src)
      if fallback
        ensure_safe!("fallback[:family]", fallback.fetch(:family))
        ensure_safe!("fallback[:name]", fallback[:name]) if fallback[:name]
      end
      rule = font_face_rule(family:, src:, weight:, style:, display:, unicode_range:)
      parts = []
      parts << preload_link(src) if preload
      parts << +"<style>\n#{rule}"
      parts[-1] << "\n#{fallback_font_face_rule(family, fallback)}" if fallback
      parts[-1] << "\n</style>"
      parts.join("\n")
    end

    # Rejects values that could break out of the CSS/HTML context. Font helper
    # arguments are emitted into trusted `<head>` markup, so they must be
    # developer-controlled, not end-user input.
    def self.ensure_safe!(name, value)
      return unless value.to_s.match?(UNSAFE_TOKEN)

      raise ArgumentError,
            "react_on_rails_font_face: #{name}=#{value.inspect} contains an unsafe character " \
            "(<, >, \", or newline); font arguments must be developer-controlled, not end-user input."
    end

    def self.preload_link(src)
      %(<link rel="preload" href="#{src}" as="font" type="font/woff2" crossorigin="anonymous">)
    end

    def self.font_face_rule(family:, src:, weight:, style:, display:, unicode_range:)
      lines = [
        "@font-face {",
        %(  font-family: "#{family}";),
        %(  src: url("#{src}") format("woff2");),
        "  font-weight: #{weight};",
        "  font-style: #{style};",
        "  font-display: #{display};"
      ]
      lines << "  unicode-range: #{unicode_range};" if unicode_range
      lines << "}"
      lines.join("\n")
    end

    # Generates the metric-matched fallback face. Hardcode `size-adjust` and the
    # override percentages from the font's published metrics (see the fonts docs
    # for how the Inter-over-Arial numbers are derived).
    def self.fallback_font_face_rule(family, fallback)
      name = fallback[:name] || "#{family} Fallback"
      local = fallback.fetch(:family)
      lines = ["@font-face {", %(  font-family: "#{name}";), %(  src: local("#{local}");)]
      lines << "  size-adjust: #{fallback[:size_adjust]};" if fallback[:size_adjust]
      lines << "  ascent-override: #{fallback[:ascent_override]};" if fallback[:ascent_override]
      lines << "  descent-override: #{fallback[:descent_override]};" if fallback[:descent_override]
      lines << "  line-gap-override: #{fallback[:line_gap_override]};" if fallback[:line_gap_override]
      lines << "}"
      lines.join("\n")
    end
  end
end
