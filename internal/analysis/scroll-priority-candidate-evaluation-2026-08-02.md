# Scroll-Priority Streaming: Independent Candidate Evaluation

**Issue:** #4835 (evaluation) → parent #4385, design doc #4769
**Date:** 2026-08-02
**Evaluator:** Independent re-derivation against the design doc's analysis, verified claims, and current React on Rails codebase

---

## 1. Executive Summary

The design doc (#4769) proposes a layered architecture:

- **Layer 0:** Manifest + byte-stable addressable sections (foundation)
- **Layer 1:** Service Worker stream-stitching (C2) as default transport
- **Layer 2:** React `prerender`/`resume` (C5) for Scenario B (origin still rendering)

**This evaluation's verdict: the layered recommendation is sound, but the payoff does not justify the complexity at this point.** The recommendation is **conditionally viable** — proceed with Layer 0 (the manifest, which has independent value) and P0/P1/P6 as low-risk validation, but defer Layers 1–2 until measured demand or CDN-served pages become a concrete product requirement.

The reasoning follows.

---

## 2. Re-Derived Comparison

### 2.1 What the evaluation confirmed

The design doc's comparison matrix is **accurate in every cell I could independently verify.** Specific confirmations:

1. **$RC idempotency (Fact 1, 8):** Confirmed. The react-dom@19.2.7 production build (installed in the Pro dummy app) contains the `$RB`/`$RV` batching pathway described in Facts 7–10. The wire format (`$RC("<id>B:n","<id>S:n")`) is stable from 18.3.1 through 19.2.7. The body was rewritten between 18.3.1 and 19.2.x exactly as described — reveals are now async with ~300ms batching.

2. **`prerender`/`resume` exports:** Confirmed against react-dom@19.2.7 in the dummy app:
   - `react-dom/static` exports: `prerenderToNodeStream`, `prerender`, `resumeAndPrerenderToNodeStream`, `resumeAndPrerender`
   - `react-dom/server` exports: `resumeToPipeableStream`, `resume`

   These are on the **stable channel**, not experimental. The APIs exist and are usable without a custom React build.

3. **`unstable_externalRuntimeSrc`:** Confirmed present in `react-dom-server.node.production.js` (19.2.7) — 20 references to `externalRuntime`/`externalRuntimeConfig`. The option works but retains the `unstable_` prefix — it has **not** been stabilized as of 19.2.7. The runtime file itself ships only in `react-dom@experimental` builds and must be vendored.

4. **ShakaCode's own `react-ppr-from-scratch` repo** demonstrates `prerender`/`resume` outside Next.js, providing a reference implementation. However, that repo's README states it requires experimental React APIs (`unstable_postpone`), which conflicts with the design doc's claim that `prerender`/`resume` compose on stable. **The distinction:** `prerender` + `resume` are stable exports; `React.postpone()` (the explicit component-level API to mark a component as postponed) is still experimental-only. The abort-based mechanism (abort the prerender to produce `postponed` state) uses only stable APIs. This is correct as described in Fact 11.

5. **Integration seam:** `streamServerRenderedReactComponent.ts` calls `renderToPipeableStream` with `{ nonce, onShellError, onShellReady, onError }` — no passthrough for `unstable_externalRuntimeSrc` or other streaming options. A small plumbing change would be needed, exactly as the design doc states.

### 2.2 What the evaluation disputes or adds nuance to

**C1 cross-colo latency (the `?` cell):** Research confirms the design doc's qualitative characterization but adds quantitative data:

- Community reports show worker-to-DO latency consistently **≥120ms**, regardless of DO creation strategy. Not every Cloudflare datacenter hosts DOs — the DO may be in a different datacenter than the worker.
- Cloudflare Queues (built on DOs) show **~60ms p50** write latency after optimization.
- For the scroll-priority use case, the relevant latency is "POST arrives at colo A → forwarded to DO in colo B → DO signals the streaming connection held in colo B." If both the navigation and the POST originate from the same user (same browser, seconds apart), colo affinity is very likely — the latency concern is real but **not the common case**. The worst case is a CDN that anycast-routes the POST to a different PoP than the navigation; this adds one cross-colo RTT (~20–100ms depending on distance).
- **Assessment:** C1's latency story is "usually fine, occasionally 100–200ms slower" — acceptable for acceleration that's already optional, but worse than C2 (which is local by construction).

**C2 Service Worker lifetime (the `?` cell):**

- Firefox: **30s idle + 30s grace** confirmed. The heartbeat mitigation (StreamSaver-style, ~29s ping) is production-proven.
- Chromium: The "5-minute" termination figure is **confirmed MV3-extension-only**. For web SWs, Chromium terminates after **30s of inactivity** (no events) but extends lifetime when events are pending. A streaming `respondWith` keeps the fetch event outstanding. The 5-minute hard cap applies to the overall event handler, which bounds our use case to pages that stream for <5 minutes — fine for realistic page loads. **New finding:** community reports indicate Chromium may terminate SWs with pending network requests, which is described as "inherently broken" behavior.
- Safari: **Safari 18.5** (released 2025) fixed "Service Worker downloads being prematurely interrupted" — directly relevant. Safari 26.6 (July 2026) fixed additional SW registration lifetime bugs. The lifetime policy for SW-held streaming responses is not precisely documented but recent fixes suggest Apple is aware of and fixing these issues.
- **Assessment:** The SW lifetime gap is real but narrower than the design doc's cautious characterization. With the heartbeat + `waitUntil`, it's a solvable engineering problem, not a design-level blocker. The truncation recovery path handles the true failure case.

**C3/C4 bfcache interaction (the `?` cell):**

- The design doc correctly identifies that both bfcache claims (blocking and not-blocking) were refuted during verification.
- New information: Chrome 123+ provides `notRestoredReasons` API for debugging. Whether a streaming navigation body or an outstanding fetch blocks bfcache is **still empirically unknown** and must be measured (P7). Recent movement (June 2026) on bfcache compatibility (WebSocket pages may now enter bfcache) suggests the spec is trending toward fewer blockers, not more.
- **Assessment:** This remains an unknown. It affects all candidates equally (the normal streamed path already has the same bfcache interaction), so it's not a differentiator.

**C5 resume outside Next.js (the `?` cell):**

- ShakaCode's `react-ppr-from-scratch` repo is the strongest evidence that this works. The APIs are stable exports.
- The design doc's P6 (standalone spike) is correctly identified as the gate. The key question is whether boundary emission order in a `resume` stream follows data-resolution order — this is untested.
- **Assessment:** Conditionally viable. P6 is the right gate, and it's a bounded experiment.

### 2.3 What the matrix asserts rather than verifies

| Cell                                                                       | Status                                                                   |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| CDN edge egress behavior on client abort (affects C2, C3)                  | Asserted. P4 is the correct experiment.                                  |
| Range-on-cached-asset per CDN (affects the Range optimization variant)     | Asserted. Standard for static files but needs CDN-specific verification. |
| External runtime instruction attributes (`data-rci`/`data-bid`/`data-sid`) | Verified present in the 19.2.7 production build (checked).               |
| C2 truncation recovery with byte cursor                                    | Designed but untested. P2 is the correct experiment.                     |

---

## 3. Candidate Verdicts

### C1 — Edge-Held State (Cloudflare Durable Object)

**Conditionally viable (Cloudflare-committed deployments only).**

Pros:

- Zero duplicate bytes by construction
- Conceptually simple — the server-side skip mechanism (already working in the prototype) moved to the edge
- Streaming from a DO is first-class
- Costs ~$0.00009 per 60s page view beyond free tier

Cons:

- **Vendor lock-in:** Cloudflare only. No equivalent on CloudFront, Fastly, Akamai, or Vercel Edge with the same coordination primitive. Lambda@Edge is 15-minute timeout, not streaming-native. Fastly Compute has no per-request durable state.
- **Cross-colo latency:** ≥120ms worker-to-DO in the worst case; same-colo is likely but not guaranteed
- **Billing complexity:** Wall-clock duration billing while the DO is active; a 60s paced stream costs per view
- **Not needed for the default recommendation:** C2 covers Scenario A without vendor state

**React on Rails fit:** Poor as a default. React on Rails targets deployment flexibility — lock-in to Cloudflare contradicts this. Fine as a documented alternative.

### C2 — Service Worker Stream-Stitching

**Viable, with known engineering work.**

Pros:

- Works against any CDN or static host (dumb static files are sufficient)
- Zero duplicate bytes (abort + pull-missing)
- React's own runtime executes reveals — zero internals dependence
- Browser APIs only; no server/edge infrastructure required
- Graceful degradation: no SW → plain streamed page (requirement 5)

Cons:

- **First-visit gap:** No controller on first navigation. Plain streaming (no acceleration) is the default. C4 as opt-in first-visit accelerator is an option.
- **SW lifecycle complexity:** Heartbeat required for Firefox; truncation recovery for unexpected death; byte-cursor persistence
- **~300–500 lines of SW code** to maintain
- **The CDN abort behavior is unverified** (P4) — if CDNs keep draining origin connections after abort, Scenario B degrades (wasted origin work, not UX)
- Chromium's streaming `respondWith` lifetime has community-reported issues

**React on Rails fit:** Good. The SW is pure client-side code — ships alongside `selective_hydration_scroll_demo.js` or as a Pro-provided utility. No node renderer or rails engine changes required for Layer 1 alone. The manifest generation extends the existing `section_cache.rake`.

### C3 — Gated `window.stop()` + Client Pull

**Ruled out for production.**

The design doc's rejection is correct and I agree:

- `window.stop()` aborts ALL in-flight subresource loads, not just the navigation stream
- `readyState` stuck at `interactive` forever
- Unknown bfcache interaction
- Requires manual `$RC` invocation (or external runtime), adding internals dependence
- The "resource-level readiness gate" (waiting for all resources to load before calling stop) is fragile — any late-loading resource (lazy image, analytics) delays the gate

**The only case for C3:** As a measurement baseline in P7 (bfcache) to establish the simplest possible zero-duplication behavior. Not for production deployment.

### C4 — No-Stop Client Pull

**Viable as a baseline and recovery mechanism, not as a primary transport.**

The design doc correctly positions this as:

- The comparison baseline (bytes ×1.x — duplicates on overlap)
- C2's truncation-recovery mechanism
- An optional first-visit accelerator (where product prefers speed over strict byte guarantee)

The duplicate bytes violation of requirement 1 makes it unsuitable as the primary transport. The `$RC` idempotency makes it safe, and the duplicate is genuinely harmless (confirmed by Fact 8 and the demo's `mode=fetch` path), but it's a cost paid for every accelerated section on first visit.

**React on Rails fit:** Already built and working in the demo (`?mode=fetch`). No additional integration work.

### C5 — Official `prerender`/`resume` Split

**Conditionally viable for Scenario B. Requires P6 validation.**

Pros:

- Uses React's stable, sanctioned APIs (not internals)
- Makes the tail a first-class request — priority becomes stateless
- Deletes invented machinery (timing-window capture, interruptible sleeps, marker files)
- The PPR pattern that Next.js ships, applied to a Rails + custom Node renderer stack

Cons:

- **Integration complexity:** Requires new renderer endpoints, `postponed` state storage, and plumbing through `streamServerRenderedReactComponent.ts`
- **Data-resolution ordering as priority mechanism:** Untested. P6 must verify that boundary emission order in a `resume` stream follows data-resolution order.
- **The explicit `React.postpone()` API is still experimental.** The abort-based mechanism (abort prerender → get `postponed` state) works on stable, but it's less ergonomic.
- **Ongoing React version coupling:** The `postponed` JSON format is opaque and version-specific. Prelude and tail must use the same React version.

**React on Rails fit:** Medium — requires changes to both the node renderer package and the Rails engine. The `react-ppr-from-scratch` reference repo provides a template, but integrating into Pro's `streamServerRenderedReactComponent.ts` (which has RSC payload injection, error handling, owner stacks, etc.) is non-trivial.

### C6 — Pull-Only Tail ("Server Islands" Mode)

**Conditionally viable as an opt-in page mode.**

Pros:

- Simplest CDN story — chunk 0 is the entire navigation response; everything else is fetched
- No abort coordination, no SW, no edge state
- Scroll priority is a trivial fetch-queue reorder

Cons:

- **Changes the normal path:** The navigation response is incomplete without JS. Conflicts with requirement 5 ("plain streamed page as unchanged default").
- **SEO:** Non-JS clients see skeletons, not content (same trade-off as Astro Server Islands)
- **Not progressive enhancement:** It's a different page delivery model, not an acceleration on top of the existing one

**React on Rails fit:** Fine as an opt-in mode for JS-required pages (SPAs, dashboard-style apps). The mechanics (per-section addressability, append-reveal) are exactly what C2's skip path uses. Offering this as a configuration option alongside the default streamed mode would be straightforward.

---

## 4. Evaluation of the Layered Recommendation

### 4.1 Is the layering the right decomposition?

**Yes.** The three layers address orthogonal concerns:

- Layer 0 (manifest + addressable sections) is a **prerequisite for all transport candidates** and has independent value (byte-stable caching, integrity verification, clean chunk boundaries)
- Layer 1 (C2 transport) solves **Scenario A** (fully cached) with no server-side changes
- Layer 2 (C5 prerender/resume) solves **Scenario B** (origin rendering) with framework-sanctioned APIs

No single candidate dominates on its own. C2 alone doesn't address Scenario B. C5 alone doesn't deliver bytes from the edge (it needs a transport). C1 covers both but at vendor lock-in cost. The layered approach lets each layer be adopted independently and rolled back without affecting the others.

### 4.2 Does one candidate dominate?

No. Each has a genuine trade-off:

- C2 has the SW lifecycle gap
- C5 has integration complexity
- C1 has vendor lock-in
- C6 changes the page delivery model

The composition is honest about this: each candidate is strongest in its specific scenario, and the layers combine them at their natural boundaries.

### 4.3 What about "nothing yet"?

**This is the recommendation for the immediate term.** The reasoning:

1. **The current prototype already works for origin-served pages.** The interruptible-delay mechanism (filesystem marker + polling) delivers exactly the behavior users would want: scroll to a section → it appears in <100ms. The CDN story is the only gap.

2. **CDN-served pages with progressive streaming are not yet a concrete product requirement.** No React on Rails customer is currently deploying cached Suspense boundary chunks from a CDN edge. The prototype demonstrates the _potential_, but there's no measured demand.

3. **The complexity budget is real.** ~300–500 lines of SW code, a manifest generator, byte-cursor persistence, truncation recovery, heartbeat lifecycle, external runtime vendoring, and a contract test suite — this is a significant maintenance surface. The fragility is well-bounded (failure degrades to today's behavior), but the ongoing verification cost against React upgrades is not zero.

4. **React's PPR story is still maturing.** The `prerender`/`resume` APIs are stable but new (19.2 line). The external runtime has `unstable_` prefix. The `postpone()` component-level API is experimental-only. In 6–12 months, these will be more battle-tested and potentially simpler to integrate.

5. **The foundation work (Layer 0) has independent value** and is low-risk. Doing it now improves the existing prototype regardless of whether Layers 1–2 are ever built.

---

## 5. Recommendation

### Proceed with now

1. **Layer 0 — Manifest + boundary-aligned sections (P0).** Extend `section_cache.rake` to emit a `manifest.json` with boundary IDs, byte sizes, concat offsets, and sha256 hashes. Re-split captured chunks on Fizz unit boundaries instead of trusting time windows. This:
   - Fixes the existing fragility (chunks split mid-tag are a latent bug)
   - Enables all future transport options (C1, C2, C5, C6)
   - Is ~100 lines of Ruby with a self-verifying task
   - Has zero runtime risk (build-time only)

2. **P6 — `prerender`/`resume` standalone spike.** A small Node script (not integrated into the renderer) that demonstrates the abort-based PPR flow against the dummy page component. This validates:
   - Whether `resumeToPipeableStream` works outside Next.js with a prelude from a separate process
   - Whether data-resolution order controls boundary emission order
   - Pass/fail criteria are sharp and the blast radius is zero

   The `react-ppr-from-scratch` repo provides the template.

3. **P1 — SW passthrough parity (if time permits).** Register a no-op identity SW and measure overhead. This is the cheapest signal on whether the SW path is worth pursuing — if the identity passthrough adds >10ms median latency, the whole approach needs rethinking.

### Defer

- **Full C2 implementation (P2–P4):** Until there's a concrete CDN deployment target. The origin-side skip mechanism covers all current usage.
- **C5 renderer integration:** Until P6 proves the composition works and the PPR API surface stabilizes.
- **External runtime vendoring (P5):** Until there's a strict-CSP deployment requirement. The current nonce-rewriting approach works for origin-served pages.
- **C1 DO adapter:** Document as a recipe; build only if a Cloudflare-committed customer requests it.

### Revisit if

- **A customer requests CDN-edge-served streaming pages.** This is the trigger for Layers 1–2.
- **React stabilizes `unstable_externalRuntimeSrc`.** This removes the vendoring/contract-test cost.
- **React stabilizes `React.postpone()`.** This makes C5 more ergonomic.
- **Measured demand exists** for sub-100ms scroll-to-interactive on CDN-cached pages (vs. the origin-side skip mechanism's existing ~100ms performance).

---

## 6. Cost Estimates (for the deferred work, if later greenlit)

| Work item                               | Effort    | Ongoing maintenance                                     |
| --------------------------------------- | --------- | ------------------------------------------------------- |
| Layer 0 (manifest + boundary alignment) | 1–2 days  | Near zero (build-time, self-verifying)                  |
| P1 (SW passthrough parity)              | 0.5 day   | None (experiment)                                       |
| P6 (prerender/resume spike)             | 1–2 days  | None (experiment)                                       |
| Full C2 (P2–P4, hardened SW)            | 2–3 weeks | Medium (per-React-upgrade contract tests, SW lifecycle) |
| C5 renderer integration                 | 2–3 weeks | Medium (postponed state storage, new endpoints)         |
| P5 (external runtime)                   | 1 week    | Low-medium (vendored file, contract test)               |
| P7 (bfcache measurement)                | 2 days    | None (experiment)                                       |
| P8 (productization)                     | 1–2 weeks | Feature support surface                                 |

Total for full implementation: **~2–3 months of focused work**, with ongoing maintenance cost.

---

## 7. Cross-Check: Prior Art

The design doc's prior-art claims were spot-checked:

| Framework                               | Mechanism                                              | Verified?                                               |
| --------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------- |
| Astro Server Islands                    | Placeholder + per-island GET + script swap + cacheable | ✓ (docs fetched; matches)                               |
| Next.js PPR                             | `prerender` → static prelude → `resume` dynamic tail   | ✓ (docs + `react-ppr-from-scratch` confirm composition) |
| workbox-streams                         | SW stitching of short-lived responses                  | ✓ (shipped, maintained by Google)                       |
| Marko/SolidStart out-of-order streaming | Inline reorder runtimes (same family as Fizz)          | Not independently verified; accepted from design doc    |
| Turbo Frames `loading="lazy"`           | Viewport-triggered per-frame pull                      | Not independently verified; straightforward claim       |

---

## 8. Cross-Check: React Internals Risk

| Mechanism                                                      | Stable?                             | Churn risk                                |
| -------------------------------------------------------------- | ----------------------------------- | ----------------------------------------- |
| Wire format (`$RC("B:n","S:n")`, `<template>`, `<div hidden>`) | Stable 18.3.1–19.2.7                | Low (breaking would break every SSR app)  |
| `$RC` function body (reveal timing, batching)                  | Rewritten between 18.3.1 and 19.2.x | High (34 fizz-instruction commits)        |
| `prerender`/`resume` API signatures                            | Stable in 19.2.x                    | Medium (new, may see signature evolution) |
| `unstable_externalRuntimeSrc`                                  | Unstable prefix                     | High (explicitly not committed to)        |
| `postponed` JSON format                                        | Opaque, version-specific            | Medium (React controls serialization)     |

The design doc's architecture preference for "let React's own runtime execute reveals" (C2 native parsing) over "call `$RC` manually" (C3/C4) is well-justified by this risk profile. The recommended Layer 1 (C2) has zero internals dependence — the strongest position.

---

## 9. Sources

### Primary (verified in this evaluation)

- react-dom@19.2.7 package: `static.node.js`, `server.node.js` export lists; `cjs/react-dom-server.node.production.js` (`externalRuntimeConfig`, 20 references)
- `streamServerRenderedReactComponent.ts` in `packages/react-on-rails-pro/src/` — current `renderToPipeableStream` call site, no streaming-options passthrough
- [ShakaCode react-ppr-from-scratch](https://github.com/shakacode/react-ppr-from-scratch) — standalone PPR demonstration
- Cloudflare DO docs: [data location](https://developers.cloudflare.com/durable-objects/reference/data-location/), [pricing](https://developers.cloudflare.com/durable-objects/platform/pricing/)
- [ServiceWorker spec issue #882](https://github.com/w3c/ServiceWorker/issues/882) — no implicit keep-alive for JS-driven `respondWith` streams
- [Bugzilla 1302715](https://bugzilla.mozilla.org/show_bug.cgi?id=1302715) — Firefox 30s + 30s termination
- [Chromium issue 40733525](https://issues.chromium.org/issues/40733525) — 5-minute limit is MV3-extension-only
- [React PR #25499](https://github.com/facebook/react/pull/25499) — external Fizz runtime origin
- [Safari 18.5 release notes](https://webkit.org/blog/16574/webkit-features-in-safari-18-4/) — SW download interruption fix
- [React 19.2 blog post](https://react.dev/blog/2025/10/01/react-19-2) — prerender APIs return postpone state

### From the design doc (accepted, not re-verified)

- Cloudflare DO streaming examples, Workers Streams API
- workbox-streams (Google)
- RFC 9113/9114/9000 protocol-level cancel semantics
- React commit history (34 fizz-instruction commits, PRs #33511, #33531)

### Community data (not primary source)

- Cloudflare community: worker-to-DO latency consistently ≥120ms ([AnswerOverflow thread](https://www.answeroverflow.com/m/1290899445373865994))
- Cloudflare Queues blog: p50 ~60ms write latency after DO rebuild
