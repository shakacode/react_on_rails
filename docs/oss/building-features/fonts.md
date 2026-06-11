# Font Optimization (a `next/font/local` analog)

Web fonts are a classic source of two performance problems:

1. **Render-blocking external requests** when you load fonts from a third-party
   host (e.g. the Google Fonts CDN) — an extra origin connection plus a
   privacy/GDPR consideration.
2. **Cumulative Layout Shift (CLS)** when the browser re-renders text after the
   web font replaces the fallback font, because the two fonts have different
   metrics.

`next/font` solves both by self-hosting the font, preloading it, setting
`font-display`, and generating a metric-matched fallback face. React on Rails
ships a small first-party helper that does the same thing on Rails — no
third-party dependency, no build plugin. You self-host (commit + fingerprint) a
`.woff2` through your asset pipeline and the helper emits the correct `<head>`
markup.

> This is the OSS v1: the **`next/font/local`** path (you commit the font file).
> Build-time Google-Fonts fetching (`next/font/google`) and automatic per-font
> metric derivation are tracked as follow-ups.

See also: [Configuring Images and Assets with Webpack](./images.md).

## The helper

`ReactOnRails::FontHelper#react_on_rails_font_face` is mixed into the standard
view helpers. It returns markup for the document `<head>`:

1. `<link rel="preload" as="font" type="font/woff2" crossorigin>` so the browser
   fetches the font in parallel with first paint;
2. an `@font-face` rule with `font-display: swap`;
3. an optional **metric-matched fallback** `@font-face` (`size-adjust` plus
   `ascent-override` / `descent-override` / `line-gap-override`) so the system
   fallback occupies the same space as the web font.

It uses the same `<head>`-injection convention as
[`react_component_hash`](./react-helmet.md): wrap the return value in
`content_for :head`, and yield it from your layout's `<head>`.

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <%= yield :head %>
  <%# ... %>
</head>
```

```erb
<%# your view %>
<% content_for :head do %>
  <%= react_on_rails_font_face(
        family: "Inter",
        src: asset_path("inter-latin-400-normal.woff2"),
        weight: 400,
        fallback: {
          family: "Arial",
          size_adjust: "107.12%",
          ascent_override: "90.44%",
          descent_override: "22.52%",
          line_gap_override: "0.0%"
        }
      ) %>
<% end %>
```

Then set your CSS font stack to the web font, then the generated fallback face,
then a generic family:

```css
body {
  font-family: 'Inter', 'Inter Fallback', Arial, sans-serif;
}
```

### Options

| Option           | Default    | Notes                                                          |
| ---------------- | ---------- | -------------------------------------------------------------- |
| `family:`        | (required) | CSS `font-family` name for the web font.                       |
| `src:`           | (required) | URL to the `.woff2`. Use `asset_path(...)` for fingerprinting. |
| `weight:`        | `400`      | A range like `"100 900"` is valid for variable fonts.          |
| `style:`         | `"normal"` | `font-style`.                                                  |
| `display:`       | `"swap"`   | `font-display`. `swap` shows fallback text immediately.        |
| `unicode_range:` | `nil`      | Emit a `unicode-range` to subset the face (see below).         |
| `preload:`       | `true`     | Emit the preload `<link>`.                                     |
| `fallback:`      | `nil`      | Metric-matched fallback face (see below).                      |

## Self-hosting through the asset pipeline

Commit the `.woff2` file into your asset pipeline so it is fingerprinted and
served with a far-future cache header. With Sprockets/Propshaft, place it under
`app/assets/fonts/` (or `vendor/assets`) and reference it with
`asset_path("inter-latin-400-normal.woff2")`. With Shakapacker, import the font
from your pack and pass the resolved URL. Either way the font is served from your
own origin — there is no runtime request to a third-party font host.

## `font-display: swap`

`swap` tells the browser to render text immediately with the fallback font and
swap in the web font when it arrives. This avoids invisible text (the "FOIT"
flash of invisible text) at the cost of a "FOUT" flash of unstyled text — which
the fallback-metrics technique below makes nearly invisible.

## The `size-adjust` fallback (eliminating CLS)

`font-display: swap` shows fallback text first, then swaps in the web font. If
the fallback and the web font have different metrics, text **reflows** on the
swap — that reflow is CLS. The fix (the same one `next/font` uses) is a second
`@font-face` that takes a **local** system font and adjusts its metrics with
`size-adjust`, `ascent-override`, `descent-override`, and `line-gap-override` so
it occupies exactly the space the real web font will. See
[web.dev: font best practices](https://web.dev/articles/font-best-practices) and
[Chrome: improved font fallbacks](https://developer.chrome.com/blog/font-fallbacks/).

### Deriving the numbers (worked example: Inter over Arial)

These values must be derived from the actual font metrics — do not guess. The
example below uses metrics from
[`@capsizecss/metrics`](https://github.com/seek-oss/capsize) `v4.0.0` (the same
data source `next/font` and `fontaine` use). All values share `unitsPerEm: 2048`.

| Metric       | Inter (web font) | Arial (fallback) |
| ------------ | ---------------- | ---------------- |
| `xWidthAvg`  | 978              | 913              |
| `ascent`     | 1984             | 1854             |
| `descent`    | -494             | -434             |
| `lineGap`    | 0                | 67               |
| `unitsPerEm` | 2048             | 2048             |

`size-adjust` scales the fallback so its average character width matches the web
font:

```
size-adjust = (inter.xWidthAvg / inter.unitsPerEm) / (arial.xWidthAvg / arial.unitsPerEm)
            = (978 / 2048) / (913 / 2048)
            = 1.0712  ->  107.12%
