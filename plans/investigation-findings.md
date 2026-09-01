# Issue #4966 — Deep Investigation Findings

All claims were independently verified against actual code. Three agents
searched in parallel across Ruby, TypeScript, specs, and tests.

---

## P1 — Error redaction: REAL, NEEDS FIX ✅

Every sub-claim is confirmed with exact code evidence.

### 1.1 `safe_error_summary` sends raw error text into AS::Notifications

**CONFIRMED.** `ppr.rb:186-188`:

```ruby
def safe_error_summary(error)
  error.message.to_s.tr("\n\r", " ")[0, 256]
end
```

Called by three instrumentation methods that publish to AS::Notifications:
- `instrument_degraded_pre_flush` (line 142) → `ppr.resume.degraded_pre_flush`
- `instrument_degraded_post_flush` (line 149) → `ppr.resume.degraded_post_flush`
- `instrument_cache_read_error` (line 173) → `ppr.cache.read_error`

256 chars is plenty for an email, name, session token, or API key.

**Who consumes these?** The `CacheWarmer` subscribes (line 196-203) and reads
`:error` directly into summary strings. Any APM tool (Datadog, New Relic) that
hooks these events also gets the raw text.

### 1.2 `ppr_sanitize_for_log` logs 1024 chars unredacted

**CONFIRMED.** `react_on_rails_pro_helper.rb:1848-1850`:

```ruby
def ppr_sanitize_for_log(value, max_length: 1024)
  value.to_s.tr("\n\r", " ")[0, max_length]
end
```

Called in `ppr_handle_pre_flush_degradation` (line 1814) and
`ppr_handle_post_flush_degradation` (line 1835). The name "sanitize" is
misleading — it sanitizes for log injection (newlines), not for PII.

### 1.3 Cache-read warn is truly unbounded

**CONFIRMED.** `react_on_rails_pro_helper.rb:1388`:

```ruby
Rails.logger.warn("[ReactOnRailsPro] PPR cache read failed (treating as miss): #{e.class}: #{e.message}")
```

No truncation, no redaction. The `e` comes from `rescue StandardError => e`
(line 1387). Additional unbounded sites at lines 1617, 1820, and 1841.

### 1.4 `PrerenderError` misses `console_messages`

**CONFIRMED.** `prerender_error.rb`:
- Lines 19-20: `@props` and `@js_code` → `redacted_value` → `"[REDACTED]"` ✓
- Line 21: `@console_messages = console_messages` → **stored verbatim** ✗
- Lines 103-105: embedded in `#message` with no redaction:
  ```ruby
  message << "#{console_messages}\n\n"
  ```

Console output comes from `consoleReplayScript` — server-side `console.log`
calls that could contain `console.log("User:", user.email)`.

### Assessment

This is a **real security-adjacent concern**. The AS::Notifications path is the
most important to fix because it fans out to external APM services beyond the
operator's log access controls. The unbounded log sites are secondary but should
be bounded for consistency.

**Necessary fix: YES.**

---

## P2 — Settle budget doesn't bound async render functions: TECHNICALLY CORRECT, BUT OVERSTATED ⚠️

### What's true

The settle timer IS created inside `.then()`, after `Promise.resolve(reactRenderingResult)`
resolves (lines 268-270). If the render function returns a slow Promise, the
timer doesn't start until that Promise settles.

Async render functions ARE supported — they're explicitly typed
(`RenderFunctionAsyncResult`), coded in `createReactOutput.ts` (lines 126-138),
and tested.

### What the issue doesn't mention

**1. This is NOT a PPR-specific problem.** The non-PPR streaming path
(`streamServerRenderedReactComponent.ts:96`) uses the exact same
`Promise.resolve(reactRenderingResult).then(...)` pattern — and it has NO
settle timer, NO abort signal, and NO timeout at all at the JS level. It's
actually worse than the PPR path.

**2. Ruby's `ssr_timeout` is an external safety net.** Default 5 seconds,
configured as `read_timeout` on the HTTP socket to the Node renderer
(`renderer_artifact_support.rb:191`). If the render function hangs and no data
is ever written, Ruby cuts the connection. This prevents true indefinite hangs
in production.

**3. The settle budget was designed to bound React's Fizz prerender**, not the
render function. The render function is supposed to create a React element tree
(fast). Heavy async work (data fetching) should happen inside the component
tree via Suspense/async components, where it IS bounded by the settle timer's
signal to `prerenderToNodeStream`.

