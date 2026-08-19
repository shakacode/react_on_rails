# PPR Implementation Plan for React on Rails

**Status:** Planning — answers the open questions in §10 of
[`ppr-investigation-findings.md`](./ppr-investigation-findings.md). Closes #3315.

**Author:** Abanoub Ghadban
**Date:** 2026-05-20

---

## Overview

This document continues the work in
[`ppr-investigation-findings.md`](./ppr-investigation-findings.md) (PR #3314). It
answers the two open questions left at the end of that document — §10.1 (RSC
payload generation with PPR) and §10.2 (implementing `"use cache"`) — and
proposes how to bring the model into React on Rails Pro.

The plan was developed by investigating how other React frameworks make PPR
work end-to-end, reading the relevant source until every mechanism was
understood, and then **building a from-first-principles reimplementation in
plain Node.js** to validate that the mechanics described here actually work in
isolation, decoupled from any framework. The reimplementation, with a full
write-up and step-by-step parts, is at:

> **<https://github.com/AbanoubGhadban/ppr-from-scratch>**

That repository also includes a side-by-side cross-check against the framework
we studied: feeding the same input app into both implementations produces
byte-identical rendered output for the static shell (markup, Suspense
placeholders, client-component SSR) and structurally matching RSC encodings.
The plan below corresponds to validated, working mechanics rather than
speculation.

---

## Answer to §10.1 — RSC Payload Generation with PPR

### The key realization

The framework we studied **does not postpone or resume the RSC payload at all**.
The streaming RSC renderer has no postpone/resume API, and the static prerender
returns only `{ prelude }` with no postponed state. The RSC payload is
**re-rendered from scratch on every request**, and that is affordable only
because `"use cache"` turns every expensive subtree into a **pre-serialized RSC
byte blob that is replayed (`createFromReadableStream`) instead of
re-executed**. Confirmed both from source reading and by independent
reimplementation.

### Implications for React on Rails

- **Do not** attempt to invent partial RSC postpone/resume. The RSC binary
  format itself is the cache storage format; that is the right abstraction.
- The `"use cache"` mechanism is therefore _memoization keyed by arguments_,
  whose stored value is an RSC byte stream. Both cache hit and cache miss
  return a tree reconstructed via `createFromReadableStream`, so cached and
  freshly-rendered output are bit-identical.
- For the build / static-generation pass we use the **static prerender API**
  (`react-server-dom-webpack/static.prerender`) with an `AbortController`. The
  abort-based shell-carving model replaces the missing postpone/resume.

### Two-pass prerender

Static generation needs two passes with intentionally opposite timing
requirements:

1. **Prospective pass (unbounded).** Renders the tree purely to warm caches.
   Gated by a coordination signal (CacheSignal) that resolves only once every
   in-flight cache read settles and no new reads arrive within a full
   event-loop turn. Once the signal resolves, the pass is aborted and **its
   output is discarded**. Slow by design — it has to wait for real cache fills.
2. **Final pass (bounded).** Renders again with caches now warm. Aborted after
   a fixed task schedule (a small number of sequential `setTimeout(0)` calls,
   typically 4 macrotask windows). Whatever resolved within that window
   becomes the static shell / prelude; whatever was still suspended on
   dynamic-data hanging promises becomes a streaming hole. Warm cache reads
   resolve via already-fulfilled promises (microtask-fast), so every cacheable
   component resolves within the first rendering task. The fixed schedule is
   only safe **because** the Resume Data Cache is an in-process JavaScript
   `Map` — cross-process reads would take real wall-clock time and be missed
   by the task-schedule abort. (See §"Settle Criterion Design" for the
   empirical proof.)

A single bounded cold pass would lose cached content (the fill cannot finish
within the deadline). A single unbounded pass would deadlock on the hanging
dynamic boundaries. The two passes resolve the contradiction by splitting the
two jobs.

**The unclosing stream bridge.** Between the RSC pass and the HTML pass, the
collected RSC (Flight) stream is replayed as an "unclosing stream" — a
`ReadableStream` that delivers all buffered chunks but intentionally never
calls `controller.close()`. This prevents React from erroring on unresolved
Flight references (dynamic holes): missing chunks stay as pending thenables
that cause clean Suspense-style suspension rather than "connection closed"
errors. The HTML renderer then converts those suspensions into postponed
boundaries in the prelude. This is the mechanism that propagates dynamic holes
from the RSC layer to the HTML layer without loss of information.

### The coordination signal (a faithful port required)

Naive "settle as soon as the in-flight count hits zero" is incorrect — it
aborts the prospective pass before late-discovered caches start. The signal
needs exactly two rules:

1. **Deferred settle.** When the in-flight count hits zero, schedule a check
   via `setImmediate(() => setTimeout(cb, 0))` — a full event-loop turn — and
   only fire listeners if the count is still zero at that point.
2. **`beginRead` cancels any pending settle timer.** A newly discovered cache
   resets the readiness clock; the signal does not declare ready until a full
   turn passes with no new reads.

**Why two event-loop turns.** The deferred check uses `setImmediate` followed
by `setTimeout(0)` because React schedules follow-up rendering work in two
different ways: microtasks during prerender, and `setImmediate` during
rendering. When a cache read completes and React processes the result, it may
discover new components that start their own cache reads. The two-level timing
ensures those follow-on reads have time to call `beginRead()` before the
settle check fires. Empirically validated on React 19.2.8: a single
`setImmediate` also works for microtask-fast cache reads, but the extra
`setTimeout(0)` provides a safety margin for React's `setImmediate`-based
rendering scheduler.

**The cancellation dance.** When the count drops to zero and a settle timer is
scheduled, a subsequent `beginRead()` cancels the pending timer immediately.
When that new read's `endRead()` fires and count returns to zero, a fresh
timer is scheduled. This loop continues until no more reads start during the
settle window — only then does `cacheReady()` resolve.

**Two-tier resolution.** CacheSignal offers two resolution speeds:

- **`inputReady()`** — fast tier (`queueMicrotask(() => process.nextTick(…))`).
  Used to abort hanging promise inputs to cached functions when all cache
  inputs are ready. Fires quickly, essentially same-tick.
- **`cacheReady()`** — standard tier (`setImmediate(() => setTimeout(0))`).
  Used for the main prerender abort decision. The extra delay ensures React
  has fully processed resolved data before the settle check runs.

A separate process-global signal tracks **in-flight dynamic module loads**
(code-split chunks that may, when loaded, expose more caches). The prospective
prerender subscribes its cache signal to this module-loading signal via
`subscribeToReads()` so that slow lazy imports also hold readiness open.

**Module load subscription.** `subscribeToReads(subscriber)` adds the
per-render CacheSignal as a subscriber to the global module-loading signal.
Every `beginRead()`/`endRead()` on the global signal is forwarded to all
subscribers. On subscription, existing in-flight counts are transferred
(each already-pending read triggers a `beginRead()` on the subscriber). The
subscription auto-unsubscribes when `cacheReady()` resolves. This is the only
kind of "slow async" the prospective pass waits for; bare uncached I/O is
intentionally treated as a dynamic boundary (it becomes a streamed hole).

The full port of these two pieces is ~150 lines of plain JavaScript; see the
reference repo.

### Hanging promise for dynamic boundaries

During the prospective and final passes, the framework's request-time APIs
(`cookies()`, `headers()`, `searchParams`, uncached `fetch`) return a promise
that **never resolves** until the render's abort signal fires. The awaiting
component suspends. When the bounded final pass aborts after one task, those
suspended boundaries become Suspense placeholders in the prelude — no errors
thrown, abort gracefully turns them into holes.

The critical design property: **hanging promises are NOT tracked by
CacheSignal.** CacheSignal only counts work that will eventually resolve
(cache reads, module loads). Hanging promises are invisible to it. This is
what prevents deadlock: CacheSignal settles when all _resolvable_ work is
done, regardless of how many hanging promises are still pending.

For React on Rails this means two APIs:

1. **`makeHangingPromise(signal)`** — a helper that creates a promise which
   never resolves, only rejects when the abort signal fires. Used internally
   to implement dynamic-boundary markers.

2. **`connection()`** — a user-facing API that components call to declare
   "this component needs a real request." During prerender it returns a hanging
   promise (the component suspends, becoming a dynamic hole). At request time
   it returns immediately. This is the explicit opt-in to dynamic rendering.

   ```jsx
   async function UserGreeting() {
     await connection(); // ← hangs during prerender, no-op at request time
     const user = getCurrentUser();
     return <p>Hello, {user.name}!</p>;
   }
   ```

   Every Rails-side "request data" API (current_user, locale, session, params
   we want treated as dynamic) should be routed through `connection()` during
   the prerender phase. Components that call any of these APIs automatically
   become dynamic holes without the user needing to understand hanging
   promises.

---

## Answer to §10.2 — Implementing the `"use cache"` Directive

The directive requires four components, all needed together. None can be
omitted.

### 1. Build-time transform

The directive does not run at runtime; the compiler rewrites the function
body. Conceptually:

```js
// before
async function f(a, b) { "use cache"; ...body... }

// after the transform
const $$INNER = async function (a, b) { ...body... }
export var f = reactCache(function () {
  return cache("default", "<stable id>", boundArgsLen, $$INNER, [a, b])
})
registerServerReference(f, "<stable id>", null)
```

Details that must be reproduced:

- **`<stable id>`** is a content hash derived from `(salt, filename,
exportName)`. It must be stable across requests and stable across deploys of
  the same source. Same recipe as the framework we studied.
- **Closure-captured variables** are bound as a leading encrypted args array
  (the same encryption used for server-action bound args). This lets a closed-
  over outer value participate in the cache key without leaking secrets into
  client bundles.
- The transform detects directive variants (`"use cache: <kind>"`) and threads
  `<kind>` as the first argument to `cache(...)`, so a function can opt into a
  specific cache backend.

**For React on Rails:** integrate as a Babel and/or SWC plugin in the existing
Shakapacker/build pipeline — same hook used by other RSC transforms. The
transform itself is largely framework-agnostic; the harder work is plumbing it
into all of our supported build configurations.

### 2. Runtime cache wrapper

`cache(kind, id, boundArgsLen, fn, args)` does:

1. Build the cache key. The recipe is **`(buildId, id, encodeReply(args))`**,
   where `encodeReply` is the same wire-format encoder used to send Server
   Action arguments. This gives a deterministic, injective serialization of
   the arguments — including async/temporary references — that we can hash
   into a string.
2. Look up the cache handler for `kind` and call `handler.get(key)`.
   - On **HIT**, take `entry.value` (a `ReadableStream<Uint8Array>` of RSC
     bytes) and return `createFromReadableStream(stream, …)`.
   - On **MISS**, run `fn(...args)`, render its output via
     `renderToReadableStream` (or `prerender` during a prerender pass) to an
     RSC byte stream, `tee()` it — one branch goes to `handler.set(key,
pending)` for storage, the other goes to `createFromReadableStream` for
     immediate return.
3. **Single exit point.** Hit and miss both return through
   `createFromReadableStream`, so the value the caller sees is always
   byte-round-tripped. This guarantees identical behavior whether the cache is
   warm or cold and isolates the storage layer cleanly.

A second, in-memory **Resume Data Cache (RDC)** lives per-render. It is
microtask-fast and is what allows cached subtrees to resolve inside the final
pass's one-task abort window even when the cache handler itself does I/O.
Implement it as a `Map` populated during set/get; flush at request boundary.

### 3. Cache storage backend

A pluggable interface, looked up by **kind**:

```ts
interface CacheHandler {
  get(cacheKey: string, softTags: string[]): Promise<CacheEntry | undefined>;
  set(cacheKey: string, pendingEntry: Promise<CacheEntry>): Promise<void>;
  refreshTags(): Promise<void>;
  getExpiration(tags: string[]): Promise<number>;
  updateTags(tags: string[], durations?: { expire?: number }): Promise<void>;
}

interface CacheEntry {
  value: ReadableStream<Uint8Array>; // the cached RSC bytes
  tags: string[];
  timestamp: number; // ms since epoch
  stale: number; // client stale window (s)
  revalidate: number; // server revalidate window (s)
  expire: number; // hard expiry (s)
}
```

**Default in-memory handler:** a doubly-linked-list LRU keyed by `string`,
sized by total byte length (the entry's serialized RSC bytes are measured by
draining a `tee()`'d copy during `set`). O(1) `get` and `set`. Configurable
cap (default e.g. 50 MB). Stale-while-revalidate is **disabled** for in-memory
— past `revalidate` it is treated as missing. Port from the reference repo;
~120 lines.

**`ActiveSupport::Cache::Store` adapter:** a CacheHandler implementation that
delegates to any `Rails.cache` backend (Memcached, Redis, file store, custom).
This gives every existing React on Rails deployment a familiar, configurable
backend the day the feature ships. Sketch:

```ruby
# rails side
config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
```

```ts
// JS side adapter (runs in the renderer process or talks to Rails over IPC)
class ActiveSupportCacheHandler implements CacheHandler {
  async get(key, tags) {
    /* Rails.cache.read(key) */
  }
  async set(key, pending) {
    /* drain stream, Rails.cache.write(key, buf, expires_in: …) */
  }
  // tag manifest stored under reserved key prefix
}
```

The exact transport between the renderer and Rails cache (in-process when the
renderer runs embedded in Ruby; HTTP/Unix socket for the node-renderer model)
is a deployment concern.

**Handler registry:** kinds → handlers in a `Map<string, CacheHandler>`,
stored on a process-global symbol so it survives module duplication across
bundles (we already have several such global singletons; this fits cleanly).
Builtin kinds: `default` (in-memory LRU), `remote` (intended for shared
persistent storage; defaults to alias of `default` until configured). Users
add custom kinds via config.

### 4. CacheSignal coordination

Covered above (§10.1). The same `CacheSignal` and `trackPendingModules`
implementation drives both passes of the prerender.

### Cache invalidation: `cacheLife`, `cacheTag`, `revalidateTag`

- `cacheLife(profile | { stale, revalidate, expire })` mutates the current
  entry's lifetimes. Named profiles (`'seconds'`, `'minutes'`, `'hours'`,
  `'days'`) for ergonomics.
- `cacheTag('tag1', 'tag2', …)` attaches tags to the current entry; tags are
  stored alongside the entry in the handler.
- `revalidateTag('tag')` writes "tag X marked stale at <now>" into a tag
  manifest (stored in the same backend as entries). `cacheHandler.get` checks
  whether any of an entry's tags has a stale-timestamp newer than the entry's
  timestamp, and treats those entries as missing.
- `revalidatePath('/foo')` is a convenience: translates a path into an
  implicit tag that the route renderer attaches to its top-level entry.

**Rails integration:** expose a Ruby-side API to call `revalidateTag` from
controllers and background jobs:

```ruby
class ProductsController < ApplicationController
  def update
    Product.find(params[:id]).update!(product_params)
    ReactOnRails::Cache.revalidate_tag("product:#{params[:id]}")
    redirect_to ...
  end
end
```

This writes to the same tag manifest the JS-side renderer reads from. The
next request automatically recomputes any cached fragment tagged
`product:<id>`.

### Cache keys with Rails-specific context

The base recipe is `(buildId, function id, encodeReply(args))`. Per-user,
per-locale, per-tenant variants are accomplished by **passing the dynamic
value as an argument** to the cached function — not by reading it from a
global inside the cache. This is the recommended pattern in the framework we
studied, and the reimplementation validates it end-to-end (the included
`[slug]`-style demo proves distinct cache entries per distinct arg).

```tsx
async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; // dynamic in the outer wrapper
  return <CachedBySlug slug={slug} />;
}

async function CachedBySlug({ slug }: { slug: string }) {
  'use cache';
  cacheTag(`product:${slug}`);
  // … uses slug, but cookies/headers/etc. are forbidden here
}
```

We must **enforce** that request-scoped Rails globals (`Current.*`, `request`,
`I18n.locale`, etc.) are not read inside a `"use cache"` body. The reference
framework throws a hard error if `cookies()` / `headers()` / `searchParams` is
called inside a cache scope. We need the same guard for our Rails-side
equivalents — a small runtime check based on async-local-storage scope (we
already use AsyncLocalStorage for some request bookkeeping).

### Custom cache kinds

Mirror the kind registry from the reference. Default kinds:

- `default` — in-memory LRU per process. Good for short-lived data and
  single-instance deploys.
- `remote` — intended for shared persistent storage across replicas. Until a
  custom handler is configured, defaults to the in-memory LRU.

Users register custom kinds in config:

```js
module.exports = {
  cacheHandlers: {
    default: require.resolve('./my-memory-handler.js'),
    remote: require.resolve('./my-redis-handler.js'),
    products: require.resolve('./my-products-cache.js'),
  },
};
```

And opt into them per cached function:

```tsx
async function getProducts() {
  'use cache: products';
  // …
}
```

---

## HTML Generation and Resume

The HTML stream **does** use real React postpone/resume — distinct from the
RSC layer.

- **Build / static generation.** `react-dom/static.prerender(element, {
signal })` returns `{ prelude, postponed }`. We persist the prelude (the
  static shell HTML) and the serialized `postponed` blob as **paired
  artifacts**. They must update together; serving a new shell with an old
  postponed state corrupts the resumed continuation.
- **Request time.** `react-dom/server.resume(element, postponed)` continues
  the Fizz render at the point it stopped, emitting only the dynamic
  continuation. A freshly-rendered per-request RSC stream feeds the `<App>`
  root that the SSR pass consumes via `createFromReadableStream`. The static
  shell is served from cache; the resumed tail is appended in the same HTTP
  response.

### HTML pass settle criterion

The HTML/Fizz prerender uses the same task-schedule abort as the RSC final
pass — a fixed sequence of macrotasks (typically 2: start the prerender, then
abort). This is safe because the HTML pass's input — the RSC Flight stream —
is already fully produced and buffered. There are no pending data reads. React
DOM's `prerender()` is just converting the Flight data to HTML: resolved
subtrees become markup, unresolved Flight chunks (propagated via the unclosing
stream) become postponed Suspense boundaries in the prelude.

**What CacheSignal tracks in the HTML pass.** The HTML pass sets
`cacheSignal: null` — cache tracking is not needed because all caches are
warm. The only tracked activity is **module/chunk loading**: client component
references in the Flight stream trigger chunk loads during SSR, and those are
tracked by a separate per-pass CacheSignal dedicated to module loading. This
prevents aborting the HTML pass while client component modules are still being
loaded and evaluated.

**Client component async work is untracked.** If a React 19 async client
component does async work during SSR (e.g., `await` expressions in the
component body), that work is invisible to any CacheSignal. If it doesn't
resolve within the task-schedule window, it becomes a dynamic hole. This is
correct behavior — client component async work is expected to complete during
hydration on the client.

Treat `postponedState` as **opaque** — never parse, never modify. It is a
React-internal serialization of the postponed Fizz state.

A second case exists where the build's prerender already emits a complete HTML
document and only the inlined RSC needs to be appended at request time (the
"dynamic data, static shell" case). The reference framework calls these two
modes `DynamicState.HTML` (resume required) and `DynamicState.DATA` (just
inline fresh RSC + `</body></html>`). We should support both — they map
naturally to "any HTML-phase dynamism present" vs "only RSC-phase dynamism."

### Inlining the per-request RSC

The freshly-rendered RSC must be inlined into the HTTP response as a sequence
of script chunks that the client-side React runtime can consume to hydrate +
support client navigation. We already have inlined-payload infrastructure;
this maps directly to the framework's mechanism.

### CDN integration (optional, advanced)

The shell + postponed pair can be cached at the CDN edge so the visitor sees
the shell at edge latency, while the CDN issues a `POST` to the origin
containing the postponed state as the body. The origin returns only the
resumed continuation, which the CDN streams into the same response body after
the shell.

Recommended:

- Define a small, explicit "resume" HTTP protocol on our Rails endpoint: a
  POST with a marker header (e.g. `X-RoR-Resume: 1`) and the opaque
  postponedState as the body. The origin returns the resume continuation as a
  streaming HTML response.
- Provide a reference Cloudflare Workers adapter (the user's deployment target
  of interest) that implements this on top of the standard Workers Streams
  API: read shell from KV/R2 → start streaming → `fetch(origin, POST + body)`
  → pipe into the same response.
- The Rails origin stays stateless w.r.t. postponed state — it receives it on
  every resume request body.

---

## Reference Implementation

All mechanisms described above are validated in
**<https://github.com/AbanoubGhadban/ppr-from-scratch>**, a ~1,000-line
reimplementation in plain Node.js using only React + `react-server-dom-webpack`

- `react-dom`. It includes:

* RSC tree ⇄ bytes round-trip (`renderToReadableStream` /
  `createFromReadableStream`).
* A hand-written `cache(id, fn)` wrapper with the `(buildId, id, args)`-keyed
  cache, both in-memory and on-disk handler examples.
* A faithful port of the coordination signal (deferred settle, `beginRead`
  cancels timer) and module-load tracking.
* The two-pass prerender (prospective + final) with abort-based shell
  carving.
* The HTML/Fizz layer: `react-dom/static.prerender` →
  `{ prelude, postponed }`; `react-dom/server.resume` → continuation.
* Client component references with a hand-rolled bundler manifest.
* A demo app that exercises every case: static, sync, cached sibling, cached
  leaf behind plain async, client component nested in a cached server
  component.

The README walks through the build in seven Parts, each with runnable
commands and expected output. The repo also documents the empirical
cross-check against the framework we studied — byte-identical rendered output
for the static shell, structurally matching RSC encoding (import rows + lazy
refs), and identical per-request behavior under counters and timing.

---

## Settle Criterion Design

> **Evidence base.** This section is backed by source-code analysis of the
> Next.js canary (August 2026) and 15 empirical experiments run on React
> 19.2.8. The findings are documented in full at:
>
> - [`internal/analysis/ppr-settle-criterion-findings.md`](../analysis/ppr-settle-criterion-findings.md)
> - [`internal/analysis/ppr-settle-by-example.md`](../analysis/ppr-settle-by-example.md)
> - [`internal/analysis/ppr-rsc-payload-by-example.md`](../analysis/ppr-rsc-payload-by-example.md)

### The core problem

When React prerenders a page, it needs to render as much of the static shell
as possible, then stop and leave holes for dynamic content. React provides one
control: the abort signal. **React never tells the framework "I'm done with
all static work."** There is no `onAllStaticWorkComplete()` callback. The
framework must decide when to fire the signal.

Aborting too early produces a shallower shell (the user sees coarse spinners
instead of fine-grained skeletons). Aborting too late deadlocks on hanging
promises. Both failures are silent — the output is valid HTML, just worse.

### The three abort points

| #   | Abort point              | Settle criterion           | Mechanism                          | Window                         |
| --- | ------------------------ | -------------------------- | ---------------------------------- | ------------------------------ |
| 1   | **RSC prospective pass** | `CacheSignal.cacheReady()` | Reference counter + deferred check | Until all tracked work settles |
| 2   | **RSC final pass**       | `runInSequentialTasks`     | Fixed task schedule                | ~4 macrotask turns             |
| 3   | **HTML/Fizz prerender**  | `runInSequentialTasks`     | Fixed task schedule                | ~2 macrotask turns             |

The prospective pass is the only one with an open-ended wait. The final pass
and HTML pass use fixed schedules because their inputs are already resolved
(warm caches / complete Flight stream respectively).

### User-facing APIs

Two user-facing APIs form the contract between application code and the settle
criterion:

#### `cacheRead(fn)` — "wait for this before aborting"

A wrapper function that users place around any async work they want the
framework to wait for. Internally calls `beginRead()` before the work starts
and `endRead()` when it settles:

```jsx
import { cacheRead } from 'react-on-rails-pro';

async function ProductList() {
  const products = await cacheRead(() => db.query('SELECT * FROM products'));
  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  );
}
```

Without this wrapper, async work is invisible to the settle criterion and may
be aborted prematurely, causing the component's entire subtree to fall behind
the nearest ancestor Suspense boundary's fallback.

**Why explicit wrapping is needed.** Unlike Next.js, which uses a compiler
transform (`"use cache"` directive) to inject `beginRead()`/`endRead()`
automatically, and monkey-patches `fetch()` to track it, React on Rails does
not have a compiler transform for this purpose. The explicit wrapper is the
equivalent mechanism without requiring SWC/Babel integration. If we later add
a `"use cache"` directive with compiler support, the wrapper becomes its
compiled output — the runtime mechanism is the same.

**What `cacheRead` does.** `cacheRead` is both a **tracker** and a **caching
wrapper**. It calls `beginRead()` before the work starts, executes `fn`,
stores the result in the Resume Data Cache (RDC) keyed by a stable identifier,
and calls `endRead()` when the work settles. On subsequent calls with the same
key, it returns the cached result from the RDC instead of re-executing `fn`.

If `fn` does multiple internal awaits, they are all covered by the single
`beginRead()`/`endRead()` pair. Nested `cacheRead()` calls are also
supported — each gets its own pair, and the settle criterion waits for all of
them.

**Interaction with the two-pass system.** During the prospective pass,
`cacheRead` registers the work with CacheSignal and populates the RDC with the
result. During the final pass, `cacheSignal` is null — `cacheRead` reads from
the already-populated RDC, returning an already-fulfilled promise
(microtask-fast). This is what makes the final pass's fixed task-schedule
abort safe: every `cacheRead` call resolves within a microtask because the
data is already in the in-process RDC.

**Relationship to `"use cache"`.** `cacheRead` is the runtime primitive that
`"use cache"` compiles down to. The `"use cache"` directive adds build-time
key derivation (stable ID from filename + export name), argument serialization
via `encodeReply`, and storage via the full `CacheHandler` interface.
`cacheRead` is a simpler entry point for users who need tracking without the
full `"use cache"` infrastructure — it uses the RDC directly with a
user-provided or auto-derived key.

#### `connection()` — "this component needs a real request"

A function that components call to declare themselves dynamic. During
prerender it returns a hanging promise; at request time it returns
immediately:

```jsx
import { connection } from 'react-on-rails-pro';

async function UserProfile() {
  await connection(); // hangs during prerender → dynamic hole
  const user = await getCurrentUser();
  return <div>{user.name}</div>;
}
```

**Design properties:**

- The hanging promise is **NOT** tracked by CacheSignal. It is invisible to
  the settle criterion. This is what prevents deadlock.
- At request time, `connection()` resolves immediately (a no-op).
- Every Rails-side request-data API (`current_user`, `session`, `locale`,
  `request`, etc.) should internally call `connection()` so that components
  using them automatically become dynamic holes.

### Tracked vs untracked work

| Async operation                               | Tracked by CacheSignal?              | Makes it into the shell?   |
| --------------------------------------------- | ------------------------------------ | -------------------------- |
| `await cacheRead(() => ...)`                  | ✅ Yes                               | ✅ Yes — CacheSignal waits |
| `await cachedFunction()` (with `"use cache"`) | ✅ Yes                               | ✅ Yes                     |
| Module/chunk loads (`import()`, `React.lazy`) | ✅ Yes (module loading subscription) | ✅ Yes                     |
| `await connection()`                          | ❌ No (by design)                    | ❌ No — becomes a hole     |
| `await rawFetch(url)` (untracked)             | ❌ No                                | ⚠️ Only if microtask-fast  |
| `await db.query()` (untracked)                | ❌ No                                | ⚠️ Only if microtask-fast  |
| Client component async during SSR             | ❌ No                                | ⚠️ Only if microtask-fast  |
| Third-party `throw promise` / `React.use(p)`  | ❌ No                                | ⚠️ Only if microtask-fast  |

**The "microtask-fast" cutoff.** Untracked async work that resolves via
`Promise.resolve()` (already-fulfilled promise) always makes it into the shell
because React processes resolved promises via microtasks, which run before any
macrotask. Untracked work that takes real wall-clock time (≥5ms) is missed by
the task-schedule abort. This was proven in experiments 7–9.

**The gap users need to understand.** Any raw `await` without `cacheRead()`
wrapping is a gamble on timing. If it resolves within a microtask, it works.
If it takes real time (database query, network call, cross-process
communication), it's missed and the component becomes a dynamic hole. The
documentation must make this clear.

### Budget and escape hatch

A hard timeout cap prevents pathological applications from stalling builds:

```js
const settled = await Promise.race([
  cacheSignal.cacheReady(),
  timeout(SETTLE_TIMEOUT_MS).then(() => 'TIMEOUT'),
]);

if (settled === 'TIMEOUT') {
  log.warn('Prerender settle timeout — aborting with partial shell');
}
controller.abort();
```

When the timeout trips, the result is a shallower shell (more dynamic holes),
not a build failure. The page still works — it just has more content streaming
in dynamically. The timeout should be configurable, with a sensible default
(e.g., 10 seconds for the prospective pass). Note: the findings doc uses 5s
in its illustrative code snippet; the actual default is an implementation
decision for #3571 — the key property is that the timeout exists, is
configurable, and degrades gracefully rather than failing the build.

### Determinism

A timing-based settle criterion introduces non-determinism: the same page
might produce different shells on different builds if component resolution
times vary. Three constraints ensure determinism:

1. **The Resume Data Cache must be in-process** (a JavaScript `Map`). This
   guarantees that final-pass cache reads resolve via already-fulfilled
   promises (microtask-fast), making the task-schedule abort deterministic.
   Cross-process reads (Node → Ruby via HTTP) would introduce timing
   variation.

2. **The settle criterion must be event-driven** (CacheSignal), not
   time-based. CacheSignal fires when all tracked work finishes, regardless
   of how long it took. Two runs with different wall-clock timings produce
   the same settle point as long as the same work is tracked.

3. **Build validation.** Prerender the same page twice and diff the shells.
   If the shell differs between runs, it indicates non-deterministic async
   work leaking into the prerender. This can be automated as a CI check.

### Ordering constraint

The `postponed` state must be serialized only **after** the prelude has fully
flushed (see react#36779 and P6 spike finding #3). Any settle design must
preserve this: abort the React render first, collect the prelude, then
serialize `postponed`.

---

## Implementation Phasing

Each phase ends with tests + a working demo and can be merged independently.

| #   | Scope                                                                                                                                                 | Rough effort |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| 1   | `CacheHandler` interface + default in-memory LRU + `ActiveSupport::Cache` adapter                                                                     | ~2 weeks     |
| 2   | Runtime `cache()` wrapper: key derivation, single-exit hit/miss, Resume Data Cache                                                                    | ~2 weeks     |
| 3   | Build-time `"use cache"` transform (Babel/SWC): directive detection, stable id, wrapper emission, server-reference registration, bound-arg encryption | ~3 weeks     |
| 4   | Coordination signal + module-load tracking + two-pass prerender driver                                                                                | ~2 weeks     |
| 5   | Hanging-promise plumbing for Rails request-time APIs (current_user, locale, session, request)                                                         | ~2 weeks     |
| 6   | HTML/Fizz prerender + resume integration; postponed-state serialization; atomic shell+state storage                                                   | ~3 weeks     |
| 7   | `cacheLife` / `cacheTag` / `revalidateTag` API + tag manifest + Ruby-side invalidation calls                                                          | ~2 weeks     |
| 8   | Client-reference threading through the cache wrapper (bundler manifest plumbing)                                                                      | ~1 week      |
| 9   | CDN resume HTTP protocol + reference Cloudflare Workers adapter                                                                                       | ~2 weeks     |
| 10  | Documentation, examples, migration guides                                                                                                             | ~2 weeks     |

Total rough order of magnitude: **~6 months** end-to-end, parallelizable to
**~3 months** with two engineers (one focused on build/transform, one on
runtime/cache/coordination).

---

## Risks and Tradeoffs

- **Build toolchain reach.** A Babel and/or SWC plugin that runs reliably
  across all our supported build configurations (Shakapacker, Vite, the
  existing RSC compiler) is non-trivial. Stage rollout behind a feature flag.
- **Cache cardinality.** Passing high-cardinality values (full request body,
  per-user IDs at scale) as cached-function arguments inflates the cache.
  Document the patterns; consider lint warnings for suspicious arg shapes.
- **Out-of-band data changes.** `revalidateTag` only catches mutations that
  the app performs. Database changes from outside the app (scripts, other
  services, scheduled jobs) require relying on `cacheLife` bounds.
- **HTML/RSC value divergence.** Non-deterministic reads inside _non-cached_
  server components on a PPR page cause a divergence between the built-once
  static HTML and the per-request fresh RSC — yielding a hydration mismatch
  for that subtree. We must implement a build-time guard similar to the
  reference framework's (block `Date.now` / `Math.random` /
  `crypto.randomUUID` in prerendered subtrees, with an opt-out for legitimate
  uses). Note that `performance.now()` slips through the reference framework's
  guard today; we should treat it the same way to start, but consider
  extending coverage to it later.
- **Two-graph requirement.** RSC and HTML render in different module graphs
  (one with the `react-server` condition, one without). Our existing RSC
  setup already handles this, but the `"use cache"` storage layer must work
  across both graphs (serialize on the server graph, deserialize on either).
- **Migration ergonomics.** Existing Rails fragment caching and Russian-doll
  caching patterns do not map 1:1 to RSC-bytes caching. Plan migration
  recipes alongside the docs.
- **Persistent storage atomicity.** Shell HTML + postponed blob must be
  written atomically. For Redis/Memcached backends, either store them as a
  single record (e.g., one Redis hash per route) or accept the consistency
  window with documented mitigation.

---

## References

- [`internal/planning/ppr-investigation-findings.md`](./ppr-investigation-findings.md)
  (PR #3314) — the upstream investigation this plan builds on.
- Reference implementation:
  <https://github.com/AbanoubGhadban/ppr-from-scratch>
- Settle criterion research (PR #4852):
  - [`internal/analysis/ppr-settle-criterion-findings.md`](../analysis/ppr-settle-criterion-findings.md)
    — Next.js CacheSignal mechanism analysis + experiment results
  - [`internal/analysis/ppr-settle-by-example.md`](../analysis/ppr-settle-by-example.md)
    — component-level "if you write this, you get that" patterns
  - [`internal/analysis/ppr-rsc-payload-by-example.md`](../analysis/ppr-rsc-payload-by-example.md)
    — RSC payload lifecycle in the PPR pipeline
- Closes #3315.
