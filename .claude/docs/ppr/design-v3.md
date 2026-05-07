# PPR Design Proposal — v3 (post-codex-v2 review)

Resolves codex's v2 critique. New revisions tagged `[v3]`. v2 items still stand unless overridden.

---

## `[v3 R-2]` — pushback on "resume is async/callback-driven"

**Codex claimed**: `resumeToPipeableStream` is documented as `await resumeToPipeableStream(..., { onShellReady })`.

**Counterevidence**: React 19.2.3 source (`react-dom/cjs/react-dom-server.node.development.js:10766`):
```js
exports.resumeToPipeableStream = function (children, postponedState, options) {
  var request = resumeRequestImpl(children, postponedState, options), hasStartedFlowing = !1;
  startWork(request);
  return {
    pipe: function (destination) { ... startFlowing(request, destination); ... },
    abort: ...
  };
};
```

The function is **synchronous** and returns `{pipe, abort}`. There is no `onShellReady`. This matches
the working `ppr-demo.mjs` in the repo root. **Closing this point as non-issue.**

(Codex's confusion was likely with `renderToPipeableStream` — which DOES have `onShellReady` —
and/or with `prerenderToNodeStream` which is async.)

---

## `[v3 R-1]` — `streaming?` is correctly OVERLOADED today; fix the consumers, not the predicate

**Codex's correct point**: Adding `:ppr_resume` to `streaming?` would route through:
1. `ProRendering#render_with_cache` → wraps stream with `StreamCache` (wrong for PPR — we manage our own cache)
2. `server_rendering_js_code.rb` → injects `generateRSCPayload` definition + RSC railsContext fields (irrelevant for PPR)
3. (and we want it to keep going through `eval_streaming_js`, which is the only correct effect)

**Fix**: We update the consumers, not the predicate.

### `[v3]` change to OSS `render_options.rb`

```ruby
def streaming?
  %i[html_streaming rsc_payload_streaming ppr_resume].include?(render_mode)
end

# New helpers — opt-in for behavior that should NOT apply to PPR
def html_streaming?              = render_mode == :html_streaming
def rsc_payload_streaming?       = render_mode == :rsc_payload_streaming
def ppr_prerender?               = render_mode == :ppr_prerender
def ppr_resume?                  = render_mode == :ppr_resume
def ppr?                         = ppr_prerender? || ppr_resume?
def html_or_rsc_streaming?       = html_streaming? || rsc_payload_streaming?
```

### `[v3]` Pro consumers updated

`react_on_rails_pro/lib/react_on_rails_pro/server_rendering_pool/pro_rendering.rb` —
`render_with_cache` should NOT engage for PPR resume. Replace the existing `render_options.streaming?`
guard for stream-cache with:

```ruby
result = if render_options.html_streaming?  # was: streaming?
           render_streaming_with_cache(prerender_cache_key, js_code, render_options)
         elsif render_options.rsc_payload_streaming?
           render_on_pool(js_code, render_options)        # RSC path: no Pro stream cache
         elsif render_options.ppr_resume?
           render_on_pool(js_code, render_options)        # PPR resume: own cache contract
         else
           Rails.cache.fetch(prerender_cache_key) do
             prerender_cache_hit = false
             render_on_pool(js_code, render_options)
           end
         end
```

Also: `ppr_react_component` always sets `skip_prerender_cache: true` so the JS-side prerender
output is not double-cached at the Pro Rendering level.

`react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb` — the
`enable_rsc_support && render_options.streaming?` guard becomes
`enable_rsc_support && render_options.html_or_rsc_streaming?`. PPR has its own railsContext
augmentation (no `generateRSCPayload`).

This is a localized, low-risk change. Audit script:

```bash
grep -RIn "\.streaming?" react_on_rails react_on_rails_pro
# Expected hits to update: pro_rendering.rb, server_rendering_js_code.rb. All other hits
# (e.g. inside ruby_embedded_java_script.rb that dispatches to streaming HTTP) are exactly
# what we want for PPR resume.
```

---

## `[v3 R-3]` — `AsyncLocalStorage` availability

**Codex's correct point**: `import { AsyncLocalStorage } from 'node:async_hooks'` may fail at bundle
parse time if the bundle doesn't have node externals; relying on a try/catch fallback inside the
import won't help.

**Fix**: Inject `AsyncLocalStorage` into the VM context as a global, alongside `AbortController`
and `AbortSignal`. Update node renderer:

```ts
// packages/react-on-rails-pro-node-renderer/src/worker/vm.ts (extendContext block)
extendContext(contextObject, {
  Buffer, TextDecoder, TextEncoder, URLSearchParams, ReadableStream,
  process, performance,
  setTimeout, setInterval, setImmediate, clearTimeout, clearInterval, clearImmediate, queueMicrotask,
  AbortController, AbortSignal,           // [v3] for PPR
  AsyncLocalStorage,                      // [v3] for PPR phase tracking
});
```

