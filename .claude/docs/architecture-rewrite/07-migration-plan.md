# Migration Plan: Step-by-Step with Backward Compatibility

## Guiding Principles

1. **Each step produces a working, releasable state** — no multi-step atomic changes
2. **Tests must pass at every step** — existing integration tests are the compatibility contract
3. **Deprecate before removing** — old interfaces get deprecation warnings before deletion
4. **Internal changes first, external last** — restructure internals before changing interfaces between packages

## Phase 0: Foundation (No Behavioral Changes)

### Step 0.1: Add RenderRequest data object

**Files:** New `lib/react_on_rails/render_request.rb`

Create the `RenderRequest` class alongside existing code. Nothing uses it yet.

```ruby
module ReactOnRails
  class RenderRequest
    attr_reader :component_name, :props, :rails_context,
                :store_initializations, :render_options, :dom_id

    def initialize(component_name:, props:, rails_context:,
                   store_initializations:, render_options:)
      @component_name = component_name
      @props = props
      @rails_context = rails_context
      @store_initializations = store_initializations
      @render_options = render_options
      @dom_id = render_options.dom_id
    end

    def streaming?
      @render_options.streaming?
    end

    def cache_key
      @cache_key ||= Digest::MD5.hexdigest(to_cache_data.to_json)
    end

    def to_cache_data
      { componentName: @component_name, props: @props,
        railsContext: @rails_context, stores: @store_initializations,
        domNodeId: @dom_id, renderMode: @render_options.render_mode }
    end
  end
end
```

**Verification:** All existing tests pass. No behavior changes.

### Step 0.2: Add RenderingStrategy interface

**Files:** New `lib/react_on_rails/rendering_strategy.rb`

Define the module as documentation of the contract. No implementation changes.

**Verification:** All existing tests pass.

### Step 0.3: Add JsCodeBuilder (core)

**Files:** New `lib/react_on_rails/js_code_builder.rb`

Create the builder that produces identical output to `ServerRenderingJsCode.render`. Add tests comparing output character-by-character.

**Verification:** New unit tests verify `JsCodeBuilder.new.build(request) == ServerRenderingJsCode.render(...)` for various inputs.

### Step 0.4: Add ComponentClassifier

**Files:** New `lib/react_on_rails/component_classifier.rb`

Create alongside existing pack generation code. Add unit tests.

**Verification:** All existing tests pass. New unit tests verify classification matches current behavior.

---

## Phase 1: Strategy Pattern (Ruby Side)

### Step 1.1: Create ExecJSRenderingStrategy

**Files:** New `lib/react_on_rails/exec_js_rendering_strategy.rb`

Wrap existing `RubyEmbeddedJavaScript` logic in the strategy interface:

```ruby
class ExecJSRenderingStrategy
  include RenderingStrategy

  def execute(render_request)
    js_code = render_request.to_js
    # Delegate to existing pool logic
    RubyEmbeddedJavaScript.exec_server_render_js(js_code, render_request.render_options)
  end

  def reset
    RubyEmbeddedJavaScript.reset_pool
  end

  def reset_if_bundle_changed
    RubyEmbeddedJavaScript.reset_pool_if_server_bundle_was_modified
  end
end
```

Initially, this delegates to the existing `RubyEmbeddedJavaScript` class rather than replacing it.

**Verification:** Unit tests verify the strategy produces identical results to direct `RubyEmbeddedJavaScript` calls.

### Step 1.2: Create NodeRenderingStrategy (Pro)

**Files:** New `lib/react_on_rails_pro/node_rendering_strategy.rb`

Wrap existing `NodeRenderingPool` and `ProRendering` logic in the strategy interface. Same delegation approach.

**Verification:** Pro integration tests pass with strategy wrapping existing code.

### Step 1.3: Wire strategies into configuration

**Files:** Modified `lib/react_on_rails/configuration.rb`, `lib/react_on_rails/engine.rb`

Add `rendering_strategy` to configuration. Engine initializers set the default:

```ruby
# react_on_rails/engine.rb
config.after_initialize do
  ReactOnRails.rendering_strategy ||= ReactOnRails::ExecJSRenderingStrategy.new
end

# react_on_rails_pro/engine.rb
config.after_initialize do
  ReactOnRails.rendering_strategy = ReactOnRailsPro::NodeRenderingStrategy.new
end
```

**Verification:** All tests pass. The strategy is set but not yet used by the rendering path.

### Step 1.4: Switch helper to use strategy

