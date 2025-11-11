# PR #1972 Investigation: Component Registration Race Condition

## Executive Summary

PR #1972 attempted to fix intermittent CI test failures by changing the default `generated_component_packs_loading_strategy` from `:async` to `:defer`. This document provides an in-depth analysis of the race condition, the proposed solution, and recommendations for a better approach.

## The Problem

### Test Failures

The following tests were failing intermittently in CI:

- `spec/system/integration_spec.rb[1:1:6:1:2]` - "2 react components, 1 store, client only, defer"
- `spec/system/integration_spec.rb[1:1:6:2:2]` - "2 react components, 1 store, server side, defer"

These tests check Redux shared store functionality where two components share the same store and typing in one component should update the other.

### Root Cause Analysis

#### The Race Condition

With `async` script loading (default on Shakapacker >= 8.2.0):

1. **Browser behavior**: When scripts have the `async` attribute, they:

   - Download in parallel (good for performance)
   - Execute immediately when download completes (unpredictable order)
   - Do not block HTML parsing

2. **The problem with generated component packs**:

   ```html
   <!-- Generated component pack (loaded via helper) -->
   <script src="/webpack/generated/ComponentName.js" async></script>

   <!-- Main client bundle (loaded in layout) -->
   <script src="/webpack/client-bundle.js" async></script>
   ```

3. **Race condition scenario**:
   - If `client-bundle.js` finishes downloading first, it executes immediately
   - React hydration starts before component registrations from generated packs
   - Error: "Could not find component registered with name ComponentName"

#### Why It's Intermittent

The race condition depends on:

- Network conditions
- File sizes (smaller files download faster)
- Browser caching
- Server response times

This makes it particularly difficult to reproduce locally but common in CI environments with varying network conditions.

## PR #1972 Solution Analysis

### What Changed

1. **Configuration default** (`lib/react_on_rails/configuration.rb`):

   ```ruby
   # OLD: Defaulted to :async when Shakapacker >= 8.2.0, else :sync
   # NEW: Always defaults to :defer
   self.generated_component_packs_loading_strategy = :defer
   ```

2. **Layout file** (`spec/dummy/app/views/layouts/application.html.erb`):

   ```erb
   <!-- OLD: Conditional logic based on uses_redux_shared_store? -->
   <!-- NEW: Always use defer: true -->
   <%= javascript_pack_tag('client-bundle', defer: true) %>
   ```

3. **Test expectations updated** to expect `:defer` as default

### How Defer "Fixes" It

With `defer`:

- Scripts still download in parallel (fast)
- Scripts execute in DOM order after HTML parsing completes
- Generated component packs execute before main bundle (predictable)
- Component registrations complete before React hydration

```html
<!-- With defer, these execute in order: -->
<script src="/webpack/generated/ComponentName.js" defer></script>
<!-- 1st -->
<script src="/webpack/client-bundle.js" defer></script>
<!-- 2nd -->
```

## The Real Issue

### Why This Solution Is Problematic

1. **Performance Impact**:

   - `async` provides better performance by executing scripts as soon as they're ready
   - `defer` forces sequential execution, which can be slower
   - Modern web apps benefit from async loading

2. **Masks Architectural Problem**:

   - The real issue is that React hydration shouldn't depend on script execution order
   - Components should be registered before hydration attempts to use them
   - This is a timing/coordination problem, not a loading strategy problem

3. **Doesn't Address Root Cause**:
   - The race condition still exists with generated component packs
   - We're just forcing a particular execution order to avoid it
   - Better solution: ensure component registry is ready before hydration

### The `uses_redux_shared_store?` Helper

Before PR #1972, there was conditional logic:

```ruby
# application_controller.rb
def uses_redux_shared_store?
  action_name.in?(%w[
    index
    server_side_redux_app
    # ... other actions with shared stores
  ])
end
```

This recognized that **only certain pages need defer**. PR #1972 removed this nuance by forcing defer everywhere.

## Recommended Approach

### Option 1: Component Registry Timeout (Already Implemented!)

React on Rails already has `component_registry_timeout` (default 5000ms):

```ruby
# configuration.rb
component_registry_timeout: DEFAULT_COMPONENT_REGISTRY_TIMEOUT # 5000ms
```

This means the client-side code should **wait** for components to register before hydrating. The race condition might indicate:

- The timeout isn't working correctly
- There's a bug in the component registration check
- The timeout is too short for CI environments

**Investigation needed**:

- Review `packages/react-on-rails/src/` for component registry logic
- Check if hydration properly waits for registrations
- Verify timeout is honored in all code paths

### Option 2: Explicit Component Dependencies

