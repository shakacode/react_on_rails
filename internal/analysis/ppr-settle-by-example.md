# PPR Settle Criterion — By Example

**What you'll get from each component pattern when React aborts the prerender.**

Every example was tested on React 19.2.8 with `react-dom/static`'s `prerender()` API.
The `signal` on the `AbortController` is what stops the render — everything still
pending at that moment becomes a "hole" showing its Suspense fallback.

---

## Rule #1: The abort timing decides which fallback the user sees

```jsx
<Suspense fallback={<Spinner />}>
  {' '}
  ← "coarse" fallback
  <ProductLayout>
    {' '}
    ← async, loads in 20ms
    <Sidebar /> ← sync
    <Suspense fallback={<Skeleton />}>
      {' '}
      ← "fine" fallback
      <UserReviews /> ← dynamic (never resolves)
    </Suspense>
  </ProductLayout>
</Suspense>
```

**If you abort before `ProductLayout` finishes (before 20ms):**

```html
<Spinner /> ← the coarse fallback — the user sees a blank spinner
```

The whole middle of the page is gone. `Sidebar` is gone. The fine `<Skeleton />`
is gone. React never got past `ProductLayout`, so it never discovered the inner
Suspense boundary at all.

**If you abort after `ProductLayout` finishes (after 20ms):**

```html
<ProductLayout>
  <Sidebar /> ← ✓ fully rendered <Skeleton /> ← the FINE fallback — much better!
</ProductLayout>
```

Now the user sees the layout, the sidebar, and a small skeleton where reviews
will stream in. This is what PPR is supposed to deliver.

**The lesson**: aborting too early doesn't produce an error — it produces a
_valid but worse_ page. The output is correct HTML, just shallower than it could be.
This is the most dangerous failure mode because it's silent.

---

## Rule #2: Only async work the framework TRACKS keeps it waiting

There are two kinds of abort strategies:

1. **Tracked abort (CacheSignal)**: the framework knows about each async
   operation and waits for all of them before aborting
2. **Task-schedule abort**: abort after a fixed number of event-loop turns,
   regardless of what's still pending

### What gets tracked? What doesn't?

| Code pattern                         | Tracked?       | Will it make it into the shell?                                |
| ------------------------------------ | -------------- | -------------------------------------------------------------- |
| `await Promise.resolve()`            | doesn't matter | ✓ Yes — resolves within a microtask, fast enough for any abort |
| `await setTimeout(0)`                | doesn't matter | ✓ Yes — resolves within one macrotask                          |
| `await fetch(url)` through framework | ✓ tracked      | ✓ Yes                                                          |
| `await fetch(url)` raw (your own)    | ✗ untracked    | ❌ **No** — invisible to the framework                         |
| `await db.query(...)`                | ✗ untracked    | ❌ **No**                                                      |
| `await readFile(...)`                | ✗ untracked    | ❌ **No**                                                      |
| `await crossProcessCacheRead()`      | ✗ untracked    | ❌ **No** — even if it's "fast" (5ms+)                         |

### Proof: the speed cutoff

We tested a single async component at different speeds, with a task-schedule
abort (the strategy used for the final render pass):

| Async work                | Time                 | Result                 |
| ------------------------- | -------------------- | ---------------------- |
| `await Promise.resolve()` | ~0ms (microtask)     | ✓ Rendered             |
| `await setTimeout(0)`     | ~1ms (one macrotask) | ✓ Rendered             |
| `await setTimeout(5)`     | ~5ms                 | ❌ **Premature abort** |
| `await setTimeout(20)`    | ~20ms                | ❌ **Premature abort** |
| `await setTimeout(100)`   | ~100ms               | ❌ **Premature abort** |

**The cutoff is around 1-2ms.** Anything slower than a single macrotask turn
gets missed by a task-schedule abort. Any real I/O (database queries, network
calls, file reads, cross-process communication) takes longer than that.

---

## Rule #3: An untracked component loses EVERYTHING below it

This is the most important rule. When an untracked async component is still
pending at abort time, React hasn't descended into it. So any Suspense boundaries,
children, or static content _below_ it in the tree are completely lost.

