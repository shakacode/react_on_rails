# Scroll-Priority Streaming Architecture Evaluation

**Issue:** #4835 (evaluation) → parent #4385, design doc #4769
**Date:** 2026-08-02 (updated)
**Method:** Independent re-derivation with adversarial multi-agent verification (24 agents across 4 workflows, ~1.5M subagent tokens, 631 tool invocations)
**Branch:** selective-hydration-scroll-priority-demo

---

## 1. Executive Summary

Six candidate architectures from the design doc (#4769) were evaluated, plus 30+ additional approaches discovered during research. Each was tested against the evaluation criteria from the issue and two hard production constraints:

- **C1-FIRST:** Works on first visit — no Service Worker, no prior state, incognito, cleared data.
- **C2-BOT:** Bots without JS execution still receive the complete page HTML in the stream.

### Verdicts

| Candidate                               | Verdict                          | One-line reason                                                                                                                                                    |
| --------------------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **C1** Edge-Held State (Cloudflare DO)  | **Conditionally viable**         | Works, but hard vendor lock-in + hosting cost (~$47-94/mo per 1M views). No equivalent on any other edge platform.                                                 |
| **C2** Service Worker Stream-Stitching  | **Ruled out**                    | Fails C1-FIRST (SW doesn't exist on first visit; 35-75% of traffic uncontrolled). Also: Safari kills idle SWs in 10s, W3C `waitForBody` still open after 10 years. |
| **C3** Gated `window.stop()` + Pull     | **Ruled out**                    | Fails C2-BOT (`window.stop()` kills ALL network activity including for JS-executing bots). Also breaks GTM, Selenium, bfcache.                                     |
| **C4** No-Stop Client Pull              | **Viable — recommended**         | Passes both constraints. Already built. Zero blast radius. Graceful degradation. Duplicate bytes are the only cost (21-35KB for 7 sections).                       |
| **C5** `prerender`/`resume` (React PPR) | **Conditionally viable — defer** | Single-response variant passes both constraints but requires deep integration (6+ files). `React.postpone()` still `unstable_`. Defer until APIs stabilize.        |
| **C6** Pull-Only Tail (Server Islands)  | **Ruled out**                    | Fails C2-BOT (no JS = permanent skeletons).                                                                                                                        |

### The Fundamental Tension

A key finding emerged from constraint analysis:

| Want                       | Requires                                                 |
| -------------------------- | -------------------------------------------------------- |
| Zero duplicate bytes       | Someone must know what was already delivered and skip it |
| CDN-served (static replay) | No per-request state, no skip logic                      |
| First-visit compatible     | No Service Worker                                        |
| Bot-safe                   | Stream must deliver all content                          |

**Zero duplicates + CDN-served + first-visit + bot-safe are mutually exclusive.** No architecture satisfies all four. You must relax one:

- Relax "zero duplicates" → **C4** (accept 21-35KB of harmless duplicate bytes) ← recommended
- Relax "CDN-served" → **Server-side section skipping** (origin holds stream, skips confirmed sections)
- Relax "no hosting cost" → **Cloudflare DO** (stateful edge, ~$47-94/mo per 1M views)
- Relax "bot-safe" → C6 Server Islands (bots see skeletons) ← unacceptable

### Recommendation

**Layer 1 (ship now):** C4 — client fetch + `$RC`, stream continues for bots. Already built.
**Layer 2 (ship in parallel):** Origin skip-delay POST (already built) as complementary optimization.
**Layer 3 (when origin holds stream):** Server-side section skipping — zero duplicates, bot-safe via timeout fallback.
**Layer 4 (long-term, 2027+):** React PPR when `React.postpone()` stabilizes.

---

## 2. What the Constraints Eliminate

### 40+ Approaches Evaluated

A comprehensive sweep of every conceivable delivery mechanism, filtered against C1-FIRST and C2-BOT:

#### Fails C1-FIRST (first visit)

| Approach                                | Why it fails                                                                                                                                                                                                                                              |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **C2: Service Worker stream-stitching** | SW doesn't exist on first visit. The navigation response goes straight from network to HTML parser — no interception possible. SW only controls _subsequent_ navigations. `clients.claim()` cannot retroactively intercept an already-streaming response. |
| ReadableStream intercept from page JS   | No browser API exists to intercept the navigation response body from client-side JS                                                                                                                                                                       |
| Navigation API `intercept()`            | Cannot intercept the initial page load — only subsequent same-origin navigations                                                                                                                                                                          |
| SW with `skipWaiting` + `clients.claim` | SW cannot intercept the navigation that registered it — fundamental to the SW lifecycle spec                                                                                                                                                              |
| ReadableStream `tee()`                  | Requires SW to access navigation response; without SW the response is inaccessible                                                                                                                                                                        |
| SharedWorker                            | Safari removed SharedWorker in 2015, no re-add planned — blocks 15-25% of web traffic                                                                                                                                                                     |

#### Fails C2-BOT (bot HTML completeness)

| Approach                                | Why it fails                                                                                                     |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **C3: `window.stop()` + client pull**   | `window.stop()` kills ALL in-flight network activity including for JS-executing bots (Googlebot renderer)        |
| **C6: Pull-only tail (Server Islands)** | No JS = permanent skeleton placeholders. AI crawlers (GPTBot, ClaudeBot, PerplexityBot) do not render JS at all. |
| SSE replacing HTML stream               | Bots request `text/html`; SSE returns `text/event-stream` — no renderable content                                |
| WebSocket replacing HTML                | Bots do not perform WebSocket protocol upgrade                                                                   |
| Turbo Frames / htmx lazy fragments      | Without JS, lazy fragments never fetch; permanent empty placeholders                                             |
| Range request after `window.stop()`     | Requires `window.stop()` (same problem); also incompatible with chunked transfer                                 |
| H2 multiplexed without stream           | If sections are ONLY in separate responses, bots see only the shell                                              |

#### Fails both constraints

| Approach           | Why                                                                                    |
| ------------------ | -------------------------------------------------------------------------------------- |
| HTTP/2 Server Push | Removed from Chrome 106 (Sep 2022), Firefox, Safari. RFC 9113 recommends against it.   |
| iframe sections    | Breaks React selective hydration across document boundaries; bot indexing inconsistent |

#### Mechanism does not exist

| Approach                                | Why                                                                                                                                                                        |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Non-Cloudflare edge state coordination  | Verified against Fastly Compute, Lambda@Edge, CloudFront Functions, Akamai EdgeWorkers, Deno Deploy, Vercel Edge Functions — none provide cross-request state coordination |
| Native CDN priority signaling           | No CDN offers client-to-edge priority signals for in-flight streaming responses                                                                                            |
| Client-side Suspense resolution control | No React API exists for client-side control of which boundary resolves next                                                                                                |

#### Not applicable (does not address delivery priority)

| Approach                                         | Why irrelevant                                                                             |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------ |
| Cache API / localStorage                         | Empty on first visit                                                                       |
| Preload link headers                             | Server cannot predict scroll target; preloading ALL sections defeats progressive streaming |
| Speculation Rules                                | Prefetches future navigations, not current page sections                                   |
| `content-visibility: auto`                       | Rendering optimization — cannot make bytes arrive faster                                   |
| MutationObserver                                 | Reacts to DOM arrivals; cannot accelerate network delivery                                 |
| `scheduler.postTask`                             | Processing priority, not delivery priority                                                 |
| 103 Early Hints                                  | Flows server→client before the response; scroll priority flows client→server mid-response  |
| React 19.2 batched reveals                       | Visual smoothness (300ms batch); no priority control                                       |
| `startTransition` / `useDeferredValue`           | Rendering priority, not delivery priority                                                  |
| External runtime (`unstable_externalRuntimeSrc`) | CSP optimization; does not affect delivery order                                           |

---

## 3. How Service Workers Control HTML Chunks (and Why It Still Fails)

A deep technical investigation (9 agents, 489K tokens) established the precise mechanism by which a SW can control streamed HTML — and why it ultimately fails the constraints.

### What the SW Can Do (on subsequent visits)

The SW sits between the network and the HTML parser:

```
Server → Network Stack → [SW TransformStream] → HTML Parser → DOM
```

- **The SW sees decompressed `Uint8Array` chunks.** Gzip/brotli decompression, HTTP chunked framing, and H2 DATA frame reassembly all happen before bytes reach the SW.
- **The SW can pass, hold, transform, discard, or inject additional bytes** on each chunk via the `TransformStream` API.
- **Chunk boundaries are meaningless** — they do not correspond to HTML structure. Patterns can split across chunks. String matching requires a 64-byte overlap buffer.
- **The correct architecture is section-boundary buffering** — only forward complete sections; abort at clean boundaries, never mid-section.

### Why Mid-Section Abort Is Fatal

If the SW forwards `<div hidden id="S:4">partial content` and injects `<div hidden id="S:7">...` without closing S:4, the parser nests S:7 inside the unclosed S:4. React's `$RC("B:4","S:4")` then swallows S:7 when it moves S:4's children, making S:7 unreachable. Injecting `</div>` doesn't reliably close S:4 because the parser's stack of open elements may include nested `<div>`, `<table>`, `<select>` scope boundaries.

### Why It Fails Anyway

Even with correct clean-cut section buffering, the SW approach fails C1-FIRST:

1. **First visit:** SW doesn't exist. Navigation response goes directly to parser. All sections stream normally with no acceleration. The SW registers during this first load.
2. **The in-flight stream cannot be intercepted.** When the SW activates mid-page-load (even with `clients.claim()`), it controls future `fetch()` calls but NOT the already-streaming navigation response. The remaining 7 sections flow from network to parser untouched.
3. **35-75% of traffic is uncontrolled** (first visits + cache eviction + hard refresh + private browsing).

Browser lifetime constraints add further risk even on controlled visits:

- Safari: 10s idle timeout (`defaultTerminationDelay = 10_s`, WebKit changeset 291467)
- Firefox: 30s idle + 30s grace (Bug 1588838)
- Chrome: 30s idle + 5min hard cap per event
- `respondWith()` settles immediately — the SW becomes "idle" while the stream body is consumed (W3C issue #882, unfixed for 10 years)

---

## 4. Surviving Approaches (Ranked)

Five architectures pass both C1-FIRST and C2-BOT. They decompose into four fundamental mechanisms.

### Rank 1: C4 — Client Fetch + `$RC` While Stream Continues

**Status:** Already built and working (`?mode=fetch`).

IntersectionObserver detects scroll to a skeleton → `fetch()` pulls the cached section file → `DOMParser` + `adoptNode` + `$RC()` reveals it immediately → stream continues delivering all sections for bots. `$RC` idempotency handles the duplicate harmlessly.

```javascript
// Already in selective_hydration_scroll_demo.js lines 243-279
function fetchAndRevealSection(index) {
  fetch('/cache/selective_hydration_demo/section' + index + '.html')
    .then(function (r) {
      return r.text();
    })
    .then(function (html) {
      // Stream may have delivered while fetch was in-flight
      if (!document.getElementById(rcPairs[0][0])) return; // stream won
      var doc = new DOMParser().parseFromString(html, 'text/html');
      var divs = doc.querySelectorAll('div[hidden][id]');
      for (var i = 0; i < divs.length; i++) document.body.appendChild(document.adoptNode(divs[i]));
      rcPairs.forEach(function (pair) {
        window.$RC(pair[0], pair[1]);
      });
    });
}
```

| Property            | Value                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------- |
| First visit         | ✅ Yes — no SW, no prior state needed                                                 |
| Bot safe            | ✅ Yes — stream delivers all sections regardless                                      |
| Duplicate bandwidth | 21-35KB (5KB/section × 7 sections fetched). Harmless — `$RC` no-ops on the duplicate. |
| Server changes      | None                                                                                  |
| CDN compatible      | ✅ Any CDN or no CDN                                                                  |
| React upgrade risk  | Low — depends on `$RC` internal, but stream fallback provides graceful degradation    |
| Key tradeoff        | Duplicate bytes. The stream re-delivers every section the client already fetched.     |

**Recommended improvements to the existing prototype:**

1. Lower IntersectionObserver threshold with `rootMargin: '0px 0px 200px 0px'` (prefetch 200px before visible)
2. `AbortController` per fetch — abort in-flight fetch if stream delivers first; abort all in `pagehide` for bfcache
3. Prefetch N+1 when section N becomes visible (via `requestIdleCallback`)
4. `fetchpriority: 'high'` on scroll-targeted section fetches

### Rank 2: C4 + Origin Skip-Delay Signal (Both Already Built)

**Status:** Both modes exist; composing them is ~3 lines of client code.

Same as Rank 1, but also POSTs a priority signal (`/selective_hydration_skip_delay/:stream_id?section=7`) so the server releases the section on the stream sooner. Whichever path wins reveals the section; `$RC` idempotency handles the other.

| Property            | Value                                                                         |
| ------------------- | ----------------------------------------------------------------------------- |
| Duplicate bandwidth | Reduced (server sends the section sooner, shrinking the duplicate window)     |
| Server changes      | None (both paths already built)                                               |
| CDN compatible      | Partial — skip signal requires origin to hold the stream                      |
| Delta from Rank 1   | ~3 lines: fire both `fetchAndRevealSection()` and `signalSection()` on scroll |

### Rank 3: C4 + Server-Side Section Skipping (Zero-Duplicate Hybrid)

**Status:** Not yet built. ~40 lines delta from existing prototype.

Client fetches priority section, reveals via `$RC`, then confirms receipt via POST. Server checks the flag and **skips** that section in the stream. Bot safety: bots never POST, so the server sends everything.

```
User scrolls to section 7:
  → Client fetch('/cache/.../section7.html'), reveal via $RC     (instant)
  → Client POST /received/:stream_id?section=7                  (confirm)
  → Server: "client has 7, skip it in the stream"               (zero dup)

Bot visits:
  → No POST ever arrives
  → Server timeout: send section anyway after 10 seconds         (bot-safe)
```

```ruby
# Server: two-phase delivery with bot-timeout fallback
def should_send_section?(stream_id, index, section_queued_at)
  client_confirmed?(stream_id, index) ||
    (monotonic_now - section_queued_at) > BOT_TIMEOUT_SECONDS
end
```

```javascript
// Client: confirm receipt after successful reveal
function confirmSectionReceived(streamId, index) {
  fetch('/selective_hydration_received/' + streamId + '?section=' + index, {
    method: 'POST',
    keepalive: true,
  });
}
```

| Property            | Value                                                                                                        |
| ------------------- | ------------------------------------------------------------------------------------------------------------ |
| Duplicate bandwidth | **Zero**                                                                                                     |
| Server changes      | Minor — new endpoint + flag check in delivery loop (~30 lines server, ~10 lines client)                      |
| CDN compatible      | **Partial** — fetch path uses CDN for section files; skip signal requires origin to hold the stream          |
| Bot safe            | ✅ — bot-timeout fallback (send after 10s if no confirmation) ensures all content is delivered               |
| Key tradeoff        | Origin must hold the stream (Puma thread). Not viable if sections are CDN-served with no origin involvement. |

**The fundamental tension applies:** This achieves zero duplicates by having the origin hold per-request state (which section the client confirmed). A pure CDN static replay cannot do this.

### Rank 4: Cloudflare Durable Object

**Status:** Not built. 2-3 weeks effort. Requires new infrastructure.

A DO at the edge holds the streaming response, reads cached sections from R2, and implements `Promise.race([sleep(delay), skipSignal])`. The client's priority POST routes to the same DO instance.

| Property            | Value                                                                                                                                                                                |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Duplicate bandwidth | Zero                                                                                                                                                                                 |
| Server changes      | Significant — Worker + DO + R2 + wrangler.toml                                                                                                                                       |
| CDN compatible      | ✅ (it IS the CDN) — **Cloudflare only**                                                                                                                                             |
| Hosting cost        | **~$47-94/mo per 1M views** (DO duration billing, cannot hibernate during streaming)                                                                                                 |
| Key tradeoff        | Hard vendor lock-in. Verified: no other edge platform can replicate this (Fastly, Lambda@Edge, Akamai EdgeWorkers, Deno Deploy, Vercel — all lack cross-request state coordination). |

### Rank 5: React PPR Single-Response Variant

**Status:** Blocked on React. `React.postpone()` still `unstable_`. 21-31 days effort when unblocked.

`prerenderToNodeStream` produces shell + postponed state → `resumeToPipeableStream` on the same HTTP response. Scroll priority controls which section's data resolves first during resume (data-resolution order = emission order, confirmed).

| Property            | Value                                                                                  |
| ------------------- | -------------------------------------------------------------------------------------- |
| Duplicate bandwidth | Zero                                                                                   |
| Server changes      | Significant — 6+ files, PostponedStateStore, new renderer endpoints                    |
| CDN compatible      | Partial — single-response variant streams from origin; loses the CDN-caching advantage |
| React upgrade risk  | **High** — `unstable_postpone()`, opaque version-specific postponed state              |
| Key tradeoff        | Framework-sanctioned long-term path, but premature to build on unstable APIs.          |

---

## 5. Re-Derived Comparison Matrix

### 5.1 Bytes on Wire (target: page size × 1.0)

| Candidate  | Verdict                      | Evidence                                                                                         |
| ---------- | ---------------------------- | ------------------------------------------------------------------------------------------------ |
| C1 (DO)    | ✅ PASS                      | Skip signal stops delivery of that section. Zero duplication.                                    |
| C2 (SW)    | ✅ PASS (but fails C1-FIRST) | SW aborts upstream + pulls missing. Zero duplication when SW is active.                          |
| C3 (stop)  | ✅ PASS (but fails C2-BOT)   | Stream killed; sections pulled individually.                                                     |
| C4 (fetch) | ✗ PARTIAL                    | Stream re-delivers fetched sections. ~21-35KB duplicate for 7 sections. `$RC` no-ops harmlessly. |
| C5 (PPR)   | ✅ PASS                      | React manages delivery — no overlap by design.                                                   |
| C6 (pull)  | ✅ PASS (but fails C2-BOT)   | Shell only on stream; sections fetched.                                                          |

### 5.2 CDN Portability

| Candidate | Verdict   | Evidence                                                                                                                                                                                                            |
| --------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1        | ✗ FAIL    | Cloudflare only. Verified: no equivalent on Fastly (no cross-request state), Lambda@Edge (5-30s timeout), Akamai EdgeWorkers (10-20ms CPU budget), Deno Deploy (no actor guarantee), Vercel Edge (no coordination). |
| C2        | ✅ PASS   | CDN-agnostic — SW runs in browser, section files are static.                                                                                                                                                        |
| C3        | ✅ PASS   | No CDN requirements.                                                                                                                                                                                                |
| C4        | ✅ PASS   | Section files are static assets at known URLs. Any CDN.                                                                                                                                                             |
| C5        | ◐ PARTIAL | Prelude CDN-cacheable. Resume requires origin compute. Only Vercel implements resume protocol.                                                                                                                      |
| C6        | ✅ PASS   | Simplest CDN story — chunk 0 is static; sections are static.                                                                                                                                                        |

### 5.3 React Upgrade Safety

| Candidate | Verdict        | Evidence                                                                                                                                  |
| --------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| C1        | ✅ PASS        | Replays cached HTML bytes verbatim. Never calls React APIs.                                                                               |
| C2        | ✅ PASS        | Pipes bytes through TransformStream without interpreting React internals.                                                                 |
| C3        | ✗ FAIL         | Calls `$RC` directly. 3 major rewrites 2024-2026: initial Fizz, errorDigest removal, `$RB`/`$RV`/`$RT` batching (React 19.2).             |
| C4        | ◐ PARTIAL      | Calls `$RC` directly BUT stream continues as fallback. If `$RC` breaks, sections arrive via stream. Graceful degradation, not hard break. |
| C5        | ✅ PASS (best) | Uses stable React APIs (`prerenderToNodeStream`, `resumeToPipeableStream`).                                                               |
| C6        | ✗ FAIL         | Same `$RC` dependency as C3 but WITHOUT stream fallback.                                                                                  |

### 5.4 First Visit + Bot Safety (the hard filter)

| Candidate  | C1-FIRST | C2-BOT | Survives              |
| ---------- | -------- | ------ | --------------------- |
| C1 (DO)    | ✅       | ✅     | ✅ (but hosting cost) |
| C2 (SW)    | ✗        | ✅     | ✗                     |
| C3 (stop)  | ✅       | ✗      | ✗                     |
| C4 (fetch) | ✅       | ✅     | ✅                    |
| C5 (PPR)   | ✅       | ✅     | ✅ (blocked on React) |
| C6 (pull)  | ✅       | ✗      | ✗                     |

### 5.5 Additional Criteria

| Criterion                     | C4 (recommended)                                                                                                                                                                                    |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Strict CSP                    | ✅ — `fetchAndRevealSection` uses DOM manipulation, never executes fetched scripts. Existing comment: "We NEVER execute the fetched scripts (their cached CSP nonces are stale anyway)" (line 257). |
| RSC compatibility             | ✅ — Stream continues; `injectRSCPayload` pipeline delivers payload normally. Fetched sections' stale RSC payload scripts are harmless duplicates.                                                  |
| Store hydration               | ✅ — Stores in chunk 0 (shell), initialized before scroll triggers. Guard in `initializeStore` prevents re-initialization.                                                                          |
| SEO                           | ✅ — Stream delivers all content. Fetch path invisible to crawlers.                                                                                                                                 |
| bfcache                       | ✅ with mitigation — abort outstanding fetches in `pagehide` handler.                                                                                                                               |
| Scenario B (origin rendering) | ✅ — Complementary to skip-delay POST. Server releases section sooner, reducing duplicate window.                                                                                                   |

---

## 6. Open Questions Closed

All 10 `?` cells from the design doc matrix resolved with primary sources:

| Question                           | Answer                                                                                                                                            | Source                                                                       |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| KV propagation delay               | Still 30-60s. Minimum `cacheTtl` reduced to 30s (Jan 2026). Unsuitable for signaling.                                                             | developers.cloudflare.com/kv/concepts/how-kv-works/                          |
| DO hibernation during streaming    | Impossible. Active request/event processing violates condition #4.                                                                                | developers.cloudflare.com/durable-objects/concepts/durable-object-lifecycle/ |
| Safari SW lifetime                 | 10s idle (`defaultTerminationDelay = 10_s`). Safari 18.5 fixed premature interruption.                                                            | WebKit changeset 291467                                                      |
| `respondWith()` keep-alive         | No. Promise settles immediately; SW becomes idle while stream consumed. `waitForBody` proposal still open after 10 years.                         | W3C ServiceWorker issue #882                                                 |
| H2 `RST_STREAM` on abort           | Yes. Chromium: `AbortController.abort()` → `SpdySession::ResetStream()` → RST_STREAM CANCEL.                                                      | Chromium source                                                              |
| CDN abort propagation              | Unreliable. Cloudflare `request.signal` has active regression (workerd#6832). CloudFront/Fastly docs don't address viewer disconnect propagation. | github.com/cloudflare/workerd/issues/6832                                    |
| React `prerender`/`resume` stable? | Yes in 19.2.7. Verified exports: `prerenderToNodeStream`, `resumeToPipeableStream`. `React.postpone()` still `unstable_`.                         | react-dom@19.2.7 static.node.js lines 10-14, server.node.js lines 17-18      |
| Boundary emission order            | Data-resolution order. Whichever boundary's data resolves first streams first. `$RC` uses `getElementById` for placement.                         | React Fizz source, confirmed in selective hydration demo                     |
| `$RC` stability                    | Unstable. 3 major rewrites 2024-2026. Current body uses `$RB`/`$RV`/`$RT` batching.                                                               | react-dom@19.2.7 production build line 2477                                  |
| Postponed state cross-process      | Works by design. React docs: load from "redis, a file, or S3." `react-ppr-from-scratch` demonstrates it.                                          | react.dev/reference/react-dom/static/prerender                               |

---

## 7. Cross-Cutting Resolutions

### 7.1 CSP Strategy

C4's fetch path uses DOM manipulation (`DOMParser` + `adoptNode` + direct `$RC()` call) — no script execution from fetched content. CSP is not involved. The stream's inline scripts use the `nonce` option on `renderToPipeableStream` (line 287 of `streamServerRenderedReactComponent.ts`).

Hash-based CSP is impractical: React's `$RC` calls contain per-render boundary IDs, making each script unique. `strict-dynamic` does not help for inline scripts without a nonce (W3C CSP issue #426).

### 7.2 `$RC` Stability and Mitigation

`$RC` has been rewritten 3 times (initial Fizz, errorDigest removal, `$RB`/`$RV`/`$RT` batching). The wire format (`B:N`, `S:N` IDs, `<template>` boundaries, `<div hidden>` content) is stable across 18.3.1-19.2.7. The function body is not.

Mitigation for C4: the stream always delivers content as fallback. If `$RC` breaks on React 20.x, the fetch path silently fails and sections arrive via stream on their normal timer. Loss of acceleration, not a break.

Additional mitigation: abstract `$RC` behind a version-detecting wrapper that checks for `window.$RC` existence and `$RB` array, with fallback to manual DOM manipulation.

### 7.3 SEO

C4 is inherently SEO-safe: the stream delivers ALL content in the HTML response. The fetch path is purely additive and invisible to crawlers. AI crawlers (GPTBot, ClaudeBot, PerplexityBot) do not render JS at all (Vercel confirmed across 1B+ monthly bot requests). Googlebot's render phase may take hours/days after initial crawl. All SEO-critical content is in the synchronous SSR output.

### 7.4 bfcache

C4 is bfcache-compatible with an `AbortController` `pagehide` cleanup pattern. The page load completes normally (`readyState` reaches `'complete'`). Outstanding `fetch()` calls are aborted in `pagehide` to avoid the `OutstandingNetworkRequestFetch` blocking reason (Chrome 123+).

---

## 8. Recommendation

### The Optimal Layered Architecture

```
Scenario A — CDN-cached static replay (no origin involvement):
  Layer 1 only: C4 fetch + $RC, stream delivers all for bots
  Accept 21-35KB duplicate. It's negligible on HTTP/2.

Scenario B — Origin holds the stream:
  Layer 1 + Layer 3: C4 fetch + server-side section skipping
  Zero duplicate bandwidth
  Bot-timeout fallback ensures crawlers get everything
  Requires Puma thread per stream

Cloudflare-specific deployment:
  Layer 1 + Cloudflare DO (replaces Layer 3 at the edge)
  Zero duplicates, CDN-level TTFB
  ~$47-94/mo per 1M views

Long-term (2027+, when React APIs stabilize):
  React PPR single-response variant
```

### Layer 1: Ship Now — C4 Productionization

| Work Item                                                  | Effort        | Ongoing Maintenance             |
| ---------------------------------------------------------- | ------------- | ------------------------------- |
| Extract `fetchAndRevealSection` into Pro module            | 2-3 days      | Low                             |
| `AbortController` management + `pagehide` cleanup          | 1 day         | None                            |
| `$RC` version detection wrapper                            | 1-2 days      | Medium (verify per React minor) |
| `fetchpriority` + rootMargin + N+1 prefetch                | 0.5 days      | None                            |
| Section file URL convention + documentation                | 1 day         | Low                             |
| Integration tests (duplicate handling, abort, degradation) | 2-3 days      | Medium                          |
| **Total**                                                  | **7-10 days** | **Low-Medium**                  |

### Layer 2: Ship in Parallel — Skip-Delay Hardening

| Work Item                                                 | Effort       | Ongoing Maintenance |
| --------------------------------------------------------- | ------------ | ------------------- |
| Replace filesystem markers with in-memory/Redis signaling | 1-2 days     | Low                 |
| Add skip-signal metrics (latency, hit rate)               | 1 day        | Low                 |
| **Total**                                                 | **2-3 days** | **Low**             |

### Layer 3: When Origin Holds Stream — Section Skipping

| Work Item                                        | Effort       | Ongoing Maintenance |
| ------------------------------------------------ | ------------ | ------------------- |
| New `/received/:stream_id` endpoint              | 0.5 days     | Low                 |
| Flag check + bot-timeout in delivery loop        | 0.5 days     | Low                 |
| Client-side confirmation POST after reveal       | 0.5 days     | Low                 |
| Integration tests (race conditions, bot-timeout) | 1 day        | Low                 |
| **Total**                                        | **2.5 days** | **Low**             |

### Layer 4: Defer — React PPR

| Work Item                                  | Effort         | Ongoing Maintenance |
| ------------------------------------------ | -------------- | ------------------- |
| `streamServerRenderedReactComponentPPR.ts` | 5-8 days       | High                |
| `injectRSCPayload.ts` two-phase support    | 3-5 days       | High                |
| PostponedStateStore + renderer endpoints   | 5-7 days       | Medium              |
| `stream.rb` + Rails routes                 | 3 days         | Medium              |
| Integration tests                          | 5-7 days       | High                |
| **Total**                                  | **21-31 days** | **High**            |

**Trigger conditions for Layer 4:**

1. `React.postpone()` drops `unstable_` prefix
2. `unstable_externalRuntimeSrc` stabilizes
3. A second CDN besides Vercel implements the resume protocol
4. `injectRSCPayload.ts` / `RSCRequestTracker` lifecycle understood for two-phase renders

### Drop

- **C2 (Service Worker):** Fails first-visit constraint. Browser lifetime constraints add further risk. Revisit only if W3C issue #882 ships `waitForBody`.
- **C3 (`window.stop()`):** Fails bot-safety constraint. Unacceptable side effects.
- **C6 (Server Islands):** Fails bot-safety constraint.
- **C1 (Cloudflare DO):** Document as a recipe for CF-specific deployments. Do not build into the framework.

---

## 9. Prototype Plan

### Phase 0: C4 Productionization (Week 1-2)

**P0:** Extract `fetchAndRevealSection` into `packages/react-on-rails-pro/src/scrollPriorityFetch.ts`.
Pass/fail: Module imports cleanly, TypeScript compiles, existing demo works.

**P1:** `$RC` version detection wrapper — checks `window.$RC`, `$RB` array, falls back to manual DOM manipulation.
Pass/fail: Works on react-dom@19.2.7 AND simulated future where `$RC` is renamed.

**P2:** `AbortController` + `pagehide` lifecycle.
Pass/fail: `notRestoredReasons` API does NOT report `OutstandingNetworkRequestFetch` after navigation.

**P3:** Duplicate handling verification — section arrives via both stream and fetch.
Pass/fail: `section.duplicates` counter increments, no visual glitch, no hydration mismatch.

### Phase 1: Integration Testing (Week 2-3)

**P4:** React version matrix — test against react-dom@18.3.1, @19.0.0, @19.2.7.
Pass/fail: Sections reveal correctly on all versions; graceful degradation on simulated `$RC` removal.

**P5:** bfcache verification — Playwright: load, scroll, navigate away, navigate back.
Pass/fail: `performance.getEntriesByType('navigation')[0].type === 'back_forward'`.

**P6:** CSP verification — strict `script-src 'self' 'nonce-<fresh>'`.
Pass/fail: Zero CSP violations, all sections reveal via fetch path.

### Phase 2: Performance Baseline (Week 3)

**P7:** Measure scroll-to-visible latency. Compare: stream-only vs C4 fetch vs C4+skip-delay.
Pass/fail: C4 measurably faster for sections 5+ (below fold).

**P8:** Measure duplicate bandwidth overhead.
Pass/fail: Duplicate overhead <20% of total page weight.

---

## 10. Sources

### Verified Against Primary Source Code

| Source                                                     | Category        | Verified How                                 |
| ---------------------------------------------------------- | --------------- | -------------------------------------------- |
| react-dom@19.2.7 `static.node.js` exports                  | React API       | Read lines 10-14 in node_modules             |
| react-dom@19.2.7 `server.node.js` exports                  | React API       | Read lines 17-18 in node_modules             |
| `unstable_externalRuntimeSrc` in rendering pipeline        | React internals | 20 occurrences in production server build    |
| `$RC` function body with `$RB`/`$RV`/`$RT`                 | React internals | Line 2477 of production build                |
| `data-rci`/`data-rri`/`data-rsi`/`data-rxi` attributes     | React internals | Lines 2474-2506 of production build          |
| W3C ServiceWorker issue #882 (waitForBody)                 | SW spec         | Open, Version 2 milestone                    |
| Firefox SW 30s+30s budget                                  | Browser         | Bug 1588838, libpref/init/all.js             |
| Safari `defaultTerminationDelay = 10_s`                    | Browser         | WebKit changeset 291467                      |
| Chromium 5min per-event hard cap                           | Browser         | service_worker_version.cc                    |
| StreamSaver.js heartbeat = 10s (not 29s)                   | Library         | mitm.html source                             |
| Cloudflare KV propagation 30-60s                           | CDN             | developers.cloudflare.com/kv                 |
| DO cannot hibernate during streaming                       | CDN             | Condition #4: active request processing      |
| CDN abort propagation unreliable                           | CDN             | workerd#6832, docs gaps on CloudFront/Fastly |
| `streamServerRenderedReactComponent.ts` options            | Codebase        | Lines 194, 287                               |
| `selective_hydration_scroll_demo.js` fetchAndRevealSection | Codebase        | Lines 243-279                                |
| SW mid-section abort causes parser state corruption        | HTML spec       | Section 13.2.6.4.7 (stack of open elements)  |
| SW sees decompressed bytes (not wire bytes)                | Fetch spec      | whatwg/fetch#1729                            |
| Chunk boundaries do not match HTML structure               | Fetch spec      | whatwg/fetch#330                             |

### Accepted From Official Documentation

| Source                               | Category  | URL                                                               |
| ------------------------------------ | --------- | ----------------------------------------------------------------- |
| Safari 18.5 SW interruption fix      | Browser   | webkit.org/blog/16923/                                            |
| Chrome 149 WebSocket bfcache         | Browser   | developer.chrome.com/release-notes/149                            |
| Chrome notRestoredReasons API        | Browser   | developer.chrome.com/docs/web-platform/bfcache-notrestoredreasons |
| Next.js PPR Platform Guide           | Framework | nextjs.org/docs/app/guides/ppr-platform-guide                     |
| AI crawlers don't render JS (Vercel) | SEO       | asklantern.com                                                    |
| RFC 9218 (HTTP Priority)             | Standards | datatracker.ietf.org/doc/html/rfc9218                             |
| RFC 9110 Section 14 (Range)          | Standards | datatracker.ietf.org/doc/html/rfc9110                             |
| react-ppr-from-scratch               | Demo      | github.com/shakacode/react-ppr-from-scratch                       |
| H2 Server Push removed Chrome 106    | Browser   | chromestatus.com/feature/6302414934114304                         |

### Community-Reported

| Claim                                     | Source                  | Risk   |
| ----------------------------------------- | ----------------------- | ------ |
| DO cross-colo latency 10-30ms             | Cloudflare Queues study | Low    |
| Googlebot rendering budget ~5s            | Community consensus     | Medium |
| 92% of ChatGPT Search uses Bing index     | prerender.io            | Low    |
| CloudFront drains origin after disconnect | Inferred from docs      | Medium |
