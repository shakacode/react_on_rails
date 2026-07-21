# Investigation Prompt: Zero-Waste Scroll-Priority Delivery of Cached Streamed HTML Sections

You are a senior web-platform architect. Your mission is to find and justify the **best
production-grade architecture** for the following problem, then deliver a comparison and a
recommendation. Research deeply (web search encouraged — verify claims against primary sources:
specs, vendor docs, framework source code). Do not take the candidate solutions below as the
final answer space; they are a starting point that you should red-team and extend.

---

## 1. Problem statement

A server-rendered React page is delivered as a **progressive HTML stream** made of cached
section chunks: an initial chunk containing the full document shell plus the first sections
already rendered, followed by N tail chunks, each completing one `<Suspense>` boundary further
down the page. In production these chunks would be served **from a CDN edge**, with pacing that
is either artificial (replaying a cached stream) or real (origin still rendering the later
sections).

If the user **scrolls toward a section that has not arrived yet**, we want that section (and any
sections between the last-delivered one and it) delivered and hydrated **as fast as possible**.

**Hard requirements:**

1. **Zero duplicate bytes.** Every section's HTML crosses the wire at most once. (A working
   solution that double-delivers — client fetches a section AND the stream later re-sends it —
   has already been built and rejected for this reason.)
2. **React 19 selective hydration must keep working.** Each section hydrates independently as
   its HTML and code become available; sections already on screen stay interactive and keep
   their component state throughout.
3. **CDN-compatible.** The primary deployment target is cached chunks at an edge (CDN worker or
   plain static files). State-at-the-edge is allowed only where the platform genuinely supports
   it; solutions requiring no edge state rank higher on portability.
4. **No full-page re-render, no client-side re-render of already-delivered content.**
5. The normal path (user never scrolls ahead) must remain a plain streamed page — the
   acceleration mechanism must be a progressive enhancement, not a tax on every page view.

---

## 2. System context (how it works today)

The existing prototype lives in a Rails app (React on Rails Pro, React 19.2, streaming SSR via
`renderToPipeableStream` on a Node renderer, delivered through `ActionController::Live`).

### Chunk format (real captured output)

**Chunk 0** — complete HTML document: `<!DOCTYPE html>` … `</html>`, with the first 3 sections
fully rendered and each pending section represented by an unresolved Suspense boundary:

```html
<!--$?--><template id="<domId>B:3"></template>
<div style="min-height:70vh;...">Loading section 3...</div>
<!--/$-->
```

Important: React closes `</body></html>` early in chunk 0; the _root_ boundary's content (which
contains all the section skeletons above) is emitted at the very END of chunk 0 as a hidden div
plus React's runtime and the first reveal call:

```html
<div hidden id="<domId>S:0">…all immediate sections + pending skeletons…</div>
<script>
  $RC=function(b,c,e){…};$RC("<domId>B:0","<domId>S:0")
</script>
```

**Chunks 1..N** — each is: one hidden content div + one reveal script (plus optional
console-replay scripts):

```html
<div hidden id="<domId>S:3">…section HTML…</div>
<script>
  $RC('<domId>B:3', '<domId>S:3');
</script>
```

`$RC` is React's Fizz `completeBoundary`: it consumes the hidden div, finds the boundary's
`<template>`, removes the fallback, moves the content in, and triggers hydration retry
(`_reactRetry`).

### Current prototype (works, but only origin-side)

- The streaming endpoint replays cached chunk files with a configurable inter-chunk delay. The
  delay is an **interruptible wait**: it polls a per-stream marker file every 50 ms.
- The shell embeds a `stream_id`; client JS posts to `/skip_delay/:stream_id` when the user
  scrolls to a pending skeleton; the streaming loop sees the flag and flushes all remaining
  chunks down the same connection immediately.
- Measured: skip requested at +7.6 s → server acknowledged in 11 ms → all 7 remaining chunks
  delivered within ~50 ms, all hydrated and interactive, zero console errors.
