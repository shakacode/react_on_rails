# Current Architecture: Detailed Problem Analysis

## Problem 1: Runtime Conditional Delegation ("The Pro Check")

### Where it happens

Every significant code path in `react_on_rails` checks `ReactOnRails::Utils.react_on_rails_pro?` at runtime to decide which implementation to use:

```
server_rendering_pool.rb:12       → Pool selection (ExecJS vs NodeRenderer)
server_rendering_js_code.rb:7     → JS code generation (core vs Pro)
pro_helper.rb:24                  → Component script generation
pro_helper.rb:51                  → Store script generation
render_options.rb:170             → Configuration value lookup
helper.rb:562                     → Attribution comment
utils.rb (multiple)               → Feature detection
```

### Why it's a problem

1. **Invisible coupling**: Core code contains hardcoded references to `ReactOnRailsPro::*` constants and classes. These references are only valid when Pro is installed, creating a latent dependency that can't be validated at load time.

2. **Non-deterministic code paths**: The behavior of `react_on_rails` changes based on whether another gem happens to be installed. This makes testing, debugging, and reasoning about behavior difficult — you must always ask "is Pro installed?"

3. **Two-level delegation**: `ServerRenderingPool` delegates to `ProRendering`, which then delegates again to `NodeRenderingPool` or `RubyEmbeddedJavaScript`. This creates a 3-class chain where the middle class (`ProRendering`) exists only to add caching.

4. **Inconsistent delegation style**: Some methods use `delegate :method, to: :pool`, others use explicit method forwarding. There's no shared interface or abstract base.

### The actual call chain for a render request

```
Helper#react_component
  → Helper#internal_react_component
    → Helper#server_rendered_react_component
      → ServerRenderingJsCode.server_rendering_component_js_code
        → js_code_renderer.render (dispatches to Core or Pro)
      → ServerRenderingPool.server_render_js_with_console_logging
        → pool.exec_server_render_js (dispatches to Core or Pro)
          → [Core] RubyEmbeddedJavaScript.exec_server_render_js
            → @js_context_pool.with { |ctx| ctx.eval(js_code) }
          → [Pro] ProRendering.exec_server_render_js
            → set_request_digest_on_render_options
            → cache check
            → pool.exec_server_render_js (dispatches again!)
              → NodeRenderingPool.exec_server_render_js
                → RubyEmbeddedJavaScript.exec_server_render_js(js_code, render_options, self)
                  → self.eval_js (back to NodeRenderingPool!)
                    → Request.render_code (HTTP to Node renderer)
```

That's **6 levels of delegation** for a single render, with the call bouncing between 4 different classes.

---

## Problem 2: String-Template JS Code Generation

### Where it happens

```
server_rendering_js_code.rb:36-50          (Core render method)
react_on_rails_pro/server_rendering_js_code.rb:60-101  (Pro render method)
helper.rb:767-791                          (Redux store initialization)
```

### Why it's a problem

1. **JavaScript built as Ruby strings**: The core generates JS via heredoc:

   ```ruby
   <<-JS
   (function() {
     var railsContext = #{rails_context};
     #{redux_stores}
     var props = #{props_string};
     return ReactOnRails.serverRenderReactComponent({...});
   })()
   JS
   ```

   This mixes two languages in one file with no syntax highlighting, no validation, and no testability of the generated JS in isolation.

2. **Two divergent generators**: Core generates a simple IIFE. Pro generates a complex IIFE with:
   - Optional RSC payload generation function injection
   - Dynamic rendering function name selection (3 possibilities)
   - React manifest injection into railsContext
   - Pre-hook JS execution
   - Parametric IIFE for component name/props replacement

   These two generators share no structure despite generating overlapping JS.

3. **No intermediate representation**: The generated JS goes directly from string to ExecJS/Node execution. There's no structured object that could be validated, cached by structure, or optimized.

4. **Regex-based RSC dispatch**: The Pro version uses a regex replacement on the generated JS string to support `generateRSCPayload`:
   ```ruby
   renderingRequest.replace(/\(\s*\)\s*$/, function() { return `(${...}, ${...})`; })
   ```
   This is fragile — it depends on the exact string format of the IIFE's closing `()`.

---

## Problem 3: Mixin-Based Method Overriding

### Where it happens

```
helper.rb:20          → include ReactOnRails::ProHelper
pro_helper.rb:7-38    → generate_component_script (overrides core)
pro_helper.rb:42-69   → generate_store_script (overrides core)
```

### Why it's a problem

1. **Silent replacement**: `ProHelper` is included into `Helper` at line 20, which means `generate_component_script` and `generate_store_script` in `ProHelper` silently replace whatever core defines. There's no explicit interface saying "these methods may be overridden."

2. **Shared mutable state**: Both core `Helper` and `ProHelper` share instance variables (`@registered_stores`, `@rendered_rails_context`, etc.) without any contract about who owns what.

3. **Order dependency**: The `include` must happen before any method calls. If Pro is loaded late, behavior changes mid-request.

4. **No composition**: The Pro helper can't selectively wrap the core behavior — it must completely replace it. This means any shared logic must be duplicated.

### Extension in Pro's helper app file

The `react_on_rails_pro_helper.rb` adds ~500 lines of additional methods to the view helper context:

