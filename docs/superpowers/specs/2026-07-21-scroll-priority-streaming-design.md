# Zero-Waste Scroll-Priority Delivery of Cached Streamed HTML Sections

- **Issue:** [#4385](https://github.com/shakacode/react_on_rails/issues/4385) (investigation), follow-on to [PR #4740](https://github.com/shakacode/react_on_rails/pull/4740)
- **Date:** 2026-07-21
- **Status:** Investigation complete — architecture recommended, prototype plan below

## Summary

A server-rendered React page is delivered as a progressive HTML stream of cached section
chunks (chunk 0 = full document shell with pending Suspense boundaries; chunks 1..N each
complete one boundary via a hidden content div plus a `$RC` reveal script). When the user
scrolls toward a section that has not arrived yet, we want that section delivered and
hydrated as fast as possible, with **zero duplicate bytes**, **React 19 selective hydration
and component state preserved**, **CDN-cached chunks**, and the plain streamed page
remaining the untouched default.

This document evaluates six candidate architectures against those requirements, backed by
an adversarially-verified research pass (18 surviving primary-source claims; 7 candidate
claims refuted) plus direct verification against shipped `react-dom` builds and the React
repository. **Recommendation: a layered architecture** —

1. **Foundation:** section chunks as individually addressable static assets behind a
   build-time manifest; for strict-CSP deployments, switch chunk generation to React's external
   Fizz runtime so cached chunks contain **zero inline scripts** and are byte-identical for
   every user.
2. **Default transport (Scenario A):** Service-Worker stream-stitching — the SW proxies the
   navigation, and on scroll intent aborts the upstream fetch (protocol-clean per-stream
   cancel) and pipes only the missing section files into the same stream the parser is
   already consuming. Verified SW-lifetime risk is mitigated by a production-proven
   heartbeat plus byte-cursor truncation recovery (exactly-once delivery with the cursor;
   at most one section-prefix repeat in the degraded cursor-lost case).
3. **Scenario B (origin still rendering):** move chunk production to React's now-stable
   `prerender`/`resume` APIs, making "the rest of the page" a first-class, parameterizable
   resume request — which makes the skip/priority signal **stateless**.
4. Cloudflare Durable Objects remain a documented, costed alternative for
   Cloudflare-committed deployments; gated `window.stop()` is rejected for production.

## Problem statement

**Hard requirements** (from the investigation brief):

1. **Zero duplicate bytes.** Every section's HTML crosses the wire at most once.
2. **React 19 selective hydration keeps working.** Sections hydrate independently as HTML
   and code arrive; on-screen sections stay interactive and keep component state.
3. **CDN-compatible.** Primary target is cached chunks at an edge; solutions requiring no
   edge state rank higher on portability.
4. **No full-page re-render; no client-side re-render of already-delivered content.**
5. **Progressive enhancement only.** The normal path (user never scrolls ahead) must remain
   a plain streamed page; acceleration must not tax every page view.

Two production scenarios must both be addressed:

- **Scenario A — fully cached at the edge.** All chunks exist as static assets at the CDN;
  pacing is artificial or bandwidth-driven. The question is purely transport/coordination.
- **Scenario B — origin still rendering.** Chunk 0 and early chunks are cached; later
  chunks are still being generated. A "skip" cannot make rendering faster — the meaningful
  operation is re-prioritization, and the signal must reach the origin renderer.

## System context

The working prototype lives under `react_on_rails_pro/spec/dummy/` (merged in
[PR #4740](https://github.com/shakacode/react_on_rails/pull/4740)):

- `CacheSection.jsx` wraps sections in `<Suspense>` with a configurable async delay so the
  stream fractures at section boundaries.
- `lib/tasks/section_cache.rake` captures the streamed response into `section<N>.html`
  files by time windows.
- `PagesController#selective_hydration_cached` replays the files over
  `ActionController::Live` with a fixed inter-chunk sleep, rewriting each cached
  `nonce="…"` to the current request's CSP nonce.

A later local experiment (not merged; documented in the investigation brief) made the delay
interruptible: the shell embeds a `stream_id`, client JS POSTs to `/skip_delay/:stream_id`
on scroll intent, and the streaming loop flushes all remaining chunks down the same
connection. Measured: skip at +7.6 s → acknowledged in 11 ms → 7 remaining chunks delivered
within ~50 ms, all hydrated, zero console errors. That design satisfies every requirement
except CDN portability — it relies on origin-held state and an origin-held open response.

The Pro integration seam for any server-side change is
`packages/react-on-rails-pro/src/streamServerRenderedReactComponent.ts` (the
`renderToPipeableStream` call site; `railsContext.cspNonce` is already plumbed through).
The renderer does not currently expose a passthrough for additional React streaming options
(e.g. `unstable_externalRuntimeSrc`) — a small plumbing change covered in the prototype
plan.

### Chunk wire format (React Fizz, verified against captured output)

Chunk 0 is a complete HTML document (`<!DOCTYPE html>` … `</html>`) whose pending sections
are unresolved Suspense boundaries:

```html
<!--$?--><template id="<domId>B:3"></template>
<div style="min-height:70vh;…">Loading section 3…</div>
<!--/$-->
```

The root boundary's content is emitted at the end of chunk 0 as a hidden div plus React's
inline runtime and first reveal call. Chunks 1..N are each one hidden content div plus one
reveal script:

```html
<div hidden id="<domId>S:3">…section HTML…</div>
<script>
  $RC('<domId>B:3', '<domId>S:3');
</script>
```

## Verified facts

### From the prototype experiments (React 19.x; re-validated where noted)

1. **`$RC` is idempotent per boundary.** A section delivered twice ends with exactly one
   copy in the DOM, zero orphan hidden divs, React component state preserved, zero errors.
2. **Manual reveal works without executing fetched scripts.** Fetch a chunk file, parse
   with `DOMParser`, `document.adoptNode` + append the hidden div(s), call
   `window.$RC(boundaryId, contentId)` directly. Hydration and interactivity confirmed.
3. **Late arrival is fine.** Sections arriving minutes after load hydrate normally;
   hydration is genuinely per-boundary.
4. **Pending boundaries are discoverable generically** via
   `document.querySelectorAll('template[id*="B:"]')` (React on Rails prefixes ids, so match
   `B:` anywhere).
5. **`window.stop()` hazards:** it aborts ALL in-flight subresource loads, not just the
   navigation stream; while a navigation response streams, `document.readyState` never
   reaches `complete` and `load` never fires.
6. **Scroll events don't bubble** — use a capturing listener on `document` to catch scrolls
   of inner `overflow` containers.

### React internals — verified against shipped builds and repo history (2026-07-21)

Verified directly against npm tarballs `react-dom@18.3.1`, `react-dom@19.2.7`,
`react-dom@19.2.8`, `react@19.2.8`, and `facebook/react` commit history. The dummy app pins
`react`/`react-dom` `~19.2.7`.

7. **The `$RC` function body was rewritten between the build the prototype captured and
   current stable 19.2.x.** 18.3.1 (and the prototype's captured runtime) reveal
   synchronously: consume the content div unconditionally, then reveal if the boundary
   template exists. 19.2.7/19.2.8 instead **batch reveals**: `$RC` guards on the content
   div existing, marks the boundary comment `$~` (new "reveal scheduled" state), enqueues
   the (template, content-div) pair into a global `$RB` array, and schedules a new `$RV`
   reveal function via `requestAnimationFrame` or a `setTimeout` computed from a `$RT`
   throttle timestamp (reveals coalesce on a ~300 ms cadence). Consequences:
   - Reveal is now **asynchronous** — code that calls `$RC` manually and assumes the
     boundary is revealed on return is wrong on 19.2.x.
   - Time-to-visible after bytes arrive can include up to ~300 ms of intentional reveal
     throttling; the prototype's ~50 ms skip-to-interactive measurement will read
     differently on 19.2.7+.
   - `$RC` now depends on sibling globals (`$RB`, `$RV`, optionally `$RT`) emitted with the
     first completeBoundary bootstrap in chunk 0 — present before any tail chunk arrives,
     so manual invocation still works, but the coupling surface grew.
8. **Idempotency survives the rewrite — intentionally.** In 19.2.x: duplicate call after
   reveal → template gone → content div consumed, no-op; duplicate call while the first is
   still queued → `$RV` guards (`e.parentNode !== null`, `if (f)`) skip the second pair.
   React commits [#33511](https://github.com/facebook/react/pull/33511) ("Delay detachment
   of completed boundaries until reveal") and
   [#33531](https://github.com/facebook/react/pull/33531) ("Ignore error if content node is
   gone before reveal", June 2025) explicitly hardened these paths — duplicate/missing-node
   tolerance is designed-in, not accidental.
9. **The emitted call-site contract is stable across 18.3.1 → 19.2.8** — every version
   emits `$RC("<id>B:n","<id>S:n")` (`completeBoundaryScript1Partial = '$RC("'`), a
   `<template id="…">` placeholder per pending boundary, and a `<div hidden id="…S:n">`
   content div. What churns is the **function body**, not the wire format. Architectures
   where the browser's parser executes React's own scripts are insulated from body churn;
   architectures that call `$RC` manually inherit semantic changes (e.g., sync → batched).
10. **The Fizz inline runtime is under active development:** 34 commits to
    `packages/react-dom-bindings/src/server/fizz-instruction-set` from 2022-10 through
    2026-07 (latest two days before this writing), including reveal throttling, Suspensey
    fonts/images, paint gating, and ViewTransition integration. Treat any dependence on
    body internals as a per-upgrade re-verification cost.
11. **React's official partial-prerender APIs are stable in the pinned version.**
    `react-dom@19.2.8` exports, on the stable channel: `prerender` /
    `prerenderToNodeStream` **and** `resumeAndPrerender` / `resumeAndPrerenderToNodeStream`
    from `react-dom/static`, plus `resume` / `resumeToPipeableStream` from
    `react-dom/server`. The prerender result includes JSON-serializable `postponed` state
    (reached by aborting a prerender; the explicit `React.postpone` API remains
    experimental-only — `react@19.2.8` stable exports no `postpone`/`unstable_postpone`).
    So "render the shell now, produce the remainder later as a resumed stream" is a
    framework-sanctioned operation on the exact React line this repo ships.
12. **React can emit chunks with no inline scripts at all.** Stable 19.2.8 supports
    `unstable_externalRuntimeSrc` (+ `externalRuntimeConfig`): boundary completion is then
    emitted as pure markup — `<template data-rci data-bid="…" data-sid="…">` instruction
    nodes (plus `data-rsi`/`data-rxi`/`data-rri` variants) — processed by an external
    runtime script that watches DOM insertions with a `MutationObserver` and performs
    reveals itself. Verified consequences:
    - Cached chunks would contain **zero inline scripts** → no CSP nonce problem, no
      per-request rewriting, chunks byte-identical for every user (perfectly cacheable).
    - **Any** insertion path triggers reveal natively — the parser during streaming, a
      Service-Worker-stitched stream, or plain client-side `append` of fetched chunk bytes.
      Manual `$RC` invocation becomes unnecessary even for pull-based delivery.
    - Caveat: the option is `unstable_`-prefixed, and the runtime file
      (`unstable_server-external-runtime.js`) ships only in the `react-dom@experimental`
      npm build — on stable it must be vendored from the React source tree at the pinned
      version and covered by a contract test.

### Edge platforms, Service Workers, and wire semantics — adversarially verified research

A verification pass over 25 extracted claims (3 independent votes per claim; 2/3 refutes
kill; 18 confirmed, 7 refuted) against
primary sources, fetched live 2026-07-21:

13. **Cloudflare Durable Objects (C1) are documented and costed for this pattern.**
    - Streaming a `ReadableStream` response from a Worker/DO is first-class, with an
      official DO example holding open a streaming response until an `AbortSignal` fires.
    - Duration billing is **wall-clock** while the DO is active or unable to hibernate,
      charged as if the full 128 MB is allocated: $12.50/M GB-s beyond 400k GB-s/month
      included (Workers Paid). A DO holding a paced 60 s stream ≈ 7.5 GB-s ≈ **$0.00009 per
      page view** beyond the allotment, before request ($0.15/M after 1M/mo) and storage
      charges. WebSocket hibernation cannot help: any in-flight request/response — the
      paced stream itself — voids hibernation eligibility.
    - A DO is instantiated near the colo of the **first** `get()` and never relocates;
      Cloudflare's docs state stateful forwarding "will often add response latency" when a
      later request (our skip POST) enters via a different colo.
    - Workers can observe client aborts via `request.signal` (behind the
      `enable_request_signal` compatibility flag) — client cancellation propagates into the
      edge compute layer.
14. **Service-Worker stream-stitching (C2) has a spec-acknowledged lifetime risk — and a
    production-proven mitigation.**
    - The ServiceWorker spec provides **no implicit keep-alive** for a `respondWith()`
      whose body is a JS-constructed `ReadableStream`
      ([w3c/ServiceWorker#882](https://github.com/w3c/ServiceWorker/issues/882), decided
      2016, still open): the developer must use `event.waitUntil()`, and spec editors
      confirm that SW termination mid-stream **kills the in-flight response** (not a
      graceful handoff). Pure native passthrough (`respondWith(fetch(req))` with no JS
      transform) is the one shape expected to survive termination — which a
      `TransformStream` design forfeits.
    - Firefox concretely enforces a ~30 s idle + 30 s grace budget and kills workers with
      pending `respondWith`/`waitUntil` (Gecko source: `dom.serviceWorkers.idle_timeout`,
      `idle_extended_timeout`; Bugzilla 1302715 remains unimplemented ~9 years on).
      StreamSaver.js (production library) pings the SW via `postMessage` every ~29 s in
      all browsers as the standard mitigation.
    - The widely-cited "Chromium kills SWs at 5 minutes even while streaming" could **not**
      be verified for web (non-extension) SWs — the commonly cited bug is scoped to MV3
      extension service workers; three stronger formulations were refuted 0-3. Chromium's
      current policy for a web SW with an in-flight streaming `respondWith` is genuinely
      unresolved (open question), as is Safari/WebKit's policy.
    - Google's `workbox-streams` is shipped, currently-maintained prior art for the exact
      stitching mechanism (precached partials + network partial concatenated into one
      streamed navigation response via `respondWith`) — though it stitches short-lived
      responses, not long-held paced streams.
15. **Client abort is protocol-clean, per-stream, in both HTTP versions.** HTTP/2
    (RFC 9113 §6.4): `RST_STREAM` requests cancellation of one stream; Chromium verifiably
    maps `AbortController.abort()`/`window.stop()` → `RST_STREAM(CANCEL)`. HTTP/3
    (RFC 9114 §4.1.1 + RFC 9000 §2.4): cancellation = `RESET_STREAM` (sending part) +
    `STOP_SENDING` (receiving part) with `H3_REQUEST_CANCELLED`; a server receiving it MAY
    abruptly terminate the response. In both protocols the abort is scoped to the single
    stream — other in-flight fetches on the same connection are unaffected.
16. **What the CDN edge does with that abort is NOT doc-verified.** Whether Cloudflare /
    CloudFront / Fastly / Akamai stop edge egress and stop draining the origin connection
    on client abort mid-stream is not answered by their public documentation (Fastly's
    streaming-miss guide, for example, describes cache-fill behavior but not client
    disconnect). This is the empirical half of the zero-waste question and is a designated
    prototype experiment (P4), not an assumption.

### Refuted during verification — do not rely on these

- "Chromium terminates a web SW at ~5 minutes even while streaming" (0-3; extension-scoped
  folklore), and both Firefox "~5 minute" formulations (superseded by the verified
  30 s + 30 s budget).
- Both bfcache claims (that an in-flight streamed navigation body, or an outstanding
  `fetch()`, definitively blocks back/forward-cache storage with specific
  `notRestoredReasons` values) failed verification (0-3 and 1-2). **bfcache interaction is
  unknown** for every candidate and is a prototype measurement (P7), not an input.

## Candidate architectures

- **C1 — Edge-held state (Cloudflare Durable Object).** Route the navigation and the skip
  POST to the same DO instance; the DO's delay loop races a sleep against the skip signal
  and flushes remaining chunks down the same connection. Zero duplication by construction;
  requires vendor edge state.
- **C2 — Service Worker stream-stitching.** A SW proxies the navigation
  (`fetch(upstream)` → `TransformStream` → `respondWith`). On scroll intent it aborts the
  upstream fetch (per-stream protocol cancel), fetches only the not-yet-seen section files,
  and writes them into the same stream feeding the parser. The parser executes React's
  reveal scripts natively. Works against a completely dumb CDN.
- **C3 — Gated `window.stop()` + client pull.** After critical resources load, stop the
  navigation stream, then fetch remaining section files and reveal via manual `$RC` (or
  external-runtime append). Zero new infrastructure; collateral damage per Facts 5 and 7.
- **C4 — No-stop client pull (rejected baseline).** Keep the stream flowing; client fetches
  ahead; idempotent `$RC` makes the race safe. Violates requirement 1 (the stream
  re-delivers what the client fetched) — kept as comparison baseline, as C2's
  truncation-recovery mechanism, and as an optional opt-in first-visit accelerator.
- **C5 — Official `prerender`/`resume` split (production pipeline).** Produce chunk 0 as a
  `prerender` prelude (cacheable static asset) and the tail as a `resume` stream generated
  on demand from the stored `postponed` state. The tail request is parameterizable —
  which section to render first — so the skip/priority signal needs **no per-stream server
  state**. A transport (C1's edge join, C2's SW stitch, or C6's pull) still decides how
  tail bytes reach the already-open document.
- **C6 — Pull-only tail ("server islands" mode).** Chunk 0 ends the navigation response;
  a loader (or the SW) fetches section files in viewport-priority order and reveals them
  (external-runtime append, or manual `$RC`). No abort coordination at all; scroll priority
  is a fetch-queue reorder. Direct prior art: Astro Server Islands (`server:defer`) —
  placeholder + per-island cacheable GET + script swap (mechanism confirmed from official
  docs). Trades away the no-JS/SEO completeness of a streamed page and changes the normal
  path (conflicts with requirement 5 as a default; fine as an opt-in page mode).

## Additional avenues evaluated

- **HTTP Range resumption.** Against the _streamed navigation URL_: dead — a paced chunked
  response has no committed `Content-Length` and no stable byte mapping, and RFC 9110 makes
  Range support optional per-resource; CDNs advertise it for cached/static objects, not
  in-flight dynamic streams. Against a **pre-concatenated static chunk asset**: viable and
  attractive. If chunks are byte-stable (external runtime; no nonce rewriting), the build
  can publish `page.html` (all chunks concatenated) plus per-section files; a SW that
  counted bytes as it stitched knows the exact received offset and can issue **one**
  `Range: bytes=<offset>-` request (with `If-Range`/strong ETag) to fetch the entire
  remainder — C2 with a single request instead of N. Requires byte-accurate accounting and
  CDN Range-on-cached-object support (universal for static files, but verify per-CDN in
  P4).
- **HTTP/2+ multiplexing reality check.** N parallel section GETs on the existing h2/h3
  connection cost roughly tens of bytes of compressed headers each (HPACK/QPACK), no new
  connections or TLS handshakes, and are independently prioritizable and cancelable. The
  "one connection" aesthetic of the pure stream carries **no material transport advantage**
  over parallel same-connection fetches. (Analysis from protocol mechanics; not separately
  benchmarked — P3 measures it.)
- **Priority signals without cancellation (Scenario B).** `fetchpriority` and
  RFC 9218 `PRIORITY_UPDATE` reprioritize _transport scheduling_ of a response the server
  is already producing; `103 Early Hints` is pre-response only. None carries an
  application-level "render section K next" instruction into React's render order. The
  practical mechanism **is the request itself**: per-section/parameterized `resume`
  requests (C5) make priority an ordinary HTTP argument. One honest limitation: within a
  single `resume` stream React chooses boundary completion order; coarse priority comes
  from _which_ tail request is issued first, not from reordering inside one stream.
- **Prior art (mechanisms, not marketing).** Astro Server Islands: initial page is
  cacheable with fallback placeholders; each `server:defer` island is fetched from a
  dedicated GET route (props encrypted in the query; POST above 2 KB) and swapped in by a
  small script; island responses are `Cache-Control`-cacheable — C6 is this pattern plus
  React hydration. Marko/SolidStart stream out-of-order fragments with inline reorder
  runtimes (same family as Fizz). Turbo Frames `loading="lazy"` and htmx lazy fragments
  are viewport-triggered per-fragment pulls (C6-family, no hydration). Next.js PPR is C5
  productized: static prelude from the edge + resumed dynamic tail, per its platform
  guide. workbox-streams is C2's stitching shipped by Google. (Astro/workbox verified
  against official docs/source; Marko/Turbo/htmx/Next docs were fetched by the research
  pass but their specific claims were not adversarially verified — flagged accordingly.)

## Cross-cutting resolutions

### CSP for cached chunks (feasibility gate)

Three workable strategies, in order of preference:

1. **External runtime (Fact 12) — recommended for strict-CSP deployments.** Chunks carry
   zero inline scripts; CSP is `script-src 'self'` for the runtime file, optionally
   hash-pinned via Subresource Integrity (`integrity=…` on the script tag — CSP
   `script-src` hashes apply to inline scripts, not external files).
   Chunks become byte-identical for all users → maximal CDN cacheability, and Range
   resumption becomes possible. Cost: vendoring the runtime file + a contract test; the
   option is `unstable_`-prefixed.
2. **Hash-enumerated CSP.** For static chunks the set of inline reveal scripts is **fixed
   at cache-build time**; the builder computes the sha256 of every inline script across all
   chunks and emits them in the CSP header. CSP hashes validate inline scripts regardless
   of when the parser inserts them (spec-level expectation — confirm in P5, which is why
   the prototype keeps a report-only phase). No per-request work; header grows with
   section count.
3. **Per-request nonce rewriting** (what the origin prototype does; an edge worker can do
   the same). Correct but forfeits byte-stable caching and requires compute on every view —
   Next.js documents the same trade-off (nonces force dynamic rendering). Keep only where
   an edge worker is already in the serving path (C1).

### Section boundary metadata (manifest)

Whatever stitches or pulls must know the chunk→boundary mapping. Generate at cache-build
time, alongside the chunk files:

```json
{
  "version": 1,
  "page": "/selective_hydration_demo",
  "reactDomVersion": "19.2.8",
  "runtime": "external",
  "sections": [
    {
      "index": 3,
      "file": "section3.html",
      "boundaryId": "<domId>B:3",
      "contentId": "<domId>S:3",
      "bytes": 18432,
      "concatOffset": 123456,
      "sha256": "…"
    }
  ]
}
```

`concatOffset`/`bytes` enable the Range variant and SW byte-accounting;
`boundaryId`/`contentId` remove filename-convention coupling; per-chunk `sha256` is a
content-integrity check (and, under the hash-enumeration CSP strategy only, the input for
computing the chunk's inline-script hashes). Chunk 0 links the manifest via
`<link rel="preload" as="fetch">` (or inlines it) so the SW and page JS discover it without
convention.

### Reliance on `$RC` and other internals

Facts 7–10 quantify the risk: the inline-runtime _body_ is high-churn (rewritten 19.1→19.2,
34 commits total, reveal timing semantics changed), while the _wire contract_ has been
stable across 18→19. Consequence for architecture choice: prefer designs where React's own
runtime executes reveals (C1/C2 native parsing; C6/C3 via external-runtime append), and
confine any manual `$RC` usage to fallback paths guarded by a **contract test** that runs
against the installed react-dom (assert: `$RC` global exists after bootstrap; calling it
with a delivered chunk's ids reveals within one frame + throttle window; duplicate call is
a no-op). React documents no supported manual boundary-completion API; the sanctioned
alternative is `resume` (C5).

### SEO / no-JS

C1, C2, C5-joined: default path is a complete streamed document — crawlers that don't
execute JS still receive every section once the stream finishes. C3: identical on the
normal path (stop only fires on scroll intent, which crawlers don't trigger). C6: non-JS
clients keep skeletons — same trade-off Astro accepts with fallback slots; unacceptable as
this project's default (requirement 5), acceptable as opt-in page mode. C4: complete
document, at the cost of duplicate bytes when accelerating.

## Comparison matrix

Legend: ✓ meets · ◐ partial/conditional · ✗ fails · **?** unverified (open question).
Weights from the brief; "Hydration" is the hard gate (all candidates pass it — designs that
would fail it were excluded up front).

| Criterion (weight)              | C1 DO edge-state          | C2 SW stitch                            | C3 stop+pull                    | C4 no-stop pull  | C5 prerender/resume                    | C6 pull-only tail           |
| ------------------------------- | ------------------------- | --------------------------------------- | ------------------------------- | ---------------- | -------------------------------------- | --------------------------- |
| Bytes ×1.0 (high)               | ✓ by construction         | ✓ abort + pull-missing                  | ✓                               | ✗ dup on overlap | ✓                                      | ✓                           |
| Scroll → interactive (high)     | ✓ fast; ◐ cross-colo      | ✓ fastest (local, ∥ pull)               | ✓ fast                          | ✓ fastest        | ✓ (transport-dependent)                | ✓ fast                      |
| CDN portability (high)          | ✗ Cloudflare-only         | ✓ any CDN/static host                   | ✓ any                           | ✓ any            | ◐ needs a join point¹                  | ✓ best                      |
| Hydration + state (gate)        | ✓                         | ✓                                       | ✓                               | ✓                | ✓                                      | ✓                           |
| Strict CSP (high)               | ◐ edge nonce or ext-rt    | ✓ hash or ext-rt                        | ◐ ext-rt needed²                | ◐ same as C3     | ✓ prelude static + ext-rt              | ✓ ext-rt                    |
| Scenario B story (medium)       | ◐ DO forwards signal      | ◐ via C5 tail request                   | ◐ via C5                        | ◐ via C5         | ✓ the sanctioned answer                | ◐ per-section reqs          |
| Complexity / ops (medium)       | ◐ DO class + billing³     | ◐ SW lifecycle⁴                         | ◐ fragile gates⁵                | ✓ lowest         | ◐ renderer + storage                   | ✓ low-med                   |
| Undocumented internals (medium) | ✓ none                    | ✓ none                                  | ✗ manual `$RC`²                 | ◐ optional `$RC` | ✓ official API                         | ✓ none (ext-rt)             |
| SEO / no-JS (medium)            | ✓                         | ✓                                       | ✓ (normal path)                 | ✓                | ✓ (joined default)                     | ✗ skeletons                 |
| **Verified open risks**         | cross-colo latency **?**⁶ | Chromium/Safari mid-stream policy **?** | bfcache **?**, readyState stuck | —                | resume-compose outside Next **?** (P6) | normal-path change vs req 5 |

¹ C5's prelude+tail must be joined into one response by an edge worker or origin for the
default path; on a purely static CDN the tail must be pulled (C6/C2 transport).
² With the external runtime (Fact 12), C3/C4's manual-`$RC` dependence disappears
(append-only reveal), upgrading both cells to ✓ — but C3's `window.stop()` collateral
(Fact 5) remains.
³ Verified: ~$0.00009/60 s view duration + $0.15/M requests beyond allotments.
⁴ Verified: heartbeat required (Firefox 30 s+30 s); mid-stream SW death kills the response;
recovery path required.
⁵ Resource-level readiness gate; `readyState` stuck at `interactive`; kills in-flight
subresource loads.
⁶ DO placement/forwarding latency is documented qualitatively ("will often add response
latency") but not quantified.

## Recommended architecture

**A layered composition — "static-first, coordinate-last":**

### Layer 0 (foundation, all scenarios): addressable sections + manifest + byte-stable chunks

Adopt the manifest above; name chunk files by boundary, publish per-section files (and
optionally the concatenated page asset for the Range variant). For strict-CSP targets,
generate chunks with `unstable_externalRuntimeSrc` so cached chunks contain no inline
scripts and are byte-identical for every user. This layer alone removes the
nonce-rewriting tax from `selective_hydration_cached` and makes every transport below
possible.

### Layer 1 (Scenario A default transport): C2 — SW stream-stitching, hardened

- SW proxies the navigation as passthrough pacing (upstream defines pacing); page posts
  scroll intent; SW `abort()`s upstream (RFC-clean per-stream cancel, Fact 15), computes
  missing sections from the manifest + bytes it has already forwarded, fetches only those
  (target section first), and writes them into the same stream. The parser executes
  React's own reveals — zero internals dependence, zero duplicate bytes.
- **Lifetime hardening (Fact 14):** `event.waitUntil()` on the stitch promise +
  StreamSaver-style `postMessage` heartbeat (~29 s) while the upstream is paced; the
  heartbeat stops once stitching completes.
- **Truncation recovery — with a byte cursor, because truncation can land mid-section:**
  if the SW is killed mid-stream anyway, the response truncates, and the cut can fall
  _inside_ a section file (sections are larger than one network chunk). The SW therefore
  persists a per-page byte cursor (total forwarded bytes, mapped through the manifest's
  `concatOffset`s to "last complete section + intra-section offset") as it forwards. The
  page detects unresolved boundaries (Fact 4) and recovers: complete sections are fetched
  whole; a partially-forwarded section is completed with a suffix request
  (`Range: bytes=<intra-section-offset>-` against that section file, or the equivalent
  offset into the concatenated asset). Bytes then remain exactly ×1.0. Where Range is
  unavailable or the cursor was lost, recovery refetches the partial section from zero —
  the guarantee degrades to "×1.0 for all sections except at most one repeated prefix",
  and that degradation is measured, not hidden (P2). The same pull path serves browsers
  without SW support. The skip path has the same mid-section geometry (an abort usually
  lands inside a section) but no fragility: the SW is alive, its cursor is exact, and the
  suffix fetch is precise. Only unexpected SW death risks a lost cursor — hence the
  persistence requirement.
- **First visit:** no controller → plain streamed page, no acceleration (requirement 5
  makes this acceptable by design). Optionally offer C4 as an opt-in first-visit
  accelerator where product prefers speed over the strict byte guarantee.
- Optional refinement once chunks are byte-stable: replace N per-section fetches with one
  `Range: bytes=<offset>-` request against the concatenated asset.

### Layer 2 (Scenario B): C5 — official `prerender`/`resume` as the production pipeline

Replace timing-window capture with a deterministic build: `prerender` (aborted at the
shell) → store `prelude` (= chunk 0, cacheable) + `postponed` JSON. The tail is a
`resume`/`resumeToPipeableStream` response generated on demand — and because the tail is
now _a request_, the skip/priority signal is **stateless**: the client (or SW) issues the
tail request (e.g. `GET /resume/:page?priority=<boundaryId>`) and aborts the paced
default. Transports from Layer 1 (or C1's edge join) carry the bytes.

**Be precise about what the priority parameter can do.** React's `resume` API accepts no
boundary selector or ordering option — within one resume stream, React completes
boundaries in the order their data resolves. The `priority` parameter is therefore an
**application contract, not a React one**, honored by one of two app-level mechanisms:

- **Data-resolution ordering (preferred):** the endpoint resolves the target section's
  data dependencies first (our `CacheSection` demo literally controls this — its async
  delay is the data dependency), so React completes that boundary first. P6 explicitly
  tests whether data-resolution order controls emission order in a resume stream.
- **Per-section resume units:** produce independently resumable artifacts per section
  (nested prerenders), so priority = which request is issued first. Coarser but
  unambiguous; higher build complexity.

These APIs are **recently stabilized** (new in the 19.2 line): treat them as a
version-pinned contract — P6 is the standalone compatibility gate before any renderer
integration, re-run on every React upgrade. This is the same shape Next.js PPR ships,
applied to a Rails + custom Node renderer stack, and it is the honest Scenario B answer:
re-prioritization = which tail request you issue plus data-resolution order inside it,
not a protocol-level reordering inside one stream.

### Positioning of the other candidates

- **C1 (Durable Object):** documented, costed, and viable — the right choice **when the
  deployment is already Cloudflare-committed and SW adoption is unwanted**. Keep as an
  alternative transport, not the default, because of vendor lock and the unquantified
  cross-colo forwarding latency on the signal path.
- **C3 (`window.stop()`):** rejected for production — collateral abort of all in-flight
  subresources, `readyState` permanently `interactive`, unknown bfcache interaction — but
  retained as the measurement baseline for "simplest possible zero-dup".
- **C4:** baseline and recovery mechanism, as above.
- **C6:** opt-in page mode for JS-required apps; its mechanics (per-section addressability,
  append-reveal) are exactly what Layer 1's skip path uses anyway.

### How much is core React vs invented?

Inventory of every mechanism the recommendation relies on, by provenance. The design rule
throughout was: **let React and the web platform do the semantically hard parts; everything
we invent must be inert data or replaceable glue.**

| Mechanism                                                      | Provenance                                                                                                                                  | Invented surface                                                                                                          |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Chunked Suspense wire format (templates, hidden divs, reveals) | **React Fizz** emits it; we never construct or modify it                                                                                    | None — we only split the byte stream on boundaries                                                                        |
| Boundary reveal + hydration retry                              | **React's own runtime** (parser-executed inline scripts, or React's external runtime)                                                       | None in the recommended path (no manual `$RC`)                                                                            |
| Shell-now / tail-later rendering (Scenario B)                  | **React stable APIs** — `prerender` → `postponed` → `resume` (the PPR foundation)                                                           | Rails/renderer endpoint plumbing only                                                                                     |
| Inline-script-free chunks (strict CSP)                         | **React option** `unstable_externalRuntimeSrc` + React's own runtime file (vendored)                                                        | A build step that copies/pins React's file                                                                                |
| Navigation proxying, stream stitching, per-stream abort        | **Web platform** (Service Worker, `TransformStream`, `AbortController`; RFC 9113/9114 cancel) — pattern shipped by Google's workbox-streams | ~300–400 lines of SW glue: byte accounting, "which boundaries passed", fetch-missing, write-through                       |
| Section manifest                                               | Invented                                                                                                                                    | Inert build-time JSON; cross-checked by a verify task; no runtime semantics                                               |
| Scroll-intent detection, heartbeat, truncation recovery        | Invented (heartbeat is the StreamSaver-proven workaround for spec gap w3c#882)                                                              | ~100–200 lines page JS + SW messages                                                                                      |
| Chunk capture (today)                                          | Invented (timing-window rake capture)                                                                                                       | **Shrinks over time**: P6 replaces it with `prerender` output, making chunk 0 a React artifact rather than a parsed guess |

Net: the two things that make the feature _work_ — out-of-order boundary completion with
selective hydration, and shell/tail splitting — are 100% core React. What we invent is
transport glue (SW) and build metadata (manifest), both of which React never sees: from
React's perspective, SW-stitched bytes are indistinguishable from origin-paced bytes. The
rejected candidates were rejected largely on this axis: C3/C4's manual `$RC` invocation is
the only variant that _calls into_ React internals, and Facts 7–10 show exactly that
surface churning (sync→batched rewrite in 19.2).

### Fragility and complexity budget

Where each layer can break, what breaks with it, and what it costs to build:

- **Layer 0 (manifest + assets): low complexity, near-zero fragility.** A rake-task
  extension (~100 lines) emitting JSON that a verify task cross-checks against the chunk
  files. Failure mode: build-time error, never a runtime one.
- **Layer 1 (SW): moderate complexity, one known spec gap, graceful blast radius.** The SW
  is a few hundred lines against standard APIs. The single genuine fragility is the
  spec-acknowledged SW-lifetime gap (Fact 14) — mitigated by the production-proven
  heartbeat, and **designed so every failure degrades to today's behavior**: SW killed
  mid-stream → truncated response → cursor-based pull recovery completes the page (×1.0
  bytes with the persisted cursor; at most one section's prefix repeats if the cursor is
  lost and Range is unavailable); no SW support / first visit / hard reload → plain
  streamed page. There is no failure mode in which the page breaks; the worst case is
  "no acceleration."
- **Layer 2 (resume): moderate integration complexity, negative net fragility.** New
  renderer endpoints + postponed-state storage, but it **deletes** invented machinery
  (timing-window capture, interruptible sleeps, marker files) in favor of stable React
  APIs. P6 gates this layer behind a standalone spike before any renderer code changes.
- **Upgrade drift is made loud, not silent.** The two places React can move under us — the
  wire format we split on, and the vendored external runtime — get contract tests that run
  against the installed `react-dom` (P0/P5) and fail CI on drift, turning "fragile
  internals dependence" into a per-upgrade checklist item. The 18.3.1→19.2.8 comparison in
  Facts 7–10 is evidence the load-bearing wire contract has already survived a major
  version plus a runtime rewrite.
- **Rollout is reversible at every step.** Each layer is opt-in per page; removing the SW
  registration or the manifest reverts to exactly the current `selective_hydration_cached`
  behavior.

### Failure modes of the recommendation

| Failure                                                  | Impact                                              | Mitigation                                                                                                   |
| -------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| SW killed mid-stitch (Firefox 30 s budget; others **?**) | Truncated navigation response, possibly mid-section | Heartbeat; cursor-based recovery with Range suffix (×1.0; ≤1 prefix repeat if cursor lost); P2 verifies both |
| No SW (first visit, unsupported browser, hard reload)    | No acceleration                                     | Plain stream (requirement 5); optional C4 opt-in                                                             |
| CDN keeps egress/origin drain after abort (**?**)        | Wasted egress/origin work, not UX                   | P4 measures per-CDN; Scenario B tails are short-lived resume requests                                        |
| External runtime is `unstable_` / not shipped stable     | Vendoring burden; upgrade risk                      | Pin + contract test per React upgrade (P5); hash-CSP fallback strategy                                       |
| `resume` composition outside Next.js unproven            | Layer 2 blocked                                     | P6 is a standalone spike before any renderer integration                                                     |
| Reveal batching adds ≤~300 ms after bytes arrive         | Perceived latency                                   | Accept (design intent of React 19.2); measure in P3; do not fight internals                                  |
| bfcache behavior unknown (claims refuted both ways)      | Possible hidden back-nav tax                        | P7 measures `notRestoredReasons` per candidate; no assumptions                                               |

## Prototype plan

Every step has an experiment with pass/fail criteria, mirroring the empirical style of the
original brief. Steps are ordered so each de-risks the next; P1–P4 exercise Layer 1, P5–P6
the foundation upgrade and Layer 2.

- **P0 — Manifest + boundary-aligned, addressable sections.** Extend `section_cache.rake`
  to emit `manifest.json` (schema above: boundary/content ids parsed from captured
  chunks, byte sizes, concat offsets, sha256) — **and make section files boundary-aligned
  rather than trusting time windows**: today's capture assigns raw 4096-byte
  `read_nonblock` fragments to time buckets, so a large section or a fragment straddling
  a delay cutoff can split a hidden div or reveal instruction across files. Re-split the
  captured byte stream on Fizz unit boundaries (each tail file starts at
  `<div hidden id="…S:` and ends after its reveal instruction) before writing. _Pass:_
  `section_cache:verify` cross-checks every manifest entry against file bytes; every
  `template[id*="B:"]` in chunk 0 has a manifest row; every tail file independently
  parses to exactly one hidden content div + its instruction (no dangling open tags);
  concatenating all files byte-equals the original captured stream.
- **P1 — SW passthrough parity.** Register a SW that pipes the navigation through an
  identity `TransformStream` (no abort logic yet). Compare against no-SW streaming.
  _Pass:_ byte-identical delivered document (hash of received bytes), all sections hydrate,
  counter-state test passes, no console errors, added latency within noise (<10 ms median
  over 20 runs).
- **P2 — Lifetime + truncation recovery.** (a) With 60 s pacing in Firefox, confirm the
  stitch dies without mitigation, then that `waitUntil` + 29 s heartbeat keeps it alive to
  completion. (b) Kill the SW deliberately mid-stream (unregister/devtools) in **two
  arms**: between sections, and **mid-section** (kill while a section's bytes are
  partially forwarded); verify the page detects unresolved boundaries and recovers via
  the persisted byte cursor — whole fetches for missing sections, a
  `Range: bytes=<offset>-` suffix fetch for the partial one. _Pass:_ page reaches full
  interactivity in all arms; server/SW byte accounting shows **every section crossed the
  wire exactly once, including the partially-forwarded one**; a third arm with the cursor
  deliberately dropped documents the degraded case (exactly one prefix repeat, page still
  completes).
- **P3 — Scroll-priority skip.** Wire the capturing scroll listener → `postMessage` → SW
  abort + manifest-driven fetch of missing sections (target first). The abort will
  usually land **mid-section**: the SW uses its byte cursor to complete the in-flight
  section with a Range suffix fetch, then fetches the rest whole. Instrument: intent
  timestamp, upstream-abort timestamp, per-section fetch start/finish, reveal time
  (MutationObserver on boundary), interactive time (click responds). _Pass:_
  scroll-intent → target-section interactive < 500 ms on localhost with 25 s pacing
  (allowing the ≤300 ms reveal batch), zero duplicate bytes (SW-side counter vs server
  log), state preserved in already-revealed sections, zero console errors.
- **P4 — Real-CDN abort behavior (closes the verified open question).** Deploy chunks to
  Cloudflare (free tier), CloudFront, and Fastly (trial): paced delivery via each vendor's
  idiom (worker/edge function or origin pacing). Client aborts mid-stream at a known byte
  offset. Measure at the edge/origin: bytes egressed after abort, and (Scenario B sim)
  whether the origin connection keeps draining. Also verify Range-on-cached-asset per CDN
  for the concatenated variant. _Pass:_ a per-CDN table with measured egress-after-abort;
  "unknown" is an acceptable cell value only where the platform provides no measurement
  surface.
- **P5 — External runtime + strict CSP.** Plumb a streaming-options passthrough
  (`unstable_externalRuntimeSrc`, `externalRuntimeConfig`) through
  `streamServerRenderedReactComponent.ts` and the renderer config; vendor the runtime file
  pinned to the installed React; regenerate chunks. Serve under
  `Content-Security-Policy-Report-Only: script-src 'self'` first (optionally with SRI
  `integrity=…` pinning the runtime script tag), then enforced. _Pass:_ chunks contain
  zero inline `<script>`; streamed, SW-stitched, and
  client-appended deliveries all reveal + hydrate with zero CSP reports; contract test
  asserts instruction attributes (`data-rci`/`data-bid`/`data-sid`) against the installed
  react-dom and fails loudly on upgrade drift.
- **P6 — `prerender`/`resume` spike (standalone, before renderer integration).** Node
  script against the dummy page component: `prerenderToNodeStream` aborted at the shell →
  persist prelude + `postponed` JSON → serve prelude → later `resumeToPipeableStream` →
  deliver tail (i) piped by the SW into the original stream and (ii) client-appended.
  Additionally test the **priority mechanism**: resolve the sections' data dependencies
  in non-document order and observe whether boundary emission order in the resume stream
  follows data-resolution order. _Pass:_ boundaries resolve and hydrate from a resume
  stream generated in a **separate process invocation** than the prelude (proves the
  on-demand composition outside Next.js); bytes ×1.0; emission order demonstrably follows
  data-resolution order (or the per-section-resume-unit fallback is documented as
  required); document any semantic surprises (this is the research pass's open
  question #3).
- **P7 — bfcache + readiness observation.** For plain stream, C2, C3, C4: instrument
  `PerformanceNavigationTiming.notRestoredReasons` and back/forward navigation across
  Chrome/Firefox/Safari, plus `readyState`/`load` timing. _Pass:_ a filled-in table; no
  candidate silently regresses back-nav (or the regression is documented and accepted).
- **P8 — Productization decision.** With P1–P7 evidence: promote the SW + manifest into an
  opt-in Pro feature (`react_on_rails_pro` config + generator), wire the priority
  parameter into the renderer's resume endpoint (Layer 2), and decide C1 support level
  (docs recipe vs shipped adapter). Includes CHANGELOG, docs, and the license-header
  policy for the new files.

## Sources

**Adversarially verified (3-vote pass, fetched live 2026-07-21):**

- Cloudflare DO pricing — wall-clock duration billing, 128 MB-equivalent, rates:
  <https://developers.cloudflare.com/durable-objects/platform/pricing/>
- Cloudflare DO data location — first-`get()` placement, no relocation, forwarding
  latency: <https://developers.cloudflare.com/durable-objects/reference/data-location/>
- Cloudflare DO WebSockets best practices — hibernation eligibility constraints:
  <https://developers.cloudflare.com/durable-objects/best-practices/websockets/>
- Cloudflare Workers Streams API + DO ReadableStream example — streaming responses are
  first-class: <https://developers.cloudflare.com/workers/runtime-apis/streams/>,
  <https://developers.cloudflare.com/durable-objects/examples/readable-stream>
- ServiceWorker spec issue #882 — no implicit keep-alive for JS-driven `respondWith`
  streams; editors confirm mid-stream death kills the response; StreamSaver keep-alive
  practice: <https://github.com/w3c/ServiceWorker/issues/882>
- ServiceWorker spec issue #1182 — `fetchEvent.waitUntil` lifetime gap, open:
  <https://github.com/w3c/ServiceWorker/issues/1182>
- Bugzilla 1302715 + Gecko source — Firefox 30 s idle + 30 s grace termination with
  pending `respondWith`: <https://bugzilla.mozilla.org/show_bug.cgi?id=1302715>
- Chromium issue 40733525 — the "5-minute" figure is MV3-extension-scoped:
  <https://issues.chromium.org/issues/40733525>
- workbox-streams — shipped SW stitching prior art:
  <https://developer.chrome.com/docs/workbox/faster-multipage-applications-with-streams>,
  <https://developer.chrome.com/docs/workbox/reference/workbox-streams/>
- RFC 9113 §6.4 (`RST_STREAM`), RFC 9114 §4.1.1 (request cancellation), RFC 9000 §2.4
  (`RESET_STREAM`/`STOP_SENDING`): <https://www.rfc-editor.org/rfc/rfc9113.html>,
  <https://datatracker.ietf.org/doc/html/rfc9114>,
  <https://www.rfc-editor.org/rfc/rfc9000>

**Verified first-hand in this investigation (npm tarballs / GitHub API / repo):**

- `react-dom@18.3.1` vs `@19.2.7` vs `@19.2.8` production builds — `$RC` rewrite, `$RB`/
  `$RV`/`$RT` batching, idempotency guards, stable export lists (`resume`,
  `resumeToPipeableStream`, `prerender`, `resumeAndPrerender`), `unstable_externalRuntimeSrc`
  - `data-rci`-family instruction attributes; `react@19.2.8` lacks stable `postpone`;
    runtime file present only in `react-dom@experimental`.
- `facebook/react` history: 34 commits to `fizz-instruction-set` (2022-10 → 2026-07);
  hardening PRs <https://github.com/facebook/react/pull/33511>,
  <https://github.com/facebook/react/pull/33531>; external-runtime origin PR
  <https://github.com/facebook/react/pull/25499>.
- This repo: `PagesController#selective_hydration_cached`, `section_cache.rake`,
  `CacheSection.jsx`, `streamServerRenderedReactComponent.ts` (integration seam; no
  streaming-options passthrough today).

**Fetched from primary docs, not adversarially verified (flagged):**

- Astro Server Islands mechanism: <https://docs.astro.build/en/guides/server-islands/>
  (fetched 2026-07-21; placeholder + per-island GET + swap + cacheability confirmed from
  doc text).
- Cloudflare Workers request-cancellation signal (compat-flag gated):
  <https://developers.cloudflare.com/changelog/2025-05-22-handle-request-cancellation/>
- Fastly streaming-miss guide (does **not** answer client-disconnect drain):
  <https://www.fastly.com/documentation/guides/full-site-delivery/performance/streaming-miss/>
- React `resume` reference and React 19.2 release notes:
  <https://react.dev/reference/react-dom/server/resume>,
  <https://react.dev/blog/2025/10/01/react-19-2>
- Next.js PPR platform guide and CSP guide (nonce ⇒ dynamic rendering):
  <https://nextjs.org/docs/app/guides/ppr-platform-guide>,
  <https://nextjs.org/docs/pages/guides/content-security-policy>
- Marko streaming, Turbo Frames: <https://markojs.com/docs/explanation/streaming>,
  <https://turbo.hotwired.dev/reference/frames>

**Explicitly unverified / open (tracked in the prototype plan):**

- CDN edge egress + origin-drain behavior on client abort, per vendor (P4).
- Chromium and Safari current lifetime policy for a web SW with an in-flight streaming
  `respondWith` (P2 measures behaviorally).
- bfcache interaction for all candidates — both directions refuted in verification (P7).
- `resume` composition with an already-delivered shell outside Next.js (P6).
- Non-Cloudflare edge-state equivalents (Fastly Compute, Akamai EdgeKV, CloudFront
  Functions/Lambda@Edge, Deno Deploy) — not needed by the recommendation; verify only if
  C1-on-another-vendor becomes a requirement.
- RFC 9218 `PRIORITY_UPDATE` browser/CDN honoring specifics (informational only here).
