# PPR Runtime Requirements

> **Experimental**: `ppr_react_component` (Partial Prerendering) is an experimental Pro feature. APIs may change between minor versions.

PPR's prerender phase relies on two runtime capabilities that the Pro Node renderer does **not** provide under its default configuration. Both must be enabled before PPR will function correctly.

## AbortController

The prerender uses an `AbortController` to implement the **settle budget** — the time limit React is given to resolve Suspense boundaries before the prerender signals postponement. `AbortController` and `AbortSignal` are deliberately not injected into the renderer's VM context by default (see `vm.ts`).

### How to enable

Add `AbortController` to your renderer's `additionalContext`:

```js
// node-renderer.js (or your renderer entry)
module.exports = {
  additionalContext: {
    AbortController,
    // ... other globals your bundle needs
  },
};
```

## Real timers (non-stubbed `setTimeout`)

The settle budget fires via `setTimeout`. The default renderer config stubs `setTimeout` and `setInterval` to no-ops to prevent unterminated timers from keeping the VM alive between requests. With the stub, `setTimeout` returns `undefined` instead of a timer handle and the callback never fires — the settle budget never triggers, so `prerenderToNodeStream` waits for **every** Suspense boundary to resolve, defeating postponement entirely.

### Failure mode

When timers are stubbed, the prerender completes with `postponed === null` (no boundaries postponed), and the **entire page** — including per-user dynamic content — is cached as the static shell. On a page with a shared `cache_key` and per-user `RSCRoute` content inside a `<Suspense>` hole, this puts user A's data into the shell served to user B.

### How to disable the stub

Set `stubTimers: false` in your renderer config:

```js
// node-renderer.js
module.exports = {
  stubTimers: false,
  // ...
};
```

Or set the environment variable:

```bash
RENDERER_STUB_TIMERS=false
```

## Preflight validation

The PPR prerender path runs a preflight check (`validatePPRRuntimeEnvironment`) on first use. It verifies that:

1. `AbortController` is defined in the VM context.
2. `setTimeout` exists and returns a truthy timer handle (not the no-op stub).

When either check fails, the prerender emits a descriptive error naming the exact config knob to change. The preflight runs once per process and is skipped when a caller-provided `AbortSignal` bypasses the internal settle timer.

## Recommended renderer config for PPR

```js
// node-renderer.js
module.exports = {
  stubTimers: false,
  additionalContext: {
    AbortController,
    URL, // commonly needed alongside AbortController
  },
  // ... other settings
};
```

## See also

- [PPR Cache Warm-Up](./ppr-cache-warm-up.md) — pre-populating the PPR cache on deploy
- [Node Renderer Configuration](./node-renderer.md) — full renderer config reference
