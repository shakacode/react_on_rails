# Critical Resource Hints for RSC Pages

RSC pages can emit browser resource hints while the server component tree renders. Use this when an
RSC page has a measured first-viewport bottleneck, such as late critical CSS, a late LCP image, or a
font request that starts after the shell is already streaming.

Use React DOM's resource hint APIs from the RSC render path. Do not import manual resource-hint
helpers from `react-on-rails-rsc/server`: the published `react-on-rails-rsc` package does not export
`preloadFont`, `preloadImage`, `preloadScript`, or `preloadStyle` helpers. That subpath is the Flight
server entry point.

Pass production URLs that your Rails, Shakapacker, webpack, or rspack manifests have already
resolved.

```tsx
import { preconnect, prefetchDNS, preinit, preload } from 'react-dom';

export default function WelcomePage() {
  prefetchDNS('https://cdn.example.com');
  preconnect('https://assets.example.com', { crossOrigin: 'anonymous' });

  preinit('/packs/generated/WelcomePage.css', { as: 'style', precedence: 'rsc-css' });
  preload('/assets/Poppins-600-abcd1234.woff2', {
    as: 'font',
    type: 'font/woff2',
    crossOrigin: 'anonymous',
  });
  preload('/assets/listing-price-comparison-abcd1234.webp', {
    as: 'image',
    fetchPriority: 'high',
    imageSrcSet:
      '/assets/listing-price-comparison-abcd1234.webp 1x, /assets/listing-price-comparison@2x-abcd1234.webp 2x',
    imageSizes: '100vw',
  });

  return <main>{/* page content */}</main>;
}
```

The useful React DOM APIs for RSC resource hints are:

- `prefetchDNS(href)`
- `preconnect(href, options)`
- `preinit(href, { as: 'style' | 'script', ...options })`
- `preload(href, { as, ...options })`
- `preinitModule(href, options)`
- `preloadModule(href, options)`

> [!NOTE]
> The generator currently installs the tested React 19.2.7 / `react-on-rails-rsc` 19.2.1 package
> line (stable `19.2.1` or later). Newer published
> `react-on-rails-rsc` releases may add automatic package-level hinting, but app-authored resource
> hints should still use React DOM's public APIs rather than package-private helpers.

Use already-resolved URLs. These helpers do not look up logical pack names such as
`generated/WelcomePage.css`; resolve those through the host app's asset manifest before calling the
helper. Treat hint URLs and origins as trusted manifest or application configuration data. Do not pass
user input, query parameters, or other request-derived values directly to these helpers.

## Choosing Hints

Use hints only for resources that are genuinely needed for the first viewport or early interaction:

- Use `preinit` with `as: 'style'` for critical CSS that should participate in React's stylesheet precedence and
  streamed boundary reveal behavior. Pass `precedence: 'rsc-css'` when authored critical CSS should
  join the same bucket React on Rails Pro uses for automatically discovered client-reference CSS. Use
  a different explicit `precedence` only when authored critical CSS must be ordered separately, and
  avoid doing that for an `href` that automatic client-reference CSS discovery also emits because
  React dedupes stylesheet preinit hints by URL.
- Use `preload` with `as: 'style'` when you only need to start downloading a stylesheet early.
- Use `preload` with `as: 'font'` for fonts used by the LCP text. Include the real production font
  URL, `type`, and `crossOrigin` when the font request needs it.
- Use `preload` with `as: 'image'` and `fetchPriority: 'high'` only for the actual LCP image, not
  for below-the-fold gallery or avatar images.
- Use `preconnect` for a CDN or asset origin that will certainly be used on the page. Use
  `prefetchDNS` when you only need the cheaper DNS lookup.
- Avoid preloading route chunks, below-the-fold images, optional third-party scripts, or assets that
  are already guaranteed by the page shell unless a measurement shows they are late.

Over-preloading can regress the same metrics this feature is intended to fix by competing with
critical CSS, fonts, or the real LCP resource.

## Verifying

Use Lighthouse, ShakaPerf, or Chrome DevTools on production-like hashed assets:

1. Confirm the LCP element. Check whether it is text, an image, or a client component boundary.
2. In the Network panel, filter downloads before LCP. Verify only the intended CSS, font, image,
   script, preconnect, or DNS hints moved earlier.
3. For text LCP, inspect layout shifts and font swaps. If font loading causes CLS or delays the LCP
   text, preload only the exact font weights used above the fold.
4. For image LCP, confirm the real LCP image has high priority and below-the-fold images remain lazy
   or low priority.
5. Compare FCP, Speed Index, LCP, TBT, total JS bytes, total downloads, and request count against the
   SSR or previous RSC baseline.
6. Remove any hint that does not improve the measured bottleneck.

For broader RSC performance work, pair this page with the
[RSC Performance Validation Playbook](../../oss/migrating/rsc-performance-validation.md).