`AsyncLocalStorage` is imported at the top of vm.ts: `import { AsyncLocalStorage } from 'node:async_hooks';`
That works at the renderer process level (not inside the sandbox) — no bundle externals needed.

The PPR JS module reads `AsyncLocalStorage` from `globalThis`:

```ts
// packages/react-on-rails-pro/src/postpone.ts
const ALS = (globalThis as any).AsyncLocalStorage;
if (typeof ALS !== 'function') {
  // Hard error at module load if PPR is reachable in this build context.
  throw new Error('PPR requires AsyncLocalStorage as a VM global. Update the Pro node renderer to >= protocol Y.Y.');
}
const phaseStore = new ALS();
```

The Pro Ruby side surfaces a clearer error at the helper level (so devs see it before JS runs):

```ruby
def ppr_react_component(component_name, options = {})
  unless ReactOnRailsPro.configuration.enable_ppr_support
    raise ReactOnRailsPro::Error, "PPR support is not enabled (set config.enable_ppr_support = true)"
  end
  unless ReactOnRailsPro.configuration.node_renderer?
    raise ReactOnRailsPro::Error, "PPR requires the Pro node renderer (ExecJS lacks AbortController/streams)"
  end
  ...
end
```

---

## `[v3 R-4]` — AbortController injection: unconditional default

**Codex's correct point**: `enable_ppr_support` is a Ruby-side flag and the node renderer doesn't
know about it.

**Fix**: Add `AbortController, AbortSignal, AsyncLocalStorage` to the default `supportModules`
context unconditionally. They're standard Node.js globals (Node ≥ 16). No node-renderer config
flag needed. Documentation update:

- `docs/oss/building-features/node-renderer/js-configuration.md` — list new globals
- `packages/react-on-rails-pro-node-renderer/src/shared/configBuilder.ts` JSDoc
- `docs/oss/migrating/rsc-troubleshooting.md` — list new globals
- `react_on_rails_pro/packages/node-renderer/package.json` — bump `protocolVersion` to indicate
  the runtime contract change (PPR-capable). Note: bumping protocolVersion is unrelated to the
  request/response wire protocol — it's just a contract tag. We document the bump and the gem
  side already accepts protocolVersion mismatches with a warning.

A vm.test.ts test asserts these new globals are present in the VM context.

---

## `[v3 R-5]` — Lazy prerender blocks the request thread

**Codex's correct point**: 30s timeout means up to 30s blocked on the first request.

**Fix**: Document explicitly as MVP tradeoff. Lower default to **8 seconds**. Make it a
per-component option (`prerender_timeout_ms:`) so devs can tune. Add a future-work note for
background warmup. Concretely:

```ruby
# react_on_rails_pro/lib/react_on_rails_pro/configuration.rb
add_attr :ppr_default_prerender_timeout_ms, default: 8_000

# usage
ppr_react_component('Page', cache_key: 'page-v1', props: {...},
                    prerender_timeout_ms: 5_000)
```

Documentation note in `docs/api/ppr.md`:

> **Cold-cache UX**. The first request to a PPR-cached page blocks while the static shell is
> built (default 8s). Subsequent requests skip prerender and serve the cached shell immediately.
> If your shell is expensive to build, prefer a build-time warmup task (planned, see
> `react_on_rails_pro:ppr_warmup` rake) over lazy first-hit prerendering.

We accept this constraint for v1.

---

## Updated final check

After the v3 changes, all five of codex's v2 issues are addressed:
- [✓] R-1: PPR-resume streaming routing surgically updated (specific consumers, not the predicate)
- [✓] R-2: kept synchronous resume API (codex was wrong; React 19.2 source confirms)
- [✓] R-3: AsyncLocalStorage injected into VM globals
- [✓] R-4: AbortController/AbortSignal/AsyncLocalStorage added unconditionally to supportModules
- [✓] R-5: blocking first-hit explicitly documented; default timeout lowered to 8s; per-call override

## Summary diff vs v2

- New OSS predicate `html_or_rsc_streaming?` and PPR predicates.
- Pro `pro_rendering.rb` and `server_rendering_js_code.rb` switched from `streaming?` to specific
  predicates where the existing behavior is RSC-aware streaming or stream caching.
- `ppr_react_component` always sets `skip_prerender_cache: true`.
- VM globals for the node renderer extended with `AbortController`, `AbortSignal`, `AsyncLocalStorage`.
- `protocolVersion` bumped (informational tag, not wire-protocol bump).
- Default prerender timeout lowered to 8s; tunable per-call.
- The shell is a component fragment; resume is synchronous; phase tracking via injected
  AsyncLocalStorage; PPR registered only in `ReactOnRails.node.ts`. (All as v2.)
