# Critical Resource Hints for RSC Pages

RSC pages can emit browser resource hints while the server component tree renders. Use this when an
RSC page has a measured first-viewport bottleneck, such as late critical CSS, a late LCP image, or a
font request that starts after the shell is already streaming.

Import the helpers from the `react-on-rails-rsc/server` export that your RSC bundle already uses, and
pass production URLs that your Rails, Shakapacker, webpack, or rspack manifests have already resolved.

```tsx
import {
  preconnect,
  prefetchDNS,
  preinitStyle,
  preloadFont,
  preloadImage,
  preloadScript,
  preloadStyle,
} from 'react-on-rails-rsc/server';

export default function WelcomePage() {
  prefetchDNS('https://cdn.example.com');
  preconnect('https://assets.example.com', { crossOrigin: 'anonymous' });

  preinitStyle('/packs/generated/WelcomePage.css');
  preloadStyle('/packs/generated/WelcomePage-abcd1234.css', { fetchPriority: 'high' });
  preloadScript('/packs/generated/WelcomePage-abcd1234.js');
  preloadFont('/assets/Poppins-600-abcd1234.woff2', { type: 'font/woff2' });
  preloadImage('/assets/listing-price-comparison-abcd1234.webp', {
    fetchPriority: 'high',
    imageSrcSet:
      '/assets/listing-price-comparison-abcd1234.webp 1x, /assets/listing-price-comparison@2x-abcd1234.webp 2x',
    imageSizes: '100vw',
  });

  return <main>{/* page content */}</main>;
}
```

These helpers are thin wrappers around React DOM's RSC-aware resource hint APIs:

- `prefetchDNS(href)`
- `preconnect(href, options)`
- `preloadAsset(href, { as, ...options })`
- `preloadStyle(href, options)`
- `preinitStyle(href, options)`
- `preloadScript(href, options)`
- `preinitScript(href, options)`
- `preloadFont(href, options)`
- `preloadImage(href, options)`

Use already-resolved URLs. These helpers do not look up logical pack names such as
`generated/WelcomePage.css`; resolve those through the host app's asset manifest before calling the
helper. Treat hint URLs and origins as trusted manifest or application configuration data. Do not pass
user input, query parameters, or other request-derived values directly to these helpers.

## Choosing Hints

Use hints only for resources that are genuinely needed for the first viewport or early interaction:

- Use `preinitStyle` for critical CSS that should participate in React's stylesheet precedence and
  streamed boundary reveal behavior. By default it uses the `rsc-css` precedence bucket, the same
  bucket React on Rails Pro uses for automatically discovered client-reference CSS. Pass an explicit
  `precedence` when author-critical CSS must be ordered separately, but avoid overriding the
  precedence for an `href` that automatic client-reference CSS discovery also emits because React
  dedupes stylesheet preinit hints by URL.
- Use `preloadStyle` when you only need to start downloading a stylesheet early.
- Use `preloadFont` for fonts used by the LCP text. Include the real production font URL and `type`,
  for example `font/woff2`.
- Use `preloadImage` with `fetchPriority: 'high'` only for the actual LCP image, not for
  below-the-fold gallery or avatar images.
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
