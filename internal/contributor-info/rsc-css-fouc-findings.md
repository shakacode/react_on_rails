# RSC CSS / FOUC Pipeline — Findings & Risk Register

Status: analysis only (Stage 3 of the CSS/FOUC research engagement, July 2026).
Boundary: no source changes before the 17.0 final release. Every finding below is
proposed-only.

Code verified against: `packages/react-on-rails-pro/src/injectRSCPayload.ts` on `main`
(92b29df93), `react-on-rails-rsc@19.2.1-rc.0` (the 17.0 RC pin, which the dummy app also
pins — dist inspected from the published npm tarball) and `19.2.0-rc.1` (published
tarball for the 19.2.0 line; also found as a stale install in one long-lived checkout),
and `shakapacker@10.3.0` (published tarball).

**Verification status:** Step 1 of the verification procedure was executed 2026-07-09 on
the dummy app (Rspack 2.0.5, `react-on-rails-rsc@19.2.1-rc.0`, `NODE_ENV=production`) —
see the addendum at the end of this document. B1 (manifest `css` arrays) **passed** on
the supported config; B2 confirmed numeric chunk ids; the observed CSS asset naming
(`css/4092-98880bc1.css`) additionally proved L2 production-dead (see F1).

## How the pipeline actually layers (corrected model)

The FOUC prevention is **four layers**, not one pipeline. Ordered by primacy:

| #   | Layer                                                                                                                                                                                                                                                                                                                                                                     | Input                                                    | Where                                                                                                                                                                       |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| L1  | **Manifest-CSS stylesheet hints** — `preinit(href, { as: 'style', precedence: 'rsc-css' })` fired during the Flight render for every client reference whose manifest entry has a `css` array. React itself then emits the `<link rel="stylesheet" data-precedence="rsc-css">` and gates the Suspense reveal (`$RR` / `completeBoundaryWithStyles`) until the sheet loads. | `css` arrays in `react-client-manifest.json`             | `react-on-rails-rsc` `dist/flight-stylesheet-hints.js`, wired into every render by `buildServerRenderer` (`dist/server.node.js`), consumed via `manifestLoaderServer.ts:17` |
| L2  | **Preload-tag promotion** — Fizz-emitted `<link rel="preload" as="style">` tags whose href matches `/css/clientN-*.css` are rewritten in the stream to render-blocking `rel="stylesheet" data-precedence="rsc-css"`. Dev/test-only in practice: production CSS filenames are id-based and never match (F1(b)).                                                            | Fizz HTML output (itself downstream of L1 hints)         | `injectRSCPayload.ts:1522` (`applyStreamedStylesheetPreloadGating`), href filter at `:115`                                                                                  |
| L3  | **Flight chunk-name inference** — raw Flight text is regex-scanned for `"clientN","js/clientN-*.chunk.js"` pairs; matches are looked up in a chunk→CSS map built from `loadable-stats.json` and injected as `data-precedence="rsc-css"` links ahead of the HTML in each flush.                                                                                            | `loadable-stats.json` copied next to the renderer bundle | `injectRSCPayload.ts:116` (regex), `:262` (map load), `:387` (tag emission)                                                                                                 |
| L4  | **Suspense-reveal deferral** — while L3 inference is "pending" for any payload stream, HTML containing React's `$RC(` reveal script is split and the reveal held back so an L3 link can flush first. Pending state clears on the **first** stylesheet found per stream, on stream end, or after a **100 ms** timeout.                                                     | L3's map being non-empty                                 | `injectRSCPayload.ts:1716` (`shouldDeferRevealHtml`), `:122` (timeout), `:1961-1978`, `:2007-2009`                                                                          |

L1 is the real mechanism (it is what Next.js-style RSC CSS does). L2–L4 are
compensations that only matter when L1's input (`css` arrays) is missing or late.
When L1 works, React's own `$RR` gating makes L2–L4 redundant for correctness.

**Correction to Stage 1:** the earlier claim "the framework calls no `preinit`" is
**wrong**. The framework's primary mechanism _is_ `preinit` — but `preinit`
_with a `precedence` option_, which is render-blocking per boundary. What the
implementation avoids is plain `preinit`/`preload` _without_ precedence (non-blocking,
the variant the July review correctly called out as flicker-prone).

## Findings (ranked)

### F1 — HIGH (correctness, both bundlers): the fallback layers (L2, L3, L4) are all silently dead in every production build

Two independent causes, each sufficient on its own:

