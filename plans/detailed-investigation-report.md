# Issue #4966 — Detailed Investigation Report

**Date:** 2026-09-01
**Issue:** [#4966](https://github.com/shakacode/react_on_rails/issues/4966) — PPR v1: harden the diagnostics surface
**Branch:** `ppr-integration`
**Method:** Three parallel investigation agents searched Ruby, TypeScript, specs, and tests independently. Every claim was verified against actual code with exact line numbers.

---

## Table of Contents

1. [P1 — Error Redaction](#p1--error-redaction)
2. [P2 — Settle Budget](#p2--settle-budget)
3. [Follow-up 1 — FOUC Visreg Gate](#follow-up-1--fouc-visreg-gate)
4. [Follow-up 2 — Ruby Spec Coverage for #4897](#follow-up-2--ruby-spec-coverage-for-4897)
5. [Follow-up 3 — Href Normalization](#follow-up-3--href-normalization)
6. [Overall Recommendation](#overall-recommendation)

---

## P1 — Error Redaction

**Issue claim:** PPR diagnostics forward raw `error.message` content through AS::Notifications payloads and log lines, potentially leaking PII.

**Verdict: REAL — fix needed.**

### 1.1 `safe_error_summary` sends raw error text into AS::Notifications

**CONFIRMED.**

File: `react_on_rails_pro/lib/react_on_rails_pro/ppr.rb`, lines 186-188:

```ruby
def safe_error_summary(error)
  error.message.to_s.tr("\n\r", " ")[0, 256]
end
```

This method does two things:
- Strips newlines and carriage returns (prevents log injection)
- Truncates to 256 characters

It does **not** redact any content. Whatever text is in `error.message` passes through verbatim up to 256 chars. The code's own comment (lines 183-185) acknowledges the risk:

> "PrerenderError#message can include renderer console output with request-derived values; truncating prevents PII from propagating through APM/logging subscribers."

But 256 characters is more than enough to contain:
- An email address (15-30 chars)
- A person's name (5-30 chars)
- A session token or API key (20-100 chars)
- A short URL with query parameters containing user data

This method is called by three instrumentation methods that publish to ActiveSupport::Notifications:

| Method | Line | AS::Notifications event name |
|---|---|---|
| `instrument_degraded_pre_flush` | 142-147 | `ppr.resume.degraded_pre_flush` |
| `instrument_degraded_post_flush` | 149-155 | `ppr.resume.degraded_post_flush` |
| `instrument_cache_read_error` | 173-179 | `ppr.cache.read_error` |

Each passes `safe_error_summary(error)` as the `:error` key in the payload hash.

**Who consumes these payloads?**

The `CacheWarmer` in `react_on_rails_pro/lib/react_on_rails_pro/ppr/cache_warmer.rb` subscribes (lines 196-203) and reads the `:error` payload directly:

```ruby
details << "#{key}: #{payload[:reason] || payload[:error]}" if payload.is_a?(Hash) &&
                                                               (payload[:reason] || payload[:error])
```

Any APM or observability tool (Datadog, New Relic, Honeybadger, etc.) that subscribes to these AS::Notifications events also receives the raw text. Unlike server-side logs, AS::Notifications payloads are consumed programmatically and can be forwarded to external services where the operator's log access controls do not apply.

### 1.2 `ppr_sanitize_for_log` logs 1024 chars unredacted

**CONFIRMED.**

File: `react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb`, lines 1848-1850:

```ruby
def ppr_sanitize_for_log(value, max_length: 1024)
  value.to_s.tr("\n\r", " ")[0, max_length]
end
```

Same pattern as `safe_error_summary` — strips newlines and truncates — but with a 4x larger window (1024 chars instead of 256). The method name "sanitize" is misleading; it sanitizes for log injection (newline injection of fake log lines), not for PII content.

Called in two places:

1. `ppr_handle_pre_flush_degradation` (line 1814):
   ```ruby
   safe_msg = ppr_sanitize_for_log(error.message)
   ```
   Then logged via `Rails.logger.warn` at lines 1815-1817.

2. `ppr_handle_post_flush_degradation` (line 1835):
   Same pattern at lines 1836-1838.

### 1.3 Cache-read warn logs `e.message` with no bound at all

**CONFIRMED.**

File: `react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb`, line 1388:

```ruby
Rails.logger.warn("[ReactOnRailsPro] PPR cache read failed (treating as miss): #{e.class}: #{e.message}")
```

This has:
- **No truncation** — the full `e.message` string is interpolated, regardless of length
- **No redaction** — content passes through verbatim

The `e` comes from `rescue StandardError => e` at line 1387, catching errors from `Rails.cache.read`.

**Inconsistency:** The AS::Notifications payload for the same error IS bounded, because line 1389 routes through `ppr_instrument_non_fatal` → `instrument_cache_read_error` → `safe_error_summary(error)` (256-char truncation). So the notification truncates but the log does not — if one path needs truncation for safety, the other arguably needs it too.

**Additional unbounded `e.message` log sites found:**

| File | Line | Context |
|---|---|---|
| `react_on_rails_pro_helper.rb` | 1617 | `ppr_write_cache_entry` rescue — `"#{e.class}: #{e.message}"` |
| `react_on_rails_pro_helper.rb` | 1820 | `ppr_handle_pre_flush_degradation` handler-failed fallback |
| `react_on_rails_pro_helper.rb` | 1841 | `ppr_handle_post_flush_degradation` handler-failed fallback |

### 1.4 `PrerenderError` redacts `props`/`js_code` but NOT `console_messages`

**CONFIRMED.**

File: `react_on_rails/lib/react_on_rails/prerender_error.rb`

**What IS redacted:**

```ruby
# Line 19-20: stored as "[REDACTED]"
@props = redacted_value(props)
@js_code = redacted_value(js_code)

# Lines 97, 101: redacted in the #message body
message << "#{redacted_value(props)}\n\n"
message << "#{redacted_value(js_code)}\n\n"
```

The `SENSITIVE_CONTEXT_KEYS` constant (line 9) is `%w[props js_code json]`.

**What is NOT redacted:**

```ruby
# Line 21: stored verbatim — no redaction
@console_messages = console_messages

# Lines 103-105: embedded in #message with no redaction
if console_messages && console_messages.strip.present?
  message << Rainbow("Console Output:").magenta.bright << "\n"
  message << "#{console_messages}\n\n"
end
```

The `console_messages` value comes from the Node renderer's `consoleReplayScript` — a JavaScript snippet that replays `console.log`, `console.warn`, `console.error` calls that happened during SSR. If application code logs request-derived data during server rendering (e.g., `console.log("Processing user:", user.email)`), that PII ends up in `PrerenderError#message` unredacted.

When a `PrerenderError` is caught by the PPR degradation handlers, its `.message` (including the raw console output) flows through both:
- `safe_error_summary` → 256 chars of it into AS::Notifications
- `ppr_sanitize_for_log` → 1024 chars of it into Rails logs

### 1.5 Arbitrary `StandardError` messages flow through the same handlers

**CONFIRMED.**

Every PPR error handling path uses `rescue StandardError => e`:

| File | Line | Context |
|---|---|---|
| `react_on_rails_pro_helper.rb` | 1387 | `ppr_read_cache_entry` — catches `Rails.cache.read` errors |
| `react_on_rails_pro_helper.rb` | 1614 | `ppr_write_cache_entry` — catches cache write errors |
| `react_on_rails_pro_helper.rb` | 1475 | `ppr_cache_hit_with_fallback` — catches cache-hit render errors |
| `react_on_rails_pro_helper.rb` | 1776 | `ppr_enqueue_resume_stream` — catches resume stream errors |

The PII risk varies by error type:

| Error type | PII risk | Typical content |
|---|---|---|
| `PrerenderError` | **HIGH** | `#message` contains unredacted console output — request-derived, PII-capable |
| Cache store errors (Redis/Memcached) | Low | "Connection refused", "Timeout" |
| `JSON::ParserError` | Low | Malformed data (could contain user content if cache corrupted) |
| Other `StandardError` | Variable | Depends on app's cache serializer, middleware, etc. |

### 1.6 Existing redaction: `safe_error_details` in `PrerenderError`

File: `prerender_error.rb`, lines 61-65

The `safe_error_details` method does redact renderer parse errors specifically — it strips the raw response body out of `JsonParseError` and `LengthPrefixedParser::ParseError` messages, replacing them with `"Renderer response could not be parsed"`. But this redaction is narrow (only parser errors) and does not cover the general case.

### P1 Summary

| Sub-claim | Verified? | Evidence |
|---|---|---|
| `safe_error_summary` sends raw text to AS::Notifications | ✅ Yes | `ppr.rb:186-188`, called at lines 142, 149, 173 |
| `ppr_sanitize_for_log` logs 1024 chars unredacted | ✅ Yes | `helper.rb:1848-1850`, called at lines 1814, 1835 |
| Cache-read warn is unbounded | ✅ Yes | `helper.rb:1388` — no truncation at all |
| `PrerenderError` misses `console_messages` | ✅ Yes | `prerender_error.rb:21,103-105` |
| Arbitrary `StandardError` flows through same handlers | ✅ Yes | Multiple `rescue StandardError` sites |
| Truncation is not redaction | ✅ Yes | 256 chars fits emails, names, tokens |

**This is a real security-adjacent concern. The AS::Notifications path is the most important to fix because it fans out to external APM services. Fix needed.**

---

## P2 — Settle Budget

**Issue claim:** The settle timer is armed only after `Promise.resolve(reactRenderingResult)` resolves, so a slow or never-settling render function bypasses `config.ppr_settle_budget_ms`.

**Verdict: TECHNICALLY CORRECT but significantly overstated. Low priority.**

### 2.1 The technical gap exists

**CONFIRMED.**

File: `packages/react-on-rails-pro/src/pprServerRenderedReactComponent.ts`

The settle timer is created at lines 268-270, inside the `.then()` handler that runs only after `Promise.resolve(reactRenderingResult)` at line 242 resolves:

```ts
// Line 242: awaits the render function's Promise
Promise.resolve(reactRenderingResult)
  // Line 243: only enters here AFTER the Promise resolves
  .then(async (reactRenderedElement) => {
    // ...
    // Lines 268-270: timer starts HERE — too late if the render function was slow
    const settleController = new AbortController();
    prerenderSignal = settleController.signal;
    settleTimeoutId = setTimeout(
      () => settleController.abort(),
      resolveSettleBudgetMs(railsContext),
    );
    // Line 274: React prerender starts with the signal
    const { prelude, postponed } = await prerenderToNodeStream(reactRenderedElement, {
      signal: prerenderSignal,
      // ...
    });
  })
```

If `reactRenderingResult` is a Promise that takes 300ms to resolve, the timer doesn't start until 300ms in. Total wall time = render function time + settle budget.

### 2.2 Async render functions ARE supported

**CONFIRMED.**

Types in `packages/react-on-rails/src/types/index.ts`, lines 181-185:

```ts
type RenderFunctionAsyncResult = Promise<string | ServerRenderHashRenderedHtml | ReactComponent | ServerRenderResult>;
type RenderFunctionResult = RenderFunctionSyncResult | RenderFunctionAsyncResult;
```

`createReactOutput.ts`, lines 126-138 — when a render function returns a Promise, it's passed through directly:

```ts
const renderFunctionResult = (component as ServerRenderFunction)(props, railsContext);
// ...
if (isPromise(renderFunctionResult)) {
  return renderFunctionResult.then((result) => { ... });
}
```

`streamingUtils.ts`, lines 397-408 — the Promise is detected and passed to the render strategy:

```ts
if (isPromise(reactRenderingResult)) {
  const promiseAfterRejectingHash = reactRenderingResult.then(...);
  return renderStrategy(promiseAfterRejectingHash, ...);
}
```

Async render functions are tested in `packages/react-on-rails/tests/serverRenderReactComponent.test.ts`, lines 322-360.

### 2.3 However: This is NOT a PPR-specific problem

**The non-PPR streaming path has the exact same pattern — and it's actually WORSE.**

File: `packages/react-on-rails-pro/src/streamServerRenderedReactComponent.ts`, line 96:

```ts
Promise.resolve(reactRenderingResult)
  .then((reactRenderedElement) => {
    // ...
    const renderingStream = renderToPipeableStream(reactRenderedElement, { ... });
  })
```

The streaming path:
- Uses the same `Promise.resolve(reactRenderingResult).then(...)` pattern ✓
- Has **NO settle timer** at all ✗
- Has **NO abort signal** ✗
- Has **NO timeout of any kind** at the JS level ✗

A never-settling render function hangs the streaming path identically. This has been the case since before PPR was implemented, and it has not been reported as a production problem.

### 2.4 Ruby's `ssr_timeout` is an external safety net

File: `react_on_rails_pro/lib/react_on_rails_pro/configuration.rb`, line 78 — default `ssr_timeout` is 5 seconds.

File: `react_on_rails_pro/lib/react_on_rails_pro/renderer_artifact_support.rb`, line 191 — applied as `read_timeout` on the HTTP socket to the Node renderer:

```ruby
read_timeout: ReactOnRailsPro.configuration.ssr_timeout
```

If the render function hangs and no response data is ever written, Ruby cuts the connection after 5 seconds. The failed request wastes a Node renderer worker for the duration, but the user's request does not hang indefinitely.

### 2.5 The settle budget was designed for a different purpose

The settle budget was designed to bound **React's Fizz prerender** — the time React spends resolving Suspense boundaries. The flow is:

1. Render function creates a React element tree (should be fast — just creating JSX)
2. `prerenderToNodeStream` runs React Fizz on that tree (may be slow — data fetching in Suspense boundaries)
3. Settle timer fires → abort signal → React stops and serializes remaining boundaries as holes

The render function is step 1 — it's supposed to return a React element, not do heavy work. Heavy async work (data fetching) belongs inside the component tree via Suspense/async components, where it IS bounded by the settle timer.

An async render function that does slow I/O is going against the intended pattern. It works (the types allow it), but it's not the expected usage.

### 2.6 Realistic risk assessment

- **Most render functions return synchronously.** Creating a React element tree is fast.
- **Async render functions exist but are uncommon.** The primary data-fetching pattern in RSC/PPR apps is async components within the tree.
- **A render function that never settles is an application bug.** `ssr_timeout` catches it.
- **A slow (but eventually settling) render function** adds latency but doesn't break correctness — the settle timer still bounds the Fizz prerender phase.

### 2.7 If we DO fix it, the fix is subtle

The fix is NOT as simple as "move the timer up." There are two scenarios:

**Scenario A — Render function is slow but returns:**
The timer fires while awaiting the Promise. When the Promise eventually resolves, we can pass the element to `prerenderToNodeStream` with the already-aborted signal. React immediately treats ALL Suspense boundaries as holes and produces a valid `PostponedState`. This is the best outcome — we get a cacheable shell.

**Scenario B — Render function never returns:**
We need `Promise.race` to escape the await. Since React never ran, there's no `PostponedState`. We must set `pprRenderErrored: true` to prevent Ruby from caching. Without it, Ruby would interpret `pprPrerenderComplete: true` with no `PostponedState` as "fully static page" and cache an empty shell — the page would render blank on every subsequent request.

If we fix the PPR path, we should arguably also fix the streaming path for consistency — it has the same gap and no timeout at all.

### P2 Summary

| Aspect | Finding |
|---|---|
| Timer starts late? | ✅ Yes — inside `.then()`, after render function resolves |
| Async render functions possible? | ✅ Yes — typed, coded, tested |
| PPR-specific problem? | ❌ No — streaming path has the same gap, actually worse |
| External safety net? | ✅ Yes — Ruby `ssr_timeout` (default 5s) |
| Realistic risk? | Low — most render functions are sync; async is uncommon |
| Priority? | **Low — nice-to-have, not P2** |

---

## Follow-up 1 — FOUC Visreg Gate

**Issue claim:** "Prove the D6 dedupe/coordination design against the FOUC failure mode the plan rates CRITICAL."

**Verdict: ALREADY FULLY IMPLEMENTED. No work needed.**

### Evidence

The codebase has four layers of FOUC protection testing:

**1. ShakaPerf release gate (CI workflow)**
File: `.github/workflows/shakaperf-release-gates.yml`

A full GitHub Actions workflow that:
- Spins up the Pro dummy app (Rails server + Node renderer)
- Runs ShakaPerf visual regression tests
- Is a `workflow_dispatch` gate tied to release validation

**2. ShakaPerf AB test**
File: `test/shakaperf/rsc-fouc/ab-tests/rsc-fouc-release-gate.abtest.ts`

Two visual regression tests:
- `rsc first paint use-client css emits stylesheet before hydration` — blocks JavaScript, verifies the RSC stylesheet `<link>` exists before capturing the visual probe. Asserts the probe element has a styled (non-default) `backgroundColor` before any JS runs.
- `rsc real first-visible probe is styled` — uses `waitUntil: "commit"` and RAF polling to assert the first visible paint is already styled.

**3. Playwright E2E tests**
File: `react_on_rails_pro/spec/dummy/e2e-tests/rsc_fouc.spec.ts`

446 lines with ~36 test assertions covering every FOUC scenario:
- RSC content is styled even while JS is delayed
- RSC content does NOT appear before CSS is loaded (the exact FOUC scenario)
- RSC content waits for CSS even if JS finishes first
- Client-only content does not appear until both JS and CSS are loaded
- Pages only load the CSS chunks they actually use (isolation)

**4. System spec**
File: `react_on_rails_pro/spec/dummy/spec/system/integration_spec.rb`, lines 43-70

Verifies critical inline styles appear before the stylesheet bundle in the DOM.

**5. Dedicated test components**
The dummy app contains purpose-built components for these tests:
- `RscFoucProbe.jsx`
- `ClientOnlyFoucProbeView.jsx`
- `RscFoucProbeClient.jsx`

### Summary

The D6 dedupe/coordination design is already proven against the FOUC failure mode across visual regression, E2E, and integration layers. This follow-up item can be closed as "already addressed."

---

## Follow-up 2 — Ruby Spec Coverage for #4897

**Issue claim:** Ruby specs for `ppr_validated_asset_manifest`, envelope `assets` field, and `pprShellAssets` injection were blocked by the local gem env and should be added under CI.

**Verdict: PARTIALLY VALID — nice-to-have, not blocking.**

### What's missing

**`ppr_validated_asset_manifest`** (helper lines 1670-1681):
```ruby
def ppr_validated_asset_manifest(raw_manifest)
  # Validates JSON shape: checks for stylesheetHrefs and initScriptKeys as string arrays
  # Returns nil on any malformed input
end
```
Grep `ppr_validated_asset_manifest` in `*_spec.rb` → **zero results**. No Ruby spec exists.

**Envelope `assets` field** (helper lines 1648-1662):
The `ppr_build_envelope` method stores the `asset_manifest` in `envelope["assets"]` when it is a String. The existing PPR helper spec (line 2305) checks `cached_entry["schema"]`, `cached_entry["shell_html"]`, `cached_entry["postponed_state"]`, and `cached_entry["checksum"]`, but does **NOT** assert on `cached_entry["assets"]`.

**`pprShellAssets` injection** (`server_rendering_js_code.rb:207-213`):
Injects `railsContext.pprShellAssets = <json>` into the JavaScript rendering context. No Ruby spec exists.

### What already covers it

| Coverage layer | What it covers |
|---|---|
| TypeScript tests (`injectRSCPayload.test.ts`, lines 2377-2542) | 6 dedicated tests: duplicate init script suppression, duplicate stylesheet suppression, hole-only CSS emission, promoted preload hrefs in manifest, dedup promoted preloads, suppress promoted preloads on resume |
| TypeScript test (`pprServerRenderedReactComponent.test.jsx`, line 483) | "passes the shell asset manifest to the resume injector via railsContext.pprShellAssets" |
| Playwright E2E tests | Exercise the full Ruby-to-JS pipeline end-to-end |

### Risk assessment

- `ppr_validated_asset_manifest` is a pure defensive validator. On any malformed input, it returns `nil` and the system degrades gracefully (resume operates without dedup — no crash, just possible duplicate CSS links).
- `pprShellAssets` injection is a straightforward `to_json` call with a type guard. Hard to break.
- The JS-side behavior is thoroughly tested.

### Summary

The claim is technically correct — there are no Ruby specs for these three methods. But the risk is significantly mitigated by TypeScript coverage, E2E tests, and graceful degradation on failure. Adding Ruby specs would be defense-in-depth, not a blocking concern.

---

## Follow-up 3 — Href Normalization for CSS Dedup

**Issue claim:** "The manifest dedup compares hrefs by exact string; equivalent hrefs with differing paths/query strings are not deduped. Low risk."

**Verdict: NOT A REAL PROBLEM. No work needed.**

### A normalization function already exists

File: `packages/react-on-rails-pro/src/injectRSCPayload.ts`, lines 260-266:

```ts
function normalizeStylesheetHref(href: string) {
  try {
    return new URL(href, 'http://react-on-rails.local').pathname;
  } catch {
    return href.split(/[?#]/, 1)[0];
  }
}
```

This strips query strings, fragments, and normalizes to just the pathname. It's used for the preload promotion path (`shouldPromoteStylesheetPreloadTag` at line 278 and `isRSCClientChunkStylesheetHref` at line 269).

### The dedup path uses exact string comparison intentionally

The main dedup path (`stylesheetTagsForRSCClientChunks` at line 432) uses exact string comparison on the `emittedStylesheetHrefs` Set. This is **correct by design** because:

1. **Both prerender and resume read hrefs from the same `loadable-stats.json` file** via `loadRSCClientChunkStylesheetHrefsByChunkName()`. The hrefs are looked up by chunk name from this single source of truth. When prerender captures `/css/client1-abc123.css` into the asset manifest, resume also reads `/css/client1-abc123.css` from the same stats file. The strings are identical by construction.

2. **The `onAssetsEmitted` callback** (line 1948) stores `Array.from(emittedRSCClientStylesheetHrefs)` — the exact hrefs added to the Set. Resume pre-seeds its Set with `new Set<string>(shellAssetManifest?.stylesheetHrefs)` (line 1696). Same source → same strings.

3. **Promoted preload hrefs** from React's streamed `<link rel="preload">` tags are also stored and compared as-is. These come from the same webpack/rspack build output.

### When would hrefs actually differ?

Only if a deployment changed the webpack output between prerender (cached) and resume (live). But in that case:
- The cache entry's `react` version key or schema would change
- This causes a cache miss
- The old manifest is never used with new hrefs

CDN rewrites can't cause a mismatch because both phases run on the same Node renderer process reading the same local files.

### Test coverage confirms this

- Test at line 2414: `'suppresses duplicate stylesheet links when shellAssetManifest provides pre-emitted hrefs'` — uses the exact same href string in both manifest and chunk stylesheet map ✓
- Test at line 2438: `'emits hole-only CSS links when shellAssetManifest does not include them'` — confirms different hrefs are NOT suppressed ✓

### Summary

The exact-string comparison is correct for this system. Normalizing the dedup path would actually be wrong — if hrefs somehow differed, that would indicate a real difference (e.g., a deployment mid-flight) where dedup should NOT happen. The existing `normalizeStylesheetHref` handles the preload promotion path where React-emitted tags might have slightly different formatting. The issue itself rated this "low risk" — it's actually no risk.

---

## Overall Recommendation

| Item | Real problem? | Fix needed? | Priority |
|---|---|---|---|
| P1 — Error redaction | ✅ Yes, all claims confirmed | ✅ Yes | **High** |
| P2 — Settle budget | ⚠️ Technically true, significantly overstated | ⚠️ Nice-to-have | **Low** |
| Follow-up 1 — FOUC visreg gate | ❌ Already fully implemented | ❌ No | **None** |
| Follow-up 2 — Ruby specs | ⚠️ Partially valid | ⚠️ Nice-to-have | **Low** |
| Follow-up 3 — Href normalization | ❌ Not a real problem | ❌ No | **None** |

### What to do

**Must fix:** P1 error redaction — the only item with a genuine security-adjacent concern.

**Can close as "already addressed":** FOUC visreg gate (fully implemented) and href normalization (not a real problem).

**Can close as "declined with reasoning":** P2 settle budget (`ssr_timeout` is the real safety net; the streaming path has the same gap and has been fine; fixing requires subtle `Promise.race` + `PostponedState` handling) and Ruby specs for #4897 (JS tests cover end-to-end; failure mode is graceful degradation).

These closures satisfy the acceptance criteria, which explicitly allow "decided: explicitly declined with reasoning."
