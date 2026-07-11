# RSC CSS Architecture Analysis

This document provides a technical analysis of the current CSS loading architecture for React Server
Components in React on Rails Pro, documenting all CSS handling locations, known gaps with reproduction
steps, and recommendations for simplification.

## Executive Summary

The current RSC CSS loading implementation is distributed across **6 distinct locations** in three
packages, totaling approximately **2,800+ lines** of CSS-related code. This fragmentation exists
because the core approach (injecting CSS links into the SSR HTML stream) cannot handle all rendering
scenarios, requiring additional handling at each layer.

**Key insight:** If CSS injection were handled at the component level (via a webpack loader that
wraps `'use client'` components with their CSS `<link>` tags), React's built-in `precedence` system
would handle all scenarios uniformly—SSR, CSR, client navigation, and dynamic fetch—eliminating the
need for additional handling at every other layer.

---

## All CSS Handling Locations

### Location 1: Build-time CSS Discovery (react-on-rails-rsc)

**File:** `RSCWebpackPlugin.ts` (~1,000 lines)  
**Purpose:** Discover CSS files associated with each `'use client'` module and record them in manifests

**What it does:**

1. Three-pass CSS collection algorithm:
   - Pass 1: Group-wide JS chunk collection
   - Pass 2: Per-chunk CSS collection (prevents broadcast of shared CSS)
   - Pass 3: Sibling-chunk CSS recovery (handles SplitChunks edge cases)

2. Records CSS in `react-client-manifest.json`:
   ```json
   {
     "filePathToModuleMetadata": {
       "client/components/Button.tsx": {
         "id": "client0",
         "chunks": ["js/client0-abc123.chunk.js"],
         "css": ["css/client0-abc123.css"],
         "name": "*"
       }
     }
   }
   ```

**Why it exists:** The SSR injection layer needs to know which CSS files belong to which client components.

---

### Location 2: SSR Stream Injection (react-on-rails-pro)

**File:** `injectRSCPayload.ts` (2,160 lines)  
**Purpose:** Inject CSS `<link>` tags into the HTML stream before component content is revealed

**What it does:**

1. Loads CSS mappings from `loadable-stats.json`:

   ```typescript
   // Lines 263-324
   function loadRSCClientChunkStylesheetHrefsByChunkName(): Map<string, string[]>;
   ```

2. Parses Flight data with regex to find client chunk references:

   ```typescript
   // Lines 116-117
   const RSC_CLIENT_CHUNK_STYLESHEET_PATH = /\/css\/client\d+-[^/]+\.css$/;
   const RSC_CLIENT_CHUNK_NAME_WITH_JS_ASSET = /"((?:client)\d+)"\s*,\s*"js\/client\d+-[^"]+\.chunk\.js"/g;
   ```

3. Injects stylesheet tags before HTML content:

   ```typescript
   // Lines 330-331
   function createStylesheetTag(href: string) {
     return `<link rel="stylesheet" href="${escapeAttributeValue(href)}" data-precedence="rsc-css">`;
   }
   ```

4. Coordinates 5 buffer types in specific flush order:

   ```text
   1. RSC initialization scripts
   2. CSS stylesheet links  ← CSS injected here, BEFORE HTML
   3. HTML content
   4. RSC payload scripts
   5. Performance marks
   ```

5. Defers Suspense reveals until CSS is available:
   ```typescript
   // Lines 1717-1724
   const shouldDeferRevealHtml =
     rscPromise &&
     shouldInferRSCClientStylesheets &&
     pendingRSCClientStylesheetInferenceStreams > 0 &&
     includesReactSuspenseRevealScript(gatedHtmlBuffer);
   ```

**Why it exists:** Prevents FOUC during SSR streaming by ensuring CSS loads before content paints.

---

### Location 3: Client Hydration CSS Waiting (react-on-rails-pro)

**File:** `ClientSideRenderer.ts` (lines 100-143)  
**Purpose:** Delay React hydration until stylesheets have loaded

**What it does:**

1. Waits for stylesheet load/error events with 10-second timeout:

   ```typescript
   // Lines 106-129
   function waitForStylesheet(link: HTMLLinkElement): Promise<void> {
     if (stylesheetAlreadyLoaded(link)) {
       return Promise.resolve();
     }
     return new Promise((resolve) => {
       let timeout: ReturnType<typeof setTimeout> | undefined;
       const done = () => {
         clearTimeout(timeout);
         link.removeEventListener('load', done);
         link.removeEventListener('error', done);
         resolve();
       };
       link.addEventListener('load', done);
       link.addEventListener('error', done);
       timeout = setTimeout(done, STYLESHEET_LOAD_TIMEOUT_MS); // 10,000ms
     });
   }
   ```