**(a) Numeric chunk ids kill L3+L4.** `RSC_CLIENT_CHUNK_NAME_WITH_JS_ASSET`
(`injectRSCPayload.ts:116`) requires a **quoted string** chunk id:
`"client1","js/client1-….chunk.js"`. Both manifest plugins emit
`chunks.push(chunk.id, file)` (webpack `RSCWebpackPlugin.js:396`; rspack `plugin.js`
`getGroupAssets`), and nothing in Shakapacker 10 (`environments/base.js`,
`optimization/{webpack,rspack}.js` — verified: no `chunkIds` key), the dummy configs, or
the generators sets `optimization.chunkIds`. So:

- `NODE_ENV=development`/`test` (mode `development`) → default `chunkIds: 'named'` → ids
  are `"client1"` strings → regex matches → L3/L4 active.
- `NODE_ENV=production` (mode `production`) → default `chunkIds: 'deterministic'` → ids
  are **unquoted numbers** (`[4092,"js/client1-….chunk.js"]` — observed in the 2026-07-09
  run) → regex never matches → L3 injects nothing and L4 never defers. No warning, no
  log.

**(b) Id-based CSS filenames kill L2 (and L3's href source).** Shakapacker sets
`chunkFilename: css/[id][hash].css` for **both** bundlers (`plugins/webpack.js:40`,
`plugins/rspack.js:51`), so async-chunk CSS is emitted as e.g. `css/4092-98880bc1.css`
in production (observed) and only takes the `css/client1-….css` shape in dev/test where
ids are names. L2's href filter `RSC_CLIENT_CHUNK_STYLESHEET_PATH`
(`injectRSCPayload.ts:115`) matches only the dev-shaped name, so preload promotion can
never fire on a default production build either. (An app that customizes
`chunkFilename` to `css/[name]…` would re-enable L2 — that is the only production
configuration in which any fallback layer is live.)

Net: **in a default production build, L1 is the only active FOUC layer, under both
bundlers.** The FOUC e2e gate (`rsc_fouc.spec.ts`, including the Rspack job in
`pro-integration-tests.yml`) builds with `RAILS_ENV=test`/`NODE_ENV=test`, i.e. named
ids — **the production posture is never exercised by any gate.** The unit-test Flight
fixtures (`injectRSCPayload.test.ts:489`) hard-code the dev-mode `"client1"` shape.

Impact: contained where L1 works — verified 2026-07-09 for the supported Rspack config
(19.2.1-rc.0, concrete publicPath: `css` arrays present), and expected for webpack with
`react-on-rails-rsc ≥ 19.0.5-rc.6` — because React's own reveal gating takes over.
Where L1 is also broken (see F2) there is **no FOUC protection at all in production**
(L2 has no preload tags to promote without L1's hints, and could not match their hrefs
anyway per (b)), and the flash is deterministic on a cold cache.

### F2 — HIGH (correctness, Rspack): manifest `css` arrays have three silent-omission conditions

In `react-on-rails-rsc` (`dist/react-server-dom-rspack/plugin.js`, 19.2.1-rc.0):

1. **Version:** `css` collection does not exist in the published 19.2.0 line at all
   (verified against the `19.2.0-rc.1` tarball — zero CSS code in its rspack plugin).
   Only `19.2.1-rc.0`+ collects CSS under Rspack. The repo dummy pins `19.2.1-rc.0`;
   any app still on a 19.2.0 package gets no `css` arrays → L1 dead.
2. **`output.publicPath` is `'auto'` or a function** → `cssPrefix === null` →
   `getChunkCss` returns `[]` and `directCssDepFiles` returns `[]` for every module.
   There _is_ a compilation warning, but the build succeeds and the manifest looks valid.
3. **Extraction mechanism:** the CSS-dependency recovery hop only recognizes modules with
   `type === 'css/mini-extract'` (`CssExtractRspackPlugin`). Rspack's native CSS support
   (`experiments.css`, module type `'css'`) is invisible to that hop; CSS is then found
   only if a `.css` asset lands in a chunk inside the same chunk group
   (`!groupChunkSet.has(cssChunk) → continue`). Split-chunks configs that pull CSS into
   a shared group can silently drop it.

Combined with F1: an Rspack production app on 19.2.0, or with `publicPath: 'auto'`, has
no active FOUC layer — L1 loses its input, and the fallback layers are production-dead
per F1(a)/(b). This — not a subtle race — is the most likely identity of "the Rspack
FOUC gap" the docs describe, and it is invisible until a cold-cache visit.

### F3 — MEDIUM (rare flicker): the L4 deferral window is heuristic and evaporates early

Three code facts (`injectRSCPayload.ts:122`, `:1961-1978`, `:2007-2009`):

- deferral pending-state times out **100 ms after the payload stream registers**, not
  after the last Flight chunk;
- it also clears on the **first** stylesheet tag found per stream — a second
  client-CSS boundary later in the same stream is unprotected by L4;
- Flight-side inference and Fizz-side HTML are two consumers of a tee
  (`RSCRequestTracker.ts:315-323`) racing on the
  same event loop; normally inference lands first (same or earlier flush — flush copy
  order puts stylesheet buffers before HTML, `injectRSCPayload.ts:1794-1807`),
  but GC pauses / event-loop contention can flush a `$RC(` reveal one chunk ahead of its
  stylesheet link once the deferral window is gone.

An async Server Component that takes >100 ms to produce its first client-reference row
(any real DB query) exits the protected window by design. **This is the only mechanism
found that is consistent with "reproduced exactly once, conditions unknown" in a
dev/test-mode build** — it needs jitter to line up, and L4 only matters at all when L1
is absent. (In a production build, F1/F2 make the flash deterministic-on-cold-cache
instead, which also matches a one-time sighting: the second visit serves the CSS from
disk cache and the flash disappears.)

### F4 — MEDIUM (ops): loadable-stats load-state caching creates silent unprotected windows

`injectRSCPayload.ts:262-323`: a failed read enters a
retry-after state with exponential backoff (100 ms → 30 s cap). Requests inside a backoff
window get the **empty map** — L3+L4 off — with no per-request signal (missing-file reads
warn only for _unexpected_ errors; ENOENT is silent by design). A renderer that boots
before assets are staged (rolling deploy, `renderer_cache_helpers.rb:38-39`
treats `loadable-stats.json` as optional) serves unprotected responses until a read
succeeds; a success is then cached for the life of the module instance (fine under
hash-scoped bundle dirs, stale if assets are ever swapped in place). Also note the
whole L3 path is skipped under HMR builds
(`clientWebpackConfig.js:43-44`) — dev
HMR inlines CSS via style-loader, so dev reproduction of any of this is impossible,
which is why "I can't reproduce it in dev" is expected, not evidence of absence.

### F5 — LOW/MEDIUM (docs): two documented claims are wrong or empty

- `css-and-styling.md:831-836` says that when the
  map is empty, "CSS for `'use client'` components still works via the Rails layout
  `stylesheet_pack_tag`". For CSS split into async `clientN` chunks this is **false** —
  async-chunk CSS is not part of the entrypoint's initial chunks, so no layout pack tag
  emits it. The fallback that actually exists is L1/L2 (when `css` arrays are present)
  or nothing.
- The same paragraph defers to `rspack-compatibility.md`
  "for details" — that page contains **no CSS/FOUC content at all**.

### F6 — LOW (fragility): React-internals coupling in the scraping layer

Exactly the class of risk the July review flagged:

- `REACT_SUSPENSE_REVEAL_SCRIPT = /\$RC\(/` (`injectRSCPayload.ts:117`) and the
  hidden-boundary `<div hidden id=…>` scraping (`:337-369`)
  depend on Fizz's private completion-script names and DOM shape. A React minor that
  renames `$RC` silently disables L4 (no error — deferral just never triggers).
- The `destination.flush()` signal (`:1904-1926`) is
  an internal convention; the code documents this and has a `setTimeout(0)` fallback —
  acceptable, but it is another per-major-version re-verification item.
- L2/L3's filename regexes (`:115-116`) hard-code a `css/clientN-*.css` /
  `js/clientN-*.chunk.js` layout and the `client[index]` chunkName default. Per F1(b),
  Shakapacker's actual CSS `chunkFilename` is `css/[id][hash].css`, which only takes
  that shape in dev/test; custom `chunkFilename`, a different CSS dir, or a custom
  `chunkName` plugin option silently disables the layers in dev/test too.

### F7 — Complexity assessment (the "accreted complexity" question, answered honestly)

`injectRSCPayload.ts` is 2,160 lines. Roughly 1,200 of them (lines ~412–1580) are an
incremental streaming-HTML scanner — raw-text elements, `<template>`, foreign content,
CDATA, script double-escape states, UTF-8 split-tail handling — whose _only_ purpose is
to let L2/L4 safely splice tags into someone else's HTML stream. That scanner is
individually well-built, but it exists **only because the design point is "re-parse
React's output"** rather than "tell React about the CSS up front" (L1).

Verdict:

- **Essential:** L1 (manifest `css` arrays → `preinit` with precedence). This is the
  smallest correct design; it is also what the reviewer's "one loader, ~100 lines"
  intuition maps onto — his loader and L1 are the same idea (attach CSS to the boundary
  and let the reveal block on it), and L1 is the React-native version of it.
- **Compensatory, removable in principle:** L2, L3, L4 — plus `loadable-stats.json`
  generation/shipping (`@loadable/webpack-plugin` in client configs,
  `renderer_cache_helpers.rb:27` staging), the
  chunk→CSS map loader, and ~2/3 of the scanner. They only add safety where L1's input
  is missing — and per F1 the two layers that need the scanner most are already inert in
  production, which is strong evidence they are not load-bearing for real deployments
  on webpack.
- **The single highest-value simplification:** close L1's input gaps (F2) and verify L1
  under production builds of both bundlers — then delete L3+L4 (and reassess L2). That
  removes the loadable-stats sidecar, the 100 ms heuristic, the `$RC` scraping, and the
  reveal-splitting logic in one move, and shrinks the FOUC surface from four layers in
  ~8 modules to one layer whose behavior is owned by React and covered by React's own
  semver contract.

Spread today (~8 modules): `injectRSCPayload.ts`, `RSCRequestTracker.ts` (tee),
`streamServerRenderedReactComponent.ts`, `rscDomMarkers.ts`,
`cache/manifestLoaderServer.ts`, `react-on-rails-rsc` (`flight-stylesheet-hints`,
`WebpackPlugin`, `RspackPlugin`), client webpack/rspack config (LoadablePlugin), and the
Ruby staging helpers. Post-simplification the CSS story would live in three:
the two manifest plugins and `flight-stylesheet-hints`.

## What a separate, later simplification engagement should tackle (priority order)

Gate each step on the verification procedure
([rsc-fouc-verification-procedure.md](./rsc-fouc-verification-procedure.md)) passing
in **production-mode** builds:

1. **Make L1 unconditionally healthy (prereq for everything).** Fix/verify Rspack `css`
   arrays on the 19.2.1 line for: concrete vs `auto` publicPath (fail loudly, not
   warn-and-omit), native-CSS vs `CssExtractRspackPlugin` extraction, split-chunks
   groups. Add a production-mode (deterministic-ids) FOUC gate to CI — the current gate
   only ever tests dev-mode builds.
2. **Delete L3 + L4** (Flight regex inference, loadable-stats map, 100 ms deferral,
   `$RC` reveal-splitting) once (1) is green. This is the single change that most
   reduces fragility: it removes the only pieces with silent env-dependent no-op
   behavior (F1, F4), the React-internals `$RC` coupling (F6), and the majority of the
   2,160-line file.
3. **Reassess L2** (preload promotion): keep only if a real case exists where Fizz emits
   a preload-but-not-stylesheet for boundary CSS with precedence hints active; otherwise
   delete, which also removes most of the remaining HTML scanner.
4. **Drop the `loadable-stats.json` sidecar end-to-end** (LoadablePlugin config,
   renderer staging, rolling-deploy checks) once L3 is gone — it has no other consumer
   in the RSC path.
5. **Fix the two doc claims in F5** (can be done now — docs-only).
6. **Keep, as-is:** the multi-buffer flush ordering (initialization scripts →
   stylesheets → HTML → payload scripts → payload marks) and the `flush()`-signal
   design — they are streaming-correctness concerns independent of CSS, are
   well-commented, and have test coverage.

## Addendum — verification Step 1 results (2026-07-09)

Executed on the Pro dummy app: `SHAKAPACKER_ASSETS_BUNDLER=rspack`
`RAILS_ENV=production NODE_ENV=production`, Rspack 2.0.5,
`react-on-rails-rsc@19.2.1-rc.0`, `bin/shakapacker-precompile-hook` +
`CLIENT_BUNDLE_ONLY=true bin/shakapacker`.

Observed in `public/webpack/production/react-client-manifest.json`:

- **B1 PASS (supported config):** the FOUC probe client reference carries
  `css: ["/webpack/production/css/4092-98880bc1.css"]` — concrete publicPath-prefixed
  href; 2 of 10 client references have `css` arrays (the two that import CSS Modules).
- **B2 numeric, as predicted:** `chunks: [4092, "js/client1-daa4837bf751aaff.chunk.js"]`
  — unquoted numeric id alongside a name-shaped JS filename, confirming F1(a).
- **CSS asset naming id-based, new evidence:** `css/4092-98880bc1.css` (not
  `css/client1-…css`), confirming F1(b): L2 cannot match production CSS hrefs.
- `loadable-stats.json` was emitted next to the manifest.

Conclusion for the 17.0 gate: on the supported Rspack production config, the primary
layer (L1) has healthy input, so no deterministic FOUC is predicted there. Runtime
confirmation of the streamed `$RR` gating (procedure Step 2) remains open. The
deterministic-FOUC rows remain predicted for 19.2.0-line packages and
`publicPath: 'auto'`/function builds.