**Files:** Modified `lib/react_on_rails/helper.rb`

Change `server_rendered_react_component` to use the configured strategy:

```ruby
def server_rendered_react_component(render_options)
  return { "html" => "", "consoleReplayScript" => "" } unless render_options.prerender

  render_request = build_render_request(render_options)
  ReactOnRails.rendering_strategy.reset_if_bundle_changed
  result = ReactOnRails.rendering_strategy.execute(render_request)

  # ... existing error handling and streaming transforms ...
end
```

**This is the critical switchover.** Run full test suite.

**Verification:** All integration tests pass. Behavior identical.

### Step 1.5: Remove ServerRenderingPool dispatch

**Files:** Modified `lib/react_on_rails/server_rendering_pool.rb`

Remove the `react_on_rails_pro?` check. The pool module becomes a thin wrapper over the strategy, or is removed entirely if nothing depends on it externally.

Add deprecation warning if anyone calls `ServerRenderingPool` directly.

**Verification:** All tests pass. Deprecation warnings appear for direct pool access.

### Step 1.6: Remove ServerRenderingJsCode dispatch

**Files:** Modified `lib/react_on_rails/server_rendering_js_code.rb`

The `js_code_renderer` dispatch is eliminated. `RenderRequest#to_js` calls the configured `JsCodeBuilder`.

**Verification:** All tests pass.

---

## Phase 2: Script Generators (Ruby Side)

### Step 2.1: Extract DefaultComponentScriptGenerator

**Files:** New `lib/react_on_rails/default_component_script_generator.rb`

Move `generate_component_script` logic from `ProHelper` into a class.

### Step 2.2: Extract ImmediateHydrationComponentScriptGenerator (Pro)

**Files:** New `lib/react_on_rails_pro/immediate_hydration_component_script_generator.rb`

Move immediate hydration logic into a subclass that calls `super`.

### Step 2.3: Wire generators into configuration

**Files:** Modified `configuration.rb`, engine initializers

### Step 2.4: Remove ProHelper mixin

**Files:** Modified `helper.rb`, removed `pro_helper.rb`

`helper.rb` no longer `include`s `ProHelper`. Instead it calls the configured generator.

**Verification:** All tests pass. Helper behavior unchanged.

---

## Phase 3: JS Package Restructuring

### Step 3.1: Create capability modules

**Files:** New `packages/react-on-rails/src/capabilities/*.ts`

Extract existing code into capability modules. Each module exports an object with the same methods currently on the `ReactOnRails` global.

### Step 3.2: Rewrite createReactOnRails as capability composer

**Files:** Modified `packages/react-on-rails/src/createReactOnRails.ts`

The factory function now accepts an array of capabilities.

### Step 3.3: Update entry points to use capabilities

**Files:** Modified `packages/react-on-rails/src/ReactOnRails.client.ts`, `ReactOnRails.full.ts`

Assemble capabilities into the `ReactOnRails` object.

### Step 3.4: Update Pro entry points

**Files:** Modified `packages/react-on-rails-pro/src/*.ts`

Pro imports capabilities from `react-on-rails/capabilities/*` and adds its own.

### Step 3.5: Unify ComponentRegistry

**Files:** Modified `packages/react-on-rails/src/ComponentRegistry.ts`, removed Pro's separate registry

The core registry gains async waiting. Pro's capability just exposes `getOrWaitFor`.

### Step 3.6: Update package.json exports

**Files:** Modified `packages/react-on-rails/package.json`

Add `capabilities/*` exports. Keep `@internal/*` as deprecated aliases.

**Verification:** All JS tests pass. Client and server bundles produce identical behavior.

---

## Phase 4: Node Renderer Protocol (Phase 1 — Clean Up)

### Step 4.1: Add proactive bundle upload

**Files:** Modified `node_rendering_pool.rb`, `request.rb`, `worker.ts`

Add `POST /bundles/:hash/upload` endpoint. Ruby uploads bundles proactively during `to_prepare`.

Keep the 410 retry path as fallback.

### Step 4.2: Simplify render endpoint

**Files:** Modified `worker.ts`, `handleRenderRequest.ts`

Add `POST /render` endpoint that accepts `bundleHash` as a field. Deprecate the old URL pattern.

### Step 4.3: Unify error responses

**Files:** Modified `worker.ts`, `handleRenderRequest.ts`, `node_rendering_pool.rb`

