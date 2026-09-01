# What "settle budget bounds the whole cold path" means

## The simple version

Imagine you're ordering coffee. The shop has a rule: "We promise your order will be ready in 30 seconds." That 30-second promise is the **settle budget**.

But here's the catch — they don't start the 30-second timer when you place your order. They start it only *after* the barista has finished grinding the beans. If grinding takes 5 minutes, your total wait is **5 minutes + 30 seconds**, even though the "budget" was 30 seconds.

That's exactly the bug in the current code.

## What PPR does (step by step)

PPR = Partial Pre-Rendering. It works in two phases:

1. **Prerender (cold path):** The server renders the page once, saves a "static shell" (the parts that don't change), and marks the dynamic parts as "holes to fill later."

2. **Resume (warm path):** On the next request, the server sends the cached shell instantly and only renders the dynamic holes.

The **settle budget** (default 500ms) is a timer that says: *"After this many milliseconds, stop waiting for slow data. Whatever hasn't loaded yet becomes a 'hole' to fill during the resume phase."*

## Where the bug is

Here's a simplified view of the code flow:

```
Step 1:  await renderFunction()          // <-- This can be slow (e.g., 300ms)
Step 2:  START the settle timer (500ms)   // <-- Timer starts HERE, not at Step 1
Step 3:  await prerenderToNodeStream()    // <-- React renders, timer running
Step 4:  Timer fires → abort → done
```

The render function (Step 1) is the app developer's code. It might:
- Fetch data from a database
- Call an external API
- Do heavy computation
- Or simply never finish (a bug / infinite loop)

The settle timer only starts at Step 2, **after** the render function finishes. So the actual wall-clock time is:

```
Total time = render function time + settle budget
```

### Example

| Scenario | Render function | Settle budget | Actual time | Expected time |
|---|---|---|---|---|
| Fast render | 5ms | 500ms | 505ms | ≤500ms ✓ |
| Slow render | 300ms | 500ms | 800ms | ≤500ms ✗ |
| Hanging render | ∞ | 500ms | ∞ (hangs) | ≤500ms ✗ |

## What the fix should do

The settle timer should cover the **entire** cold path — including waiting for the render function:

```
Step 1:  START the settle timer (500ms)   // <-- Timer starts FIRST
Step 2:  await renderFunction()           // <-- Timer is already running
Step 3:  await prerenderToNodeStream()    // <-- Timer still running
Step 4:  Timer fires → abort → done
```

Now the total time is bounded by the settle budget, regardless of how slow the render function is.

### With the fix

| Scenario | Render function | Settle budget | Actual time |
|---|---|---|---|
| Fast render | 5ms | 500ms | ≤500ms ✓ |
| Slow render | 300ms | 500ms | ≤500ms ✓ (aborts at 500ms) |
| Hanging render | ∞ | 500ms | ≤500ms ✓ (aborts at 500ms) |

## What happens when the timer fires mid-render-function?

If the render function hasn't returned yet when the timer fires, two options:

**Option A:** Race the render function against the timer. If the timer wins, skip the render entirely and output a **fallback-only shell** (a page with all holes, no pre-rendered content). This is still valid — the resume phase fills everything in.

**Option B:** Reject async render functions entirely for `ppr_react_component` — require them to return a React element synchronously. This is simpler but more restrictive.

The issue suggests Option A as the primary direction, with Option B as an alternative.

---

## Code snippets

### Defective code (current)

File: `packages/react-on-rails-pro/src/pprServerRenderedReactComponent.ts`

The settle timer is created **inside** the `.then()` — meaning it only starts
after `Promise.resolve(reactRenderingResult)` has resolved (i.e. after the
developer's render function has returned):

```ts
// ❌ CURRENT — timer starts AFTER the render function finishes

  Promise.resolve(reactRenderingResult)                    // ← waits for render function
    .then(async (reactRenderedElement) => {                // ← only enters here when it resolves
      // ... string check omitted ...

      let settleTimeoutId: ReturnType<typeof setTimeout> | undefined;
      try {
        let prerenderSignal: AbortSignal;
        if (options.signal) {
          prerenderSignal = options.signal;
        } else {
          const settleController = new AbortController();
          prerenderSignal = settleController.signal;
          settleTimeoutId = setTimeout(                     // ← timer starts HERE (too late!)
            () => settleController.abort(),
            resolveSettleBudgetMs(railsContext),
          );
        }

        const { prerenderToNodeStream } = getValidatedPPRApis();
        const { prelude, postponed } = await prerenderToNodeStream(reactRenderedElement, {
          // ... onError, signal, etc. ...
          signal: prerenderSignal,
        });
```

If `reactRenderingResult` is a Promise that takes 300ms to resolve, the timer
doesn't start until 300ms in. A render function that never resolves means the
timer never starts and the request **hangs forever**.

### Fixed code (proposed)

The fix isn't simply "move the timer up and check if aborted." There are **two
distinct scenarios** when the timer fires before `prerenderToNodeStream` runs,
and they need different handling:

#### Scenario A: Render function is slow but eventually returns

The timer fires while we're still inside `await Promise.resolve(reactRenderingResult)`.
When the render function finally resolves, we **do** have a valid React element.
We can still pass it to `prerenderToNodeStream` with the **already-aborted** signal.
React will immediately treat ALL Suspense boundaries as holes and produce a valid
`PostponedState`. This is the best outcome — we get a real (if hole-heavy) shell
that Ruby can cache, and the resume phase fills everything in.

#### Scenario B: Render function never returns (true hang)

The `Promise.resolve(reactRenderingResult)` never settles — neither `.then()` nor
`.catch()` ever fires. The timer fires but nobody is listening. We need
`Promise.race` to escape the await. Since React never ran, there's **no
PostponedState to produce** — we can't fake one. The right response is to set
`pprRenderErrored: true` so Ruby doesn't cache this, and falls back to a normal
server render for this request.

> **Why not emit `pprPrerenderComplete: true` with empty HTML?**
> Without `pprPostponedState`, Ruby would interpret this as "the page is fully
> static" and cache an empty shell. The page would render blank on every
> subsequent request. We must set `pprRenderErrored` to prevent caching.

#### The actual fix

```ts
// ✅ FIXED — timer starts BEFORE awaiting the render function

  // 1. Create the settle controller FIRST, before awaiting anything.
  let settleTimeoutId: ReturnType<typeof setTimeout> | undefined;
  let settleController: AbortController | undefined;
  let prerenderSignal: AbortSignal;

  if (options.signal) {
    prerenderSignal = options.signal;
  } else {
    settleController = new AbortController();
    prerenderSignal = settleController.signal;
    settleTimeoutId = setTimeout(                          // ← timer starts NOW
      () => settleController!.abort(),
      resolveSettleBudgetMs(railsContext),
    );
  }

  // 2. Helper: a promise that rejects when the settle signal aborts.
  const settleRejection = new Promise<never>((_, reject) => {
    prerenderSignal.addEventListener(
      'abort',
      () => reject(prerenderSignal.reason),
      { once: true },
    );
  });

  // 3. Race the render function against the settle signal.
  Promise.race([
    Promise.resolve(reactRenderingResult),
    settleRejection,
  ])
    .then(async (reactRenderedElement) => {
      // Render function returned before the timer. Clear the timer
      // (any remaining budget goes to prerenderToNodeStream via the signal).
      if (settleTimeoutId !== undefined) clearTimeout(settleTimeoutId);
      // ... BUT re-arm if there's remaining budget (timer may not have fired)
      // Actually, DON'T clear — let the same timer bound prerenderToNodeStream too.
      // The signal is shared: when it fires, prerenderToNodeStream aborts and
      // demotes remaining Suspense boundaries to holes, producing PostponedState.

      if (typeof reactRenderedElement === 'string') {
        // ... same string handling as before ...
      }

      // prerenderToNodeStream runs with the same signal. If the budget
      // already expired (Scenario A), the signal is already aborted and
      // React immediately treats ALL boundaries as holes → valid PostponedState.
      const { prerenderToNodeStream } = getValidatedPPRApis();
      const { prelude, postponed } = await prerenderToNodeStream(reactRenderedElement, {
        // ... onError, etc. ...
        signal: prerenderSignal,
      });

      // ... rest of the prelude/protocol handling unchanged ...
    })
    .catch((e: unknown) => {
      // Scenario B: the settle signal won the race (render function hung).
      // React never ran → no PostponedState exists.
      if (prerenderSignal.aborted && isAbortErrorLike(e)) {
        // Signal Ruby not to cache this: pprRenderErrored prevents caching,
        // pprPrerenderComplete tells Ruby the protocol was followed.
        writeChunk('', {
          [PPR_PRERENDER_COMPLETE_CHUNK_KEY]: true,
          [PPR_RENDER_ERRORED_CHUNK_KEY]: true,            // ← prevents caching!
        });
        endStream();
        return;
      }
      // Other errors: handle as before (reportError + sendErrorHtml).
      const error = convertToError(e);
      reportError(error);
      sendErrorHtml(error);
    });
```

### What changed (summary)

| Aspect | Before (defective) | After (fixed) |
|---|---|---|
| Timer created | Inside `.then()`, after render function resolves | Before `Promise.resolve()`, before any await |
| Slow render function (300ms) | 300ms + 500ms = 800ms | Render function returns late; `prerenderToNodeStream` runs with already-aborted signal → all boundaries become holes → valid PostponedState cached |
| Hanging render function | Request hangs forever | `Promise.race` escapes; `pprRenderErrored` prevents caching; Ruby falls back to normal render |
| Fast render function (5ms) | Works fine (5ms + 500ms) | Identical behavior — timer still bounds `prerenderToNodeStream` |
| `options.signal` provided | Uses caller signal (unchanged) | Uses caller signal (unchanged) |