```

The overrides describe the **web font's** vertical metrics, scaled by
`size-adjust` so the adjusted fallback's line box matches:

```
ascent-override   = (inter.ascent  / inter.unitsPerEm) / size-adjust = 0.9044 -> 90.44%
descent-override  = (|inter.descent| / inter.unitsPerEm) / size-adjust = 0.2252 -> 22.52%
line-gap-override = (inter.lineGap / inter.unitsPerEm) / size-adjust = 0.0    -> 0.0%
```

These match the values `next/font/local` generates for Inter with an Arial
fallback. For other fonts, plug the font's own metrics into the same formulas,
or read the generated numbers from your `next/font` setup if you are migrating.

## Subsetting guidance

Ship only the glyphs you need. A full font can be hundreds of KB; a `latin`
subset is typically 15–30 KB. Sensible default: **start with the `latin`
subset** for English-language sites, then add `latin-ext` if you need accented
European characters. Declare the covered range with `unicode_range:` so the
browser can skip the download when a page has no matching glyphs:

```erb
<%= react_on_rails_font_face(
      family: "Inter",
      src: asset_path("inter-latin-400-normal.woff2"),
      unicode_range: "U+0000-00FF, U+0131, U+0152-0153, U+2000-206F"
    ) %>
```

Most font distributions (e.g. [Fontsource](https://fontsource.org)) ship
per-subset `.woff2` files plus the matching `unicode-range` for each — commit the
subset you need and copy its range.

## Core Web Vitals (CLS) note

Self-hosting + preload removes the render-blocking third-party request; the
`size-adjust` fallback removes the layout shift on swap. Together they target two
Core Web Vitals at once (LCP/render time and CLS). To verify, record CLS in
Chrome DevTools (Performance panel) or the
[web-vitals](https://github.com/GoogleChrome/web-vitals) library before and after
adding the fallback face: the font-swap layout shift should drop to ~0.

## Runnable example

A working example lives in the dummy app:

- View: `react_on_rails/spec/dummy/app/views/pages/font_optimization_example.html.erb`
- Vendored font: `react_on_rails/spec/dummy/public/fonts/inter-latin-400-normal.woff2`
  (Inter, OFL-1.1 — see `public/fonts/LICENSE-Inter.txt`)
- Unit spec: `react_on_rails/spec/react_on_rails/font_helper_spec.rb`
- Request spec: `react_on_rails/spec/dummy/spec/requests/font_optimization_spec.rb`

## Known follow-ups (not in v1)

- **Build-time Google-Fonts fetching** (the `next/font/google` path): fetch and
  vendor a Google font at build time instead of committing the file.
- **Automatic per-font metric derivation**: compute the `size-adjust` and
  override values programmatically from the font binary instead of hardcoding
  documented numbers.
- **Pro streaming-shell coverage**: ensure the preload `<link>` lands in the
  streaming shell before the first body flush (see
  `react_on_rails_pro/lib/react_on_rails_pro/concerns/stream.rb`). v1 covers the
  non-streaming `react_component_hash` head-injection path only.
