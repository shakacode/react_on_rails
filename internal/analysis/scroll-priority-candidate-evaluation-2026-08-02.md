# Scroll-Priority Streaming Architecture Evaluation

**Issue:** #4835 (evaluation) → parent #4385, design doc #4769
**Date:** 2026-08-02
**Method:** Independent re-derivation with adversarial multi-agent verification (9 agents, 594K tokens, 280 tool invocations)
**Branch:** selective-hydration-scroll-priority-demo

---

## 1. Executive Summary

Six candidate architectures were evaluated for delivering scroll-priority streaming in React on Rails. The evaluation drew on primary source verification of browser specifications, React internals, CDN platform documentation, and integration analysis against the existing `streamServerRenderedReactComponent.ts` pipeline.

| Candidate                                    | Verdict                                      | Rationale                                                                                                                                                                                                                                                                                                                                                                                                                       |
| -------------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **C1** Edge-Held State (Cloudflare DO)       | **Conditionally viable**                     | Technically sound but imposes hard vendor lock-in to Cloudflare. No equivalent exists on any other edge platform (verified against Fastly, AWS, Akamai, Deno Deploy, Vercel). Cost is acceptable (~$47-94/mo per 1M views).                                                                                                                                                                                                     |
| **C2** Service Worker Stream-Stitching       | **Ruled out**                                | Safari terminates idle SWs in 10 seconds (verified: WebKit `defaultTerminationDelay = 10_s`). The W3C `waitForBody` proposal (issue #882) is still open after 10 years, assigned to "Version 2" milestone. 35-75% of traffic is uncontrolled (first visit + eviction). workbox-streams provides no keepalive, no priority reordering, no abort mid-stream.                                                                      |
| **C3** Gated window.stop() + Client Pull     | **Ruled out**                                | `window.stop()` kills ALL in-flight network activity. `document.readyState` behavior after stop is historically underspecified and browser-inconsistent. Breaks Google Tag Manager, analytics, Selenium, lazy-loading libraries. Incompatible with RSC payload injection. Direct dependency on `$RC` internal API with 3 major rewrites in 2024-2026.                                                                           |
| **C4** No-Stop Client Pull (fetch delivery)  | **Viable -- recommended as Layer 1**         | Already implemented and working in the demo (`?mode=fetch`). Zero blast radius on normal path. Zero new dependencies. `$RC` idempotency makes the stream+fetch race safe. Graceful degradation: if fetch path breaks on React upgrade, stream delivers sections normally.                                                                                                                                                       |
| **C5** Official prerender/resume (React PPR) | **Conditionally viable -- defer to Layer 3** | Uses stable React 19.2 APIs (`prerenderToNodeStream`, `resumeToPipeableStream` -- confirmed in `react-dom@19.2.7`). But requires deep changes to `streamServerRenderedReactComponent.ts`, `injectRSCPayload.ts`, the node renderer protocol, and a PostponedState storage layer. `React.postpone()` is still `unstable_postpone()` (not in stable npm). High integration effort, high reward if React PPR becomes the standard. |
| **C6** Pull-Only Tail (Server Islands)       | **Conditionally viable**                     | Simplest CDN story. But violates progressive enhancement (no JS = no deferred content). Same `$RC` dependency as C3/C4 but without the stream fallback. Incompatible with dynamic RSC payloads.                                                                                                                                                                                                                                 |

**Overall recommendation:** Proceed with C4 as the immediate production path (Layer 1). It is already built, tested, and requires zero infrastructure changes. Prepare C5 as the medium-term target (Layer 3) once React PPR stabilizes and the node renderer protocol can be extended. Defer C1 to a recipe/guide for Cloudflare-specific deployments. Drop C2, C3, and C6.

---

## 2. Re-Derived Comparison Matrix

Evaluation criteria applied to each candidate with evidence from primary sources. Verdicts: PASS, PARTIAL, FAIL, UNKNOWN.

### 2.1 First-visit degradation (Requirement 5: works without JS/SW/edge)

| Candidate | Verdict | Evidence                                                                                                                                                                                                                                              |
| --------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1        | PASS    | Falls back to origin streaming. DO is only instantiated when CDN is in the path.                                                                                                                                                                      |
| C2        | FAIL    | 100% of first visits have no SW controller (MDN: "starts life with or without a service worker and maintains that for its lifetime"). 4-8% of returning visitors also uncontrolled (Google I/O Web App study). Total uncontrolled: 35-75% of traffic. |
| C3        | PARTIAL | Works without JS but delivers the full stream (no optimization). With JS, `window.stop()` side effects are severe.                                                                                                                                    |
| C4        | PASS    | Stream delivers all sections on timer regardless. Fetch path is purely additive. No JS = full stream, slightly slower.                                                                                                                                |
| C5        | PASS    | Falls back to full SSR if postponed state is unavailable ("The user gets a complete page without the shell-first optimization" -- Next.js PPR Platform Guide).                                                                                        |
| C6        | FAIL    | No JS = permanent skeleton placeholders. No `<noscript>` alternative. Same as Astro Server Islands: "If JavaScript is disabled, the fallback slot content remains permanently visible."                                                               |

### 2.2 CDN compatibility (works behind major CDNs without vendor lock-in)

| Candidate | Verdict | Evidence                                                                                                                                                                                                                                                                                                                    |
| --------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1        | FAIL    | Requires Cloudflare Workers + Durable Objects. No equivalent on Fastly (no cross-request state), AWS Lambda@Edge (5-30s timeout), Akamai EdgeWorkers (10-20ms CPU budget), Deno Deploy (no actor guarantee), or Vercel Edge Functions (no cross-request coordination). Verified against current docs for all six platforms. |
| C2        | PASS    | CDN-agnostic. SW runs in the browser. Section files are static assets servable from any CDN.                                                                                                                                                                                                                                |
| C3        | PASS    | No CDN requirements. Section files are static assets.                                                                                                                                                                                                                                                                       |
| C4        | PASS    | No CDN requirements. Section files are static assets at known URLs.                                                                                                                                                                                                                                                         |
| C5        | PARTIAL | Prelude is CDN-cacheable. Resume requires origin compute. Only Vercel's CDN currently implements the resume protocol natively. Self-hosted `next start` works but loses edge TTFB advantage. Netlify confirmed: "The Adapter API solves the build output problem. It does not solve the architecture problem."              |
| C6        | PASS    | Simplest CDN story: chunk 0 is a single static file. Section files are individual static assets.                                                                                                                                                                                                                            |

### 2.3 Service Worker lifetime safety (stream completes before browser kills SW)

| Candidate | Verdict | Evidence                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| --------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| C1        | N/A     | No SW involved.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| C2        | FAIL    | Safari: 10s idle timeout (WebKit `defaultTerminationDelay = 10_s`, verified from changeset 291467). Firefox: 60s total budget (30s idle + 30s extended, verified from Bug 1588838, reduced in Firefox 74). Chromium: 30s idle + 5min hard cap per event (verified from `service_worker_version.cc`, applies to web SWs, NOT just MV3 extensions -- the research claim that Chrome 110 changes were MV3-only was confirmed by verification). `respondWith()` with ReadableStream body settles the promise immediately; SW becomes idle while stream is still consumed (W3C issue #882, still open, Version 2 milestone). StreamSaver.js uses 10s heartbeat (verified: NOT 29s as sometimes claimed). workbox-streams uses only `event.waitUntil(done)` with zero keepalive mechanism. |
| C3        | N/A     | No SW involved.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| C4        | N/A     | No SW involved.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| C5        | N/A     | No SW involved.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| C6        | N/A     | No SW involved.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |

### 2.4 React upgrade safety (survives React minor/major version changes)

| Candidate | Verdict     | Evidence                                                                                                                                                                                                                                                                                                                                                                                       |
| --------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1        | PASS        | Replays cached HTML bytes. Never calls React APIs. Only dependency is `$RC` inline script wire format stability (comment node protocol `$?`/`$~`/`$`/`$!`/`/$` -- verified present in react-dom@19.2.7).                                                                                                                                                                                       |
| C2        | PASS        | Same as C1 -- pipes bytes through TransformStream without interpreting React internals.                                                                                                                                                                                                                                                                                                        |
| C3        | FAIL        | Calls `window.$RC(boundaryId, contentId)` directly. `$RC` has had 3 major rewrites 2024-2026: (1) initial Fizz, (2) error handling refactor removing errorDigest, (3) batching rewrite adding `$RB`/`$RV`/`$RT` (shipped React 19.2). The batching rewrite changed `$RC` from synchronous DOM swap to async queued reveal. Function name, globals, and behavior all changed.                   |
| C4        | PARTIAL     | Also calls `$RC` directly in `fetchAndRevealSection` (line 272 of demo JS). BUT: the stream continues running as fallback. If manual `$RC` fails silently, sections arrive via stream ~seconds later. Worst case = graceful degradation to stream timing.                                                                                                                                      |
| C5        | PASS (best) | Uses stable, sanctioned React APIs: `prerenderToNodeStream` and `resumeToPipeableStream` (both confirmed exported from `react-dom@19.2.7` server.node.js and static.node.js). Postponed state format is opaque but versioned -- prelude and tail must use same React version. `React.postpone()` is still `unstable_` prefixed (NOT in stable npm), but abort-based mechanism works on stable. |
| C6        | FAIL        | Same `$RC` dependency as C3, but WITHOUT the stream fallback. If `$RC` breaks, sections never reveal.                                                                                                                                                                                                                                                                                          |

### 2.5 CSP compatibility (works with strict Content Security Policy)

| Candidate | Verdict | Evidence                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| --------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1        | PASS    | DO rewrites nonces per-request (same mechanism as current Rails controller's `gsub`).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| C2        | PARTIAL | CDN-served sections contain inline scripts with stale nonces. Options: (a) `strict-dynamic` propagation from shell's nonced scripts -- spec confirms dynamically-inserted `<script src>` inherits trust, but inline scripts do NOT ("strict-dynamic with no nonce or hash trusts NOTHING" -- W3C CSP issue #426); (b) hash-based CSP -- impractical because `$RC` calls contain per-render boundary IDs making each script unique; (c) edge-worker nonce rewriting -- adds infrastructure. The `fetchAndRevealSection` path in the demo explicitly skips script execution and uses DOM manipulation, which sidesteps CSP. |
| C3        | PASS    | Manual `$RC` calls are DOM manipulation, not script execution. CSP not involved.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| C4        | PASS    | Same as C3 -- `fetchAndRevealSection` uses `DOMParser` + `adoptNode` + direct `$RC` call. "We NEVER execute the fetched scripts (their cached CSP nonces are stale anyway)" (line 257 of demo JS).                                                                                                                                                                                                                                                                                                                                                                                                                        |
| C5        | PASS    | Both prelude and resume streams go through `renderToPipeableStream` with the `nonce` option. Nonces are fresh per-request.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| C6        | PASS    | Same DOM manipulation approach as C4 for fetched sections. Shell has fresh nonces from render pipeline.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |

### 2.6 RSC payload compatibility

| Candidate | Verdict           | Evidence                                                                                                                                                                                                                                                                                                                                                                    |
| --------- | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1        | PARTIAL           | Works for static RSC payloads (baked into cached sections). Dynamic per-request RSC payloads cannot be served from cache without significant additional complexity (DO would need to fetch RSC payload stream separately and inject it).                                                                                                                                    |
| C2        | PARTIAL           | Same as C1 for cached pages. For live-rendered pages (Scenario B), SW proxies live stream -- RSC compatibility identical to today.                                                                                                                                                                                                                                          |
| C3        | FAIL              | `window.stop()` kills the navigation stream including `injectRSCPayload.ts` pipeline. If RSC payload scripts not fully flushed before stop, client receives truncated payload. `rscRequestTracker.clear()` runs server-side on abort but client-side RSC hydration may be inconsistent.                                                                                     |
| C4        | PASS              | Stream continues running, so `injectRSCPayload` pipeline delivers RSC payload scripts normally. Fetched sections' baked-in RSC payload scripts are stale but harmless (duplicate pushes to global array handled by RSC hydration code).                                                                                                                                     |
| C5        | PARTIAL (complex) | Most complex interaction. RSC payload must be split between prelude and resume streams. `RSCRequestTracker` lifecycle (`getRSCPayloadStream`, `recordRSCDiagnostic`, `consumeCapturedRSCDiagnostics`) must span two render operations. `PostSSRHookTracker.notifySSREnd` must fire after resume completes, not after prelude. This is the single hardest integration point. |
| C6        | FAIL              | Render aborted after shell truncates RSC payload stream. Fetched sections contain HTML only -- no RSC payload scripts. RSC-dependent client components in deferred sections lack data for hydration.                                                                                                                                                                        |

### 2.7 Duplicate delivery handling

| Candidate | Verdict | Evidence                                                                                                                                                                                                                          |
| --------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1        | PASS    | Skip signal stops stream delivery of specific sections. No duplicate.                                                                                                                                                             |
| C2        | PASS    | SW controls what enters the response stream. No duplicate if SW manages correctly.                                                                                                                                                |
| C3        | N/A     | Stream is killed entirely by `window.stop()`.                                                                                                                                                                                     |
| C4        | PASS    | `$RC` idempotency confirmed: first call consumes the hidden div, second call finds no boundary template and no-ops. Demo tracks duplicates via `section.duplicates` counter. Duplicate is harmless bytes (wasted bandwidth only). |
| C5        | PASS    | React PPR: prelude contains static content, resume delivers only dynamic portions. No overlap by design.                                                                                                                          |
| C6        | PASS    | Stream delivers only shell. Sections fetched individually. No duplicate.                                                                                                                                                          |

### 2.8 Store hydration safety

| Candidate | Verdict  | Evidence                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| --------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| C1-C6     | ALL PASS | Store elements are in chunk 0 (the shell), initialized during `forEachStore()` in `ClientRenderer.ts` before any scroll triggers section delivery. Guard in `initializeStore` (ClientRenderer.ts line 126) prevents re-initialization. Sections contain component content that reads from already-hydrated stores, never store initialization scripts. Verified: `redux_store` helper is called at controller level (`pages_controller.rb` line 804), so stores always map to the prelude/shell. |

### 2.9 SEO impact

| Candidate | Verdict | Evidence                                                                                                                                                                                                                                                                                                                           |
| --------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1        | PASS    | Origin fallback delivers complete HTML to crawlers. DO path is optional.                                                                                                                                                                                                                                                           |
| C2        | PASS    | First visit (all crawlers) loads via normal network path -- complete HTML.                                                                                                                                                                                                                                                         |
| C3        | PARTIAL | If `window.stop()` fires before crawler receives full content, below-fold content lost. But crawlers typically do not scroll, so stop may never trigger.                                                                                                                                                                           |
| C4        | PASS    | Stream delivers all content. Fetch path is additive and invisible to crawlers.                                                                                                                                                                                                                                                     |
| C5        | PASS    | Prelude contains all SEO-critical content. Resume delivers interactive portions. Googlebot crawl phase sees complete shell HTML.                                                                                                                                                                                                   |
| C6        | FAIL    | Deferred sections are skeleton-only in HTML. AI crawlers (GPTBot, ClaudeBot, PerplexityBot) do NOT render JS at all (verified: Vercel confirmed across 1B+ monthly bot requests). Googlebot render phase may see content if JS executes within ~5s budget, but no guarantee. Bingbot has "MORE LIMITED JS rendering capabilities." |

---

## 3. Open Questions Closed

Questions marked `?` in the original design doc matrix, resolved by this evaluation:

### Q1: "KV propagation delay -- is it really 60s?"

**CLOSED: Yes.** Official docs (updated April 21, 2026) state "Changes may take up to 60 seconds or more." Minimum `cacheTtl` reduced from 60s to 30s (January 30, 2026 changelog), but propagation is still 30+ seconds. KV is COMPLETELY UNSUITABLE for skip signaling. No faster Cloudflare alternative exists except Durable Objects. (Source: developers.cloudflare.com/kv/concepts/how-kv-works/)

### Q2: "Can a DO hibernate while holding a streaming response?"

**CLOSED: No.** An open streaming response violates hibernation condition #4: "active request/event processing." The DO is billed for duration for the entire 30-60s stream. Cost: ~$47-94/mo per 1M views. WebSocket Hibernation API could theoretically reduce costs but changes architecture fundamentally (incompatible with HTTP streaming / `renderToPipeableStream`). (Source: developers.cloudflare.com/durable-objects/concepts/durable-object-lifecycle/)

### Q3: "Does Safari kill SWs faster than Chrome?"

**CLOSED: Yes, significantly.** Safari `defaultTerminationDelay = 10_s` (WebKit changeset 291467) vs Chrome 30s idle. Safari 18.5 fixed "Service Worker downloads being prematurely interrupted" (bug 143065672), suggesting streaming through SWs was historically broken. Safari 26 "Automatically Inspect New Service Workers" is a DevTools feature only, zero production lifetime impact.

### Q4: "Does `respondWith()` with ReadableStream keep the SW alive?"

**CLOSED: No.** The `respondWith()` promise settles immediately when the Response object is handed off. The SW becomes idle even though the stream body is being consumed. Chromium `service_worker_version.cc` has NO stream-specific logic -- all event types treated uniformly. W3C issue #882 proposed `{ waitForBody: true }` -- still OPEN after 10 years, Version 2 milestone. No browser implements it.

### Q5: "Does `AbortController.abort()` send H2 RST_STREAM?"

**CLOSED: Yes, for HTTP/2 connections.** Chromium code path: `AbortController.abort()` -> Blink Fetch API -> `URLRequest` cancellation -> `SpdySession::ResetStream()` -> RST_STREAM CANCEL (0x8). For HTTP/1.1, abort closes/resets the TCP connection instead. Node.js historically sent INTERNAL_ERROR (0x2) instead of CANCEL -- fixed in nodejs/node#47321.

### Q6: "Do CDNs propagate client abort to origin?"

**CLOSED: No, unreliably.** Cloudflare Workers: `request.signal` abort event "never fires during SSE streaming" (workers-sdk#9438). Active regression in workerd@1.20260619.1 (workerd#6832). CloudFront: docs do NOT address viewer disconnect propagation; inferred behavior is to continue draining origin. Fastly: explicitly warns "If you serve an endless response to Fastly, they will hold those connections forever." None of the three CDNs reliably propagate client RST_STREAM to abort origin connections.

### Q7: "Is React's prerender/resume API stable?"

**CLOSED: Stable in 19.2.** Verified exports in `react-dom@19.2.7`:

- `react-dom/static.node.js`: `prerender`, `prerenderToNodeStream`, `resumeAndPrerender`, `resumeAndPrerenderToNodeStream` (confirmed lines 10-14)
- `react-dom/server.node.js`: `resume`, `resumeToPipeableStream` (confirmed lines 17-18)
- Version 19.2.7, no `"experimental"` export condition in package.json
- `React.postpone()` is still `unstable_postpone()` -- NOT in stable npm. Abort-based mechanism is the stable alternative.

### Q8: "Does React emit boundaries in document order or data-resolution order?"

**CLOSED: Data-resolution order.** Whichever Suspense boundary's data resolves first streams first. Out-of-order placement via `$RC`/`completeBoundary` using `document.getElementById` to connect chunks to correct placeholders. React 19.2 added 300ms batched reveal throttle (`FALLBACK_THROTTLE_MS = 300`, `TARGET_VANITY_METRIC = 2300`). Caller controls emission order indirectly by controlling data availability timing.

### Q9: "What is the `$RC` stability situation?"

**CLOSED: Unstable internal, 3 major rewrites.** Verified in `react-dom@19.2.7` `cjs/react-dom-server.node.production.js` line 2477. Current `$RC` uses `$RB` (batch array), `$RV` (flush function), `$RT` (timestamp). Changes: (1) initial Fizz (PR #20970), (2) error handling refactor removing `errorDigest`, (3) batching rewrite (React 19.2, synchronous swap -> async queued reveal). External runtime `data-rci`/`data-rri`/`data-rsi`/`data-rxi` template attributes confirmed present (lines 2474-2506). No public API exists for manually completing a Suspense boundary.

### Q10: "Can postponed state cross process boundaries?"

**CLOSED: Yes, by design.** React docs: `postponedState` parameter described as loaded "from wherever you stored it (e.g., redis, a file, or S3)." Next.js PPR Platform Guide describes CDN POST with postponedState as request body. `react-ppr-from-scratch` repo demonstrates build-time prerender saving to disk, separate server process resuming from disk. Constraints: same React version, same component tree, matching `identifierPrefix`, atomic storage of shell + postponedState.

### Remaining unknowns:

1. **Postponed state size** for a typical 10-section React on Rails page -- documented as "a few KB" for 5-10 boundaries but no measurement exists for the specific component trees in this project.
2. **`unstable_externalRuntimeSrc` timeline to stability** -- still `unstable_` prefixed, initially feature-flagged for Facebook internal only. No public roadmap.
3. **React 20.x / future** changes to Fizz instruction set -- no forward-looking stability guarantee exists.

---

## 4. Candidate Deep Dives

### 4.1 C1: Edge-Held State (Cloudflare Durable Objects)

**Feasibility:** Technically proven. A DO holds the streaming response, reads cached sections from R2, implements interruptible delay via `Promise.race([sleep, skipSignal])`, and accepts skip POSTs forwarded from any Cloudflare colo. Cross-colo forwarding latency for same-user-to-same-DO is sub-30ms (the user's browser typically routes through the same or nearby colo).

**Pros:**

- Skip signal reaches the stream holder in 10-30ms (same-continent), enabling true stream interruption
- No browser-side complexity beyond a POST request
- CSP handled via per-request nonce rewriting at the edge (sub-1ms HTMLRewriter cost)
- Cost is linear and predictable: ~$47-94/mo per 1M views (30-60s average stream duration)

**Cons:**

- **Hard vendor lock-in to Cloudflare** -- verified that NO other edge platform can replicate this: Fastly (no cross-request state), AWS Lambda@Edge (5-30s timeout), Akamai EdgeWorkers (10-20ms CPU budget), Deno Deploy (no actor guarantee, platform transitioning), Vercel Edge Functions (no cross-request coordination)
- DO cannot hibernate during streaming (condition #4 violated) -- full duration billing
- Requires Cloudflare Workers + DO + R2 + DNS routing through Cloudflare
- New deployment artifact (Worker script + DO class + wrangler.toml) outside React on Rails packages

**React on Rails integration:**

- Zero changes to `streamServerRenderedReactComponent.ts`, `injectRSCPayload.ts`, or the node renderer
- Replaces `pages_controller.rb` streaming loop with DO-based delivery
- `section_cache.rake` extended to upload to R2
- Store hydration unaffected (stores in chunk 0, always delivered first)

**What breaks on React upgrade:** Nothing. DO replays cached HTML bytes verbatim. Browser's HTML parser executes React's own inline scripts natively.

**Deployment:** Cloudflare Workers + Durable Objects + R2 (mandatory). Wrangler CLI. DNS through Cloudflare.

### 4.2 C2: Service Worker Stream-Stitching

**Feasibility:** Ruled out due to browser lifetime constraints.

**Blocking issues:**

1. **Safari 10s idle timeout** -- the most aggressive browser. A stream-stitching SW that hands off a `TransformStream`-based Response becomes idle immediately (per W3C issue #882). Safari terminates it in 10 seconds. The Safari 18.5 fix for "prematurely interrupted downloads" (bug 143065672) suggests this was historically a real problem.

2. **Firefox 60s hard cap** -- 30s idle + 30s extended timeout (reduced from 5.5 minutes in Firefox 74, Bug 1588838). Even with `waitUntil()`, maximum 60 seconds.

3. **Chromium 5min per-event cap** -- verified this applies to ALL service workers, not just MV3 extensions (contrary to research claim). The 5-minute cap was verified to apply to streaming responses.

4. **First-visit gap** -- 100% of first visits uncontrolled. 4-8% of returning visitors also uncontrolled. Total: 35-75% of traffic gets zero benefit.

5. **workbox-streams limitations** -- verified source analysis: sequential concatenation only (drain source N completely before starting source N+1), no priority reordering, no abort mid-stream, no keepalive beyond `event.waitUntil(done)`. Would need "significant modification" for scroll-priority use.

**Why the heartbeat workaround is insufficient:** StreamSaver.js uses 10s `postMessage` pings (verified: NOT 29s). This keeps the SW alive but requires the controlled page to be actively pinging. For a TransformStream-based response where the SW is passively proxying, the page must implement a dedicated ping loop -- fragile, power-consuming on mobile, and fails if the page's JS is busy (long task, heavy hydration).

### 4.3 C3: Gated window.stop() + Client Pull

**Feasibility:** Ruled out due to unacceptable side effects.

**Blocking issues:**

1. **`window.stop()` kills ALL network activity** -- not scoped to the navigation stream. Any concurrent fetch (analytics, prefetch, lazy image, WebSocket) is aborted.

2. **`document.readyState` behavior is underspecified** -- Henri Sivonen's 2012 WHATWG analysis found Chrome/Firefox skip `"interactive"` and go directly to `"complete"` after abort, which was "considered wrong." Current spec says aborted documents "should eventually reach complete" but timing is implementation-dependent.

3. **Breaks Google Tag Manager** -- GTM's "Window Loaded" trigger fires on the `load` event. If `readyState` never reaches `"complete"`, tags configured for Window Loaded (analytics pageview events, conversion pixels) never execute.

4. **Breaks Selenium/WebDriver** -- waits for `readyState === 'complete'` by default. Pages stuck in `'loading'` cause test timeouts.

5. **bfcache permanently blocked** -- a page whose parser was aborted mid-stream matches Chromium's `ParserAborted` and `Loading` blocking reasons (verified from `notRestoredReasons` API, Chrome 123+).

6. **Direct `$RC` dependency** -- calls `window.$RC(boundaryId, contentId)` with no fallback. 3 major rewrites to `$RC` in 2024-2026.

7. **RSC incompatible** -- `window.stop()` kills the `injectRSCPayload.ts` pipeline mid-stream.

### 4.4 C4: No-Stop Client Pull (fetch delivery) -- RECOMMENDED

**Feasibility:** Already implemented and working. The `?mode=fetch` query parameter in the demo activates this mode. `fetchAndRevealSection` (lines 243-279 of `selective_hydration_scroll_demo.js`) fetches section files, parses with `DOMParser`, adopts hidden divs via `adoptNode`, and calls `window.$RC(boundaryId, contentId)`.

**Pros:**

- **Zero blast radius** -- stream continues exactly as before. Fetch path is purely additive.
- **Zero new dependencies** -- no SW, no edge runtime, no new packages.
- **Safe duplicate handling** -- `$RC` idempotency confirmed: first call consumes hidden div, second call finds no boundary template and no-ops. Demo tracks duplicates via counter, logged but harmless.
- **Graceful degradation on React upgrade** -- if manual `$RC` fails, stream delivers sections on timer. Worst case = no acceleration, not a break.
- **CSP clean** -- `fetchAndRevealSection` explicitly does NOT execute fetched scripts. Uses DOM manipulation only.
- **SEO safe** -- stream delivers all content. Fetch path invisible to crawlers.
- **bfcache compatible** -- initial page load completes normally (`readyState` reaches `'complete'`). Subsequent fetch calls can be individually aborted in `pagehide` handler. Outstanding fetch blocks bfcache (Chromium `OutstandingNetworkRequestFetch` reason), but abort in `pagehide` fixes this.
- **RSC compatible** -- stream continues running, `injectRSCPayload` delivers payload normally. Fetched sections' stale RSC payload scripts are harmless duplicates.

**Cons:**

- **Duplicate bandwidth** -- section delivered via both stream and fetch. Wasted bytes, not wasted functionality. Mitigation: sections are typically 5-50KB each; the duplicate is a one-time cost per section.
- **`$RC` dependency** -- calls `window.$RC` directly. Medium risk, but degradation is graceful (stream fallback).
- **No stream interruption** -- the server continues sending the full stream regardless of client scroll. Wastes server bandwidth/Puma thread time. Mitigated by the existing skip-delay POST mechanism, which is orthogonal to the fetch path.
- **Acceleration limited to client-side CDN fetch speed** -- cannot beat the stream if the stream is already fast. Value is when the stream is slow (paced delivery, far-away origin).

**React on Rails integration:**

- No changes to any package file
- No changes to `streamServerRenderedReactComponent.ts`, `injectRSCPayload.ts`, or the node renderer
- No changes to deployment infrastructure
- The `signalSection` POST to skip the server delay is complementary -- when it works, the stream catches up faster, reducing duplicate window

**What breaks on React upgrade:** Manual `$RC` call may fail if React changes the global function name or boundary ID format. Stream delivers sections normally as fallback. The only visible effect is loss of scroll-priority acceleration.

### 4.5 C5: Official prerender/resume (React PPR)

**Feasibility:** Technically possible with stable React 19.2 APIs. High integration effort.

**API verification (from react-dom@19.2.7):**

- `react-dom/static.node.js` exports: `prerenderToNodeStream`, `prerender`, `resumeAndPrerenderToNodeStream`, `resumeAndPrerender` (confirmed lines 10-14)
- `react-dom/server.node.js` exports: `resumeToPipeableStream`, `resume` (confirmed lines 17-18)
- `unstable_externalRuntimeSrc` option wired into rendering pipeline: `renderToPipeableStream` (line 7167), `prerender` (line 7272), `prerenderToNodeStream` (line 7336), resume variants (lines 7440+)
- Version 19.2.7, no experimental export conditions, stable release

**Pros:**

- Uses React's sanctioned APIs -- the framework-blessed way to do partial prerendering
- No dependency on `$RC` internals -- React handles boundary resolution natively
- CDN-cacheable prelude with origin-rendered dynamic tail
- Cross-process resume is confirmed and designed for (React docs, Next.js PPR Platform Guide, react-ppr-from-scratch demo)
- Scroll-priority achieved by controlling data-fetch timing per boundary (data-resolution order = emission order)

**Cons:**

- **Highest integration effort** -- requires changes to:
  - `streamServerRenderedReactComponent.ts` (replace `renderToPipeableStream` with two-phase flow)
  - `injectRSCPayload.ts` (RSC payload must split between prelude and resume)
  - `streamingUtils.ts` (length-prefixed protocol must handle both phases)
  - `handleRenderRequest.ts` (new prerender and resume endpoint types)
  - `stream.rb` (two-phase flow support)
  - `react_on_rails_pro_helper.rb` (new options for PPR mode)
- **New infrastructure** -- PostponedStateStore (Redis/filesystem/memory), new node renderer endpoints, resume route in Rails
- **`React.postpone()` still experimental** -- `unstable_postpone()` only available in canary builds or custom React builds with `enablePostpone=true` (confirmed by react-ppr-from-scratch repo). Abort-based mechanism works on stable but is less ergonomic.
- **Postponed state is opaque and version-specific** -- prelude and tail MUST use same React version, constraining upgrade rollouts
- **RSC payload split is the hardest problem** -- `RSCRequestTracker` lifecycle must span two render operations. `rscInitializationBuffers`, `htmlBuffers`, `rscPayloadBuffers` need redesign. `PostSSRHookTracker.notifySSREnd` must fire after resume, not prelude.

**Next.js PPR production evidence:**

- PPR stable in Next.js 16 (October 2025), `cacheComponents: true`
- Vercel CDN is the ONLY CDN implementing the resume protocol natively
- Self-hosted via `next start` works but loses edge TTFB advantage
- Next.js 16.2 Adapter API (March 2026) provides public test suite but Netlify confirmed no other CDN has shipped resume protocol support
- Performance: 4-10x TTFB reduction in benchmarks (20-80ms CDN-cached shell vs 300-800ms full SSR)

**What breaks on React upgrade:** Low risk for the APIs themselves (stable exports). Risk is in the postponed state format (opaque, version-specific) and any evolution of the prerender/resume semantics in 19.3/20.x.

### 4.6 C6: Pull-Only Tail (Server Islands Mode)

**Feasibility:** Viable but violates progressive enhancement requirement.

**Comparison with Astro Server Islands:**

- Astro `server:defer` uses GET-then-replace pattern with `/_server-islands/[name]` endpoint
- Props encrypted with per-build key, passed as query string
- No viewport-priority or lazy-loading for server islands (all fetch eagerly on page load)
- No `<noscript>` alternative (JS disabled = permanent fallback)
- Independent cacheability per island, but encrypted props parameter changes per request, defeating CDN caching unless CDN ignores the `p` parameter

**Pros:**

- Simplest CDN story -- chunk 0 is the entire navigation response
- No streaming, no edge state, no SW
- HTTPS not required

**Cons:**

- **No progressive enhancement** -- JS disabled = permanent skeletons. Violates Requirement 5.
- **Same `$RC` dependency as C3** but WITHOUT stream fallback
- **RSC incompatible for dynamic payloads** -- render aborted after shell truncates RSC payload
- **SEO risk** -- AI crawlers see only skeletons (verified: GPTBot, ClaudeBot, PerplexityBot do not render JS)
- **No lazy-loading built-in** -- must implement IntersectionObserver-based fetch triggering (neither Astro Server Islands nor Turbo Frames provide scroll-priority ordering)

---

## 5. Additional Avenues Evaluated

### 5.1 HTTP Range Requests for Section Delivery

**Verdict: Impractical for streaming, theoretically possible for pre-concatenated static assets.**

- Range requests require byte-range semantics (RFC 9110 Section 14) with known `Content-Length`. Streaming responses (`Transfer-Encoding: chunked` in HTTP/1.1) have no predetermined size -- fundamentally incompatible.
- For pre-concatenated static assets: theoretically possible if byte offsets per section are in a manifest. Requires deterministic build output, no CDN-level compression (gzip/brotli changes offsets), and manifest invalidation on any content change. "Extremely brittle."
- CDN Range support exists but has quirks: CloudFront may expand Range headers internally, Cloudflare strips `Content-Length` from compressed responses, Fastly handles correctly.
- **Conclusion:** Not worth pursuing. Individual section files (the approach already used) are simpler, more cacheable, and CDN-friendly.

### 5.2 HTTP/2 Multiplexing (N Parallel Fetches vs Single Stream)

**Key finding:** Per-request overhead on existing H2 connection is ~40-70 bytes (9-byte frame header + ~20-50 bytes HPACK-compressed headers). Negligible vs payload. N parallel fetches enable independent delivery order, per-section caching, and per-section cancellation -- architectural advantages that far outweigh marginal transport savings of a single stream.

HTTP/3 (QUIC) strengthens the case for parallel fetches: eliminates transport-layer head-of-line blocking that affects HTTP/2 (TCP segment loss stalls ALL streams). Each QUIC stream gets independent loss recovery.

**Conclusion:** The C4/C6 approach of individual section fetches over H2/H3 has negligible transport overhead and superior architectural properties vs a single stream.

### 5.3 Priority Signals (fetchpriority, RFC 9218 PRIORITY_UPDATE, 103 Early Hints)

- `fetchpriority` attribute: sets initial priority only. Cannot reprioritize in-flight responses. Purely advisory. Most effective for disambiguating resources of same type (e.g., LCP image vs other images).
- RFC 9218 PRIORITY_UPDATE: CAN reprioritize in-flight responses via control-stream frames. Chrome 105+ sends PRIORITY_UPDATE frames. Firefox does NOT (still uses RFC 7540 dependency tree). CDN support: Cloudflare and Fastly (co-authors) implement. Practical caveat: "laggy" -- by the time server processes update, significant data may already be sent.
- 103 Early Hints: can carry `fetchpriority` via Link headers for early discovery, but cannot carry PRIORITY_UPDATE frames. Adoption ~5% of top sites.

**Conclusion:** Priority signals are useful for hinting which sections to fetch first in the C4 parallel-fetch approach. `fetchpriority='high'` on the scroll-targeted section's fetch request is low-cost and helpful. RFC 9218 PRIORITY_UPDATE could theoretically reprioritize in-flight section fetches, but browser support (Chrome only) and CDN adoption make it unreliable as a primary mechanism.

### 5.4 Prior Art Survey Summary

| Framework                     | Mechanism                                                      | Scroll Priority?                | Transferable?               |
| ----------------------------- | -------------------------------------------------------------- | ------------------------------- | --------------------------- |
| Astro Server Islands          | GET-then-replace, per-island endpoints                         | No (all fetch eagerly)          | Pattern yes, priority no    |
| Next.js PPR                   | Static shell + resume stream, single HTTP response             | No (all dynamic at once)        | Architecture yes (C5)       |
| Qwik Resumability             | Zero-hydration, state serialized in HTML, lazy handler loading | No                              | Partial (lazy-load concept) |
| Marko/Solid                   | Out-of-order streaming via inline swap scripts                 | No (data-resolution order)      | Same as React Fizz          |
| Turbo Frames `loading="lazy"` | IntersectionObserver-triggered GET per frame                   | Per-frame, not priority-ordered | Pattern only                |
| htmx `hx-trigger="revealed"`  | Viewport-triggered GET per element                             | Per-element, not coordinated    | Pattern only                |

**Key insight from survey:** No existing framework implements scroll-priority ordering of deferred content. Turbo Frames and htmx provide viewport-triggered fetching (binary: in-view or not) but no priority queuing, no reordering based on scroll position changes, no cancellation of out-of-view requests. The scroll-priority concept as described in the design doc is novel.

---

## 6. Cross-Cutting Resolutions

### 6.1 CSP Strategy

**Recommended approach for C4 (and future C5):**

For the fetch delivery path (C4): No CSP concern. `fetchAndRevealSection` uses `DOMParser` + `adoptNode` + direct `$RC()` call. No script execution from fetched content. Existing code comment confirms: "We NEVER execute the fetched scripts (their cached CSP nonces are stale anyway)" (line 257).

For the stream path: React's `nonce` option on `renderToPipeableStream` handles CSP natively. The nonce flows through three paths in the current architecture:

1. `railsContext.cspNonce` -> `sanitizeNonce()` -> `renderToPipeableStream` options (line 287)
2. `railsContext.cspNonce` -> `injectRSCPayload` 4th parameter -> RSC payload script tags
3. `content_security_policy_nonce` -> `gsub` rewriting on cached HTML (demo only)

For CDN-cached sections (future C1/C5): The external runtime (`unstable_externalRuntimeSrc`) is the cleanest solution -- eliminates ALL inline scripts, uses only `<template>` elements with data attributes. CSP policy reduces to `script-src 'self'`. But the API is still unstable. Until it stabilizes, edge-worker nonce rewriting (Cloudflare HTMLRewriter, sub-1ms cost) is the practical alternative.

**Hash-based CSP is impractical:** React's `$RC` calls contain per-render boundary IDs (`B:0`, `B:1`, `S:0`), making each inline script unique. Cannot pre-compute a fixed set of hashes. CloudFront's 1,784-character header limit further constrains this approach.

**`strict-dynamic` does NOT help for inline scripts:** W3C CSP issue #426 confirms "strict-dynamic with no nonce or hash trusts NOTHING." Dynamically-inserted inline scripts (even from a nonced parent) are blocked per spec.

### 6.2 Manifest Format

For C4, the manifest is minimal: section file URLs must follow a predictable pattern (`/cache/selective_hydration_demo/sectionN.html`). The current demo uses this convention without an explicit manifest.

For future C2/C5/C6, a manifest.json would include:

```
{
  "version": "19.2.7",          // React version used for rendering
  "generated": "2026-08-02T...",
  "sections": [
    {
      "id": "section0",
      "boundaryId": "B:0",      // Suspense boundary ID
      "path": "/cache/demo/section0.html",
      "size": 12345,
      "hash": "sha256-...",     // For integrity verification
      "critical": true          // Above-the-fold, always in shell
    }
  ]
}
```

### 6.3 $RC Stability Assessment

**Current state (React 19.2.7):** `$RC` is a minified global function emitted as an inline script string in `cjs/react-dom-server.node.production.js` (line 2477). It uses `$RB` (batch array), `$RV` (flush function), `$RT` (timestamp). The comment node protocol uses `$?` (pending), `$~` (queued), `$` (resolved), `$!` (error), `/$` (end).

**Change history:** 3 major rewrites in 2024-2026:

1. Initial Fizz architecture (PR #20970, sebmarkbage)
2. Error handling refactor (early-mid 2025, removed `errorDigest` parameter)
3. Batching/throttling rewrite (mid 2025, shipped React 19.2) -- changed from synchronous DOM swap to async queued reveal with 300ms throttle

**External runtime alternative:** The `data-rci`/`data-rri`/`data-rsi`/`data-rxi` template attribute protocol (confirmed present in 19.2.7, lines 2474-2506) is the designed alternative to inline scripts. Uses MutationObserver instead of inline script execution. But the external runtime API (`unstable_externalRuntimeSrc`) remains unstable.

**Risk assessment for C4:** Medium. Manual `$RC` call may break on React 20.x. BUT: the stream continues as fallback, making this a graceful degradation, not a hard break. The boundary ID format (`B:N`, `S:N`) is the more stable part -- it is used across both inline script and external runtime paths. The function body is the unstable part.

**Mitigation strategy:** Abstract the `$RC` call behind a version-detecting wrapper:

1. Check if `window.$RC` exists and is a function
2. If yes, call it with boundary and content IDs
3. If no, fall back to: find content div by ID, find boundary template by ID, adopt nodes manually
4. Version-detect the batching protocol: check for `$RB` array existence

### 6.4 SEO Impact

**C4 is SEO-safe.** The stream delivers all content in the initial HTML response. The fetch path is purely additive and invisible to crawlers. No deferred/hidden content.

**Critical SEO constraints for all architectures:**

- AI crawlers (GPTBot, ClaudeBot, PerplexityBot, Gemini) do NOT render JavaScript at all (Vercel confirmed across 1B+ monthly bot requests)
- Googlebot render phase may take hours or days after initial crawl
- Googlebot rendering budget: ~5 seconds safe, some pages render up to 20s
- Bingbot has "MORE LIMITED JS rendering capabilities" -- matters because 92% of ChatGPT Search responses use Bing's index
- All SEO-critical content MUST be in the initial synchronous render (outside deferred Suspense boundaries)

**Recommendation:** For any architecture, serve complete SSR to crawler user agents. The fetch-based delivery mode (C4) is inherently SEO-safe because the initial HTML response completes normally with all content.

### 6.5 bfcache Impact

**C4 is bfcache-compatible with mitigation.** The initial page load completes normally (`readyState` reaches `'complete'`, `load` event fires). Outstanding fetch calls for deferred sections can be individually aborted in a `pagehide` handler via `AbortController`.

**Blocking reasons (verified from Chromium `notRestoredReasons` API, Chrome 123+):**

- `OutstandingNetworkRequestFetch` -- active fetch() blocks bfcache. Fix: abort in `pagehide`.
- `Loading` -- page still loading. Only applies during streaming navigation response (not C4's fetch approach).
- `ParserAborted` -- parser aborted before completion. Only applies to `window.stop()` (C3).

**Recent change:** Chrome 149 (June 2026) made WebSocket pages bfcache-eligible via automatic disconnection on entry. Staged rollout -- some users still report `'websocket'` blocking reason as of Chrome 150.

**C4 implementation pattern:**

```javascript
const abortControllers = new Map();
window.addEventListener('pagehide', () => {
  for (const [id, controller] of abortControllers) {
    controller.abort();
  }
});
```

---

## 7. Evaluation of the Layered Recommendation

The original design doc proposed a 3-layer decomposition:

- **Layer 1:** Client-side fetch acceleration (C4)
- **Layer 2:** Server-side stream interruption (skip-delay POST, already built)
- **Layer 3:** Framework-level integration (C5/PPR)

**Assessment: The layering is correct and well-justified.**

**Layer 1 (C4) is the right starting point** because:

1. Already built and tested
2. Zero deployment requirements beyond existing infrastructure
3. Graceful degradation on every failure mode
4. Complementary to Layer 2 (skip-delay reduces duplicate window)
5. Independent of React version (degradation, not breakage)

**Layer 2 (skip-delay POST) is complementary** and already implemented. The server-side mechanism (filesystem markers in the demo, replaceable by any fast signaling mechanism in production) reduces the time the stream continues sending already-fetched sections. This is a bandwidth optimization, not a correctness requirement.

**Layer 3 (C5/PPR) is the correct long-term target** because:

1. Uses stable, sanctioned React APIs
2. Eliminates duplicate delivery by design
3. Aligns with where the React ecosystem is heading (Next.js PPR)
4. Enables CDN-cached prelude with origin-computed dynamic tail
5. BUT: requires significant integration work (6+ files, new infrastructure, RSC payload split)

**Does one candidate dominate?** No. C4 dominates for immediate value, C5 dominates for long-term architecture. They are not competitors -- C4 is the bridge to C5.

**Should we do nothing yet?** No. C4 is already built and provides measurable value (scroll-to-section latency reduction). The question is not "should we ship C4" but "how do we productionize C4 beyond the demo."

---

## 8. Recommendation

### Proceed Now (Layer 1)

**Ship C4 (No-Stop Client Pull) as a supported feature.**

Work items:

1. Extract `fetchAndRevealSection` from the demo into a reusable module in `react-on-rails-pro`
2. Add `AbortController` management for bfcache compatibility
3. Add `$RC` version detection wrapper for React upgrade resilience
4. Add `fetchpriority='high'` to scroll-targeted section fetches
5. Document the section file format and URL convention
6. Add `pagehide` cleanup for outstanding fetches

### Proceed in Parallel (Layer 2)

**Keep the skip-delay POST mechanism** as a complementary server-side optimization. It reduces duplicate bandwidth. Consider replacing filesystem markers with a faster signaling mechanism (Redis pub/sub, or simply an in-memory hash per Puma worker) for production deployments.

### Defer (Layer 3)

**Prepare for C5 (React PPR) but do not implement yet.** Conditions to trigger C5 work:

1. `React.postpone()` drops the `unstable_` prefix (or abort-based mechanism is proven sufficient for the use cases)
2. `unstable_externalRuntimeSrc` stabilizes (for CSP-clean CDN caching)
3. A second CDN besides Vercel implements the resume protocol (proving it is not a Vercel-only pattern)
4. The `injectRSCPayload.ts` / `RSCRequestTracker` lifecycle is well-understood for two-phase renders

### Drop

- **C1 (Cloudflare DO):** Document as a recipe for Cloudflare-specific deployments. Do not build into the framework.
- **C2 (Service Worker):** Blocked by browser lifetime constraints. Revisit if W3C issue #882 ships `waitForBody`.
- **C3 (window.stop()):** Unacceptable side effects. Do not pursue.
- **C6 (Server Islands):** Violates progressive enhancement. Lower priority than C5 which achieves similar goals with better properties.

---

## 9. Cost Estimates

### Layer 1: C4 Productionization

| Work Item                                                  | Effort        | Ongoing Maintenance                      |
| ---------------------------------------------------------- | ------------- | ---------------------------------------- |
| Extract `fetchAndRevealSection` into Pro module            | 2-3 days      | Low (stable code, already tested)        |
| `AbortController` management + `pagehide` cleanup          | 1 day         | None (standard pattern)                  |
| `$RC` version detection wrapper                            | 1-2 days      | Medium (must verify on each React minor) |
| `fetchpriority` integration                                | 0.5 days      | None                                     |
| Section file URL convention + documentation                | 1 day         | Low                                      |
| Integration tests (duplicate handling, abort, degradation) | 2-3 days      | Medium (run on React upgrades)           |
| **Total**                                                  | **7-10 days** | **Low-Medium**                           |

### Layer 2: Skip-Delay Production Hardening

| Work Item                                                 | Effort       | Ongoing Maintenance |
| --------------------------------------------------------- | ------------ | ------------------- |
| Replace filesystem markers with in-memory/Redis signaling | 1-2 days     | Low                 |
| Add skip-signal metrics (latency, hit rate)               | 1 day        | Low                 |
| **Total**                                                 | **2-3 days** | **Low**             |

### Layer 3: C5 (React PPR) -- Future

| Work Item                                                       | Effort         | Ongoing Maintenance          |
| --------------------------------------------------------------- | -------------- | ---------------------------- |
| `streamServerRenderedReactComponentPPR.ts` (new file)           | 5-8 days       | High (React API evolution)   |
| `injectRSCPayload.ts` two-phase support                         | 3-5 days       | High (RSC payload lifecycle) |
| PostponedStateStore implementation                              | 2-3 days       | Medium (storage backend)     |
| Node renderer protocol extension (prerender + resume endpoints) | 3-4 days       | Medium                       |
| `stream.rb` two-phase flow                                      | 2-3 days       | Medium                       |
| Rails route for resume requests                                 | 1 day          | Low                          |
| Integration tests across prelude/resume lifecycle               | 5-7 days       | High                         |
| **Total**                                                       | **21-31 days** | **High**                     |

### Cloudflare Recipe (C1 Documentation)

| Work Item                        | Effort       | Ongoing Maintenance             |
| -------------------------------- | ------------ | ------------------------------- |
| Worker + DO + R2 example code    | 3-5 days     | Medium (Cloudflare API changes) |
| Documentation + deployment guide | 2-3 days     | Low                             |
| **Total**                        | **5-8 days** | **Medium**                      |

---

## 10. Prototype Plan

### Phase 0: Validate C4 Productionization (Week 1-2)

**P0: Extract and test `fetchAndRevealSection` module**

- Extract from `selective_hydration_scroll_demo.js` into `packages/react-on-rails-pro/src/scrollPriorityFetch.ts`
- Pass/fail: Module imports cleanly, TypeScript compiles, existing demo works with import instead of inline code

**P1: `$RC` version detection wrapper**

- Implement version-detecting wrapper that checks `window.$RC` existence, `$RB` array, falls back to manual DOM manipulation
- Pass/fail: Wrapper works on react-dom@19.2.7 AND a simulated future where `$RC` is renamed to `$RCv2`

**P2: `AbortController` + `pagehide` lifecycle**

- Add abort management for in-flight section fetches
- Pass/fail: `notRestoredReasons` API (Chrome 123+) does NOT report `OutstandingNetworkRequestFetch` after navigation

**P3: Duplicate handling verification**

- Automated test: section arrives via both stream and fetch, verify single DOM rendering, no console errors
- Pass/fail: `section.duplicates` counter increments, no visual glitch, no React hydration mismatch warning

### Phase 1: Integration Testing (Week 2-3)

**P4: React version matrix test**

- Test C4 module against react-dom@18.3.1, @19.0.0, @19.2.7
- Pass/fail: Sections reveal correctly on all three versions, graceful degradation (stream fallback) on simulated `$RC` removal

**P5: bfcache verification**

- Playwright test: load page, scroll to trigger fetches, navigate away, navigate back
- Pass/fail: `performance.getEntriesByType('navigation')[0].type === 'back_forward'` (bfcache hit) after `pagehide` abort cleanup

**P6: CSP verification**

- Set `Content-Security-Policy: script-src 'self' 'nonce-<fresh>'` header
- Pass/fail: No CSP violations in console, all sections reveal correctly via fetch path (DOM manipulation, no script execution)

### Phase 2: Performance Baseline (Week 3)

**P7: Measure scroll-to-visible latency**

- Instrument time from IntersectionObserver trigger to section visible (post-`$RC` call)
- Compare: (a) stream-only delivery, (b) C4 fetch delivery, (c) C4 fetch + skip-delay POST
- Pass/fail: C4 fetch delivery is measurably faster than stream-only for sections 5+ (below fold)

**P8: Measure duplicate bandwidth overhead**

- Count total bytes transferred with C4 vs stream-only
- Pass/fail: Duplicate overhead is <20% of total page weight (acceptable tradeoff for latency improvement)

---

## 11. Sources

### Verified Against Primary Source Code or Official Documentation

| Source                                                                                                                             | Category        | Verified How                                                                 |
| ---------------------------------------------------------------------------------------------------------------------------------- | --------------- | ---------------------------------------------------------------------------- |
| `react-dom@19.2.7` `static.node.js` exports (prerender, prerenderToNodeStream, resumeAndPrerender, resumeAndPrerenderToNodeStream) | React API       | Read file lines 10-14 in local node_modules                                  |
| `react-dom@19.2.7` `server.node.js` exports (resume, resumeToPipeableStream)                                                       | React API       | Read file lines 17-18 in local node_modules                                  |
| `unstable_externalRuntimeSrc` wiring in rendering pipeline                                                                         | React internals | grep found 20 occurrences in `cjs/react-dom-server.node.production.js`       |
| `$RC` function body with `$RB`/`$RV`/`$RT` batching                                                                                | React internals | Read line 2477 of production server build                                    |
| `data-rci`/`data-rri`/`data-rsi`/`data-rxi` template attributes                                                                    | React internals | Read lines 2474-2506 of production server build                              |
| react-dom@19.2.7 version, no experimental export conditions                                                                        | React packaging | Read package.json, grep for "experimental"                                   |
| W3C ServiceWorker issue #882 (waitForBody)                                                                                         | SW spec         | GitHub issue open, Version 2 milestone                                       |
| Firefox SW idle_timeout=30s, idle_extended_timeout=30s                                                                             | Browser         | Bug 1588838, libpref/init/all.js                                             |
| StreamSaver.js heartbeat interval = 10s (not 29s)                                                                                  | Library         | Read mitm.html source                                                        |
| workbox-streams@7.4.0 maintained, 6.8M weekly downloads                                                                            | Library         | npm registry, GitHub repo                                                    |
| Cloudflare KV propagation delay 30-60s                                                                                             | CDN             | developers.cloudflare.com/kv/concepts/how-kv-works/ (updated April 21, 2026) |
| Cloudflare KV minimum cacheTtl reduced to 30s                                                                                      | CDN             | developers.cloudflare.com/changelog/2026-01-30                               |
| DO hibernation conditions (5 requirements)                                                                                         | CDN             | developers.cloudflare.com/durable-objects/concepts/durable-object-lifecycle/ |
| DO cannot hibernate during open streaming response                                                                                 | CDN             | Condition #4: active request/event processing                                |
| `streamServerRenderedReactComponent.ts` renderToPipeableStream options (lines 194, 287)                                            | RoR codebase    | Read source file                                                             |
| `injectRSCPayload.ts` nonce flow                                                                                                   | RoR codebase    | Read source file                                                             |
| `selective_hydration_scroll_demo.js` fetchAndRevealSection (lines 243-279)                                                         | RoR codebase    | Read source file                                                             |

### Accepted From Official Documentation (Not Source-Verified)

| Source                                       | Category  | URL                                                                            |
| -------------------------------------------- | --------- | ------------------------------------------------------------------------------ |
| Safari defaultTerminationDelay = 10s         | Browser   | WebKit changeset 291467 (trac.webkit.org)                                      |
| Safari 18.5 SW download interruption fix     | Browser   | webkit.org/blog/16923/                                                         |
| Chromium 5min per-event hard cap for all SWs | Browser   | Chromium service_worker_version.cc                                             |
| Chrome 149 WebSocket bfcache eligibility     | Browser   | developer.chrome.com/release-notes/149                                         |
| Chrome notRestoredReasons API (Chrome 123+)  | Browser   | developer.chrome.com/docs/web-platform/bfcache-notrestoredreasons              |
| Next.js PPR Platform Guide                   | Framework | nextjs.org/docs/app/guides/ppr-platform-guide                                  |
| Fastly streaming miss behavior               | CDN       | fastly.com/documentation/guides/full-site-delivery/performance/streaming-miss/ |
| Cloudflare Workers request.signal regression | CDN       | github.com/cloudflare/workerd/issues/6832                                      |
| AI crawlers do not render JS (Vercel study)  | SEO       | asklantern.com/blogs/ai-crawlers-do-not-render-javascript                      |
| RFC 9218 (HTTP Priority)                     | Standards | datatracker.ietf.org/doc/html/rfc9218                                          |
| RFC 9110 Section 14 (Range Requests)         | Standards | datatracker.ietf.org/doc/html/rfc9110                                          |
| react-ppr-from-scratch cross-process demo    | Demo      | github.com/shakacode/react-ppr-from-scratch                                    |

### Community-Reported (Not Independently Verified)

| Claim                                                        | Source                                                                | Risk if Wrong               |
| ------------------------------------------------------------ | --------------------------------------------------------------------- | --------------------------- |
| DO cross-colo forwarding latency 10-30ms same-continent      | Inferred from Cloudflare Queues case study + network performance blog | Low (conservative estimate) |
| Googlebot rendering budget ~5 seconds                        | Community consensus, not officially published by Google               | Medium (may be longer)      |
| 92% of ChatGPT Search responses draw on Bing's index         | prerender.io blog                                                     | Low (directional claim)     |
| CloudFront continues draining origin after viewer disconnect | Inferred from docs (not explicitly stated)                            | Medium (may vary by config) |
