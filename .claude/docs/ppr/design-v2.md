# PPR Design Proposal — v2 (post-codex-v1 review)

Revisions in v2 are tagged `[v2]` and grouped by codex's numbered findings.

## Scope (unchanged)

MVP of React 19.2 PPR for React on Rails Pro. Helper `ppr_react_component`. Cache `(shell, postponed)`
in Rails.cache. Lazy first-request prerender. SSR HTML layer only — RSC composition deferred.

## Rendering pipeline (revised)

### `[v2 #1]` — explicit render modes

Add to `react_on_rails/lib/react_on_rails/react_component/render_options.rb`:

```ruby
def ppr_prerender? = render_mode == :ppr_prerender
def ppr_resume?    = render_mode == :ppr_resume
def ppr?           = ppr_prerender? || ppr_resume?

# streaming? returns true for :ppr_resume so the existing streaming path is used.
def streaming?
  %i[html_streaming rsc_payload_streaming ppr_resume].include?(render_mode)
end
```

Update `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb` to pick the JS
function name explicitly:

```ruby
render_function_name =
  if render_options.ppr_prerender?
    "'prerenderReactComponentForPPR'"
  elsif render_options.ppr_resume?
    "'resumeReactComponentForPPR'"
  elsif ReactOnRailsPro.configuration.enable_rsc_support && render_options.streaming?
    "ReactOnRails.isRSCBundle ? 'serverRenderRSCReactComponent' : 'streamServerRenderedReactComponent'"
  else
    "'serverRenderReactComponent'"
  end
```

The PPR functions are registered on the Pro `ReactOnRails` global, so the existing
`ReactOnRails[#{render_function_name}]({...})` invocation at `server_rendering_js_code.rb:91`
calls them directly without further changes.

### `[v2 #2]` — prerender returns Promise<Hash>

`prerenderReactComponentForPPR` returns a `Promise<{ html, consoleReplayScript, hasErrors,
isShellReady, pprPostponedState }>`. The node renderer VM at `vm.ts:161` already awaits and
JSON-stringifies non-string results, so no protocol changes needed.

ExecJS does NOT support async, Node streams, or AbortController. PPR fails fast when the active
render pool is `RubyEmbeddedJavaScript`:

```ruby
def ppr_react_component(component_name, options = {})
  unless ReactOnRailsPro.configuration.node_renderer?
    raise ReactOnRailsPro::Error,
          'PPR requires the Pro node renderer (ExecJS does not support AbortController/async).'
  end
  ...
end
```

### `[v2 #3]` — shell HTML is a component fragment, not a full document

The user's PPR root component returns a React fragment, not `<html>`. Fizz produces fragment HTML.
The cached `shell_html` is exactly what existing `serverRenderReactComponent` would produce for
the same component, modulo postponed boundaries. `build_react_component_result_for_server_rendered_string`
will wrap it inside `<div id="...">…</div>` exactly as today.

Note: PPR-emitted `<template id="B:N">` placeholders work even when the surrounding HTML is a
fragment. The `$RC` instructions emitted during resume are JS that look up nodes by id, so
position is irrelevant.

