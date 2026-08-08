# How Next.js Decides When to Stop Prerendering (PPR Settle Criterion)

**Research for [#4852](https://github.com/shakacode/react_on_rails/issues/4852)** — findings from Next.js source code analysis + empirical validation on React 19.2.8.

---

## Part 1: The Practical Picture

### The Problem in One Sentence

When you prerender a page with Partial Prerendering (PPR), React needs to render
as much of the static shell as possible, then _stop_ and leave "holes" for
dynamic content. The question is: **when exactly should it stop?**

### Why Getting It Wrong Is Bad

There are two failure modes, and they're both silent:

**Abort too early** → You get a shallower shell than you could have. Imagine a
page layout like this:

```
┌────────────────────────────────┐
│ Header (sync — always static)  │
├────────────────────────────────┤
│ Layout (async — loads in 20ms) │
│ ┌────────────┬───────────────┐ │
│ │ Sidebar    │ Content       │ │
│ │ (sync)     │ (async 40ms)  │ │
│ │            │ ┌───────────┐ │ │
│ │            │ │ Comments  │ │ │
│ │            │ │ (async)   │ │ │
│ │            │ │ ┌───────┐ │ │ │
│ │            │ │ │Replies│ │ │ │
│ │            │ │ │(dyn.) │ │ │ │
│ │            │ │ └───────┘ │ │ │
│ │            │ └───────────┘ │ │
│ └────────────┴───────────────┘ │
├────────────────────────────────┤
│ Footer (sync — always static)  │
└────────────────────────────────┘
```

If you abort _before_ the Layout component finishes loading, the entire middle
section shows a spinner ("Loading..."). The user sees Header + spinner + Footer.

If you abort _after_ Layout finishes but before Content and Comments resolve,
the user sees Header + Layout + Sidebar + "Content loading..." + Footer.

If you wait for _everything_ to resolve (Layout → Content → Comments) and then
abort, the user sees the complete page with only the tiny Replies section as a
dynamic hole. This is vastly better for LCP/TTFB — the user sees the whole page
structure instantly.

**Abort too late** → You never abort at all. Dynamic content (like user-specific
replies) is backed by promises that _never resolve_ during prerender. If the
abort criterion waits for "no pending work" without understanding that some
promises are deliberately hanging, you get a deadlock. The prerender hangs
forever.

### What Next.js Actually Does: A Two-Pass System

Next.js solves this with a two-pass prerender:

**Pass 1: "Fill the caches"** (called the _prospective_ prerender)

Think of it like a dry run. Next.js renders your entire component tree, letting
every `"use cache"` function, `fetch()` call, and async component run to
completion. The goal is purely to fill caches — the HTML output is thrown away.

The key mechanism is a **counter** called `CacheSignal`:

- Every time a cache read starts → counter goes up
- Every time a cache read finishes → counter goes down
- When the counter hits zero and _stays at zero_ for a brief window → all caches
  are filled

Only _after_ all caches are filled does Next.js abort this pass.

**Pass 2: "Render with warm caches"** (called the _final_ prerender)

Now Next.js renders again, but this time all the cache data is already available.
Async components that read from cache resolve instantly (within a microtask).
This pass uses a strict task-based schedule:

1. **Task 1**: Start the render. React runs one rendering "work unit."
2. **Task 2**: Advance to the "Static" stage (static params become available).
3. **Task 3**: Collect metadata.
4. **Task 4**: **Abort.** Whatever is still pending becomes a dynamic hole.

Because the caches are warm, every cacheable component resolves within the first
task. The only things still pending at abort time are genuinely dynamic
(hanging promises for `cookies()`, `headers()`, user-specific data).

### Concrete Example

Here's a page with three levels of async components:

```jsx
// app/page.tsx
export default async function Page() {
  return (
    <div>
      <Header /> {/* sync — always in shell */}
      <Suspense fallback={<Spinner />}>
        <ProductLayout>
          {' '}
          {/* async — loads categories from cache */}
          <Sidebar /> {/* sync child */}
          <Suspense fallback={<ContentSkeleton />}>
            <ProductList>
              {' '}
              {/* async — loads products from cache */}
              <Suspense fallback={<ReviewsSkeleton />}>
                <UserReviews /> {/* dynamic — needs user session */}
              </Suspense>
            </ProductList>
          </Suspense>
        </ProductLayout>
      </Suspense>
      <Footer /> {/* sync — always in shell */}
    </div>
  );
}
```

**Pass 1** renders the whole tree. `ProductLayout` fetches categories (20ms),
`ProductList` fetches products (40ms). Both results get cached. CacheSignal
counts: 1→2→1→0. After `setImmediate + setTimeout(0)`, count is still 0 →
settled. Pass 1 aborts. HTML is discarded.

**Pass 2** renders again. `ProductLayout` reads from cache → resolves instantly.
React renders its children in the same microtask. `ProductList` reads from cache
→ resolves instantly. React descends to `UserReviews` which reads `cookies()` →
gets a hanging promise (deliberate). React shows the `<ReviewsSkeleton />`
fallback. After 4 tasks, abort fires. Output: the full page with only
`<ReviewsSkeleton />` as a placeholder.

Result: the user instantly sees the complete page layout, sidebar, product list,
and a skeleton where reviews will stream in.

### The Key Insight: Tracking vs Not Tracking

The critical difference between the two passes is **whether async work is
tracked**:

|                    | Pass 1 (Prospective)     | Pass 2 (Final)         |
| ------------------ | ------------------------ | ---------------------- |
| **Cache tracking** | Yes — CacheSignal        | None — caches are warm |
| **Abort trigger**  | CacheSignal settles      | Fixed task schedule    |
| **Dynamic APIs**   | Keep rendering past them | Abort on encounter     |
| **Purpose**        | Fill caches              | Produce output         |

This means: **if your async component does I/O that doesn't go through a tracked
channel (cache, fetch, module load), the framework cannot see it, and a bare
task-schedule abort will miss it.**

### What Does "Settled" Actually Mean?

The settle detection uses a two-level deferred check:

```
When count drops to 0:
  → Schedule a setImmediate callback
    → Inside that, schedule a setTimeout(0) callback
      → If count is STILL 0: settled! Fire the signal.
      → If count went back up: cancel, wait for next 0.
```

**Why two levels?** React schedules new rendering work in different ways:

- During prerender, React uses **microtasks** to schedule follow-up work
- During normal rendering, React uses **setImmediate**

By waiting through both a `setImmediate` and a `setTimeout(0)`, the settle check
ensures React has had a chance to process the resolved data and discover new
components that might need their own cache reads.

**In practice**: when `ProductLayout` finishes loading and React renders its
children, React might discover that `ProductList` needs to start its own cache
read. If the settle check fired too early (right when `ProductLayout`'s read
finished), it would miss `ProductList` entirely.

### Empirical Proof

We ran 8 experiments on React 19.2.8 to verify this:

**Experiment 1 — Fallback Reachability**: An outer async component (50ms) wraps
an inner Suspense boundary backed by a hanging promise.

- Abort at 0ms → shows "Loading outer..." (outer's coarser fallback — **bad**)
- Abort at 100ms → shows "Loading inner..." (inner's own fallback — **good**)
- The difference is whether the framework waited for the outer component to
  resolve, revealing the inner boundary.

**Experiment 3 — Complex Nested Tree**: Header/Layout/Sidebar/Content/Comments/
Replies with 4 Suspense boundaries at different depths.

- Abort at 5ms → only "Main loading..." (everything behind outer spinner)
- Abort at 30ms → Layout+Sidebar visible, "Content loading..." shown
- Abort at 80ms → Content visible, "Comments loading..." shown
- Abort at 150ms → Everything visible, only "Replies loading..." as the hole

Each level of async resolution reveals one more Suspense boundary's own fallback.

**Experiment 4 — CacheSignal Simulation**: Three levels of tracked async
components (30ms each). CacheSignal correctly waits through all three:

```
L1.beginRead → L1.endRead → [settle check cancels because:]
L2.beginRead → L2.endRead → [settle check cancels because:]
L3.beginRead → L3.endRead → [setImmediate+setTimeout → SETTLED]
```

Result: all three levels rendered, deep fallback shown. ✓

**Experiment 8 — Untracked I/O** (the critical finding):

- **Without tracking**: bare `setImmediate` abort → premature abort, shows outer
  fallback. The cross-process reads (20ms each) were invisible to the framework.
- **With CacheSignal tracking**: waits for both reads, shows deep fallback. ✓

This experiment proves that **a bare timing-based abort is not sufficient when
components do real I/O.** You need explicit tracking of in-flight work.

---

## Part 2: The Three Abort Points

Now let's look at the three distinct abort points in a PPR prerender and what
signal each one should use.

### Abort Point 1: RSC Prospective Pass

**When**: During `next build` or ISR revalidation, the first render of the React
Server Components tree.

**Purpose**: Fill all caches so the final pass can read them synchronously.

**Settle criterion**: `CacheSignal.cacheReady()` — a reference-counting signal
that tracks every `beginRead()`/`endRead()` pair across:

- `"use cache"` function calls
- `fetch()` calls (the patched version)
- `unstable_cache` calls
- Dynamic `import()` / chunk loads (via module loading subscription)
- Server Action argument decryption

**How it works in practice**:

```
Component render starts
  → fetch('/api/products') → beginRead() [count=1]
  → "use cache" getData() → beginRead() [count=2]
  → fetch completes → endRead() [count=1]
  → getData() completes → endRead() [count=0]
  → schedule setImmediate → schedule setTimeout(0) → count still 0?
    → YES → cacheReady() resolves
    → Abort React render
```

If a just-completed cache read causes React to render a new component that
starts another cache read, the cycle restarts:

```
  → endRead() [count=0]
  → schedule setImmediate
  → React processes result, renders child, child calls fetch()
  → beginRead() [count=1] → cancels pending setImmediate
  → ... eventually count=0 again → new settle check
```

**The deferred check prevents a specific race**: when `endRead()` fires, React
hasn't yet processed the resolved promise. It will do so in a microtask (during
prerender) or `setImmediate` (during rendering). The `setImmediate + setTimeout`
window guarantees React's follow-up rendering has happened before the settle
check runs.

### Abort Point 2: RSC Final Pass

**When**: After all caches are warm, the second render that produces the actual
RSC Flight stream.

**Purpose**: Produce the static Flight data, with dynamic holes for anything
that can't be prerendered.

**Settle criterion**: Task-schedule-based via `runInSequentialTasks`. Each
function in the sequence runs in its own macrotask (`setTimeout(0)`). The abort
fires in the last task, unconditionally.

**Why this works**: All caches are warm from Pass 1. Cache reads resolve via
already-fulfilled promises (microtask-fast). React processes them within a single
rendering task. By the time the abort fires (task 4), every cacheable component
has resolved.

**What it assumes**: Warm cache reads resolve within a microtask. This is true
when the cache is in-process (a JavaScript Map or similar). It is **NOT
guaranteed** when cache reads cross a process boundary (e.g., an HTTP call to
a Ruby process to read from ActiveSupport::Cache).

**Relevant for react_on_rails**: If our Resume Data Cache adapter crosses a
process boundary (Node → Ruby via HTTP/Unix socket), the final pass's
single-task window may not be enough. The prospective pass fills the cache, but
the final pass reads from it, and those reads might take real wall-clock time
if they're not in-process. This is safe only if the RDC is an in-process
JavaScript cache (which is the plan).

### Abort Point 3: HTML/Fizz Prerender

**When**: After the RSC Flight stream is produced, it's consumed by React DOM's
`prerender()` to produce the HTML shell.

**Purpose**: Convert the Flight data to HTML, with `postponed` state for dynamic
holes.

**Settle criterion**: Same task-schedule pattern:

```
Task 1: Start React DOM prerender (pass the Flight stream + signal)
Task 2: Abort the React DOM render
```

Two tasks, one macrotask window. The Flight stream is already fully produced, so
there are no pending data reads. Any postponed boundaries become `postponed`
state that React DOM returns alongside the HTML prelude.

**Why this is safe**: The Flight stream is complete. React DOM is just converting
it to HTML. All the async resolution happened in the RSC passes. React DOM's
prerender processes the Flight data, emits HTML for resolved subtrees, and emits
`<template>` placeholders for postponed boundaries.

---

## Part 3: CacheSignal Deep Dive

### The Reference Counter

At its core, CacheSignal is a counter:

```
beginRead() → count++, cancel any pending settle timer
endRead()   → count--, if count==0 schedule settle check
```

It's conceptually identical to a "pending work" semaphore. The subtle part is the
settle check timing.

### The Two-Tier Settle Check

CacheSignal has two resolve speeds:

**Fast tier: `inputReady()`** — `queueMicrotask(() => process.nextTick(...))`

Used to abort hanging promise inputs to cached functions. When all cache reads
have their inputs ready, there's no point keeping hanging promises alive. This
fires quickly (microtask + nextTick ≈ same tick, just after current microtask
queue drains).

**Standard tier: `cacheReady()`** — `setImmediate(() => setTimeout(0))`

Used for the main prerender abort decision. Fires after two event-loop turns:

1. `setImmediate` runs after I/O callbacks but before timers
2. `setTimeout(0)` runs in the next timer phase

The two-level design covers both scheduling strategies React uses internally:
React schedules prerender follow-up work via microtasks, and rendering follow-up
work via `setImmediate`. By waiting past both, CacheSignal ensures React has
fully processed any resolved data before declaring settlement.

### Module Loading Integration

Dynamic `import()` calls are also tracked. A global `moduleLoadingSignal` (itself
a CacheSignal) tracks all chunk loads. Per-render CacheSignals subscribe to it
via `subscribeToReads()`:

```
Global moduleLoadingSignal
  ├── beginRead() for import('./ProductList.js')
  ├── propagates to → Per-render cacheSignal.beginRead()
  │
  ├── Chunk loads, module evaluates
  ├── endRead()
  └── propagates to → Per-render cacheSignal.endRead()
```

This prevents aborting while modules are still loading — a loading module might
contain a component that reads from cache.

### The Cancellation Dance

When a new `beginRead()` arrives while a settle timer is pending:

```
endRead()      → count=0 → schedule setImmediate (timer A)
beginRead()    → count=1 → CANCEL timer A
endRead()      → count=0 → schedule setImmediate (timer B)
[no more reads]
setImmediate B → schedule setTimeout C
setTimeout C   → count still 0 → SETTLED
```

This is crucial: without cancellation, the first `setImmediate` would fire while
count was 1 (because the second read started before the timer ran), and either
incorrectly settle or require complex count-checking.

---

## Part 4: Hanging Promises — How Dynamic Holes Work

### The Mechanism

Dynamic content in Next.js doesn't use `React.postpone()` (that's the legacy
PPR path). The modern path uses **hanging promises**: promises that never resolve.

When a server component calls a dynamic API:

```
// Inside cookies() implementation
if (prerenderStore.type === 'prerender') {
  return makeRuntimeHangingPromise(renderSignal, error);
}
```

`makeRuntimeHangingPromise` returns:

```javascript
new Promise((_, reject) => {
  signal.addEventListener('abort', () => reject(error), { once: true });
});
```

This promise never resolves. React sees it, suspends at the nearest Suspense
boundary, and renders the fallback. The Suspense boundary becomes a dynamic hole.

When the prerender eventually aborts (via the abort signal), the hanging promise
rejects, and React knows to finalize that boundary as a "postponed" placeholder.

### Hanging Promises vs Real Async Work

The system distinguishes between "work that will finish" and "work that should
never finish during prerender" through what gets tracked:

| Type                            | Tracked by CacheSignal?   | Resolves during prerender? |
| ------------------------------- | ------------------------- | -------------------------- |
| `fetch('/api/data')` with cache | ✓ Yes (beginRead/endRead) | Yes                        |
| `"use cache"` function          | ✓ Yes                     | Yes                        |
| `import('./Component')`         | ✓ Yes (module loading)    | Yes                        |
| `cookies()`                     | ✗ No                      | No (hanging promise)       |
| `headers()`                     | ✗ No                      | No (hanging promise)       |
| `searchParams`                  | ✗ No                      | No (hanging promise)       |
| `connection()`                  | ✗ No                      | No (hanging promise)       |

The CacheSignal only counts tracked work. Hanging promises are invisible to it.
So when CacheSignal says "settled," it means "all the work that _can_ resolve has
resolved." The hanging promises are still hanging, but that's correct — they're
the dynamic holes.

---

## Part 5: What This Means for React on Rails

### The Core Design Decision

React on Rails needs to answer: **which of our async operations need tracking,
and which are deliberate hanging promises?**

In Next.js, the answer is clean because all cacheable work flows through
framework-controlled channels (`fetch`, `"use cache"`, `import()`). The framework
intercepts each one and brackets it with `beginRead()`/`endRead()`.

For react_on_rails, the tracked operations should be:

1. **Resume Data Cache reads** — equivalent to Next.js's `"use cache"` reads
2. **Module/chunk loads** — same as Next.js
3. **Any other framework-controlled async** — e.g., our own data-fetching helpers

The deliberately-hanging operations should be:

1. **Dynamic boundary markers** — our equivalent of cookies/headers access
2. **Any per-request data access** that signals "this is not cacheable"

### The Cross-Process Question

Next.js's final pass works with a single-task abort because warm cache reads are
in-process (a JavaScript `Map`). The concern for react_on_rails is:

If the Resume Data Cache adapter crosses a process boundary (Node → Rails via
HTTP), even "warm" reads take real wall-clock time. A single-task abort would fire
before those reads complete.

**Solution options**:

1. **Keep the RDC in-process** (JavaScript-side cache): The final pass's
   single-task abort works correctly, matching Next.js's behavior.
2. **Track RDC reads in the final pass too**: Use a CacheSignal even in the
   final pass, turning the cross-process reads into tracked operations. The abort
   waits for them.
3. **Use a timeout budget**: Set a maximum wait time (e.g., 5 seconds) beyond
   which the prerender aborts regardless, degrading gracefully to more dynamic
   holes.

Option 1 is what the plan already specifies (the RDC is a Node-side cache). The
prospective pass fills it via cross-process reads, and the final pass reads from
the local JavaScript cache. This is architecturally correct.

### The Budget/Escape Hatch

Next.js doesn't have an explicit timeout budget — it relies on the CacheSignal
settling naturally. But pathological cases exist:

- A `"use cache"` function that does an extremely slow external API call
- Circular cache dependencies that never settle
- A module that takes forever to load

For react_on_rails, a hard timeout cap is advisable:

```
const settled = await Promise.race([
  cacheSignal.cacheReady(),
  timeout(5000).then(() => 'TIMEOUT')
]);

if (settled === 'TIMEOUT') {
  log.warn('Prerender settle timeout — aborting with partial shell');
}
controller.abort();
```

When the timeout trips, the result is a shallower shell (more dynamic holes), not
a build failure. This is a **degradation**, not an error — the page still works,
it just has more content streaming in dynamically.

### Determinism

A timing-based settle criterion introduces non-determinism: the same page might
produce slightly different shells on different builds if component resolution
times vary.

Next.js handles this implicitly because:

- Cached values resolve synchronously (microtask-fast) on the final pass
- The task schedule is deterministic (same number of macrotasks)
- The only variance is in the prospective pass, whose output is discarded

For react_on_rails, determinism requires:

1. The RDC must be in-process (so final-pass reads are synchronous)
2. The settle criterion must be event-driven (CacheSignal), not time-based
3. Builds should be validated with a diff check: prerender twice, compare shells

---

## Part 6: Summary Table

| Abort Point     | Next.js Criterion          | Mechanism                          | Window                         |
| --------------- | -------------------------- | ---------------------------------- | ------------------------------ |
| RSC Prospective | `CacheSignal.cacheReady()` | Reference counter + deferred check | Until all tracked work settles |
| RSC Final       | `runInSequentialTasks`     | Task-schedule (4 macrotasks)       | ~4 event-loop turns            |
| HTML/Fizz       | `runInSequentialTasks`     | Task-schedule (2 macrotasks)       | ~2 event-loop turns            |

The prospective pass is the only one with an open-ended wait. The final pass and
HTML pass use fixed schedules because their inputs are already resolved.

---

## Appendix A: Experiment Results Summary

| #   | Experiment                  | Key Finding                                                                                                                                               |
| --- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Fallback reachability       | Abort timing determines WHICH Suspense fallback appears — inner (narrow) or outer (coarse)                                                                |
| 2   | Deep nested async           | 3 levels of async (30ms each): setImmediate abort misses all; 150ms gets all                                                                              |
| 3   | Complex tree                | Progressive reveal: each resolved level exposes one more Suspense boundary                                                                                |
| 4   | CacheSignal simulation      | CacheSignal correctly chains through L1→L2→L3, settling only after L3                                                                                     |
| 5   | setImmediate vs deferred    | With _already-tracked_ components (manual beginRead/endRead), all strategies work because React's own scheduling is microtask-fast                        |
| 6   | Microtask gap               | Warm-cache scenario (Promise.resolve): CacheSignal survives the gap between endRead and React's follow-up render                                          |
| 7   | Bare abort without tracking | When all components are microtask-fast, even bare setImmediate works (React resolves everything in one task)                                              |
| 8   | **Untracked I/O**           | **The critical finding**: Without CacheSignal tracking, a 20ms cross-process read is invisible → premature abort → shallow shell. With tracking: correct. |

**Experiment 8 is the proof that tracking is necessary.** A bare timing abort
only works when all async work resolves within the first macrotask (microtask-
fast). Any real I/O — network calls, file reads, cross-process communication —
takes longer and is invisible without explicit tracking.

---

## Appendix B: The Exact Settle Sequence (From Next.js Source)

```
1. Create CacheSignal (count=0)
2. Create AbortController for React render
3. Start React prerender(element, { signal })
4. trackPendingModules(cacheSignal)  ← subscribe to module loads
5. await cacheSignal.cacheReady()    ← blocks until settled
   │
   │  During render, React calls components:
   │    Component A: fetch() → cacheSignal.beginRead() [count=1]
   │    Component A: fetch resolves → cacheSignal.endRead() [count=0]
   │      → schedule setImmediate (timer 1)
   │    React processes result, renders child B
   │    Component B: "use cache" → cacheSignal.beginRead() [count=1]
   │      → CANCEL timer 1
   │    Component B: cache resolves → cacheSignal.endRead() [count=0]
   │      → schedule setImmediate (timer 2)
   │    React processes result, renders child C
   │    Component C: dynamic API (cookies) → hanging promise (NOT tracked)
   │    [no more beginReads]
   │    setImmediate timer 2 fires → schedule setTimeout(0) (timer 3)
   │    setTimeout timer 3 fires → count still 0 → SETTLED
   │
6. abortController.abort()           ← kill the React render
7. Collect the produced stream (used to fill caches, HTML discarded)
```

---

_Experiments run on: Node.js, React 19.2.8, macOS Darwin 25.5.0_
_Source: Next.js canary (latest as of 2026-08-08)_