Standardize error format to JSON with `code` field. Ruby handles new error format alongside old.

### Step 4.4: Move auth and protocol version to headers

**Files:** Modified `request.rb`, `worker.ts`, `authHandler.ts`, `checkProtocolVersionHandler.ts`

### Step 4.5: Remove old endpoints

**Files:** Modified `worker.ts`

Remove deprecated URL patterns. Bump protocol version.

**Verification:** All integration tests pass with new protocol.

---

## Phase 5: Node Renderer Protocol (Phase 2 — JSON Protocol)

### Step 5.1: Add JSON render handler to Node renderer

**Files:** Modified `worker.ts`, new `handleJsonRenderRequest.ts`

The renderer accepts JSON render requests alongside JS code. Feature-flagged for testing.

### Step 5.2: Add JSON request generation to Ruby

**Files:** Modified `node_rendering_strategy.rb`

`NodeRenderingStrategy` sends JSON when the renderer supports it (detected via a capability check on the `/health` endpoint).

### Step 5.3: Switch default to JSON

After testing, make JSON the default. Keep JS code path as fallback.

### Step 5.4: Remove JS code path

Once stable, remove the JS code execution path from the renderer.

**Verification:** All integration tests pass with JSON protocol.

---

## Phase 6: Component Classification

### Step 6.1: Integrate ComponentClassifier into PacksGenerator

**Files:** Modified `packs_generator.rb`

Use the classifier for all pack generation. Verify output matches current behavior.

### Step 6.2: Remove file I/O classification

Remove `client_entrypoint?` and `warn_if_likely_client_component`. Add deprecation warning for RSC users who rely on `'use client'` without `.server` suffix.

### Step 6.3: Simplify pack generation

Reduce to single-pass processing.

**Verification:** All integration tests pass. Generated packs identical.

---

## Backward Compatibility Checklist

At each step, verify:

- [ ] `react_component("Foo", props: { a: 1 })` renders identically
- [ ] `react_component("Foo", props: { a: 1 }, prerender: true)` SSR works
- [ ] `react_component_hash("Foo", props: { a: 1 }, prerender: true)` returns Hash
- [ ] `redux_store("myStore", props: { items: [] })` initializes store
- [ ] `server_render_js("1 + 1")` returns "2"
- [ ] `ReactOnRails.register({ Foo })` registers component
- [ ] `ReactOnRails.registerStore({ myStore: storeGenerator })` registers store
- [ ] `ReactOnRails.getStore("myStore")` retrieves store
- [ ] Render function `(props, railsContext) => <Foo />` works
- [ ] Renderer function `(props, railsContext, domNodeId) => { render(...) }` works
- [ ] Auto-bundling generates correct packs
- [ ] Turbo/Turbolinks navigation works
- [ ] CSP nonce handling works
- [ ] Console replay works
- [ ] Error handling (PrerenderError) works
- [ ] Hot Module Replacement works in development
- [ ] [Pro] Streaming SSR works
- [ ] [Pro] Cached rendering works
- [ ] [Pro] Async rendering works
- [ ] [Pro] Immediate hydration works
- [ ] [Pro] RSC payload generation works
- [ ] [Pro] ExecJS fallback works
- [ ] [Pro] Node renderer communication works

## Timeline Recommendation

| Phase   | Scope                             | Estimated PRs |
| ------- | --------------------------------- | :-----------: |
| Phase 0 | Foundation (additive, no changes) |  4 small PRs  |
| Phase 1 | Strategy pattern                  |    3-4 PRs    |
| Phase 2 | Script generators                 |    2-3 PRs    |
| Phase 3 | JS package restructuring          |    3-4 PRs    |
| Phase 4 | Node renderer cleanup             |    3-4 PRs    |
| Phase 5 | JSON protocol                     |    3-4 PRs    |
| Phase 6 | Component classification          |    2-3 PRs    |

Total: ~20-26 PRs, each independently releasable.

Phases 1-2 (Ruby side) and Phase 3 (JS side) can proceed in parallel.
Phases 4-5 (protocol) depend on Phase 1 being complete.
Phase 6 is independent and can be done at any time.

## Risk Mitigation

1. **Each PR is small and focused** — easy to review, easy to revert
2. **Feature flags** — new code paths can be gated behind configuration
3. **Shadow testing** — run both old and new code paths and compare results
4. **Deprecation before removal** — old interfaces log warnings for one major version
5. **Integration test coverage** — the dummy apps in both gems are the primary compatibility test
