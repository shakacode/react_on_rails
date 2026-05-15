# Plan: Decouple Props from JS Source String (Issue #3281)

## Problem Statement

React on Rails Pro embeds component props as a JavaScript object literal inside the IIFE source string sent to the Node renderer. For large components (e.g., the mega benchmark with ~1.1 MB of props JSON), this means V8 must parse the entire props payload through its JavaScript parser on every request.

Crucially, **V8 cannot cache the compiled IIFE across requests** because `domNodeId` is a random UUID generated per render, making every source string unique. This means V8 re-parses the full source (including the large props object) from scratch on every single request.

## V8 Compile Cache Discovery

V8 has an in-memory compile cache keyed on source string identity. When the exact same source string is passed to `vm.runInContext()`, V8 reuses the previously compiled bytecode, skipping parse and compile entirely.

However, the React on Rails Pro rendering IIFE includes `domNodeId` (a random UUID per request), so **every source string is unique** and V8 gets zero cache hits. This was confirmed by adding MD5 hash instrumentation to `vm.ts` — every request produced a different hash.

This means the full cost of V8's JavaScript parser is paid on every request, and the larger the props payload, the more time is wasted.

## Hypothesis

`JSON.parse()` uses V8's optimized JSON parser, which is significantly faster than V8's full JavaScript parser for structured data. By sending props as a separate field and using `JSON.parse()` on the Node side, we should see measurable performance improvement for large payloads.

## Microbenchmark Results

A standalone microbenchmark (`/tmp/bench-json-vs-js-v2.mjs`) compared parsing 1.1 MB of JSON data as a JS object literal vs. `JSON.parse()`:

| Method                                     | Mean (ms) | Notes                                                |
| ------------------------------------------ | --------- | ---------------------------------------------------- |
| JS object literal (unique source per call) | 11.86     | Simulates real-world: unique `domNodeId` per request |
| `JSON.parse()`                             | 6.56      | V8's optimized JSON parser                           |

**JSON.parse is ~1.8x faster** (~5.3 ms savings per request for 1.1 MB payloads).

> **Note on benchmark methodology:** An initial benchmark showed no difference (~0.4 ms) because it reused the same source string across iterations, allowing V8's compile cache to kick in. The corrected benchmark uses a unique UUID per iteration to simulate the real-world behavior where `domNodeId` changes every request.

## End-to-End Benchmark Results

Benchmarked the full React on Rails Pro rendering pipeline (30 runs, 15 warmup, Rails + Node renderer, mega benchmark page with ~1.1 MB props):

| Endpoint                      | Baseline (ms) | Experiment (ms) | Diff (ms) | Improvement |
| ----------------------------- | ------------- | --------------- | --------- | ----------- |
| `/mega_benchmark_traditional` | 132.4         | 113.9           | -18.5     | 14.0%       |

The ~18 ms improvement exceeds the microbenchmark prediction (~5 ms) because the end-to-end measurement also captures reduced HTTP body size (the IIFE source string shrinks from ~1.1 MB to ~200 bytes, reducing serialization/transfer overhead to the Node renderer).

## Architecture: Current Render Path

The production render path for server-side rendering:

```
rails_helper.rb (react_component / stream_react_component)
  → ReactOnRails::ServerRenderingJsCode.server_rendering_component_js_code
    → ReactOnRailsPro::ServerRenderingJsCode.render (builds IIFE with embedded props)
      → ReactOnRails::ServerRenderingPool#exec_server_render_js
        → ReactOnRailsPro::Request#form_with_code (HTTP POST to Node renderer)
          → Node: worker.ts route handler
            → handleRenderRequest.ts
              → vm.ts: runInVM (vm.runInContext with the IIFE)
```