The `bootstrapScripts` option of `prerenderToNodeStream` is **omitted** for PPR. ROR's existing
client-bundle injection is responsible for booting React on the page. We do NOT pass bootstrap
scripts to Fizz from JS (this also avoids duplicating React's `$RC` runtime in the shell).

### `[v2 #4]` — PPR cache is its own contract

The cache stores a hash:

```ruby
{
  shell_html: String,            # component-fragment HTML, ready to feed into existing wrapper
  postponed_state: String|nil,   # JSON.stringify(postponed) or nil for fully-static pages
  console_replay_script: String, # captured during prerender
  ppr_version: 1                 # bump if cache shape changes
}
```

We do NOT reuse `cached_stream_react_component`'s "cache the final Rails-side chunks" pattern.
PPR's cache is the React-side artifact (shell + postponed). We rebuild Rails-side wrapping
on every request.

### `[v2 #5]` — `isShellReady = true` before writing shell

In `resumeReactComponentForPPR`:

```ts
const renderState = { result: null, hasErrors: false, isShellReady: true }; // ← true from start
const { readableStream, pipeToTransform, writeChunk } = transformRenderStreamChunksToResultObject(renderState);
writeChunk(shellHtml);   // first JSON chunk has isShellReady: true
const stream = resumeToPipeableStream(element, JSON.parse(postponedState), { onError });
pipeToTransform(stream); // resume chunks follow
```

Also: the resume side returns the stream synchronously (do not await renderToPipeableStream's
async boundary chain). The first chunk is immediately available.

### `[v2 #6]` — phase tracking via AsyncLocalStorage; PPR not registered in RSC bundle

PPR capability is registered ONLY in `packages/react-on-rails-pro/src/ReactOnRails.node.ts`, NOT
in `ReactOnRailsRSC.ts`. The `usePostpone` helper:

```ts
import { AsyncLocalStorage } from 'node:async_hooks';
const phaseStore = new AsyncLocalStorage<{ phase: 'prerender' | 'resume' }>();

export function usePostpone(reason?: string): void {
  // Hook runs inside React's render — the AsyncLocalStorage propagates if we wrap our
  // render() calls with phaseStore.run(...). Module-level fallback is acceptable for v1
  // because each worker request is serial.
  const phase = phaseStore.getStore()?.phase;
  if (phase === 'prerender') throw NEVER_RESOLVES;
  // resume → no-op
}
```

`prerenderReactComponentForPPR` calls `phaseStore.run({phase:'prerender'}, () => prerenderToNodeStream(...))`.
`resumeReactComponentForPPR` calls `phaseStore.run({phase:'resume'}, () => resumeToPipeableStream(...))`.

If `node:async_hooks` is unavailable (ExecJS path), `usePostpone` falls back to a module-level
flag set/cleared by the same wrappers. Since the ExecJS path is guarded out at the helper level
[v2 #2], the fallback is dead code on production paths but covers test scaffolding.

`ppr_react_component` does NOT support RSC components for v1. It is documented explicitly:
"Use `ppr_react_component` only for client/SSR React trees. For RSC use `stream_react_component`
(or `cached_stream_react_component`) — the two helpers compose differently and we'll address
PPR+RSC in a follow-up."

### `[v2 #7]` — AbortController in VM context

The Pro node renderer's worker VM at `vm.ts:221` uses `additionalContext` to inject globals.
We add `AbortController, AbortSignal` to the *default* set of VM globals when
`enable_ppr_support` is true, and we hard-fail if `globalThis.AbortController` is missing in the
PPR functions:

```ts
function ensurePPRRuntime() {
  if (typeof AbortController === 'undefined') {
    throw new Error(
      'React on Rails Pro PPR requires AbortController on the JS runtime. ' +
      'Add it to the node renderer VM globals (additionalContext.AbortController) ' +
      'or upgrade your node renderer to a version that includes it by default.'
    );
  }
}
```

### `[v2 #8]` — abort cleanup is precise

Pseudocode for `prerenderReactComponentForPPR`:

```ts
let timer: NodeJS.Timeout | undefined;
const controller = new AbortController();

function cleanup() {
  if (timer) { clearTimeout(timer); timer = undefined; }
  if (!controller.signal.aborted) controller.abort();
}

try {
  timer = setTimeout(() => controller.abort(new Error('ppr-prerender-timeout')), timeoutMs);
  const { prelude, postponed } = await prerenderToNodeStream(element, {
    signal: controller.signal,
    identifierPrefix: domNodeId,
    onError(err) { /* swallow expected AbortError; report others */ },
  });

  // Drain prelude. AbortController fired? prelude still emits up to the abort point + then ends.
  const shellHtml = await streamToString(prelude);
  return {
    html: shellHtml,           // existing field — reused for non-streaming consumer
    pprShellHtml: shellHtml,
    pprPostponedState: postponed ? JSON.stringify(postponed) : null,
    consoleReplayScript,
    hasErrors: false,
    isShellReady: true,
  };
} catch (e) {
  // Do NOT cache. Ruby side will fall back to error HTML rendering.
  return { html: '', hasErrors: true, errorMessage: String(e), pprShellHtml: '', pprPostponedState: null, ... };
} finally {
  cleanup();
}
```

Specifically:
- Always `clearTimeout(timer)` in finally.
- `controller.abort()` is idempotent so calling it in finally is safe.
- We do NOT call `prelude.destroy()` once we've consumed it; `streamToString` exits via `'end'`.
- If the prelude errors before any chunk: `prerenderToNodeStream` rejects → we go to `catch` → no cache.
- We never partially cache. `Rails.cache.fetch(key) { yield_block_or_raise }` only writes the
  cache when the block returns normally. If the JS returns a hash with `hasErrors: true`, the
  Ruby caller raises before caching.

### `[v2 #9]` — explicit cache_key required

```ruby
def ppr_react_component(component_name, options = {})
  raise ReactOnRailsPro::Error, "ppr_react_component requires :cache_key" unless options[:cache_key]
  ...
end
```

The cache key composition mirrors `cached_stream_react_component`:

```ruby
ReactOnRailsPro::Cache.react_component_cache_key(component_name, options.merge(prerender: true))
# Already includes server bundle digest; we add a 'ppr-v1' namespace and the React major version.
```

### `[v2 #10]` — strict prerender/resume tree separation

Document and enforce: **all per-request reads must be inside Suspense boundaries that postpone**.

We provide a runtime check in `resumeReactComponentForPPR` — if React's `onError` fires with a
"resume tree mismatch" error during resume, we surface it as a hard error in the Rails stream
(`hasErrors: true`, `error: ...`), so devs notice immediately rather than silently falling back
to client rendering.

For prerender, we pass a sanitized railsContext:

```ts
const prerenderRailsContext = {
  // Only static-safe fields. No cookies, no headers, no current_user, no locale.
  serverSide: true,
  rorPro: railsContext.rorPro,
  reactClientManifestFileName: railsContext.reactClientManifestFileName, // for RSC bundle ref
  __isPrerendering: true,
};
```

The resume side gets the FULL railsContext but the user's component contract is: "do not read
request-varying values outside a postponed boundary."

## Phase boundaries / files

### JS — packages/react-on-rails-pro/src

- `capabilities/proPPR.ts` — new
- `postpone.ts` — new (`usePostpone`, `phaseStore`)
- `ReactOnRails.node.ts` — register PPR capability
- (NOT modified) `ReactOnRailsRSC.ts`

### Ruby — react_on_rails_pro

- `lib/react_on_rails_pro/ppr.rb` — cache helpers
- `lib/react_on_rails_pro/configuration.rb` — `enable_ppr_support`, `ppr_prerender_timeout_ms`
- `app/helpers/react_on_rails_pro_helper.rb` — `ppr_react_component`

### Open-source — react_on_rails

- `lib/react_on_rails/react_component/render_options.rb` — add `ppr_prerender?`, `ppr_resume?`,
  update `streaming?`. (This is the only OSS-side change required.)

### Tests

- `packages/react-on-rails-pro/tests/proPPR.test.tsx` — unit tests for prerender/resume capability
- `react_on_rails_pro/spec/react_on_rails_pro/ppr_spec.rb` — Ruby unit tests
- `react_on_rails_pro/spec/dummy/client/app/components/PPRDemo/` — multi-Suspense demo
- `react_on_rails_pro/spec/dummy/app/views/pages/ppr_demo.html.erb`
- `react_on_rails_pro/spec/dummy/e2e-tests/ppr.spec.ts` — Playwright (for CI; chrome-devtools MCP for interactive verification)

## Acceptance for v1 (reaffirmed)

- [ ] `ppr_react_component('PPRDemo', cache_key: 'demo')` works in Pro dummy.
- [ ] First request: shell built, cached, streamed; postponed state cached alongside.
- [ ] Subsequent request: cache HIT skips React; shell streamed first, resume fills holes.
- [ ] Component using `usePostpone()` becomes a hole; siblings appear in cached shell.
- [ ] Error during prerender → graceful failure HTML; cache not written.
- [ ] Resume tree mismatch → hard error visible to dev (not silent client-rendering fallback).
- [ ] Chrome DevTools MCP test: shell first, `$RC` later, second request faster than first.

## Open questions remaining

a) `streaming?` change in OSS `render_options.rb` — does this risk breaking other consumers? Need
   to grep.
b) `ReactOnRailsPro::Cache.react_component_cache_key` already includes bundle digest, but we need
   to verify it also varies on `cache_key`. Need to read.
c) Should `ppr_prerender_timeout_ms` be per-call instead of global? Per-call wins, set default
   from config.
