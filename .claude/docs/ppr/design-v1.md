# PPR Design Proposal — v1 (for Codex review)

**Goal**: Implement a credible MVP of React 19.2 Partial Prerendering (PPR) for React on Rails
Pro that the dummy app can demo end-to-end. Stay within RFC #3244 directions but trim Phase 3
(node-renderer protocol bump) since we can dispatch through the existing render endpoint via a
new `render_mode`. Phases 1, 2, 4 are in-scope; docs/changelog are minimal.

## Non-goals (deliberately deferred)

- RSC + PPR composition. PPR works on the SSR HTML layer. Pages using `<RSCRoute>` keep working
  with `stream_react_component`; PPR is offered as a sibling helper.
- A new `/ppr/prerender` `/ppr/resume` endpoint pair on the node renderer. We reuse the existing
  `/bundles/<hash>/render/<digest>` endpoint and dispatch by `render_mode` inside the JS bundle.
  No `protocolVersion` bump.
- `prerender_only` build-time prerender CLI. First request lazily prerenders + caches.

## High level flow

```
ppr_react_component('Page', props: {...})
  ├── compute cache key (component + JSON-stable props + bundle digest + RoR-Pro version)
  ├── Rails.cache.fetch(key):
  │     MISS → invoke "ppr_prerender" render mode on the SSR bundle
  │            → returns Hash { shellHtml, postponedState (JSON string or null), hasErrors, isShellReady }
  │            → cache the Hash
  │     HIT  → load Hash from cache
  ├── if postponedState is null (fully static) → just emit shellHtml as a single chunk and finish
  └── else → invoke "ppr_resume" render mode on the SSR bundle, passing shell + postponedState via railsContext
        → JS path streams shellHtml first, then resumeToPipeableStream() output
        → flowed through existing Pro stream_view_containing_react_components pipeline
```

## File-level plan

### JS — packages/react-on-rails-pro/src

#### `capabilities/proPPR.ts` (new)
Exports `createProPPRCapability()` returning two methods registered on the Pro ReactOnRails
instance:

```ts
{
  isPPRCapable: true as const,
  // Non-streaming: returns a Hash via the existing serverRenderReactComponent contract,
  // with two extra fields: pprShellHtml, pprPostponedState (JSON string or null).
  // Reuses createReactOutput + ComponentRegistry like serverRenderReactComponent does.
  prerenderReactComponentForPPR(options: PPRPrerenderParams): Promise<{
    html: string; // shell HTML — duplicated under `html` so existing helpers pick it up cleanly
    pprShellHtml: string;
    pprPostponedState: string | null;
    consoleReplayScript: string;
    hasErrors: boolean;
    isShellReady: boolean;
  }>;
  // Streaming: shell first, then resume chunks via existing transform stream pipeline.
  resumeReactComponentForPPR(options: PPRResumeParams): Readable;
}
```

##### prerender phase

1. Set up an `AbortController`. The user app can opt to call `controller.abort()` themselves
   via a callback we expose, but default behavior is a configurable timeout
   (`pprPrerenderTimeoutMs`, default 30s).
2. Resolve the registered component with a `railsContext` extended with:
   `{ isPrerendering: true, ppr: { reason: 'prerender' } }`.
3. Wrap the resolved element in `<PPRPhaseContext.Provider value={{ phase: 'prerender' }}>`.
4. Call `prerenderToNodeStream(element, { signal, identifierPrefix: domNodeId, bootstrapScripts, onError })`.
5. Wait for the abort timer to fire OR an external "static work done" signal (TBD); call `controller.abort()`.
6. Drain the prelude into a string. Return `{ pprShellHtml, pprPostponedState: postponed ? JSON.stringify(postponed) : null }`.
7. Errors during static rendering → emit error HTML and set `hasErrors: true`.

##### resume phase

1. Parse `postponedState` from `railsContext.pprPostponedState` (JSON string).
2. Resolve the component again with `{ isPrerendering: false }` and the FULL railsContext (cookies, headers, query).
3. Wrap in `<PPRPhaseContext.Provider value={{ phase: 'resume' }}>`.
4. Use existing `transformRenderStreamChunksToResultObject` so the output passes through the same
   chunk-format pipeline that `streamServerRenderedReactComponent` uses.
5. Write `shellHtml` as the FIRST chunk via `writeChunk(shellHtml)`, then pipe
   `resumeToPipeableStream(element, postponed, { onError })` through `pipeToTransform`.
6. Run `injectRSCPayload` if the page contains RSC routes (re-uses RSCRequestTracker).

#### `postpone.ts` (new)
Exposes:

```ts
export const PPRPhaseContext: React.Context<{ phase: 'prerender' | 'resume' | null }>;
// Throws never-resolving promise during prerender, no-op during resume.
export function usePostpone(reason?: string): void;
```