- `cached_react_component`
- `stream_react_component`
- `rsc_payload_react_component`
- `async_react_component`
- `cached_stream_react_component`
- `cached_async_react_component`
- plus ~10 internal methods

These are loaded via Rails engine autoloading and become available in views alongside core methods, with no namespace separation.

---

## Problem 4: Stub-Throw Pattern (JS Side)

### Where it happens

```
createReactOnRails.ts:54-78     → 5 methods throw "requires Pro" errors
createReactOnRailsPro.ts:96-136 → Same 5 methods replaced with real implementations
```

### Why it's a problem

1. **Core package knows about Pro features**: The core package defines method stubs for Pro-only features (`streamServerRenderedReactComponent`, `serverRenderRSCReactComponent`, `getOrWaitForComponent`, etc.). Adding a new Pro feature requires modifying core.

2. **Runtime error discovery**: Users only discover they're missing Pro when they call a method and get a thrown error. No compile-time or bundler-time feedback.

3. **Multi-step object construction**: The `ReactOnRails` global is built in stages:
   - `createBaseClientObject` or `createBaseFullObject` builds the base
   - `createReactOnRails` adds core-specific functions via `Object.assign`
   - `createReactOnRailsPro` replaces core-specific functions via another `Object.assign`
   - `ReactOnRails.node.ts` adds `streamServerRenderedReactComponent`
   - `ReactOnRailsRSC.ts` adds `serverRenderRSCReactComponent`

   That's **5 mutation stages** for a single object.

4. **Conditional preservation** (createReactOnRailsPro.ts:146-154):

   ```typescript
   if (reactOnRailsPro.streamServerRenderedReactComponent) {
     reactOnRailsProSpecificFunctions.streamServerRenderedReactComponent =
       reactOnRailsPro.streamServerRenderedReactComponent;
   }
   ```

   Pro must check if a method was already added (by a previous entry point) before overwriting with its own stub. This creates a timing-dependent initialization.

5. **Type safety workaround**: Both factory functions use `as unknown as ReactOnRailsInternal` because TypeScript can't track mutations via `Object.assign`.

---

## Problem 5: Dual Classification Systems for Components

### Where it happens

```
packs_generator.rb:8-27   → Header comment explaining the two systems
packs_generator.rb:92     → client_entrypoint? checks 'use client' directive
packs_generator.rb:502-532 → File suffix matching (.client/.server)
```

### Why it's a problem

1. **Orthogonal but interacting**: System 1 (file suffixes) controls which webpack bundle includes a component. System 2 ('use client' directive) controls how Pro registers the component. These are independent decisions that produce a matrix:

   |                | No suffix                      | .client                       | .server                       |
   | -------------- | ------------------------------ | ----------------------------- | ----------------------------- |
   | `'use client'` | Both bundles, client component | Client only, client component | Server only, client component |
   | No directive   | Both bundles, server component | Client only, server component | Server only, server component |

   Some combinations don't make semantic sense (e.g., `.client` file as a React Server Component), but the system allows them.

2. **File I/O per classification**: `client_entrypoint?` reads each component file from disk to check for `'use client'` on every pack generation cycle.

3. **Heuristic warnings**: `warn_if_likely_client_component` uses regex pattern matching against React client-only APIs to warn about missing `'use client'` — a fragile, incomplete heuristic.

---

## Problem 6: Monolithic Rendering Pipeline

### Where it happens

```
helper.rb:697-765   → server_rendered_react_component (core)
helper.rb:576-603   → internal_react_component (orchestrator)
pro_rendering.rb:19-33 → exec_server_render_js (Pro wrapping)
```

### Why it's a problem

`server_rendered_react_component` (68 lines) handles:

- SSR skip (no prerender)
- Pool reset check
- JS code generation
- Pool execution
- Streaming result transformation
- Streaming error handling
- Sync error handling
- Prerender error construction

All in a single method with nested if/elsif/else branches. The Pro version wraps this with caching, tracing, and digest computation in another method.

There's no way to:

- Add a rendering middleware (e.g., custom caching, metrics, logging)
- Test individual stages in isolation
- Replace a single stage without copying the entire method

---

## Problem 7: Node Renderer Protocol Complexity

### Where it happens

```
node_rendering_pool.rb:48-88    → Eval with 410/bundle retry
node_rendering_pool.rb:98-109   → Path construction with hashes
request.rb:104-149              → HTTP request with retry logic
worker.ts:247-314               → Route handler
handleRenderRequest.ts:187-267  → Decision tree for bundles
vm.ts:181-372                   → VM creation with race conditions
```

### Why it's a problem

1. **Bundle management in the protocol**: The renderer manages its own bundle cache via HTTP status codes (410 = "send me the bundle"). This means every render request might trigger a bundle upload, adding latency and complexity.

2. **Request digest in URL**: The URL path includes a request digest (`/bundles/:hash/render/:digest`) that's only needed for prerender caching. The TODO comment at line 105 acknowledges this should be removed.

3. **Multi-pass rendering**: A single SSR request may require multiple HTTP round-trips:
   - First request → 410 (bundle needed)
   - Second request with bundle → 200 (success)
   - For RSC: potentially another round for the RSC bundle

4. **File-based locking**: The renderer uses filesystem locks to prevent concurrent bundle writes. This is complex and can cause timeout failures under load.
