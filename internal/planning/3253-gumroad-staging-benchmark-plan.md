# Gumroad RSC Benchmark — Staging Repeat Plan

**Status:** Planning — addresses [Issue #3253](https://github.com/shakacode/react_on_rails/issues/3253) acceptance
criteria 2 and 3 (stable deployed/staging repeat with full environment metadata and named measurement gaps).

**Related:** [Issue #3128](https://github.com/shakacode/react_on_rails/issues/3128),
[Issue #3144](https://github.com/shakacode/react_on_rails/issues/3144),
[Issue #3259](https://github.com/shakacode/react_on_rails/issues/3259),
[Issue #3263](https://github.com/shakacode/react_on_rails/issues/3263),
[PR #3233](https://github.com/shakacode/react_on_rails/pull/3233).

**Demo repo:** [shakacode/react-on-rails-demo-gumroad-rsc](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc)

**Date:** 2026-05-20

---

## Why this plan exists

The April 30, 2026 local Gumroad benchmark documented in
[`performance-benchmarks.md`](../../docs/oss/core-concepts/performance-benchmarks.md#gumroad-style-rsc-demo) is a
non-production directional signal. Its environment metadata (`RAILS_ENV`, hardware/OS, Ruby/Node/Rails versions,
browser-cache state) was not preserved and is not recoverable. The current docs hedge with that caveat, but readers
cannot calibrate the absolute timings without an environment baseline.

Issue #3253 asks for two follow-ups that this plan covers:

1. A deployed/staging repeat with the same Inertia vs RSC comparison, full environment metadata, and renderer-internal
   timing.
2. Named measurement gaps so readers can calibrate the benchmark.

The plan below converts those into an executable protocol.

---

## Scope

In scope:

- Repeat the existing two-route comparison (`/dashboard/inertia_demo` vs `/dashboard/rsc_demo`) on a stable
  staging-class host.
- Capture all environment metadata listed in
  [`performance-benchmarks.md` env checklist](../../docs/oss/core-concepts/performance-benchmarks.md#gumroad-rsc-env-metadata-checklist).
- Add renderer-internal timing for the RSC render/payload path (`Server-Timing` and/or Pro tracing).
- Publish raw per-run distribution artifacts, not just medians.

Out of scope:

- Production traffic shadowing.
- Isolating the three confounded axes (RSC vs Pro Node renderer vs SSR). That is tracked elsewhere; this plan keeps the
  combined route-level signal.
- Cross-bundler comparison (both routes continue to use Shakapacker with Rspack).

---

## Environment

The staging host must be stable across the full measurement window (no autoscaling, no shared CPU contention).
Acceptable options, in order of preference:

1. A dedicated bare-metal or fixed-instance VM (e.g., a fixed Linode/Hetzner/EC2 instance with no neighbors).
2. A Fly.io / Render dedicated CPU plan with a known instance class, no autoscale, and at least 4 GB RAM.
3. A local laptop run with all OS power management disabled. Acceptable only as a fallback; document the limitation.

Required configuration:

- `RAILS_ENV=production`, `NODE_ENV=production`.
- Compiled page assets from the same Shakapacker with Rspack build for both routes.
- Compiled RSC demo bundles.
- Rails server running without the Shakapacker dev server.
- Dedicated React on Rails Pro Node renderer process, `RENDERER_PORT=3800`, worker count fixed and recorded.
- Eager loading enabled, asset caching enabled, fragment caching default.
- Database fixture data identical to the local run (same product/sale counts) and pre-seeded before warmup.

---

## Run protocol

1. **Warmup floor.** Before any measured run, hit each route at least 20 times sequentially. This is well above the
   single warmup of the local run; the goal is to push the Pro Node renderer worker pool past JIT and RSC-payload
   compilation steady state. Record the wall-clock duration of the warmup phase.
2. **Alternation.** Measured runs alternate strictly between Inertia and RSC, starting with the route that has more
   variance historically (RSC).
3. **Sample size.** Target `n = 30` per route (60 total measured runs). This is enough to compute a real p95 rather
   than a max-as-p95 substitute, and to bound the confidence interval on the median.
4. **Browser-cache policy.** Run each measured request in a fresh Chrome profile (cold cache). Record this explicitly.
5. **Per-run capture.** For each measured run, record: navigation duration (Playwright), LCP, `responseEnd`, controller
   `action_total`, `Server-Timing` values, page-script request count, total transfer size.

---

## Renderer-internal timing

The local run could not attribute Rails wall time to the RSC render/payload split because the Pro Node renderer runs
out-of-process. The staging repeat must close that gap with one of:

- **Preferred: `Server-Timing`.** Emit `Server-Timing` headers from the Rails controller covering: total controller
  time, RSC payload-fetch time (round trip to the Pro Node renderer), HTML render time. The browser captures these on
  `PerformanceServerTiming` entries and they can be read directly from Playwright. This is the most precise option and
  it is visible from the browser side.
- **Fallback: Pro tracing.** Set `config.tracing = true` in `config/initializers/react_on_rails_pro.rb`. This logs
  renderer-side timings to the Pro Node renderer log. Correlate with controller logs via request ID.

The plan should produce at least the `Server-Timing` path. Tracing is a belt-and-suspenders backup for any timings the
browser cannot see.

---

## Required artifacts

Each staging run must publish (alongside the existing `docs/performance-findings.md` artifact in the demo repo):

- `environment.md` — full env checklist from
  [`performance-benchmarks.md`](../../docs/oss/core-concepts/performance-benchmarks.md#gumroad-rsc-env-metadata-checklist),
  filled in completely. Missing fields explicitly marked `unknown` rather than omitted.
- `raw-runs.csv` — one row per measured run with every captured metric. This is the distribution artifact #3263 has
  been asking for.
- `summary.md` — median, p95, min, max, IQR for each metric; explicit `n` and variance commentary; renderer-internal
  timing breakdown.
- `methodology.md` — exact run protocol, warmup script, browser-profile reset procedure, alternation pattern,
  hardware/OS, tool versions.

The demo repo's `docs/performance-findings.md` should link to all four.

---

## Doc updates after the staging run completes

When the staging numbers land, update
[`performance-benchmarks.md`](../../docs/oss/core-concepts/performance-benchmarks.md) to:

1. Add a new "Staging repeat (date)" subsection alongside the April 2026 local section, not replacing it. The local
   section stays as historical context; the staging numbers become the recommended directional signal.
2. Replace the WARNING block with one that names which gaps the staging run closed and which remain (e.g., still a
   single staging host, still confounds three axes).
3. Update the worst-case `responseEnd` table with `n = 30` p95 rather than max-as-p95.
4. Add a `Server-Timing` row to the metrics table so readers see the renderer-internal split.

---

## Closing #3253

Issue #3253 closes when:

- [x] Criterion 1: doc explicitly states the April 30 specs were not preserved. _(covered by the doc edits in this
      branch, jg/3253-benchmark-env-metadata)._
- [ ] Criterion 2: staging repeat published with the four artifacts listed above.
- [ ] Criterion 3: residual measurement gaps named in the new WARNING block.

This plan tracks criteria 2 and 3; executing the staging run is a separate work item.

---

## Risks and unknowns

- **Staging host availability.** A dedicated stable host is a real spend; if the team chooses the laptop fallback,
  document the limitation prominently and treat staging results as another directional signal rather than a stable
  baseline.
- **`Server-Timing` instrumentation.** The Pro Node renderer round-trip is the trickiest segment; the Rails controller
  may need a small wrapper around the renderer client to capture the round-trip duration. Plan a 1–2 hour spike before
  the run to confirm the instrumentation works.
- **n = 30 budget.** Sixty measured runs plus warmup is roughly 30–45 minutes wall-clock. Confirm the staging host
  budget can absorb this; if not, drop to `n = 20` and accept wider confidence intervals.
- **Browser cache state surprises.** Playwright can share state across runs if the profile is not reset between
  navigations. The methodology must explicitly reset each measured run's profile, not just clear cookies.