**4. Realistic risk is low.** Most render functions return synchronously. Async
render functions exist but are uncommon. A render function that returns a
never-settling Promise is an application bug that `ssr_timeout` already catches.

### If we DO fix it, the fix is more subtle than it looks

(See the updated `settle-budget-explained.md` for the two-scenario analysis.)

If the render function returns late (timer already fired), we can still pass the
element to `prerenderToNodeStream` with the already-aborted signal — React
immediately treats ALL boundaries as holes and produces a valid
`PostponedState`. We can't just emit empty HTML with `pprPrerenderComplete: true`
because without `PostponedState`, Ruby interprets it as "fully static page" and
caches an empty shell.

If the render function truly never returns, we need `Promise.race` to escape,
and must set `pprRenderErrored: true` to prevent Ruby from caching.

### Assessment

The gap exists and the technical claim is correct. But:
- It's not a PPR regression (streaming has the same gap, longer)
- `ssr_timeout` already prevents true hangs in production
- The settle budget was designed for a different purpose (bounding Fizz, not
  the render function invocation)
- Realistic risk is low

**Necessary fix: NICE-TO-HAVE, not P2.** If we do fix it, we should fix both
the PPR and streaming paths for consistency.

---

## Follow-up 1 — FOUC visreg gate: ALREADY DONE, NO WORK NEEDED ❌

The codebase already has extensive FOUC protection testing:

- **ShakaPerf release gate**: `.github/workflows/shakaperf-release-gates.yml`
  — full CI workflow that spins up the Pro dummy app and runs visual regression
  tests
- **ShakaPerf AB test**: `test/shakaperf/rsc-fouc/ab-tests/rsc-fouc-release-gate.abtest.ts`
  — verifies CSS exists before hydration, first-visible-paint is styled
- **Playwright E2E tests**: `react_on_rails_pro/spec/dummy/e2e-tests/rsc_fouc.spec.ts`
  — 446 lines, ~36 test assertions covering every FOUC scenario
- **System spec**: `react_on_rails_pro/spec/dummy/spec/system/integration_spec.rb`
  — verifies inline styles appear before stylesheet bundle in DOM

**No code change needed.**

---

## Follow-up 2 — Ruby spec coverage for #4897 pieces: PARTIALLY VALID, LOW PRIORITY ⚠️

### What's missing

- `ppr_validated_asset_manifest` (helper lines 1670-1681): No Ruby spec
- Envelope `assets` field (helper lines 1648-1662): No Ruby spec
- `pprShellAssets` injection (`server_rendering_js_code.rb:207-213`): No Ruby spec

### What already covers it

- TypeScript tests comprehensively cover the end-to-end dedup behavior
  (6 dedicated tests in `injectRSCPayload.test.ts`, lines 2377-2542)
- `ppr_validated_asset_manifest` degrades gracefully to `nil` (no dedup, no crash)
- `pprShellAssets` injection is a straightforward `to_json` call
- Playwright E2E tests exercise the full Ruby-to-JS pipeline

**Nice-to-have for defense-in-depth, not blocking.**

---

## Follow-up 3 — Href normalization for CSS dedup: NOT A REAL PROBLEM ❌

### Why it's not a problem

1. A `normalizeStylesheetHref` function **already exists** (`injectRSCPayload.ts:260-266`)
   for the preload promotion path.

2. The dedup path uses exact string comparison **intentionally** — both prerender
   and resume read hrefs from the **same `loadable-stats.json`** file. The strings
   are identical by construction.

3. Hrefs can only differ if a deployment changed between prerender and resume,
   but in that case the cache entry's schema/version key changes → cache miss →
   old manifest is never used with new hrefs.

**No code change needed.**

---

## Summary: What actually needs doing

| Item | Verdict | Priority |
|---|---|---|
| P1 error redaction | **REAL — fix needed** | High |
| P2 settle budget | Technically correct but overstated; `ssr_timeout` is safety net | Low |
| FOUC visreg gate | Already fully implemented | None |
| Ruby specs for #4897 | Nice-to-have, not blocking | Low |
| Href normalization | Not a real problem | None |

**Recommended scope for this issue: P1 error redaction only.** The other items
can be closed as "already addressed" or "declined with reasoning" per the
acceptance criteria.