- This satisfies requirements 1–2 and 4–5 but **not 3**: it relies on origin-held state
  (filesystem marker) and an origin holding the open response, which does not translate to a
  CDN edge as-is.

---

## 3. Verified facts you may rely on (empirically tested, React 19.2)

These were established by direct experiment on the working prototype. Re-verify only if you
suspect version drift.

1. **`$RC` is idempotent per boundary.** Its source (from the shipped react-dom build):

   ```js
   $RC = function (b, c, e) {
     c = document.getElementById(c);
     c.parentNode.removeChild(c); // always consumes the hidden content div
     var a = document.getElementById(b); // boundary template
     if (a) {
       /* reveal + _reactRetry */
     } // ← already-revealed boundary → no-op
   };
   ```

   Tested: a section delivered twice (client-injected first, then the stream's copy ~17 s
   later) ends with exactly one copy in the DOM, zero orphan hidden divs, **React component
   state preserved** (a counter clicked to 1 before the duplicate stayed 1 after), zero errors.

2. **Manual reveal works without executing any fetched script.** Fetch a chunk file, parse
   with `DOMParser`, `document.adoptNode` + append the hidden div(s), then call
   `window.$RC(boundaryId, contentId)` directly. Hydration and interactivity confirmed. This
   sidesteps CSP-nonce and script-execution issues entirely on the client side.