2. Called before component hydration:
   ```typescript
   // Lines 304-307
   const [componentObj] = await Promise.all([
     ComponentRegistry.getOrWaitForComponent(name),
     waitForGeneratedComponentStylesheets(name, el),
   ]);
   ```

**Why it exists:** Even with SSR injection, race conditions can cause hydration before CSS fully loads.

---

### Location 4: Ruby-side Stylesheet Href Embedding (react_on_rails gem)

**File:** `pro_helper.rb` (lines 50-58)  
**Purpose:** Embed stylesheet hrefs in component data attributes for client-side lookup

**What it does:**

```ruby
# Lines 24-25
"data-generated-stylesheet-hrefs" => generated_stylesheet_hrefs_json(render_options)

# Lines 50-58
def generated_stylesheet_hrefs_json(render_options)
  return unless ReactOnRails::Utils.react_on_rails_pro?
  return unless render_options.auto_load_bundle  # Only applies when auto_load_bundle is enabled
  pack_name = "generated/#{render_options.react_component_name}"
  sources = preload_sources_for_stylesheet_pack(pack_name)
  hrefs = unique_preload_sources_by_href(sources).map { |source| source.fetch(:href) }
  hrefs.to_json if hrefs.present?
end
```

**Why it exists:** The client-side hydration code needs to know which stylesheets to wait for.

**Note:** This mechanism only applies when `auto_load_bundle` is enabled, which limits how broadly FOUC prevention gaps (Bugs 1/2) affect applications not using this option.

---

### Location 5: Rails Layout Stylesheet Tags

**File:** Application layout (user code)  
**Purpose:** Load global CSS that applies to all components

```erb
<%= stylesheet_pack_tag "client-bundle", media: "all" %>
```

**Why it exists:** Global styles shared across the application must be loaded via the Rails layout.

