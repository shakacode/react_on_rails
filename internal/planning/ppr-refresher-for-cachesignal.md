# PPR & Cached Components — Refresher for Issue #3885

**Date:** 2026-08-03
**Author:** Abanoub Ghadban (memory refresher, composed with Claude Code)
**Purpose:** Reconnect with the PPR plan after time away. Explains how Next.js
cached components work, our plan to implement the same in React on Rails, and
where issue #3885 (`cacheSignal`) sits in that plan.

---

## Table of Contents

1. [How Next.js Cached Components Work](#1-how-nextjs-cached-components-work)
2. [The PPR Architecture (Static Shell + Dynamic Holes)](#2-the-ppr-architecture)
3. [Where `cacheSignal` Fits in the PPR Lifecycle](#3-where-cachesignal-fits)
4. [Our Plan to Implement This in React on Rails](#4-our-plan)
5. [What We've Already Shipped](#5-what-weve-already-shipped)
6. [What's Still Greenfield](#6-whats-still-greenfield)
7. [Where Issue #3885 Sits in the Plan](#7-where-issue-3885-sits)
8. [Issue Tracker Map](#8-issue-tracker-map)
9. [Key Files to Know](#9-key-files-to-know)

---

## 1. How Next.js Cached Components Work

### The Mental Model: "Dynamic by Default, Opt-in Caching"

Next.js 16 (React 19.2) flipped the caching model. Nothing is cached unless
you explicitly ask for it. The mechanism is the **`"use cache"` directive** —
a compiler-level directive (like `"use client"` or `"use server"`) that you
place at the top of a function or component:

```tsx
async function ProductCard({ id }: { id: string }) {
  'use cache';
  cacheTag(`product:${id}`);
  cacheLife('hours');

  const product = await db.products.find(id);
  return (
    <div>
      {product.name} — ${product.price}
    </div>
  );
}
```

### What Happens Under the Hood

**At build time**, the SWC/Babel compiler transforms `"use cache"` functions:

```
Source code                          Compiled output
─────────────                        ───────────────
async function f(a, b) {             const $$INNER = async (a, b) => { ...body... }
  "use cache";                  →    export var f = reactCache(function() {
  ...body...                           return cache("default", "<sha256-id>", $$INNER, [a, b])
}                                    })
                                     registerServerReference(f, "<sha256-id>", null)
```

**At runtime**, the `cache()` wrapper does:

1. **Derive the cache key:** `sha256(buildId + functionId + encodeReply(args))`
2. **Check the cache handler:**
   - **HIT →** Return `createFromReadableStream(cachedRSCBytes)` — the
     component function **never executes**
   - **MISS →** Execute the function, render result to RSC bytes via
     `renderToReadableStream`, `tee()` the stream (one branch to cache
     storage, one to `createFromReadableStream` for immediate return)
3. **Single exit point:** Both HIT and MISS return through
   `createFromReadableStream`, so behavior is identical whether cache is warm
   or cold

### What Gets Cached

The cached value is **serialized RSC flight data** (the React Server Components
wire format), not raw JSON or HTML. This means cached components preserve their
full React tree structure, client component references, and streaming
semantics.

### Cache Invalidation

- **`cacheLife('hours')`** — time-based expiry (named profiles: `'seconds'`,
  `'minutes'`, `'hours'`, `'days'`, or custom `{ stale, revalidate, expire }`)
- **`cacheTag('product:42')`** — attaches tags to cache entries
- **`revalidateTag('product:42')`** — marks all entries with that tag as stale
  (callable from Server Actions, API routes, or — in our case — Rails controllers)
- **`revalidatePath('/products')`** — convenience wrapper around implicit
  route-level tags

---

## 2. The PPR Architecture

### The Problem PPR Solves

Before PPR, a page was either **fully static** (built at deploy, served from
CDN) or **fully dynamic** (rendered per-request). PPR eliminates this
all-or-nothing choice by splitting a single page into:

- **Static shell** — layout, navigation, above-the-fold cached content → served
  instantly from CDN edge
- **Dynamic holes** — user-specific data, real-time content → streamed from
  origin into the same HTTP response

### The Two-Layer Architecture

PPR coordinates two independent rendering layers:

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Layer 1: RSC (React Server Components)                                  │
│ • Generates flight data (serialized component tree)                     │
│ • Uses react-server-dom-webpack                                         │
│ • prerender() returns { prelude } only — NO postpone/resume            │
│ • Must execute ALL components unless "use cache" short-circuits them    │
├─────────────────────────────────────────────────────────────────────────┤
│ Layer 2: Fizz (HTML Generation)                                         │
│ • Generates HTML from the RSC output                                    │
│ • Uses react-dom/static + react-dom/server                              │
│ • prerender() returns { prelude, postponed } — CAN be resumed          │
│ • Supports React.postpone() to create dynamic holes                    │
└─────────────────────────────────────────────────────────────────────────┘
```

**Key insight you discovered:** RSC prerender has NO postpone/resume. The RSC
payload is re-rendered from scratch on every request. `"use cache"` is the
**only** mechanism that prevents re-execution — it turns expensive subtrees
into pre-serialized RSC byte blobs that are replayed via
`createFromReadableStream`.

### The Two-Pass Build-Time Prerender

This was the breakthrough in your investigation. Static generation needs two
passes with opposite timing:

**Pass 1 — Prospective (unbounded, cache-warming):**

1. Render the full tree to warm all `"use cache"` entries
2. Wait for a coordination signal (CacheSignal) that fires when all cache reads
   settle and no new reads arrive within a full event-loop turn
3. **Abort and discard the entire output** — this pass only existed to fill caches

**Pass 2 — Final (bounded, shell-carving):**

1. Render again with caches now warm → cached components resolve synchronously
2. Dynamic APIs (`cookies()`, `headers()`, request-specific data) return
   **hanging promises** — promises that never resolve until the render aborts
3. Abort after one task (`setImmediate`) → whatever resolved is the static shell;
   whatever was still suspended becomes a Suspense placeholder (dynamic hole)

```
Pass 1: Warm caches (slow, unbounded)
  ┌──────┐  ┌──────┐  ┌──────┐
  │Cache1│  │Cache2│  │Cache3│  → all settled → CacheSignal fires → abort
  └──────┘  └──────┘  └──────┘    Output discarded. Caches warm.

Pass 2: Carve static shell (fast, bounded)
  ┌──────┐  ┌──────┐  ┌──────────────┐
  │Cache1│  │Cache2│  │ cookies() ←─── hanging promise (never resolves)
  │ HIT  │  │ HIT  │  │  suspends...  │
  │instant│  │instant│  │  → fallback  │
  └──────┘  └──────┘  └──────────────┘
            ↓ abort after one task
  Static shell = cached content + Suspense fallbacks for dynamic holes
```

### CacheSignal Coordination (the framework's internal signal — NOT React's `cacheSignal()`)

This is a framework-level coordination mechanism (distinct from React 19.2's
`cacheSignal()` API). It tracks when all `"use cache"` reads have settled:

- **Deferred settle:** When in-flight count hits zero, schedule a check via
  `setImmediate(() => setTimeout(cb, 0))`. Only fire if still zero after a full
  event-loop turn.
- **`beginRead` cancels pending settle:** A newly discovered cache read resets
  the clock, so late-discovered caches don't get missed.

### HTML Layer: Postpone / Resume

The Fizz (HTML) layer **does** support real postpone/resume:

- **Build time:** `react-dom/static.prerender(element, { signal })` returns
  `{ prelude, postponed }` — the static HTML shell + an opaque PostponedState blob
- **Request time:** `react-dom/server.resume(element, postponed)` renders only
  the dynamic parts, emitting `<script>` chunks that swap Suspense fallbacks
  with real content

The `postponedState` is **opaque** — never parse or modify it. Shell and state
must update atomically.

### Serving the Response

The client receives a single HTTP stream:

1. Static shell HTML (instant, from cache/CDN)
2. Dynamic content streamed in as `$RC()` script chunks (from origin, replacing
   Suspense fallbacks in-place)

No second HTTP request needed — the browser sees progressive content.

---

## 3. Where `cacheSignal` Fits

There are **two different "cache signal" concepts** in play. Understanding
the distinction is critical:

### Concept A: Framework CacheSignal (our coordination mechanism)

This is the **framework-internal** coordination mechanism described above — a
counter-based signal that tracks when all `"use cache"` reads have settled
during the prospective prerender pass. It tells the framework "all caches are
warm, abort the prospective render now."

**Status:** Phase 4 of our plan. Fully greenfield — not started.

### Concept B: React's `cacheSignal()` API (React 19.2)

This is a **React-provided API** that returns an `AbortSignal` tied to the
lifetime of the current render:

```tsx
import { cache, cacheSignal } from 'react';

const fetchData = cache(async (id) => {
  const signal = cacheSignal();
  // signal.aborted becomes true when:
  //   - The render completes successfully
  //   - The render is aborted (client disconnect, timeout, prospective pass discard)
  //   - The render fails
  const res = await fetch(`/api/data/${id}`, { signal });
  return res.json();
});
```

**What it does:** When a streamed render is abandoned (client disconnects,
render is aborted), React settles the `cacheSignal()`, which cancels any
in-flight fetch/DB work using that signal. This prevents wasted work.

**Where it matters for PPR:**

- During **Pass 1 (prospective render)**, when the pass is aborted after caches
  warm, `cacheSignal` fires → cancels any lingering fetch/DB connections
- During **normal streaming SSR**, when a client disconnects mid-stream,
  `PipeableStream.abort()` fires → React settles `cacheSignal` → cancels
  in-flight data work

**Status:** This is issue #3885. The abort wiring prerequisite (making sure
`PipeableStream.abort()` actually fires on disconnect) shipped in PR #4093.
The remaining work is adding a test + docs.

### How They Relate

When both are in place:

1. Framework CacheSignal says "all caches warm" → aborts prospective render
2. `PipeableStream.abort()` fires on the prospective render
3. React's `cacheSignal()` fires inside each `cache()` scope → cancels
   in-flight fetches
4. Clean cleanup — no leaked DB connections or wasted API calls

---

## 4. Our Plan

### Track A vs Track B (Issue #3255, closed — still source of truth)

| Track       | What                                                                                                                                                 | Status                                                                                              |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **Track A** | Streaming SSR + Suspense with a Rails-fragment-cached shell (`cached_stream_react_component`). First shippable PPR example, no `"use cache"` needed. | Helpers shipped. Error boundaries merged. Track A risk: #4581 (stream caches persist error chunks). |
| **Track B** | Full `"use cache"` directive for RSC PPR. 10 phases, ~6 months. Your `ppr-from-scratch` reimplementation validates the mechanics.                    | Foundation partially shipped (`unstable_cache`). Phases 3–8 greenfield.                             |

### Track B: The 10-Phase Plan

From `ppr-implementation-plan.md` (your plan, 2026-05-20):

| Phase  | Scope                                                                              | Status                                                                                                                                                   | Effort   |
| ------ | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| **1**  | `CacheHandler` interface + in-memory LRU + `ActiveSupport::Cache` adapter          | ⚠️ **Partially shipped** (divergent: 2-method not 5-method, entry-count not byte-sized, ioredis not ActiveSupport, module-Map breaks across VM contexts) | ~2 weeks |
| **2**  | Runtime `cache()` wrapper: key derivation, single-exit hit/miss, Resume Data Cache | ⚠️ **Partially shipped** (`unstable_cache` — hand-rolled serializer not `encodeReply`, no per-render RDC, only per-worker single-flight Map)             | ~2 weeks |
| **3**  | Build-time `"use cache"` transform (Babel/SWC)                                     | 🔴 **Greenfield**                                                                                                                                        | ~3 weeks |
| **4**  | CacheSignal coordination + module-load tracking + two-pass prerender driver        | 🔴 **Greenfield** — _#3885 feeds into this_                                                                                                              | ~2 weeks |
| **5**  | Hanging-promise plumbing for Rails request-time APIs                               | 🔴 **Greenfield**                                                                                                                                        | ~2 weeks |
| **6**  | HTML/Fizz prerender + resume; postponed-state serialization                        | 🔴 **Greenfield** (PPR spike exists: `pprServerRenderedReactComponent.ts`)                                                                               | ~3 weeks |
| **7**  | `cacheLife` / `cacheTag` / `revalidateTag` + tag manifest + Ruby-side invalidation | 🔴 **Greenfield** on JS RSC-byte layer (Ruby tag system exists but on wrong layer)                                                                       | ~2 weeks |
| **8**  | Client-reference threading through cache wrapper                                   | 🔴 **Greenfield**                                                                                                                                        | ~1 week  |
| **9**  | CDN resume HTTP protocol + Cloudflare Workers adapter                              | 🔴 **Greenfield**                                                                                                                                        | ~2 weeks |
| **10** | Documentation, examples, migration guides                                          | 🔴 **Greenfield**                                                                                                                                        | ~2 weeks |

**Total estimate:** ~6 months (parallelizable to ~3 months with 2 engineers).
The July 2026 validity review confirmed this estimate is **not reduced** by the
partial Phase 1-2 work — Phases 4 and 6 dominate the risk/time.

### The Four Required Components for `"use cache"`

All needed together, none can be omitted:

1. **Build-time transform** — SWC/Babel plugin that rewrites `"use cache"` functions
   into `cache(kind, id, fn, args)` wrapper calls with stable content-hashed IDs
2. **Runtime cache wrapper** — `cache()` function with key derivation, single-exit
   hit/miss through `createFromReadableStream`, per-render Resume Data Cache
3. **Cache storage backend** — Pluggable `CacheHandler` interface with LRU default,
   `ActiveSupport::Cache` adapter for Rails teams
4. **CacheSignal coordination** — Deferred-settle signal for the two-pass prerender

---

## 5. What We've Already Shipped

### Cache Infrastructure (partial Track B foundation)

| Component                 | File                                                      | What it does                                                                                                         |
| ------------------------- | --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `unstable_cache`          | `packages/react-on-rails-pro/src/cache/unstable_cache.ts` | Manual RSC-byte cache with single-exit hit/miss, per-worker single-flight dedup. Exported from `ReactOnRailsRSC.ts`. |
| `CacheHandler`            | `cache/CacheHandler.ts`                                   | 2-method interface (`get`/`set`) — simpler than P2's 5-method spec                                                   |
| `buildCacheKey`           | `cache/buildCacheKey.ts`                                  | `sha256(buildId:id:stableStringify(args))` — hand-rolled serializer                                                  |
| `InMemoryLRUCacheHandler` | `cache/InMemoryLRUCacheHandler.ts`                        | Entry-count-capped LRU (default 1000)                                                                                |
| `RedisCacheHandler`       | `cache/RedisCacheHandler.ts`                              | Direct ioredis, 1MB max entry, binary header                                                                         |
| `TieredCacheHandler`      | `cache/TieredCacheHandler.ts`                             | L1/L2 tiered cache                                                                                                   |
| `cacheHandlerRegistry`    | `cache/cacheHandlerRegistry.ts`                           | Module-level Map (⚠️ breaks across VM contexts)                                                                      |

### PPR Spike (experimental)

| Component                                     | File                                                                  |
| --------------------------------------------- | --------------------------------------------------------------------- |
| `pprPrerenderServerRenderedReactComponent`    | `packages/react-on-rails-pro/src/pprServerRenderedReactComponent.ts`  |
| `pprResumeServerRenderedReactComponent`       | Same file                                                             |
| Ruby helper `ppr_react_component`             | `react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb`         |
| Render modes `:ppr_prerender` / `:ppr_resume` | `react_on_rails/lib/react_on_rails/react_component/render_options.rb` |

### Abort Wiring (prerequisite for cacheSignal, PR #4093)

- Worker: `res.raw.once('close', abortRenderOnClientDisconnect)` in `worker.ts`
- streamingUtils: `cancelUpstream()` → `pipedStream.abort()` on consumer disconnect
- streamServerRenderedReactComponent: `onConsumerAbort` → `renderingStream.abort()`
- RSCRequestTracker: clears resolved-but-post-teardown streams

### React 19.2 Support

- Peer check widened (PR #4026) — `rscPeerSupport.ts` accepts 19.2.7+
- Pro packages dev on React 19.2.7 + `react-on-rails-rsc` 19.2.1
- Pro/OSS dummies soak-test 19.2 in CI

---

## 6. What's Still Greenfield

| What                                                | Why it matters                                                                                                 | Blocking issue    |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | ----------------- |
| `"use cache"` build transform                       | Without it, developers must manually wrap components with `unstable_cache` — no directive ergonomics           | Phase 3           |
| Framework CacheSignal coordination                  | Needed for the two-pass prerender to know when to abort Pass 1                                                 | Phase 4           |
| Hanging promises for Rails APIs                     | Needed for `cookies()`/`headers()`/`current_user` to create dynamic boundaries during prerender                | Phase 5           |
| HTML Fizz prerender + resume                        | The actual `prerenderToNodeStream` → `resumeToPipeableStream` integration (spike exists, not production-ready) | Phase 6           |
| `cacheLife`/`cacheTag`/`revalidateTag` on RSC layer | Ruby tag system exists but operates on the wrong layer (HTML fragments, not RSC bytes)                         | Phase 7           |
| Per-render Resume Data Cache                        | Needed for cached components to resolve within the final pass's one-task abort window                          | Phase 2 hardening |
| `encodeReply` parity for cache keys                 | Current hand-rolled serializer diverges from the spec                                                          | Phase 2 hardening |
| Process-global handler registry                     | Current module-Map breaks across `vm.createContext` boundaries in the node renderer                            | Phase 1 hardening |

---

## 7. Where Issue #3885 Sits in the Plan

### Issue #3885 is at the intersection of two things:

```
                    ┌──────────────────────────────┐
                    │ Phase 4: CacheSignal          │
                    │ coordination + two-pass       │
                    │ prerender driver               │
                    │                                │
                    │ Needs: Framework CacheSignal   │
          ┌────────│ + React's cacheSignal() works  │
          │        └──────────────────────────────┘
          │
    ┌─────▼──────────────────────────────┐
    │ Issue #3885: cacheSignal settle    │ ◄── YOU ARE HERE
    │                                    │
    │ Scope:                             │
    │ 1. Test: RSC cache()-wrapped fetch │
    │    observes aborted on disconnect  │
    │ 2. Docs: docs/pro/ data-fetching  │
    │    section with cacheSignal usage  │
    │ 3. (Stretch) Cancel pending        │
    │    generateRSCPayload via signal   │
    └─────▲──────────────────────────────┘
          │
          │        ┌──────────────────────────────┐
          │        │ PR #4093: Abort wiring        │
          └────────│ (MERGED June 18)              │
                   │                                │
                   │ PipeableStream.abort() now     │
                   │ fires on client disconnect →   │
                   │ React settles cacheSignal()    │
                   └──────────────────────────────┘
```

### What #3885 proves for the PPR plan:

- **React's `cacheSignal()` works end-to-end** in our renderer — when a render
  is aborted, cooperating fetches are cancelled
- This is the **precondition for Phase 4**: the framework's CacheSignal
  coordination mechanism aborts the prospective render → React settles
  `cacheSignal()` → in-flight data work is cancelled cleanly
- Without #3885 validated, Phase 4 is building on unproven ground

### What #3885 does NOT cover:

- The framework-level CacheSignal coordination (Phase 4)
- The two-pass prerender driver (Phase 4)
- The `"use cache"` build transform (Phase 3)
- Hanging promises (Phase 5)
- HTML prerender/resume (Phase 6)

#3885 is a small, focused piece that validates one link in the chain.

---

## 8. Issue Tracker Map

| Issue     | Title                              | State                    | Relevance                                                     |
| --------- | ---------------------------------- | ------------------------ | ------------------------------------------------------------- |
| **#3255** | Track A/B split decision           | CLOSED                   | Source of truth for the two-track strategy                    |
| **#3571** | Track B tracking                   | OPEN                     | P2 implementation plan is its plan                            |
| **#3572** | CDN edge-resume                    | OPEN (parked)            | Phase 9                                                       |
| **#3865** | Lift RSC 19.0.x peer pin           | OPEN (umbrella)          | ✅ Peer-pin lift done; umbrella still tracks feature adoption |
| **#3885** | `cacheSignal` settle RSC cleanup   | **OPEN — current issue** | Phase 4 precondition                                          |
| **#3891** | Static export (SSG) on PPR shells  | OPEN                     | Post-PPR optimization                                         |
| **#4581** | Stream caches persist error chunks | OPEN                     | Track A risk                                                  |
| **#4607** | Post-17.0.0 roadmap                | OPEN                     | Frames PPR/perf work                                          |
| **#3485** | Turbo interaction                  | OPEN                     | Track A open question                                         |

---

## 9. Key Files to Know

### Planning Documents

| File                                                       | What                                                                                    |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `internal/planning/ppr-investigation-findings.md`          | Research findings — two-layer architecture, no RSC postpone, `"use cache"` is essential |
| `internal/planning/ppr-implementation-plan.md`             | Your 10-phase plan, validated by `ppr-from-scratch`                                     |
| `internal/planning/ppr-plan-validity-review-2026-07-12.md` | July 2026 validity review — both plans still valid, partial Phase 1-2 divergences       |
| `internal/planning/react-19-partial-prerendering-plan.md`  | Track A plan — streaming SSR + Rails fragment cache                                     |

### Reference Implementation

| Repo                                                 | What                                                                                                                                                                    |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `https://github.com/AbanoubGhadban/ppr-from-scratch` | Your ~1,000-line from-first-principles reimplementation. Validated: RSC round-trip, cache wrapper, CacheSignal coordination, two-pass prerender, Fizz prerender/resume. |

### Source Code (Pro package)

| Path                                                                    | What                                                            |
| ----------------------------------------------------------------------- | --------------------------------------------------------------- |
| `packages/react-on-rails-pro/src/cache/`                                | Cache infrastructure (unstable_cache, handlers, registry)       |
| `packages/react-on-rails-pro/src/pprServerRenderedReactComponent.ts`    | PPR spike (prerender + resume)                                  |
| `packages/react-on-rails-pro/src/streamServerRenderedReactComponent.ts` | Main streaming SSR — abort wiring lives here                    |
| `packages/react-on-rails-pro/src/streamingUtils.ts`                     | `cancelUpstream()`, `transformRenderStreamChunksToResultObject` |
| `packages/react-on-rails-pro/src/RSCRequestTracker.ts`                  | RSC payload lifecycle — known gap comment at line 295           |
| `packages/react-on-rails-pro/src/capabilities/proRSC.ts`                | RSC Flight rendering path                                       |
| `packages/react-on-rails-pro/src/capabilities/proStreaming.ts`          | Exposes PPR as Pro streaming capability                         |

### Ruby Side

| Path                                                                    | What                                          |
| ----------------------------------------------------------------------- | --------------------------------------------- |
| `react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb`           | `ppr_react_component` helper (lines 449+)     |
| `react_on_rails/lib/react_on_rails/react_component/render_options.rb`   | `:ppr_prerender` / `:ppr_resume` render modes |
| `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb` | JS code generation for PPR render modes       |

---

_This document is a point-in-time refresher. For the canonical plans, see the
planning documents listed above. For current issue status, check GitHub._