3. **Late arrival is fine.** Sections arriving minutes after load hydrate normally; hydration
   is genuinely per-boundary (untouched sections' state/status unaffected by neighbors).
4. **Pending boundaries are discoverable generically** via
   `document.querySelectorAll('template[id*="B:"]')`; each template's `nextElementSibling` is
   the visible fallback/skeleton (note: React on Rails prefixes the ids, so match `B:`
   _anywhere_ in the id, not at the start).
5. **`window.stop()` hazards (measured):** it aborts ALL in-flight subresource loads, not just
   the navigation stream. Also, while a navigation response is streaming, `document.readyState`
   never reaches `complete` and the `load` event never fires — readiness gates must use
   resource-level signals instead.
6. **Scroll events don't bubble** — if the page scrolls an inner `overflow-y:auto` container, a
   `window` scroll listener never fires; a capturing listener on `document` catches it
   regardless of which element scrolls.

---

## 4. Two production scenarios — address both

**Scenario A — fully cached at the edge.** All chunks exist as static assets at the CDN.
Pacing, if any, is artificial or bandwidth-driven. Here the question is purely about transport
and coordination.

**Scenario B — origin still rendering.** Chunk 0 and early chunks are cached; later chunks are
being generated by the origin as the stream progresses. Here a "skip" cannot make rendering
faster — the meaningful operation is **re-prioritization** (render the scrolled-to section
next) and the signal must reach the origin renderer. Evaluate how each architecture degrades
into or composes with this scenario.

---

## 5. Candidate architectures already identified — red-team these

### C1. Edge-held state: Cloudflare Durable Object

Route both the streaming request and the client's skip/priority POST to the same DO instance
(id embedded in the shell). Inside the DO the delay loop is
`await Promise.race([sleep(delay), skipSignal])`; on signal, flush remaining chunks down the
same connection. Zero duplication by construction.

Known facts: streaming a `ReadableStream` from a DO is a documented first-class pattern;
duration is billed on wall-clock while active; alarm/cron handlers cap at 15 min (a bounded
page stream fits). Workers KV is NOT usable for the signal (writes take up to ~60 s to
propagate; same-PoP fast-visibility is explicitly not guaranteed). The per-PoP Cache API can
emulate a same-datacenter marker file but is a hack, not a guarantee.

Open questions for you: DO invocation/duration cost per page view at scale; behavior when the
navigation and the POST arrive at different colos (DO routing latency); equivalents on other
platforms (Fastly Compute, Akamai EdgeWorkers, AWS CloudFront Functions/Lambda@Edge, Deno
Deploy — what is the current, verified state-coordination story on each?).

### C2. Service Worker stream-stitching (client-side programmable edge)

A SW proxies the navigation: `fetch(upstream)` → pipe through `TransformStream` →
`respondWith`. The page `postMessage`s scroll intent. The SW then: (a) `abort()`s the upstream
fetch — a protocol-level cancellation (H2 `RST_STREAM`), so the CDN stops sending; (b) knowing
exactly which sections already passed (it watches marker scripts/section delimiters flow by),
fetches only the missing section files; (c) writes them into the same stream feeding the
parser. The parser executes the reveal scripts natively; no client-side injection code at all.
Works with a completely dumb/static CDN. Zero duplication.

Open questions for you:

- **First-visit gap:** no controller on the first navigation. Quantify prevalence; design the
  fallback (plain streaming, or the manual-`$RC` pull from Verified Fact 2?).
- **Does client-side abort actually stop edge egress on the major CDNs?** And in Scenario B,
  does the CDN keep draining the origin connection after the client aborts (wasting origin
  work), per vendor? Verify per-CDN behavior (Cloudflare, CloudFront, Fastly, Akamai).
- SW keep-alive rules while holding a long-lived streaming `respondWith` (browser differences,
  Safari in particular).
- Interaction with navigation preload, BFCache, and HTTP caching of the SW script itself.

### C3. Gated `window.stop()` + client pull

After all critical resources have loaded (resource-level gate — see Verified Fact 5), the only
significant in-flight request is the nav stream; `window.stop()` then kills it (also a real
RST_STREAM), and the client pulls the remaining static section files and reveals them via
manual `$RC` (Verified Fact 2). Zero duplication, zero new infrastructure. Costs: kills
in-flight images/prefetches, `readyState` stuck at `interactive` forever, relies on internal
`$RC` (see §7.3).

### C4 (rejected baseline, for reference). No-stop client pull

Keep the stream flowing; client fetches ahead; `$RC` idempotency makes the race safe. Fully
working, simplest — **rejected because the stream re-delivers what the client already fetched**
(violates requirement 1). Use it only as the comparison baseline and possibly as the
first-visit fallback in C2.

---

## 6. Additional avenues you must evaluate (at minimum)

1. **HTTP Range resumption:** stop the stream, then Range-request the remainder of the same
   URL. Presumably dead on arrival for chunked/streamed responses without `Content-Length`
   (and for dynamically paced bodies), but verify and document precisely why, or find the
   variant that works (e.g., byte-addressable pre-concatenated chunk asset + client-tracked
   offset?).
2. **React's official partial prerender/resume APIs** (`prerender` → `postponed` state →
   `resume` / `resumeAndPrerender` in react-dom static). This is the framework-sanctioned
   version of "shell now, rest later" and the foundation of Next.js PPR. Could the tail
   sections be delivered as a _resumed stream_ fetched on demand — and does that compose with a
   scroll-priority signal? Assess maturity, stability, and fit for a non-Next stack (Rails +
   custom Node renderer).
3. **Prior art survey (verify against current docs/source, not blog folklore):** Next.js PPR
   resume semantics and its CDN story; Astro Server Islands (`server:defer`) delivery +
   replacement mechanism; Turbo Frames `loading="lazy"`; htmx lazy fragments; Qwik resumability
   claims relevant to out-of-order section delivery; Marko/SolidStart out-of-order streaming
   implementations. Extract transferable mechanisms, not marketing.
4. **HTTP/3 semantics:** does QUIC stream cancellation change anything about C2/C3 through the
   named CDNs?
5. **Priority signals without cancellation** (Scenario B): `103 Early Hints`, `fetchpriority`,
   or an application-level priority channel to the origin renderer. Is "reprioritize, don't
   skip" the actually-correct production behavior, with the artificial-delay problem being an
   artifact of the demo?

## 7. Cross-cutting open problems — must be addressed in the recommendation