```jsx
<Suspense fallback={<p>Loading all...</p>}>
  {' '}
  ← boundary A
  <TrackedLayout>
    {' '}
    ← tracked, 20ms → renders ✓
    <TrackedSidebar>
      {' '}
      ← tracked, 20ms → renders ✓
      <UntrackedContent>
        {' '}
        ← UNTRACKED, 20ms
        <Suspense fallback={<p>Dynamic hole</p>}>
          {' '}
          ← boundary B (never reached!)
          <HangingComponent />
        </Suspense>
      </UntrackedContent>
    </TrackedSidebar>
  </TrackedLayout>
</Suspense>
```

**What you'd expect**: Layout and Sidebar render. Content is pending. Boundary B
shows "Dynamic hole".

**What actually happens**: Layout and Sidebar render inside a hidden div.
`UntrackedContent` is still pending when the CacheSignal settles (because the
CacheSignal doesn't know about it). Since `UntrackedContent` is between
boundary A and boundary B, it suspends at boundary A. The user sees:

```html
<p>Loading all...</p>
← the OUTERMOST fallback!
```

Layout and Sidebar are in a hidden `<div>` (React's streaming buffer), but
they're invisible. Boundary B's "Dynamic hole" fallback never appears because
React never reached it.

**The fix**: either track `UntrackedContent` with beginRead/endRead, or put a
Suspense boundary _directly above_ it:

```jsx
<Suspense fallback={<p>Loading layout...</p>}>
  <TrackedLayout>
    <TrackedSidebar>
      <Suspense fallback={<p>Loading content...</p>}>
        {' '}
        ← NEW boundary
        <UntrackedContent>
          <Suspense fallback={<p>Dynamic hole</p>}>
            <HangingComponent />
          </Suspense>
        </UntrackedContent>
      </Suspense>
    </TrackedSidebar>
  </TrackedLayout>
</Suspense>
```

Now if `UntrackedContent` is still pending, it suspends at the NEW boundary.
The user sees Layout + Sidebar + "Loading content..." instead of just
"Loading all...".

---

## Rule #4: The mixed-tracking trap

When tracked and untracked components are mixed in the same tree, the CacheSignal
correctly waits for tracked components but then settles immediately — even if
an untracked child was _just_ discovered by the tracked component's resolution.

```jsx
<Suspense fallback={<p>Loading...</p>}>
  <TrackedLayout>
    {' '}
    ← tracked, 20ms
    <Suspense fallback={<p>Content loading...</p>}>
      <UntrackedContent>
        {' '}
        ← untracked, 20ms
        <Suspense fallback={<p>Details loading...</p>}>
          <HangingComponent />
        </Suspense>
      </UntrackedContent>
    </Suspense>
  </TrackedLayout>
</Suspense>
```

Timeline:

```
  0ms: TrackedLayout starts (beginRead, count=1)
 20ms: TrackedLayout finishes (endRead, count=0)
       → CacheSignal schedules settle check
       → React renders TrackedLayout's children
       → Discovers UntrackedContent, starts its 20ms work
 21ms: CacheSignal's setImmediate fires
 22ms: CacheSignal's setTimeout fires → count still 0 → SETTLED
       → Abort fires!
       → UntrackedContent is still at 2ms out of 20ms → MISSED
```

**Result**: TrackedLayout renders. "Content loading..." shows for the untracked
component. You get the middle fallback, not the deepest one.

```html
<div>
  [Layout-tracked]
  <p>Content loading...</p>
  ← middle fallback, not "Details loading..."
</div>
```

This is better than the outermost fallback (because we have a Suspense boundary
between the tracked parent and the untracked child), but it's still not ideal.
The "Details loading..." fallback would have been more specific.

---

## Rule #5: Fallbacks can themselves suspend — and that can empty your shell

```jsx
// ⚠️ DANGEROUS: async fallback
<Suspense fallback={<AsyncFallback />}>
  {' '}
  ← fallback is async (50ms)!
  <HangingComponent />
</Suspense>
```

**If you abort before `AsyncFallback` resolves (before 50ms):**

```html
(empty) ← the shell is COMPLETELY EMPTY
```

React needs to show the fallback, but the fallback itself is pending. There's no
Suspense boundary above it to catch the suspension. The prelude is empty.

**If you abort after 50ms**: the async fallback renders normally.

**Safe version** — wrap the async fallback in its own Suspense:

```jsx
<Suspense
  fallback={
    <Suspense fallback={<p>Loading...</p>}>
      {' '}
      ← sync fallback catches it
      <AsyncFallback />
    </Suspense>
  }
>
  <HangingComponent />
</Suspense>
```

Now if `AsyncFallback` is still pending at abort time, the inner Suspense catches
it and shows the sync "Loading..." text. The shell is never empty.

**Practical rule**: keep your Suspense fallbacks synchronous. If you must use an
async fallback, wrap it in another Suspense with a sync fallback.

---

## Rule #6: `Promise.resolve()` is magic — it always works

If your async component's work resolves via `Promise.resolve()` (or any
already-fulfilled promise), it will ALWAYS make it into the shell, regardless of
abort strategy:

```jsx
async function FastComponent({ children }) {
  const data = await Promise.resolve(cachedData); // ← instant
  return <div>{data}</div>;
}
```

**Why**: React processes resolved promises via microtasks. Microtasks run before
ANY macrotask (before `setImmediate`, before `setTimeout`). So even if you abort
on the very next `setImmediate`, the component has already resolved.

This is why the final render pass works in Next.js — warm cache reads return
already-fulfilled promises, so they all resolve within a single rendering task.

**This breaks if**: the "warm" read still crosses a process boundary. Even a
"cached" value that requires an HTTP round-trip (Node → Rails → response) takes
5-20ms of real wall-clock time. That's too slow.

---

## Rule #7: Nesting depth doesn't matter — speed does

We tested 5 levels of async components, each resolving via `Promise.resolve()`:

```jsx
<L1>           ← async, Promise.resolve()
  <L2>         ← async, Promise.resolve()
    <L3>       ← async, Promise.resolve()
      <L4>     ← async, Promise.resolve()
        <L5>   ← async, Promise.resolve()
          ...
```

**Result with setImmediate abort**: all 5 levels rendered ✓

Each level resolves in a microtask. React chains them: L1 resolves → render
children → L2 resolves → render children → ... → all done, all within the same
macrotask.

But change `Promise.resolve()` to `setTimeout(20)` and only the first level
renders. The rest are pending at abort time.

**The rule**: nesting depth doesn't matter. What matters is whether each level
resolves within the same event-loop turn (microtask-fast) or requires real
wall-clock time.

---

## Summary: When does each component pattern make it into the static shell?

| Your component does...            | Prospective pass (CacheSignal) | Final pass (task-schedule)   |
| --------------------------------- | ------------------------------ | ---------------------------- |
| `await Promise.resolve(data)`     | ✓ always works                 | ✓ always works               |
| `await trackedCacheRead()` (20ms) | ✓ CacheSignal waits            | ✓ if cache is warm (instant) |
| `await rawFetch(url)` (20ms)      | ❌ missed (untracked)          | ❌ missed (too slow)         |
| `await db.query()` (20ms)         | ❌ missed (untracked)          | ❌ missed (too slow)         |
| `await crossProcessRead()` (5ms)  | ❌ missed (untracked)          | ❌ missed (too slow)         |
| `cookies()` / `headers()`         | hanging (correct)              | hanging (correct)            |

**The takeaway**: the only async work that reliably makes it into the shell is
work that either:

1. Resolves instantly (already-fulfilled promise), or
2. Is explicitly tracked by the framework (beginRead/endRead)

Everything else is a gamble on timing.

---

## Visual Summary

```
Abort too early                  Abort at right time
─────────────────                ─────────────────

┌──────────────┐                 ┌──────────────┐
│   Header ✓   │                 │   Header ✓   │
├──────────────┤                 ├──────────────┤
│              │                 │  Layout ✓    │
│  Loading...  │  ← coarse       │ ┌──────────┐ │
│  (spinner)   │    fallback     │ │Sidebar ✓ │ │
│              │                 │ ├──────────┤ │
├──────────────┤                 │ │Loading...│ │ ← fine
│   Footer ✓   │                 │ │(skeleton)│ │   fallback
└──────────────┘                 │ └──────────┘ │
                                 ├──────────────┤
                                 │   Footer ✓   │
                                 └──────────────┘

User sees less.                  User sees more.
LCP is worse.                    LCP is better.
More work at request time.       Less work at request time.
```

---

_All findings verified empirically on React 19.2.8, Node.js, macOS._
_Source experiments: experiments 9-12 in the settle-criterion directory._
