# Fast Images in React on Rails

Next.js markets `next/image` as a single component that solves responsive
images, lazy loading, modern formats, layout-shift (CLS) prevention, and LCP
prioritization. Rails already ships the primitives for every one of those
concerns — no hosted image service, no Vercel lock-in. This recipe shows how to
combine them in a React on Rails app, both in ERB views and in React components
rendered with `react_component`.

> **A first-party `<Image>` component is under consideration** for React on
> Rails (see [issue #3874](https://github.com/shakacode/react_on_rails/issues/3874)).
> Everything on this page works today with stock Rails — the proposed component
> would only package these defaults, not replace them.

For configuring webpack to _bundle_ images imported from your JavaScript (the
asset-loading side), see
[Configuring Images and Assets with Webpack](./images.md). This page is about
the _markup and serving_ side: what the browser receives.

## The checklist

A "fast image" means:

1. **Responsive `srcset` + `sizes`** — the browser downloads a size appropriate
   for the layout, not a 2400px original on a phone.
2. **Intrinsic `width`/`height` (+ CSS `aspect-ratio`)** — layout space is
   reserved before the image loads, so there is no CLS.
3. **`loading="lazy"` + `decoding="async"`** on everything below the fold.
4. **`fetchpriority="high"` + `loading="eager"` + a preload** on the LCP/hero
   image only.
5. **AVIF/WebP with a fallback** via `<picture>`.

## Responsive `srcset` from the asset pipeline

For images that ship with your app (Sprockets/Propshaft), commit the size
variants and let `image_tag` build the `srcset`. Hash keys are resolved through
the asset pipeline just like the main `src`, so fingerprinting works:

```erb
<%= image_tag("team-photo-800.jpg",
      srcset: {
        "team-photo-400.jpg" => "400w",
        "team-photo-800.jpg" => "800w",
        "team-photo-1600.jpg" => "1600w"
      },
      sizes: "(max-width: 600px) 100vw, 600px",
      width: 800,
      height: 533,
      loading: "lazy",
      decoding: "async",
      alt: "The team at launch") %>
```

`sizes` tells the browser how wide the image will render at each viewport
width; without it the browser assumes `100vw` and over-downloads.

## Responsive `srcset` from Active Storage variants

For user-uploaded images, generate the width set with
[Active Storage variants](https://guides.rubyonrails.org/active_storage_overview.html#transforming-images).
You need the `image_processing` gem (libvips recommended):

```ruby
# Gemfile
gem "image_processing", "~> 1.2"
```

```erb
<%# app/views/products/show.html.erb %>
<% widths = [400, 800, 1600] %>
<% variants = widths.index_with { |w| @product.photo.variant(resize_to_limit: [w, nil]) } %>
<%= image_tag url_for(variants[800].processed),
      srcset: widths.map { |w| "#{url_for(variants[w].processed)} #{w}w" }.join(", "),
      sizes: "(max-width: 600px) 100vw, 600px",
      width: 800,
      height: (800 * @product.photo_aspect_ratio).round,
      loading: "lazy",
      decoding: "async",
      alt: @product.name %>
```

:::warning Request-time variant generation is a performance footgun

`variant(...)` does **not** resize anything until the variant is first served.
With the default redirect mode, the first visitor to hit each width pays the
transformation cost (or times out on large images), and a cold cache after a
storage migration pays it again for every image on the page — multiplied by
every width in your `srcset`.

Treat request-time generation as a fallback, not the plan:

- **Pre-generate variants** when the upload happens, in a background job, by
  calling `.processed` (which transforms and uploads the variant if missing):

  ```ruby
  class Product < ApplicationRecord
    has_one_attached :photo do |attachable|
      attachable.variant :w400, resize_to_limit: [400, nil], preprocessed: true
      attachable.variant :w800, resize_to_limit: [800, nil], preprocessed: true
      attachable.variant :w1600, resize_to_limit: [1600, nil], preprocessed: true
    end
  end
  ```

  Named variants with `preprocessed: true` (Rails 7.1+) enqueue transformation
  right after upload instead of on first request. Reference them as
  `@product.photo.variant(:w800)`.

- **Run `analyze` on attach** (Active Storage does this by default via a job)
  so `metadata[:width]`/`metadata[:height]` are available for CLS attributes
  without downloading the blob.

- **Serve through a CDN.** Put a CDN in front of your storage service (or use
  [proxy mode](https://guides.rubyonrails.org/active_storage_overview.html#putting-a-cdn-in-front-of-active-storage)
  plus a CDN in front of the app) so each generated variant is transformed
  once and cached at the edge — not re-served by your Rails dynos.

:::

To get intrinsic dimensions for the `width`/`height` attributes, read the
analyzed metadata instead of hardcoding:

```ruby
# app/models/product.rb
def photo_aspect_ratio
  meta = photo.metadata
  return 2.0 / 3 unless meta["width"].to_i.positive?

  meta["height"].to_f / meta["width"]
end
```

## Passing image props to a React component

When the `<img>` lives inside a React component, keep the URL math in Rails —
where the asset pipeline and Active Storage live — and hand React a plain props
hash via `react_component`. Compute the props in a helper:

```ruby
# app/helpers/images_helper.rb
module ImagesHelper
  RESPONSIVE_WIDTHS = [400, 800, 1600].freeze

  # Returns {src:, srcSet:, sizes:, width:, height:} for an Active Storage attachment.
  def responsive_image_props(attachment, sizes: "100vw", display_width: 800)
    variants = RESPONSIVE_WIDTHS.index_with do |w|
      attachment.variant(resize_to_limit: [w, nil]).processed
    end
    width = attachment.metadata["width"].to_i
    height = attachment.metadata["height"].to_i
    aspect_ratio = width.positive? ? height.to_f / width : 2.0 / 3

    {
      src: url_for(variants[display_width]),
      srcSet: RESPONSIVE_WIDTHS.map { |w| "#{url_for(variants[w])} #{w}w" }.join(", "),
      sizes: sizes,
      width: display_width,
      height: (display_width * aspect_ratio).round
    }
  end
end
```

```erb
<%# app/views/products/show.html.erb %>
<%= react_component("ProductHero", props: {
      name: @product.name,
      image: responsive_image_props(@product.photo, sizes: "(max-width: 600px) 100vw, 600px")
    }) %>
```

The React side is just an `<img>` spreading those attributes — it renders
identically on the server and client, so there is nothing to hydrate
incorrectly:

```jsx
// app/javascript/src/ProductHero/ror_components/ProductHero.jsx
export default function ProductHero({ name, image }) {
  return (
    <figure>
      <img
        src={image.src}
        srcSet={image.srcSet}
        sizes={image.sizes}
        width={image.width}
        height={image.height}
        loading="lazy"
        decoding="async"
        alt={name}
      />
      <figcaption>{name}</figcaption>
    </figure>
  );
}
```

For asset-pipeline images the same pattern applies — build the hash with
`image_path`/`image_url` instead of `url_for(variant)`.

## CLS prevention: intrinsic size + `aspect-ratio`

Always emit `width` and `height` attributes (the intrinsic pixel dimensions,
not the display size). Browsers use them to reserve the correct box before the
bytes arrive, which is what keeps CLS at zero. Then let CSS control the actual
display size:

```css
img {
  max-width: 100%;
  height: auto; /* keep the reserved aspect ratio when width is constrained */
}
```

If you size an image with CSS alone (e.g. a `background-size: cover`-style
crop), reserve the space explicitly:

```css
.card-thumb {
  aspect-ratio: 3 / 2;
  width: 100%;
  object-fit: cover;
}
```

## Defaults for non-hero images

Every image that can start below the fold should opt out of competing with
critical resources:

- `loading="lazy"` — the browser defers the download until the image nears the
  viewport.
- `decoding="async"` — decode off the main thread instead of blocking paint.

These are plain attributes in both ERB (`loading: "lazy", decoding: "async"`)
and JSX (`loading="lazy" decoding="async"`). They are the right default for
everything **except** the LCP image — lazy-loading the hero is one of the most
common LCP regressions.

## The LCP/hero image: prioritize and preload

For the one image that is your [Largest Contentful Paint](https://web.dev/articles/optimize-lcp)
element, invert the defaults:

```erb
<%= image_tag("hero-1600.jpg",
      srcset: { "hero-800.jpg" => "800w", "hero-1600.jpg" => "1600w" },
      sizes: "100vw",
      width: 1600,
      height: 900,
      loading: "eager",
      fetchpriority: "high",
      alt: "") %>
```

- `fetchpriority="high"` tells the browser to fight for bandwidth for this
  request.
- `loading="eager"` (the default, but explicit beats accidental `lazy`).

Additionally, preload it from your **layout's `<head>`**, so the fetch starts
before the browser has parsed down to the `<img>` (or, for client-rendered
components, before React renders at all):

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <%= yield :preloads %>
  <%# ... %>
</head>
```

If the hero has a single source,
[`preload_link_tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-preload_link_tag)
is the right tool:

```erb
<%# app/views/home/index.html.erb %>
<% content_for :preloads do %>
  <%= preload_link_tag image_path("hero-1600.jpg"), as: "image", fetchpriority: "high" %>
<% end %>
```

For a **responsive** hero (the `srcset` case above), the preload must carry
`imagesrcset`/`imagesizes` so the browser preloads the same candidate the
`<img>` will pick. Use a plain `<link>` here — **not** `preload_link_tag`:
besides the tag, `preload_link_tag` also sends an HTTP `Link: rel=preload`
header built only from the fixed `href` (it does not include
`imagesrcset`/`imagesizes`), so browsers that honor the header would fetch the
full-size image on every viewport, duplicating the download the responsive
preload was supposed to avoid.

```erb
<%# app/views/home/index.html.erb %>
<% content_for :preloads do %>
  <link
    rel="preload"
    as="image"
    fetchpriority="high"
    imagesrcset="<%= image_path('hero-800.jpg') %> 800w, <%= image_path('hero-1600.jpg') %> 1600w"
    imagesizes="100vw"
  />
<% end %>
```

This is deliberately a **layout-level** concern: the preload belongs in the
document `<head>` your layout owns, declared by the page that knows its hero.
You do not need (and React on Rails does not currently provide) a
head-injection helper for it. Preload at most one or two images per page —
preloading more steals bandwidth from the things you actually wanted to
prioritize.

## Modern formats: AVIF/WebP with fallback

AVIF and WebP are typically 30–50% smaller than JPEG at equivalent quality.
Active Storage variants can transcode on the fly (libvips must be built with
AVIF support for `:avif`):

```erb
<% avif = @product.photo.variant(resize_to_limit: [800, nil], format: :avif) %>
<% webp = @product.photo.variant(resize_to_limit: [800, nil], format: :webp) %>
<picture>
  <source srcset="<%= url_for(avif.processed) %>" type="image/avif" />
  <source srcset="<%= url_for(webp.processed) %>" type="image/webp" />
  <%= image_tag url_for(@product.photo.variant(resize_to_limit: [800, nil]).processed),
        width: 800, height: 533, loading: "lazy", decoding: "async",
        alt: @product.name %>
</picture>
```

The browser picks the first `<source>` it supports and falls back to the
`<img>` otherwise — older browsers never download the modern formats. On
Rails 7.1+ you can also use the
[`picture_tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-picture_tag)
helper. In JSX the same markup is `<picture>` + `<source>` elements with
`srcSet`/`type` props.

The same request-time-generation warning applies doubly here: a `<picture>`
with two formats × three widths is six variants per image. Pre-generate them.

## Putting it together

| Concern          | Non-hero image            | LCP/hero image                          |
| ---------------- | ------------------------- | --------------------------------------- |
| `srcset`/`sizes` | yes                       | yes                                     |
| `width`/`height` | always                    | always                                  |
| `loading`        | `lazy`                    | `eager`                                 |
| `decoding`       | `async`                   | (default)                               |
| `fetchpriority`  | (default)                 | `high`                                  |
| Preload          | no                        | preload `<link>` in the layout `<head>` |
| Formats          | AVIF/WebP via `<picture>` | AVIF/WebP via `<picture>`               |

To verify the result, check LCP and CLS in Chrome DevTools (Performance panel)
or with the [web-vitals](https://github.com/GoogleChrome/web-vitals) library:
the hero should be discovered in the preload scanner's first pass, and CLS from
images should be ~0.

## See also

- [Configuring Images and Assets with Webpack](./images.md) — bundling images
  imported from JavaScript/SCSS.
- [Font Optimization](./fonts.md) — the companion recipe for the other classic
  CLS source.
- [web.dev: Optimize LCP](https://web.dev/articles/optimize-lcp) and
  [web.dev: CLS](https://web.dev/articles/cls).
