# RSC CSS blocks per-boundary via `data-precedence`, not plain preinit and not all-CSS-in-`<head>`

Status: accepted (documented retroactively 2026-07-09 from the July 2026 CSS/FOUC
research pass; the decision itself shipped across the 17.0 RC line)

Streamed RSC pages deliver each client component's extracted CSS as a
`<link rel="stylesheet" data-precedence="rsc-css">` tied to that component's Suspense
boundary, driven by per-client-reference `css` arrays in `react-client-manifest.json`
and `preinit(href, { as: 'style', precedence: 'rsc-css' })` calls during the Flight
render. React then blocks **that boundary's reveal** — and only that boundary's — until
the sheet loads. Stream-level fallbacks (preload-tag promotion, Flight chunk-name
inference, reveal deferral) exist for builds where the manifest `css` input is missing.

## Why

Three designs were genuinely on the table; each fails a different requirement:

- **All page CSS render-blocking in `<head>` (the traditional SSR answer):** correct but
  defeats streaming. An RSC page SSRs the _whole_ page (no hand-tuned skeletons), so
  head-blocking on the union of every boundary's CSS makes first paint wait on
  below-the-fold styles — the exact metric regression RSC streaming exists to avoid.
  This remains the right answer for shell/global CSS (Rails layout pack tags), just not
  for per-boundary CSS.
- **Plain `preinit`/`preload` without precedence:** non-blocking by design. The browser
  may paint the boundary's HTML before the stylesheet applies — this is FOUC, verified
  experimentally during development (the assumption that plain `preinit` blocks
  rendering is false). Rejected as the primary mechanism; preload tags appear in the
  stream only as hint residue and are _promoted_ to blocking links by the fallback
  layer.
- **`data-precedence` stylesheets bound to the boundary (chosen):** React 19's resource
  system treats a precedence-tagged stylesheet as a blocking dependency of the Suspense
  boundary that referenced it (`completeBoundaryWithStyles`). First paint depends only
  on shell CSS; each streamed section reveals exactly when _its_ CSS is ready. This is
  also the Next.js App Router shape, so it tracks the design React's own team keeps
  working.

The "Fizz-scraping" part of the implementation — regex-detecting reveal scripts and
splicing links into the HTML stream — is **not** part of this decision's ideal state.
It is fallback machinery for builds whose manifests lack `css` arrays (notably Rspack
before `react-on-rails-rsc` 19.2.1 and `publicPath: 'auto'` builds). The intended end
state is manifest-driven hints everywhere, with the scraping layers deleted once that
input is verified under production builds of both bundlers (see
`internal/contributor-info/rsc-css-fouc-findings.md`).

## Consequences

- The `rsc-css` precedence group lands at the end of `<head>`, so it wins source-order
  ties against precedence-less layout CSS — the documented "unscoped selector in a CSS
  Module overrides globals" pitfall follows directly from this choice.
- Per-boundary blocking means a slow stylesheet delays only its own boundary, but also
  means a _missing_ manifest `css` entry produces no error — the boundary simply
  reveals unstyled. Silent-degradation risk is inherent to the layered-fallback design
  and is the main argument for shrinking it.
- The manifest `css` array schema is a cross-package contract (bundler plugins in
  `react-on-rails-rsc`, the Pro runtime, renderer asset staging); changing the CSS
  strategy means coordinating all three, which is why this ADR exists.
- App-authored critical CSS may opt into the same `data-precedence="rsc-css"` bucket to
  cooperate with dedup and ordering, rather than inventing a second bucket.

See `packages/react-on-rails-pro/CONTEXT.md` ("CSS & FOUC") for the supporting
vocabulary (Manifest CSS, Stylesheet Hint, FOUC fallback layers).
