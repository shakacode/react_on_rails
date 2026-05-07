# PPR Design Proposal — v5 (post-codex-v4 review)

Codex blessed v4's four contract points; blocked on 2 import/registration concerns. v5 addresses both.

---

## `[v5 R-1]` — Lazy React PPR API imports

**Codex right**. Pro's `package.json` declares `react >= 16`, and a static import of
`react-dom/static.prerenderToNodeStream` would crash module loading in apps on React 16/17/18/19.0/19.1.

**Fix**: lazy-import React PPR APIs inside the first PPR call. Two-step approach:

### Step 1 — `proPPR.ts` does NOT import React PPR APIs at module top

```ts
// packages/react-on-rails-pro/src/capabilities/proPPR.ts (top — note: no direct react-dom imports)
import type { Readable } from 'stream';
// imports for our internal helpers, types, etc. — but NOT for prerenderToNodeStream / resumeToPipeableStream
```

### Step 2 — first call lazily resolves both React entry points

```ts
type PPRReactAPIs = {
  prerenderToNodeStream: typeof import('react-dom/static').prerenderToNodeStream;
  resumeToPipeableStream: typeof import('react-dom/server').resumeToPipeableStream;
};

let cachedPPRReactAPIs: PPRReactAPIs | null = null;
let cachedPPRError: Error | null = null;

async function loadPPRReactAPIs(): Promise<PPRReactAPIs> {
  if (cachedPPRReactAPIs) return cachedPPRReactAPIs;
  if (cachedPPRError) throw cachedPPRError;
  try {
    const [staticMod, serverMod] = await Promise.all([
      import('react-dom/static'),
      import('react-dom/server'),
    ]);
    if (typeof staticMod.prerenderToNodeStream !== 'function' ||
        typeof serverMod.resumeToPipeableStream !== 'function') {
      throw new Error(
        'React on Rails Pro PPR requires React 19.2+ (react-dom/static.prerenderToNodeStream and react-dom/server.resumeToPipeableStream). ' +
        `Current React is ${require('react').version}. Upgrade react and react-dom to >= 19.2.`
      );
    }
    cachedPPRReactAPIs = {
      prerenderToNodeStream: staticMod.prerenderToNodeStream,
      resumeToPipeableStream: serverMod.resumeToPipeableStream,
    };
    return cachedPPRReactAPIs;
  } catch (e) {
    cachedPPRError = e as Error;
    throw e;
  }
}
```

### Step 3 — capability check expanded

`pprRuntimeMissing()` (in `postpone.ts`) checks both VM globals AND React APIs:

```ts
async function checkPPRRuntime(): Promise<void> {
  const missing: string[] = [];
  if (typeof globalThis.AbortController !== 'function') missing.push('AbortController');
  if (typeof globalThis.AbortSignal !== 'function') missing.push('AbortSignal');
  if (typeof (globalThis as any).AsyncLocalStorage !== 'function') missing.push('AsyncLocalStorage');
  if (missing.length) throw new Error(`PPR missing VM globals: ${missing.join(', ')}`);
  await loadPPRReactAPIs(); // throws on missing React APIs
}
```

### Step 4 — registration is cheap

Registering the capability does NOT trigger the lazy import. The capability methods just call
`await loadPPRReactAPIs()` on entry. So `ReactOnRails.node.ts` can safely include
`createProPPRCapability()` without breaking older React apps. The error only surfaces if the
user actually invokes a PPR helper.

---

## `[v5 R-2]` — RSC component detection

**Codex right**. `registerServerComponent` wraps RSCRoute and calls plain `ReactOnRails.register`,
losing the "this is RSC" tag in the registry.

**Fix**: Tag RSC wrappers with a shared symbol; carry through `RegisteredComponent`.

### Step 1 — shared symbol

```ts
// packages/react-on-rails/src/types/rscMarker.ts (or a small new file in shared types)
// New OSS export so it's available to both Pro registry and Pro RSC wrapper.
export const RSC_COMPONENT_MARKER = Symbol.for('react_on_rails_pro.rsc_component');

export function markAsRSCComponent<T extends object>(fn: T): T {
  Object.defineProperty(fn, RSC_COMPONENT_MARKER, { value: true, enumerable: false, configurable: false });
  return fn;
}

export function isRSCComponent(value: unknown): boolean {
  // typeof a function is 'function', not 'object' — accept both.
  return !!value &&
    (typeof value === 'function' || typeof value === 'object') &&
    (value as any)[RSC_COMPONENT_MARKER] === true;
}
```