**Important distinction:** This location handles **global CSS only**. It does not address the separate
issue of CSS imported directly by Server Components (see [#4049](https://github.com/shakacode/react_on_rails/issues/4049)).
Server-Component-imported CSS requires different handling—manifest discovery, build-artifact emission,
and network delivery—which is outside the scope of Rails layout tags.

---

### Location 6: Client-Side RSC Fetching (MISSING)

**File:** `getReactServerComponent.client.ts` (422 lines)  
**Purpose:** Fetch and render RSC payloads on client-side navigation

**What it does NOT do:**

```typescript
// The entire 422-line file contains ZERO CSS handling:
// - No preinit() calls
// - No stylesheet waiting
// - No CSS preloading
// - No precedence handling
```

**Impact:** Client-side navigation and non-SSR RSC fetching have **no FOUC prevention**.

---

## Known Bugs and Reproduction Steps

### Bug 1: Client-Side Navigation FOUC

**Severity:** High  
**Status:** Unaddressed

**Description:** When navigating client-side to a new RSC route, CSS for newly-rendered client
components loads after the components paint, causing FOUC.

**Steps to reproduce:**

1. Create an RSC app with two routes: `/page-a` and `/page-b`
2. `/page-b` renders a client component with CSS that has visible styling (e.g., colored background)
3. Load `/page-a` (initial SSR load)
4. Click a link to navigate to `/page-b` (client-side navigation)
5. Observe: The client component briefly appears unstyled before CSS loads

**Root cause:** `getReactServerComponent.client.ts` has no CSS handling code.

---

### Bug 2: Non-SSR RSC Fetch FOUC

**Severity:** High  
**Status:** Unaddressed

**Description:** RSC components fetched without initial SSR (e.g., `createWithoutSSR` or dynamic
content insertion) have no FOUC prevention.

**Steps to reproduce:**

1. Create a component using `createWithoutSSR` that renders a client component with visible CSS
2. Load the page
3. Observe: Component appears unstyled, then styles load after React renders

**Root cause:** No HTML stream exists, so `injectRSCPayload.ts` is never invoked.

---

### Bug 3: rspack CSS Field Conditional Omission

**Severity:** High (in affected configurations)  
**Status:** Partially addressed in recent versions

**Description:** In certain rspack configurations or older versions, the manifest may not carry the
`css` field, causing `withStylesheetHints` preinit to be a no-op.

**Note:** This issue has been addressed in `react-on-rails-rsc` 19.2.1-rc.0 and later for supported
Pro/RSC configurations. The Rspack production dummy app on that version produces manifest `css`
arrays correctly. This bug applies to older versions or specific Rspack/publicPath setups.

**Steps to reproduce (in affected configurations):**

1. Use rspack with an older version of `react-on-rails-rsc` or specific publicPath settings
2. Render any RSC page with client components that import CSS
3. Check the `react-client-manifest.json`: no `css` arrays present
4. Observe: FOUC on Suspense-deferred client components

**Root cause:** `RSCRspackPlugin` CSS field population depends on version and configuration.

---

### Bug 4: Hardcoded Naming Pattern Failure

**Severity:** Medium  
**Status:** Known limitation

**Description:** CSS inference relies on hardcoded regex patterns that assume specific webpack output structure.

**Steps to reproduce:**

1. Configure webpack with custom chunk naming:
   ```javascript
   output: {
     chunkFilename: 'chunks/[name].[contenthash].js',  // Not js/clientN-hash.chunk.js
   }
   ```
2. Render an RSC page with client components
3. Observe: CSS inference silently fails, FOUC occurs

**Root cause:**

```typescript
// injectRSCPayload.ts:116-117
const RSC_CLIENT_CHUNK_STYLESHEET_PATH = /\/css\/client\d+-[^/]+\.css$/;
const RSC_CLIENT_CHUNK_NAME_WITH_JS_ASSET = /"((?:client)\d+)"\s*,\s*"js\/client\d+-[^"]+\.chunk\.js"/g;
```

---

### Bug 5: `publicPath: 'auto'` Causes Empty CSS

**Severity:** Medium  
**Status:** Known limitation

**Description:** A common webpack configuration silently breaks all CSS inference.

**Steps to reproduce:**

1. Set webpack config:
   ```javascript
   output: {
     publicPath: 'auto',
   }
   ```
2. Render any RSC page with client components
3. Observe: All CSS hrefs resolve to empty, FOUC occurs on all pages

**Root cause:** `loadable-stats.json` asset paths are relative when `publicPath: 'auto'`.

---

### Bug 6: Silent Retry in injectRSCPayload.ts with Missing loadable-stats.json

**Severity:** Medium  
**Status:** Known limitation

**Description:** When `loadable-stats.json` is missing in the Node renderer environment,
`injectRSCPayload.ts` retries with exponential backoff but does not log a warning during
the retry window.

**Note:** The Ruby-side rolling-deploy staging path does warn when appropriate and suppresses
warnings for builds where the file is legitimately absent. This bug specifically affects the
`injectRSCPayload.ts` retry path in the Node renderer.

**Steps to reproduce:**

1. Deploy without copying `loadable-stats.json` to the renderer bundle directory
2. Render RSC pages during the retry window
3. Observe: The `injectRSCPayload.ts` retry path logs no warning
4. Pages have FOUC until the file appears or retry cap is reached

**Root cause:**

```typescript
// injectRSCPayload.ts:296-316
// ENOENT errors are caught and trigger retry without warning
catch (error) {
  const retryDelayMs = Math.min(previousRetryDelayMs * 2, LOADABLE_STATS_MAX_READ_RETRY_DELAY_MS);
  // ...retry scheduled but no warning logged for common ENOENT case
}
```

---

### Bug 7: Transitive CSS Gap

**Severity:** Medium  
**Status:** Partially addressed

**Description:** CSS imported through JavaScript intermediaries misses render-blocking preload.

**Steps to reproduce:**

1. Create structure:
   ```text
   ClientComponent.tsx → helpers.js → helpers.css
   ```
2. Configure splitChunks to move `helpers.js` to a shared chunk
3. Render the client component
4. Observe: `helpers.css` loads but NOT in render-blocking way, potential FOUC

**Root cause:** The CSS collection algorithm only follows direct CSS imports, not transitive ones through JS modules.

---

## Architectural Limitation

The current architecture centers on **injecting CSS links into the HTML stream during SSR**.

This approach has inherent limitations:

1. **Only works for SSR** — no HTML stream exists for CSR or client navigation
2. **Requires coordination across 6 locations** — each with its own failure modes
3. **Has silent failures** — regex mismatches, missing files, and config issues cause FOUC with no warning
4. **Requires separate solution for client navigation** — different mechanism needed for non-SSR scenarios

---

## Alternative: Component-Level CSS Injection

The original proposal was a webpack loader that wraps `'use client'` components:

```javascript
// Input
'use client';
import './Button.css';
export const Button = (props) => <button {...props} />;

// Output (after loader)
('use client');
import './Button.css';
const Button_internal = (props) => <button {...props} />;
export const Button = (props) => (
  <>
    <link rel="stylesheet" precedence="ror-rsc" href="/css/Button-abc123.css" />
    <Button_internal {...props} />
  </>
);
```

**Why this works everywhere:**

| Scenario           | Current Approach          | Loader Approach           |
| ------------------ | ------------------------- | ------------------------- |
| SSR streaming      | Works (injectRSCPayload)  | Works (React precedence)  |
| SSR hydration      | Works (waitForStylesheet) | Works (React precedence)  |
| Client navigation  | **FOUC**                  | Works (React precedence)  |
| Non-SSR fetch      | **FOUC**                  | Works (React precedence)  |
| rspack             | **FOUC**                  | Works (same loader)       |
| Custom chunk names | **FOUC**                  | Works (no regex patterns) |

**Complexity comparison:**

| Metric              | Current   | Loader Approach        |
| ------------------- | --------- | ---------------------- |
| Lines of code       | ~2,800+   | ~50-100                |
| Number of locations | 6         | 1                      |
| Failure modes       | 7+ silent | Visible (missing link) |
| Maintenance burden  | High      | Minimal                |

**Historical context:** The loader-wrapper approach was originally implemented (react_on_rails_rsc
PR #35) but later replaced. The reasons documented in the git history were:

1. **Lost `react.client.reference` metadata** (PR #45): When component exports were wrapped for CSS,
   they lost their `$$typeof === Symbol(react.client.reference)` tag, breaking React's ability to
   identify them as client references.

2. **Required React fork patches** (Issue #58): The loader implementation required patching React's
   internals (`react-server-dom-webpack`), which couldn't be upstreamed to facebook/react.

3. **Cross-request races** (PR #49): The original implementation used `globalThis.__reactFlightClientManifest`
   which caused races when multiple requests ran concurrently.

**Key insight:** These were implementation issues, not fundamental problems with the approach. The
concept of wrapping components with CSS links is sound—the issues were:

- The wrapper should preserve `react.client.reference` metadata
- It should work without patching React internals
- It should be request-scoped, not process-global

A revised implementation that addresses these specific issues could provide the same simplicity
benefits (single location, ~50 lines, works everywhere) without the original problems.

---

## Recommendations

### Immediate

1. Add runtime warnings for CSS inference failures
2. Document client navigation limitation in user docs
3. Add E2E tests for client navigation FOUC

### Short-term

1. Implement CSS preloading in `getReactServerComponent.client.ts` using `ReactDOM.preinit()`
2. Remove hardcoded naming patterns by reading from manifest data

### Long-term

Re-evaluate the loader-based approach:

1. CSS injection happens once, at the component level
2. React's `precedence` system handles all rendering modes uniformly
3. No need for additional handling at 5 other locations
4. Eliminates entire categories of silent failures
5. Works with rspack, custom configs, and future bundlers

---

## Appendix: Code References

| Location         | File                                | Lines   | Purpose                            |
| ---------------- | ----------------------------------- | ------- | ---------------------------------- |
| Build-time       | `RSCWebpackPlugin.ts`               | ~1,000  | CSS discovery, manifest generation |
| SSR injection    | `injectRSCPayload.ts`               | 2,160   | Stream injection, FOUC prevention  |
| Client hydration | `ClientSideRenderer.ts`             | 100-143 | Stylesheet waiting                 |
| Ruby embedding   | `pro_helper.rb`                     | 50-58   | Stylesheet href attributes         |
| Rails layout     | User code                           | N/A     | Global CSS loading                 |
| Client fetch     | `getReactServerComponent.client.ts` | 422     | **No CSS handling**                |

---

## Related Issues

- [#4474](https://github.com/shakacode/react_on_rails/issues/4474) — RSC client-component asset delivery audit
- [#4049](https://github.com/shakacode/react_on_rails/issues/4049) — Server-component CSS under-delivery
- [#4111](https://github.com/shakacode/react_on_rails/issues/4111) — Shared client boundary CSS/JS bloat