**Important:** The `JsCodeBuilder` class (part of the capability architecture from issue #2905) is NOT yet wired into the main rendering path. The actual production path goes through `ReactOnRailsPro::ServerRenderingJsCode.render`.

## Implementation Plan

### 1. Ruby: `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb`

In the `render` method:

- Stash the props string in a thread-local variable for the downstream `Request` layer
- Replace the inline props embedding with a read from `globalThis.__rorpProps`
- Keep the IIFE parameter fallback for RSC `generateRSCPayload` re-invocations

```ruby
def render(props_string, rails_context, redux_stores, react_component_name, render_options)
  Thread.current[:ror_decoupled_props] = props_string

  # ... existing render_function_name and rsc_params logic unchanged ...

  <<-JS
  (function(componentName = #{react_component_name.to_json}, props = undefined) {
    var railsContext = #{rails_context};
    #{rsc_params}
    #{generate_rsc_payload_js_function(render_options)}
    #{ssr_pre_hook_js}
    #{redux_stores}
    var usedProps = typeof props === 'undefined' ? globalThis.__rorpProps : props;
    #{async_props_setup_js(render_options)}
    return ReactOnRails[#{render_function_name}]({
      name: componentName,
      domNodeId: #{render_options.dom_id.to_json},
      props: usedProps,
      trace: #{render_options.trace},
      railsContext: railsContext,
      throwJsErrors: #{ReactOnRailsPro.configuration.throw_js_errors},
      renderingReturnsPromises: #{ReactOnRailsPro.configuration.rendering_returns_promises},
      generateRSCPayload: typeof generateRSCPayload !== 'undefined' ? generateRSCPayload : undefined,
    });
  })()
  JS
end
```

The key change is replacing `#{props_string}` (which was on the old line: `var usedProps = typeof props === 'undefined' ? #{props_string} : props;`) with `globalThis.__rorpProps`. The thread-local `Thread.current[:ror_decoupled_props]` passes the raw JSON string to the Request layer without changing method signatures.

### 2. Ruby: `react_on_rails_pro/lib/react_on_rails_pro/request.rb`

In `form_with_code`, pick up the thread-local and send props as a separate form field:

```ruby
def form_with_code(js_code, send_bundle)
  form = common_form_data
  form["renderingRequest"] = js_code
  if (props = Thread.current[:ror_decoupled_props])
    form["props"] = props
    Thread.current[:ror_decoupled_props] = nil
  end
  populate_form_with_bundle_and_assets(form, check_bundle: false) if send_bundle
  form
end
```

### 3. Ruby: `react_on_rails_pro/lib/react_on_rails_pro/rendering_strategy/node_strategy.rb`

Add cleanup in an `ensure` block to prevent thread-local leaks:

```ruby
ensure
  Thread.current[:ror_decoupled_props] = nil
```

### 4. Node: `packages/react-on-rails-pro-node-renderer/src/worker.ts`

In the `/bundles/:bundleTimestamp/render/:renderRequestDigest` route handler, extract `body.props`:

```typescript
const { renderingRequest, props: propsJson } = body as Record<string, unknown>;
// ... pass to handleRenderRequest:
propsJson: typeof propsJson === 'string' ? propsJson : undefined,
```

### 5. Node: `packages/react-on-rails-pro-node-renderer/src/worker/handleRenderRequest.ts`

Add `propsJson?: string` to the params type and thread it through both `prepareResult` calls (regular and streaming paths):

```typescript
interface HandleRenderRequestParams {
  // ... existing fields ...
  propsJson?: string;
}

// Thread to prepareResult → executionContext.runInVM
```

### 6. Node: `packages/react-on-rails-pro-node-renderer/src/worker/vm.ts`

In `runInVM`, accept optional `propsJson`, inject parsed props into the VM context before executing the IIFE:

```typescript
const runInVM = async (
  renderingRequest: string,
  bundleFilePath: string,
  vmCluster?: typeof cluster,
  propsJson?: string,
) => {
  // ... existing context setup ...
  try {
    if (propsJson) {
      context.__rorpProps = JSON.parse(propsJson);
    }
    return vm.runInContext(renderingRequest, context) as RenderCodeResult;
  } finally {
    context.__rorpProps = undefined;
    // ... existing cleanup ...
  }
};
```

`JSON.parse(propsJson)` uses V8's optimized JSON parser (~6.6 ms for 1.1 MB) instead of V8's JavaScript parser (~11.9 ms).

## RSC Compatibility

The `generateRSCPayload` function modifies the IIFE's trailing `()` to pass `(componentName, propsString)` and runs on another bundle's VM context. With this change:

- `usedProps = typeof props === 'undefined' ? globalThis.__rorpProps : props`
- When `generateRSCPayload` calls the IIFE with props, `props !== undefined`, so `usedProps = props` (the passed-in value)
- `globalThis.__rorpProps` on the RSC bundle's context will be `undefined`, but it's never read because the RSC path always passes props through the IIFE parameter
- `railsContext` remains embedded in the IIFE (it's small, ~1-2 KB), so it works on any bundle's context without changes

## Streaming and Incremental Paths

- **Streaming render** (`render_code_as_stream`): Also calls `form_with_code`, so props will be decoupled automatically
- **Incremental render** (`render_code_with_incremental_updates`): Uses `build_initial_incremental_request` which calls `form_with_code` with JS code that also embeds props — needs the same thread-local treatment
- **RSC payload generation**: Uses `generateRSCPayload` which passes props through the IIFE parameter — no changes needed

## Files to Modify

| File                                                                            | Changes                                                                    |
| ------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb`         | Add thread-local stash, replace inline props with `globalThis.__rorpProps` |
| `react_on_rails_pro/lib/react_on_rails_pro/request.rb`                          | Add `props` form field from thread-local                                   |
| `react_on_rails_pro/lib/react_on_rails_pro/rendering_strategy/node_strategy.rb` | Add `ensure` cleanup for thread-local                                      |
| `packages/react-on-rails-pro-node-renderer/src/worker.ts`                       | Extract `body.props`, pass to handler                                      |
| `packages/react-on-rails-pro-node-renderer/src/worker/handleRenderRequest.ts`   | Thread `propsJson` through params                                          |
| `packages/react-on-rails-pro-node-renderer/src/worker/vm.ts`                    | Inject `__rorpProps` via `JSON.parse()` into VM context                    |

## Future Optimization: vm.Script Caching

With props decoupled, the IIFE source string becomes much smaller (~200 bytes of template + railsContext). A follow-up optimization could:

1. Cache compiled `vm.Script` objects keyed on source string hash
2. Since `domNodeId` still varies per request, consider extracting it too (or making it deterministic for SSR)
3. This would eliminate V8 parse+compile entirely for repeated renders of the same component

## Verification Checklist

1. Start Rails + Node renderer, verify pages render identical HTML
2. Log `renderingRequest.length` in Node renderer to confirm IIFE is ~200 bytes (vs ~1.1 MB before)
3. Run end-to-end benchmarks comparing baseline vs experiment
4. Test RSC rendering path (streaming + RSC payload generation)
5. Test incremental rendering path