`usePostpone` reads the phase from React context. The shared context provider is added by the
Pro PPR capability around the registered component. Server components don't use React context, but
any boundary that calls `usePostpone` is by definition rendering inside the SSR HTML pass — so
SSR React context is available.

The shared sentinel is allocated once:
```ts
const NEVER_RESOLVES: Promise<never> = new Promise(() => {});
```

#### `ReactOnRailsRSC.ts`, `ReactOnRails.node.ts`
Register `createProPPRCapability()` alongside existing capabilities.

### Ruby

#### `react_on_rails_pro/lib/react_on_rails_pro/ppr.rb` (new)
```ruby
module ReactOnRailsPro::PPR
  module_function

  CACHE_NAMESPACE = 'ror_pro_ppr'

  def cache_key(component_name, props:, **)
    [
      *ReactOnRailsPro::Cache.base_cache_key(CACHE_NAMESPACE, prerender: true),
      component_name,
      Digest::SHA1.hexdigest(props.to_json) # JSON-stable enough for cache keying
    ]
  end

  def fetch(component_name, props:, cache_options: {}, &block)
    Rails.cache.fetch(cache_key(component_name, props: props), cache_options) { yield }
  end
end
```

#### `react_on_rails_pro/lib/react_on_rails_pro/configuration.rb`
Add:
- `enable_ppr_support` (default false)
- `ppr_prerender_timeout_ms` (default 30_000)

#### `app/helpers/react_on_rails_pro_helper.rb`
Add `ppr_react_component(component_name, options = {})`:

```ruby
def ppr_react_component(component_name, options = {})
  raise ReactOnRailsPro::Error, 'PPR support is not enabled' unless ReactOnRailsPro.configuration.enable_ppr_support

  options[:prerender] = true
  on_complete = options.delete(:on_complete)

  cached = ReactOnRailsPro::PPR.fetch(
    component_name,
    props: options[:props] || {},
    cache_options: options[:cache_options] || {}
  ) do
    internal_ppr_prerender(component_name, options)
  end

  consumer_stream_async(on_complete: on_complete) do
    if cached[:postponed_state].nil?
      static_shell_only_stream(cached, component_name, options)
    else
      internal_ppr_resume(component_name, options.merge(
        ppr_shell_html: cached[:shell_html],
        ppr_postponed_state: cached[:postponed_state]
      ))
    end
  end
end
```

#### dispatch via render_mode
`server_rendering_js_code.rb` picks the JS function name based on render mode:
- `:ppr_prerender` → `'prerenderReactComponentForPPR'`
- `:ppr_resume`   → `'resumeReactComponentForPPR'`

The Ruby `internal_ppr_prerender` runs the existing non-streaming `eval_js` path; the Ruby
`internal_ppr_resume` runs the existing streaming `eval_streaming_js` path. railsContext gets
extra fields injected at JS level for both phases (`isPrerendering`, `pprPostponedState`,
`pprShellHtml`).

## Open questions for codex

1. **Timeout vs. signal-driven abort.** Fixed timeout is robust but pessimistic. Should we expose
   a per-render hook so user code can tell us when it's done with static work? Tradeoff:
   simplicity vs. flexibility.
2. **Tree-shape stability.** Bundle digest is part of the cache key — so a code change invalidates
   the shell. Is that enough, or do we also fingerprint the rendered tree? React itself logs a
   warning if resume sees a different tree shape; should we surface that as a Rails error?
3. **Shell-as-cached-Hash vs streaming the cached shell.** First version writes the shell as a
   single chunk. Pro: simplicity. Con: long shells have high TTFB. OK to defer streaming the shell?
4. **Where does `usePostpone` read its phase?** A React context wrapped around the registered
   component is clean but only works if the user's component tree is rendered through the Pro
   wrapper (it always is for `ppr_react_component`). Confirm this is acceptable, or do we want a
   `globalThis` fallback for code paths outside the wrapper?
5. **RSC interaction.** Pages using `<RSCRoute>` re-fetch their Flight payload on resume. Confirm
   we just document this and don't try to cache the Flight payload in v1.
6. **Postponed state size.** The `postponed` JSON can be large. Is Rails.cache (default
   memory_store) the right default? Or should we mandate `:file_store` / Redis with a size cap?

## Acceptance for v1

- `ppr_react_component('PPRDemo')` works on a Rails view in the Pro dummy app.
- First request: shell is built, cached, streamed; postponed state cached alongside.
- Subsequent request: cache HIT skips React; shell is streamed immediately, then resume fills holes.
- A component using `usePostpone()` becomes a hole; siblings appear in the cached shell.
- Multiple Suspense boundaries with different latencies all settle into the shell unless they call
  `usePostpone()`.
- Errors during prerender → fall back to `stream_react_component`-style error HTML.
- Chrome DevTools MCP test: shell appears in first chunk, `$RC` instructions arrive later.