### Step 2 — wrap server component registrations

```ts
// packages/react-on-rails-pro/src/registerServerComponent/server.tsx
const componentsWrappedInRSCRoute: Record<string, RenderFunction> = {};
for (const [componentName] of Object.entries(components)) {
  componentsWrappedInRSCRoute[componentName] = markAsRSCComponent(
    wrapServerComponentRenderer(
      (props: unknown) => <RSCRoute componentName={componentName} componentProps={props} />,
      componentName,
    ),
  );
}
```

### Step 3 — proPPR refuses RSC components

```ts
// in prerenderReactComponentForPPR
const componentObj = ComponentRegistry.get(name);
if (isRSCComponent(componentObj.component)) {
  throw new Error(
    `ppr_react_component does not support RSC components in v1. ` +
    `Use stream_react_component for "${name}" or wait for PPR+RSC support.`
  );
}
```

The Ruby helper relays this error to the Rails view via the standard error path
(`hasErrors: true`).

---

## v5 implementation contract (final)

1. **Cache shape**: `{ shell_html: String, postponed_state: String|nil, console_replay_script: String, ppr_version: 1 }`. ✅
2. **Helper signature**: `ppr_react_component(name, cache_key:, props:, prerender_timeout_ms:, cache_options:, if:, unless:, on_complete:)`. ✅
3. **Failure semantics**: prerender JS returns `hasErrors: true`; Ruby raises (or falls back per `raise_on_prerender_error`); cache never written. ✅
4. **Registration scope**: PPR registered in `ReactOnRails.node.ts` only. RSC components rejected at runtime. ✅
5. **Lazy React imports**: PPR APIs loaded on first call, not at module top. ✅
6. **VM globals**: `AbortController`, `AbortSignal`, `AsyncLocalStorage` injected unconditionally. ✅
7. **Phase tracking**: `withPhase(phase, fn)` defense-in-depth wrap on every callback boundary. ✅
8. **Predicate audit**: `streaming?` updated where needed, surgically; `html_or_rsc_streaming?`
   added; `js_code_builder.rb`, `pro_rendering.rb`, `server_rendering_js_code.rb` updated. ✅

## Implementation order

1. `react_on_rails/lib/react_on_rails/react_component/render_options.rb` — predicates.
2. `react_on_rails_pro/lib/react_on_rails_pro/{server_rendering_pool/pro_rendering.rb, server_rendering_js_code.rb, js_code_builder.rb, request.rb}` — predicate consumers.
3. `packages/react-on-rails-pro-node-renderer/src/worker/vm.ts` — VM globals (AbortController, AbortSignal, AsyncLocalStorage), unconditional.
4. `packages/react-on-rails/src/types/rscMarker.ts` — RSC marker symbol (OSS so it's shared).
5. `packages/react-on-rails-pro/src/registerServerComponent/server.tsx` — tag RSC wrappers.
6. `packages/react-on-rails-pro/src/postpone.ts` — `withPhase`, `usePostpone`.
7. `packages/react-on-rails-pro/src/capabilities/proPPR.ts` — capability impl, lazy React imports.
8. `packages/react-on-rails-pro/src/ReactOnRails.node.ts` — register PPR capability.
9. `react_on_rails_pro/lib/react_on_rails_pro/{configuration.rb, ppr.rb}` — config + cache module.
10. `react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb` — `ppr_react_component`.
11. JS unit tests (`packages/react-on-rails-pro/tests/proPPR.test.tsx`).
12. Ruby unit tests (`react_on_rails_pro/spec/react_on_rails_pro/ppr_spec.rb`).
13. VM tests (`packages/react-on-rails-pro-node-renderer/tests/vm.test.ts`).
14. Dummy app demo (`react_on_rails_pro/spec/dummy/client/app/components/PPRDemo/`, `app/views/pages/ppr_demo.html.erb`, route).
15. Chrome DevTools MCP verification + Playwright E2E (`react_on_rails_pro/spec/dummy/e2e-tests/ppr.spec.ts`).
16. CHANGELOG entry.
