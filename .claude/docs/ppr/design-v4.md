# PPR Design Proposal — v4 (post-codex-v3 review)

Codex concurred on R-2 (resume is sync — APPROVED). 4 new findings; addressed below as `[v4]`.

---

## `[v4 R-1]` — JsCodeBuilder also reads `streaming?`

**Codex right**. `react_on_rails_pro/lib/react_on_rails_pro/js_code_builder.rb:107`:
```ruby
def rsc_streaming?(render_request)
  ReactOnRailsPro.configuration.enable_rsc_support && render_request.streaming?
end
```

**Fix**: Update to use `html_or_rsc_streaming?` (or equivalently, exclude PPR resume explicitly).
Add a delegated predicate to `RenderRequest`:

```ruby
# react_on_rails_pro/lib/react_on_rails_pro/request.rb (or wherever RenderRequest lives)
delegate :html_or_rsc_streaming?, :ppr_prerender?, :ppr_resume?, to: :@render_options

# js_code_builder.rb:107
def rsc_streaming?(render_request)
  ReactOnRailsPro.configuration.enable_rsc_support && render_request.html_or_rsc_streaming?
end
```

Audit script (broader): `grep -RIn 'streaming?' react_on_rails_pro/ react_on_rails/`.
Confirmed consumers requiring update:
- `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_pool/pro_rendering.rb:64`
- `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb` (RSC params/bundle dispatch)
- `react_on_rails_pro/lib/react_on_rails_pro/js_code_builder.rb:107`
- `react_on_rails/lib/react_on_rails/server_rendering_pool/ruby_embedded_java_script.rb:61, :82`
  → KEEP (we want PPR resume to dispatch through the streaming HTTP path)

---

## `[v4 R-2]` — `configuration.rb` syntax

**Codex right**. The repo uses `attr_accessor` + `DEFAULT_*` constants + explicit `initialize`
keyword args. Concretely:

```ruby
# Add to constants block:
DEFAULT_ENABLE_PPR_SUPPORT = false
DEFAULT_PPR_PRERENDER_TIMEOUT_MS = 8_000

# Append to attr_accessor list:
attr_accessor ..., :enable_ppr_support, :ppr_prerender_timeout_ms

# Update self.configuration block:
@configuration ||= Configuration.new(
  ...
  enable_ppr_support: Configuration::DEFAULT_ENABLE_PPR_SUPPORT,
  ppr_prerender_timeout_ms: Configuration::DEFAULT_PPR_PRERENDER_TIMEOUT_MS,
)

# Update initialize signature, body assigns, etc.
```

We will follow the existing pattern verbatim.

---

## `[v4 R-3]` — `protocolVersion` bump is unsafe

**Codex right**. `protocolVersion` mismatch returns `412` and Ruby raises hard. Bumping it would
break older renderers immediately upon gem upgrade.

**Fix**: **Do NOT bump `protocolVersion`**. Use runtime capability detection instead.

```ts
// packages/react-on-rails-pro/src/postpone.ts (module top)
function pprRuntimeMissing(): string | null {
  const missing: string[] = [];
  if (typeof globalThis.AbortController !== 'function') missing.push('AbortController');
  if (typeof globalThis.AbortSignal !== 'function') missing.push('AbortSignal');
  if (typeof (globalThis as any).AsyncLocalStorage !== 'function') missing.push('AsyncLocalStorage');
  return missing.length ? missing.join(', ') : null;
}

// In capabilities/proPPR.ts entry (lazy-checked at first call):
const missing = pprRuntimeMissing();
if (missing) {
  throw new Error(
    `React on Rails Pro PPR requires runtime globals not available in this VM: ${missing}. ` +
    `Upgrade your Pro node renderer to a version that injects these globals (>= the version that ships PPR support).`
  );
}
```

Add a Ruby-side companion check that prints a helpful message at boot if `enable_ppr_support` is
true but the renderer doesn't have these globals. We add a tiny capability probe sent to the
renderer at startup:

```ruby
# Lazy: only checked when first PPR helper is invoked, to avoid extra startup cost.
def ppr_react_component(component_name, options = {})
  ReactOnRailsPro::PPR.ensure_runtime_supported!
  ...
end
```

`ensure_runtime_supported!` issues a `runInVM` that returns `typeof AbortController === 'function' && typeof AsyncLocalStorage === 'function'`. Cached after first success per process.

This avoids the protocol-version compatibility break entirely.

---

## `[v4 R-4]` — ALS context propagation across delayed callbacks

**Codex right** — ALS is fragile when callbacks fire from external async resources. While Node's
ALS does propagate across `await`, timers, and most stream events that were registered inside
`als.run`, codex is correct that it's risky to assume — and stream `_read` invoked by an
external pull may run with the consumer's ALS context, not the producer's.