Make the main bundle explicitly wait for generated pack scripts:

```javascript
// In generated component packs:
window.ReactOnRailsComponentsReady = window.ReactOnRailsComponentsReady || [];
window.ReactOnRailsComponentsReady.push('ComponentName');

// In client-bundle before hydration:
function waitForComponents(required, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const check = () => {
      if (required.every((name) => window.ReactOnRailsComponentsReady.includes(name))) {
        resolve();
      }
    };
    // Poll until ready or timeout
  });
}
```

### Option 3: Module Dependencies

Use ES modules with dynamic imports:

```javascript
// Instead of script tags, use:
const component = await import(`./generated/${componentName}`);
```

This gives explicit control over load order without sacrificing async benefits.

### Option 4: Smart Loading Strategy

Keep async as default but fall back to defer only when needed:

```ruby
# Configuration that detects when defer is necessary
def required_loading_strategy
  if @rendered_components.any? { |c| needs_guaranteed_order?(c) }
    :defer
  else
    :async
  end
end
```

## Test Analysis

### The Failing Tests

Looking at `spec/dummy/spec/system/integration_spec.rb:360-382`:

```ruby
describe "2 react components, 1 store, client only, defer", :js do
  include_examples "React Component Shared Store", "/client_side_hello_world_shared_store_defer"
end

describe "2 react components, 1 store, server side, defer", :js do
  include_examples "React Component Shared Store", "/server_side_hello_world_shared_store_defer"
end
```

These tests **specifically test defer functionality**. The fact that they fail with async is expected behavior! The routes ending in `_defer` are explicitly testing defer mode.

**Key insight**: The failures might not be a bug but tests failing because:

1. Default was changed from async to defer
2. Tests expected defer behavior
3. When default was async, these defer-specific tests used async instead

## Recommendations

### Immediate Actions

1. **Revert PR #1972** ✅ (Already done)

2. **Investigate component registry timeout**:

   - Review `packages/react-on-rails/src/ComponentRegistry.ts`
   - Check `component_registry_timeout` implementation
   - Add detailed logging to see when/why registrations fail

3. **Reproduce the race condition locally**:

   ```bash
   # Throttle network to simulate CI conditions
   # Use browser DevTools Network tab -> Throttling
   # Run tests multiple times to catch intermittent failures
   ```

4. **Add instrumentation**:
   ```javascript
   console.log('[RoR] Component registered:', componentName, Date.now());
   console.log('[RoR] Attempting hydration:', componentName, Date.now());
   console.log('[RoR] Registry contents:', Object.keys(componentRegistry));
   ```

### Long-term Solutions

1. **Fix the timing issue properly**:

   - Ensure `component_registry_timeout` works correctly
   - Make hydration explicitly wait for required components
   - Add warnings when components aren't registered in time

2. **Make loading strategy configurable per-component**:

   ```ruby
   react_component('ComponentName', props, loading_strategy: :defer)
   ```

3. **Document when defer is needed**:

   - Update docs to explain async vs defer trade-offs
   - Provide guidance on when to use each
   - Explain the performance implications

4. **Improve test reliability**:
   - Add retries for tests with network dependencies
   - Use `retry: 3` in RSpec for these specific tests
   - Consider mocking/stubbing script loading in tests

## Questions to Answer

1. **Why does `component_registry_timeout` not prevent the race condition?**

   - Is it being used correctly?
   - Is there a code path that bypasses it?
   - Are generated component packs registering correctly?

2. **Why do defer-specific tests fail with async default?**

   - Are the routes configured correctly?
   - Should these tests explicitly set the loading strategy?
   - Is there a bug in the configuration precedence?

3. **Can we detect when defer is truly necessary?**
   - Shared Redux stores?
   - Inline component registration?
   - Server-side rendering?

## Conclusion

PR #1972's solution works but treats the symptom rather than the disease. The real fix requires:

1. Understanding why the component registry timeout doesn't prevent the race
2. Fixing the underlying timing/coordination issue
3. Keeping async as the default for performance
4. Using defer only when truly necessary (documented cases)

The intermittent nature of the failures suggests a real race condition that needs proper synchronization, not just forced execution order.

## Next Steps

1. ✅ Revert PR #1972
2. ⏳ Deep dive into component registry timeout implementation
3. ⏳ Reproduce failures locally with network throttling
4. ⏳ Add instrumentation to understand timing
5. ⏳ Implement proper synchronization fix
6. ⏳ Update documentation with clear guidance
7. ⏳ Create new PR with proper solution

---

**Author**: Claude Code
**Date**: November 11, 2025
**Status**: Investigation Complete, Awaiting Implementation