1. **CSP nonces vs. static CDN chunks.** The cached chunks contain inline `<script nonce=…>`
   (React reveal scripts). The current origin prototype rewrites nonces per request; a static
   CDN cannot. Resolve: hash-based CSP for the known reveal scripts? `strict-dynamic`? Serving
   chunk scripts as external `src` with `'self'`? Edge-worker nonce rewriting (and its cost)?
   What do streaming-SSR-on-CDN deployments actually do here? This can decide feasibility of
   the whole static-chunk model under a strict CSP.
2. **Section boundary metadata.** Whatever stitches or pulls (DO, SW, or page JS) must know the
   chunk→boundary mapping. Today it is derived from filename convention + in-stream marker
   scripts. Propose a robust manifest format (and who generates it at cache-build time).
3. **Stability of relying on `$RC`.** It is an undocumented internal of react-dom's Fizz
   runtime. Assess breakage risk across React versions (check React repo history for
   `completeBoundary` churn) and identify the supported alternative if any (see §6.2). Note
   that C2 does NOT depend on calling `$RC` manually (the parser runs React's own scripts) —
   weight this in the comparison.
4. **SEO / no-JS:** crawlers see chunk 0 only (shell + first sections + skeletons) unless they
   execute JS or the stream is allowed to complete. Quantify impact per architecture.
5. **Multiplexing reality check:** with HTTP/2+ the "one connection" aesthetic of the pure
   stream has little transport cost advantage over parallel section fetches on the same
   connection. Verify and use this to challenge any candidate whose main claim is
   connection reuse.

---

## 8. Evaluation criteria (score each candidate)

| Criterion                                                                             | Weight    |
| ------------------------------------------------------------------------------------- | --------- |
| Bytes on wire (target: page size × 1.0 exactly)                                       | high      |
| Time from scroll intent → scrolled-to section interactive                             | high      |
| CDN portability (works on dumb static hosting ↔ requires specific vendor)            | high      |
| Preserves React selective hydration + component state                                 | hard gate |
| Strict-CSP compatibility (nonce or hash based)                                        | high      |
| Scenario B story (origin reprioritization)                                            | medium    |
| Implementation & operational complexity (incl. first-visit, SW lifecycle, DO billing) | medium    |
| Dependence on undocumented internals                                                  | medium    |
| SEO / progressive enhancement without JS                                              | medium    |

## 9. Deliverable

1. **Comparison matrix** of all candidates (including any new ones you find) against §8.
2. **A recommended architecture** — possibly a composition (e.g., C2 with C4 as first-visit
   fallback) — with an explicit rationale and its failure modes.
3. **A prototype plan**: ordered implementation steps, what to measure, and pass/fail criteria
   for each step (mirror the empirical style of §3 — every claim gets an experiment).
4. **Sources**: primary links (specs, vendor docs, framework source) for every load-bearing
   claim. Flag anything you could not verify.

## 10. Repo pointers (only if you have access to `shakacode/react_on_rails`)

Working prototype (all under `react_on_rails_pro/spec/dummy/`):

- `app/controllers/pages_controller.rb` — `selective_hydration_cached` (interruptible-delay
  streaming), `selective_hydration_skip_delay` (signal endpoint)
- `public/selective_hydration_scroll_demo.js` — boundary discovery, scroll trigger, race guard
- `lib/tasks/section_cache.rake` — chunk capture (`rake "section_cache:generate[/selective_hydration_demo,10,5,3]"`)
- `client/app/components/CacheSection.jsx` — Suspense wrapper creating the boundaries
- `public/cache/selective_hydration_demo/section*.html` — captured chunks (chunk format source
  of truth)

Local run: build dummy bundles, start node renderer (`pnpm run node-renderer`, port 3800) +
Rails (`rails s -p 5150`), then `http://localhost:5150/selective_hydration_cached?delay=25`.

Related: issue #4385, PR #4740 (experimental cache infrastructure).