**Fix**: Defense-in-depth — wrap every callback with `phaseStore.run` explicitly. Also,
inject PPR globals OUTSIDE the `supportModules` gate so PPR-without-supportModules either works
or fails fast.

```ts
// packages/react-on-rails-pro/src/postpone.ts
const phaseStore = new (globalThis as any).AsyncLocalStorage<{ phase: 'prerender' | 'resume' }>();
type Phase = 'prerender' | 'resume';

export function withPhase<T>(phase: Phase, fn: () => T): T {
  return phaseStore.run({ phase }, fn);
}

export function getCurrentPhase(): Phase | null {
  return phaseStore.getStore()?.phase ?? null;
}

export function usePostpone(reason?: string): void {
  if (getCurrentPhase() === 'prerender') throw NEVER_RESOLVES;
}
```

In `proPPR.ts`:

```ts
async function prerenderReactComponentForPPR(options) {
  return withPhase('prerender', async () => {
    const controller = new AbortController();
    const timer = setTimeout(
      () => withPhase('prerender', () => controller.abort()),    // re-bind in callback
      options.prerenderTimeoutMs,
    );
    try {
      const { prelude, postponed } = await prerenderToNodeStream(element, {
        signal: controller.signal,
        identifierPrefix: domNodeId,
        onError: (err) => withPhase('prerender', () => reportError(err)),
      });
      const shellHtml = await streamToString(prelude); // streamToString listens to 'data'/'end'
      ...
    } finally {
      clearTimeout(timer);
    }
  });
}
```

Likewise for resume — wrap `resumeToPipeableStream(...)`, `pipe(destination)`, all event listeners
in `withPhase('resume', ...)`. Cheap, robust, no reliance on subtle async_hooks behavior.

For inject-outside-supportModules: make a separate `ppr-globals` block in vm.ts that runs
unconditionally (or at least independently of `supportModules`). PPR-only globals are tiny and
have no side effects.

```ts
// vm.ts (always-on PPR globals, independent of supportModules)
const PPR_GLOBALS = { AbortController, AbortSignal, AsyncLocalStorage };
extendContext(contextObject, PPR_GLOBALS);
```

This means PPR works even when users have `supportModules: false`, AND it preserves the
existing semantic that PPR-using codepaths fail loud (via runtime detection) if for some
reason these globals are missing.

VM tests:
```ts
test('AbortController is available unconditionally', async () => {
  const config = getConfig();
  config.supportModules = false; // explicit
  await createUploadedBundleForTest();
  await buildVM(uploadedBundlePathForTest());
  const result = await runInVM(`typeof AbortController === 'function'`, uploadedBundlePathForTest());
  expect(result).toBe('true');
});
test('AsyncLocalStorage is available unconditionally', ...);
test('phase persists across await/setTimeout/abort within ALS run', ...);
```

---

## Open question answered (codex v3 final asks)

a) **Cache shape blessed**: `{ shell_html: String, postponed_state: String|nil, console_replay_script: String, ppr_version: 1 }`.
b) **`cache_key:` required**, `:if`/`:unless` supported (mirrors `cached_react_component`). The
   `use_cache?` check from `ReactOnRailsPro::Cache` already handles `:if`/`:unless`.
c) **Failure mode**: prerender JS returns `{ hasErrors: true, errorMessage }`; Ruby helper raises
   `ReactOnRailsPro::Error` (or falls back to error HTML if `raise_on_prerender_error: false`),
   never writes the cache (Rails.cache.fetch's block must return normally to write).

## Diff vs v3

- `js_code_builder.rb` updated; `RenderRequest` gets new delegated predicates.
- `configuration.rb` follows existing `attr_accessor` + `DEFAULT_*` + `initialize` pattern.
- No `protocolVersion` bump. Runtime capability detection in JS + Ruby probe.
- Defense-in-depth ALS wrapping (`withPhase`) on every callback boundary.
- PPR globals injected unconditionally (independent of `supportModules`).

## Verdict request

If this is APPROVE, I'll start implementing in this order:
1. OSS render_options.rb predicates (single small commit)
2. Pro consumer surgical updates (pro_rendering.rb, server_rendering_js_code.rb, js_code_builder.rb)
3. Node renderer VM globals (AbortController, AbortSignal, AsyncLocalStorage)
4. JS PPR capability + postpone helper + register in node entry only
5. Ruby ppr_react_component + PPR cache module + configuration knobs
6. Dummy app demo pages (multi-Suspense, edge cases)
7. Tests: unit (JS+Ruby) + Playwright + Chrome DevTools MCP verification
