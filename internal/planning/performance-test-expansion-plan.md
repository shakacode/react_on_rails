# Performance Test Expansion Plan

## Purpose

Plan expanded performance coverage for [Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169) while
explicitly mitigating CI runtime noise.

The goal is to compare React on Rails rendering operations against their own historical baselines, not to produce broad
marketing benchmarks from noisy shared runners.

This plan extends the existing benchmark infrastructure in `benchmarks/bench.rb`, `benchmarks/k6.ts`,
`benchmarks/bench-node-renderer.rb`, and `.github/workflows/benchmark.yml`; it should stay aligned with the max-rate
strategy in `internal/planning/library-benchmarking.md`. Rails HTTP routes, including Pro streaming SSR, should continue
through `benchmarks/bench.rb` and `benchmarks/k6.ts`. Direct Pro Node Renderer transport coverage should build on the
existing Vegeta HTTP/2 Cleartext benchmark rather than duplicating that transport setup in k6.

## Performance Claim Parity Gate

Before quoting benchmark numbers as a public-page speedup, apply the parity gate from
[`internal/analysis/2026-07-gumroad-pagespeed-parity-cautionary-tale.md`](../analysis/2026-07-gumroad-pagespeed-parity-cautionary-tale.md).

- Prefer same-fixture A/B evidence for architecture claims: same host, same data, same browser settings, and matched
  control/candidate routes.
- Treat PageSpeed, Lighthouse, WebPageTest, or live external URL comparisons as diagnostic until media, chrome, CDN,
  cache, and production-service differences are documented.
- Require screenshot or filmstrip evidence that key images, fonts, page chrome, and above-the-fold content exist on both
  sides before calling a result a performance win.
- Keep copy-paste benchmark commands tied to the host that produced the headline artifact, or label them as current-host
  reruns.

## Operations Matrix

Start with a small, representative matrix before adding more routes:

| Area                  | Operation                                 | Primary metric          | Notes                                                                                                                                             |
| --------------------- | ----------------------------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Client rendering      | `react_component` with `prerender: false` | RPS, p50, p90, p99, max | Uses existing HTTP benchmark output; browser mount timing is follow-up instrumentation                                                            |
| Traditional SSR       | `react_component` with `prerender: true`  | RPS, p50, p90, p99, max | OSS first slice uses ExecJS; Pro Node Renderer follow-up uses `benchmarks/bench-node-renderer.rb`                                                 |
| Hash SSR              | `react_component_hash`                    | RPS, p50, p90, p99, max | Deferred; see First PR Scope. Payload-size capture requires tooling extension                                                                     |
| Streaming SSR         | `stream_react_component`                  | RPS, p50, p90, p99, max | Pro-only Rails HTTP path; TTFB (`http_req_waiting`) and response-end (`http_req_duration`) capture in k6 artifacts required before new thresholds |
| RSC payload rendering | `rsc_payload_react_component`             | RPS, p50, p90, p99, max | Use a static/default route because route discovery skips required params                                                                          |
| Fragment caching      | `react_component` with `cache: true`      | RPS, p50, p90, p99, max | Requires separate primed-hit and busted-miss paths or setup steps; k6 cannot infer cache state                                                    |

Here `p50` maps to k6's `med` stat and the `p50_latency` Bencher Metric Format measure. `p90`, `p99`, and `max`
keep their k6 names (`p(90)`, `p(99)`, `max`) and map to the `p90_latency`, `p99_latency`, and `max_latency` Bencher
measures — only `med`/`p50` is renamed in the mapping.

## First PR Scope

The first implementation PR should add only one or two routes per category and should reuse existing dummy app examples
where possible. Avoid building a large benchmark suite until the noise profile is understood.

### OSS First Slice

Recommended OSS first slice for [Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169):

1. Client-only component route
2. Traditional SSR route with the same component and props
3. Cached SSR route with explicit hit and miss measurements

Hash SSR is deferred to a follow-on PR after the initial OSS noise profile is understood.

### Cache Setup

The cached SSR slice should define separate cache-hit and cache-miss benchmark paths before comparing results. Use a
dedicated cache adapter and namespace for benchmark routes, such as
`ActiveSupport::Cache::FileStore.new(Rails.root.join("tmp/benchmark_cache").to_s)`, instead of the app's default store.

**Clearing the dedicated cache store.** Target the exact store root for the dedicated `FileStore`. From Rails-loaded
code, use `FileUtils.rm_rf(Rails.root.join("tmp/benchmark_cache"))`. From `benchmarks/bench.rb` or another plain Ruby
wrapper where `Rails.root` is unavailable, use `FileUtils.rm_rf(File.join(APP_DIR, "tmp/benchmark_cache"))`. `APP_DIR`
in `benchmarks/bench.rb` is the relative path `react_on_rails/spec/dummy` (or `react_on_rails_pro/spec/dummy` with
`PRO=true`), so this `File.join` call only resolves correctly when bench.rb is invoked from the repo root. The
benchmark workflow already runs from the repo root, but the implementation PR must either document that
working-directory assumption near the cache-clear call or anchor the path explicitly, so a future runner-configuration
change cannot silently skip the cache clear. The anchored form below must live in `benchmarks/bench.rb` itself, where
`__dir__` resolves to `benchmarks/` and `File.join(__dir__, "..")` resolves to the repo root:

```ruby
# In benchmarks/bench.rb (__dir__ is benchmarks/, File.join(__dir__, "..") is the repo root):
FileUtils.rm_rf(File.expand_path(File.join(APP_DIR, "tmp/benchmark_cache"), File.join(__dir__, "..")))
```

If this logic is later extracted into a helper file (for example `benchmarks/lib/cache_helpers.rb`), `__dir__` becomes
the helper's directory and `File.join(__dir__, "..")` resolves to `benchmarks/` — one directory level short of the repo
root, silently skipping the cache clear. In that case, anchor the path from `__FILE__` in `bench.rb` and pass the
resolved root into the helper as an argument rather than calling `__dir__` inside the helper.

**Caches to leave alone.** Do not clear `tmp/cache/assets` or the app's default cache store. Avoid `Rails.cache.clear`
on the application cache. Avoid relying on a shared Redis instance, environment-default `:null_store`/`:memory_store`
behavior, or manual cache state.

**Cache-miss measurement.** To avoid mixing cold Rails-process noise into the measurement:

1. Warm the Rails process against a route that does not populate the benchmark cache.
2. Clear the dedicated benchmark cache (using one of the `FileUtils.rm_rf` forms above) immediately before the k6
   measurement.
3. Run the k6 measurement against the route under test.

Cache-miss routes are the explicit exception to the per-route k6 warm-up loop described under Noise Controls; otherwise
the 10 pre-requests would populate the fragment cache for the route before measurement begins.

**Cache-hit measurement.**

1. Clear the dedicated benchmark cache (using one of the `FileUtils.rm_rf` forms above).
2. Send one explicit cache-prime request to the measured route so the fragment is written to the dedicated cache.
3. Run the existing per-route k6 warm-up loop. The warm-up does not clear the cache, so the fragment stays primed.
4. Run the k6 measurement against the primed route.

### Pro Follow-Up Slice

Recommended Pro slice for [Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169), implemented after the
OSS first slice or in a dedicated follow-up PR:

1. Streaming route with a small Suspense boundary. Start with the existing HTTP summary metrics, then add explicit
   TTFB/response-end capture in the k6 artifacts, CI summary, and Bencher output before defining streaming-specific
   thresholds. LCP remains separate browser instrumentation such as Playwright or Lighthouse.
2. RSC payload route with representative payload size measurements. Treat this as endpoint throughput and payload-size
   coverage rather than streaming TTFB measurement. Use a static benchmark route with no required URL params. If the
   dummy app has no parameter-free RSC route, run `benchmarks/k6.ts` with an explicit `TARGET_URL`; alternatively,
   introduce an `RSC_BENCHMARK_COMPONENT` environment variable defaulting to a known component name so
   `benchmarks/bench.rb` can construct the URL without relying on route discovery. When `RSC_BENCHMARK_COMPONENT` is set,
   `benchmarks/bench.rb` constructs the target URL as `/rsc_payload/#{RSC_BENCHMARK_COMPONENT}` and bypasses route
   discovery for that entry. The implementation PR must verify that the `/rsc_payload/` prefix still matches the Pro
   dummy app's `routes.rb` before relying on this convention. If neither `TARGET_URL` nor `RSC_BENCHMARK_COMPONENT` is
   provided and no parameter-free RSC route exists, route-list setup must call `abort(msg)` or otherwise exit non-zero
   before benchmark measurements begin, with an actionable error instead of silently skipping RSC coverage. Do this as a
   preflight check during route-list construction, not as a mid-run abort after partial artifacts have been written.
   Automatic route discovery currently skips required-parameter routes such as `/rsc_payload/:component_name`.

### Script Boundaries And Naming

Use `benchmarks/bench.rb`/`benchmarks/k6.ts` for Rails HTTP routes such as streaming SSR and static RSC payload endpoint
checks. Use `benchmarks/bench-node-renderer.rb` for direct Pro Node Renderer transport coverage unless that script is
extended to cover full Rails streaming behavior.

Run Pro routes with `PRO=true`; `benchmarks/bench.rb` switches `APP_DIR` to `react_on_rails_pro/spec/dummy`. The current
Bencher suffix is `: Core` for OSS routes and `: Pro` for Pro routes, so cache-hit/cache-miss benchmark names should
preserve that suffix while adding the exact cache-state suffix ` (cache-hit)` or ` (cache-miss)`, for example
`/my_route: Core (cache-hit)` and `/my_route: Core (cache-miss)`. Keep the parentheses and hyphenated spelling
consistent because Bencher treats the benchmark name as the primary key.

## Noise Controls

Use these controls before treating results as regressions.

Already in place:

- Keep the existing per-route warm-up before k6 measurement: 10 sequential requests with 0.5 seconds between requests.
  Each iteration is request round-trip plus 0.5 seconds of sleep, so the warm-up takes a lower bound of 5 seconds per
  route plus the actual request time, which is on the order of 5-6 seconds for SSR routes today. Expand it if routes,
  especially streaming routes, need more stable startup behavior. Cache-miss benchmark routes are the explicit exception
  to this per-route warm-up: see Cache Setup above, which warms the Rails process against a different route and then
  clears the dedicated benchmark cache immediately before the cache-miss k6 measurement, so the 10 pre-requests never
  populate the fragment cache for the route under measurement.
- Keep the current max-rate throughput baseline from `internal/planning/library-benchmarking.md`.
- Keep hard CI gates disabled until the benchmark gate tuning in
  [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169) has a stable baseline.

Prerequisites for the first implementation PR (blocking — must land before or with the first benchmark-routes PR):

- Record sample count, runner type, Ruby version, Node version, React version, renderer, and bundle mode in a
  `metadata.json` artifact and mirror the key fields in the `summary.txt` header. Capture runtime-dependent fields when
  the benchmark runs instead of hard-coding the example schema values: use `ruby --version` for `ruby_version`,
  `node --version` for `node_version`, populate `runner_type` from `ENV["RUNNER_OS"]` and `ENV["RUNNER_ARCH"]` (both
  set by GitHub Actions, so local runs fall back to `"unknown"` via the snippet below), and capture `react_version`
  by invoking Node from `APP_DIR` so OSS and Pro dummy apps report their own installed React
  package. The implementation PR must use a chdir-aware Ruby call so `require()` resolves against `APP_DIR/node_modules`
  rather than `Dir.pwd`. Preferred form (no global side effects):

  ```ruby
  begin
    react_version_output, status = Open3.capture2(
      "node", "-e", "console.log(require('react/package.json').version)",
      chdir: APP_DIR
    )
    react_version = status.success? ? react_version_output.strip : "unknown"
    warn "WARNING: could not capture react_version" unless status.success?
  rescue StandardError => e
    react_version = "unknown"
    warn "WARNING: could not capture react_version: #{e.message}"
  end
  ```

  The `rescue StandardError` wrapper is required so `Errno::ENOENT` (node not on `PATH`), `Errno::EACCES`, and similar
  spawn failures fall through to the same `"unknown"` fallback as a non-zero exit. Without it, an implementer copying the
  snippet verbatim will let those exceptions abort the benchmark run.

  Derive `renderer` from the same `PRO` switch that selects `APP_DIR`, rather than copying the example schema value.
  Reuse the existing `PRO = ENV.fetch("PRO", "false") == "true"` constant defined at the top of `benchmarks/bench.rb`
  rather than re-deriving the boolean inline, so a future change to the constant cannot diverge from the renderer
  selection:

  ```ruby
  renderer = PRO ? "node_renderer" : "execjs"
  ```

  Equivalent block form using `Dir.chdir(APP_DIR) do ... end` is acceptable when the surrounding code already manages
  working directory state. The snippet above already records `react_version: "unknown"` and emits a warning for both
  non-zero exit codes (for example when `node_modules` is not yet installed in `APP_DIR`) and `Open3.capture2`
  exceptions; do not let either path abort the benchmark run. Capture `bundle_mode` from `ENV["NODE_ENV"]` (falling back to
  `"production"`) as a best-effort process environment label. Do not treat that value as proof of the Webpack build mode
  when prebuilt assets or explicit build flags may diverge; if exact asset-build fidelity is needed later, record it from
  the build output or a build-written metadata file.
  Populate `runner_type` with:

  ```ruby
  runner_type = [ENV["RUNNER_OS"], ENV["RUNNER_ARCH"]]
                .compact
                .join("/")
                .then { |value| value.empty? ? "unknown" : value }
  ```

  Define `sample_count` as the number of completed k6 measurement runs contributing to the route's reported summary. The
  first slice should start at one run per route. If a later implementation aggregates forward and reverse passes into a
  single route summary, record `sample_count: 2`; if it writes one summary per pass, keep each summary at
  `sample_count: 1`. Do not count a run whose `rps` value is `FAILED`, `MISSING`, or otherwise non-numeric toward
  `sample_count`; this matches the `BmfCollector#add` guard that skips non-numeric RPS entries.

  Use these metadata keys as the minimum schema. The JSON block shows example output values; populate the real artifact
  with the runtime capture rules above instead of copying these literals:

  ```json
  {
    "ruby_version": "ruby 3.3.6",
    "node_version": "v22.13.1",
    "react_version": "18.2.0",
    "renderer": "execjs",
    "runner_type": "Linux/X64",
    "bundle_mode": "production",
    "sample_count": 1
  }
  ```

  The implementation PR also needs to extend the `actions/upload-artifact` step in `.github/workflows/benchmark.yml` to
  upload `metadata.json` alongside the existing summary and BMF artifacts; otherwise the schema lands but the artifact
  never reaches CI consumers.

- Preserve the existing `benchmarks/bench.rb` summary metrics (`RPS`, `p50`, `p90`, `p99`, and `max`) and extend Bencher
  BMF reporting to include `max_latency` alongside the existing `rps`, `p50_latency`, `p90_latency`, `p99_latency`, and
  `failed_pct` measures. Today `max` appears in `summary.txt` but not in the BMF output. Add a `max:` keyword parameter
  to `BmfCollector#add` in `benchmarks/lib/bmf_helpers.rb` with a default of `nil` so existing callers stay valid, then
  pass `max: max_latency` from the `bmf_collector.add` call in `benchmarks/bench.rb`. Inside `add`, also store the
  new keyword on the appended `@results` hash by adding `max: max` alongside the existing `name`, `rps`, `p50`,
  `p90`, `p99`, and `failed_pct` keys; without this step `r[:max]` is always `nil` in `to_bmf` and `add_measure`
  silently skips the measure. In `BmfCollector#to_bmf`, emit the new measure as
  `add_measure(benchmark_entry, "max_latency", r[:max])` so the BMF key matches the `_latency` suffix convention
  already used by `p50_latency`, `p90_latency`, and `p99_latency`. Updating the matching
  `bmf_collector.add` calls in `benchmarks/bench-node-renderer.rb` (inside the `non_rsc_tests.each` and
  `rsc_tests.each` blocks) is deferred to the Pro follow-on PR so the OSS first slice can land without changing Node
  Renderer benchmark output. That follow-on change is intentionally small: `bench-node-renderer.rb` already extracts
  `vegeta_max` from the Vegeta JSON report and threads `max_latency` through `run_vegeta_benchmark` and
  `add_to_summary`. The Pro PR only needs to pass `max: max_latency` to those two existing `bmf_collector.add` calls;
  no Vegeta extraction or summary-row changes are required.

  While editing `BmfCollector` to thread `max_latency`, also fix the stale comment near the top of
  `benchmarks/lib/bmf_helpers.rb` that currently reads `p50_latency_ms, p90_latency_ms, p99_latency_ms`. The actual
  measure keys emitted by `to_bmf` are `p50_latency`, `p90_latency`, and `p99_latency` (no `_ms` suffix); leaving the
  comment as-is invites a future implementer to add `max_latency_ms` by analogy and diverge from the Bencher measure
  keys.

  `max_latency` lands as an unthresholded advisory metric in the OSS first slice: the BMF payload includes the new key,
  but the `run_bencher` function in `.github/workflows/benchmark.yml` is not modified, so Bencher tracks the value
  without gating CI. Adding the corresponding threshold block is a deliberate follow-on step (see "Follow-on
  enhancements" below) so the OSS first slice can land without absorbing a new CI gate before the baseline is
  characterized.

- Extract the current k6 `--summary-trend-stats` string (`med,max,p(90),p(99)` in `benchmarks/bench.rb`) into a named
  constant such as `K6_TREND_STATS = "med,max,p(90),p(99)"`, defined alongside `DURATION` in
  `benchmarks/lib/benchmark_config.rb`, and reference it from the existing `--summary-trend-stats` invocation in
  `benchmarks/bench.rb`. Landing the constant in the first implementation PR — before any follow-on PR adds `p95` or
  otherwise extends the trend-stats column set — keeps the percentile list in one place rather than scattered across
  the bench script, summary table, artifacts, and Bencher reporting. The constant applies only to k6 in
  `benchmarks/bench.rb`. `benchmarks/bench-node-renderer.rb` drives Vegeta, which has no equivalent flag and extracts
  percentiles directly from its JSON report, so do not thread the constant through the Vegeta path.

Recommended prior work (desirable but not blocking for the first benchmark-routes PR):

- Define forward-then-reverse route passes in `benchmarks/bench.rb` as two deterministic passes over the same route list:
  first in `rails routes` order, then in reverse order in the same job. Record the pass order with the per-route
  artifacts before using route ordering as a noise-control signal. This is large enough to land as its own preparatory
  PR, and the first benchmark-routes PR can defer it if the route-order work blocks progress. Budget it intentionally
  because it roughly doubles route runtime: each route gets two k6 runs plus two warm-up phases, or about
  `2 * (DURATION + warm-up requests * (request round-trip + warm-up sleep))` per route. With today's defaults and the
  hard-coded warm-up loop in `benchmarks/bench.rb`, the sleep-only lower bound is
  `2 * (DURATION + 10 * 0.5s) = 2 * (30s + 10 * 0.5s) = 70 seconds` at the current `DURATION` default of `30s`;
  for SSR routes today the warm-up adds another roughly 1-2 seconds per route, putting the real per-route budget closer
  to 72-80 seconds before any server overhead. This estimate does not include the per-job `bundle exec rails routes`
  discovery call, server startup, or server warmdown time. At the job level, a benchmark job covering about 10 routes
  should be budgeted as roughly doubling from 11-12 minutes to 22-24 minutes before additional startup or warmdown
  overhead. Recalculate the estimate if `DURATION` changes or if the `benchmarks/bench.rb` warm-up loop changes.

Follow-on enhancements:

- Add a `--threshold-measure max_latency` block to `run_bencher` in `.github/workflows/benchmark.yml` so `max_latency`
  becomes a CI gate. Mirror the existing latency-block shape (`--threshold-test t_test`,
  `--threshold-max-sample-size $MAX_SAMPLE`, `--threshold-lower-boundary _`,
  `--threshold-upper-boundary $BOUNDARY`) used for `p50_latency`, `p90_latency`, and `p99_latency`. Gate this on
  observing a stable `max_latency` baseline first, since `max` is more sensitive to single-iteration spikes than the
  percentile measures.

- Add `p95` only when the k6 `--summary-trend-stats` flag, currently `med,max,p(90),p(99)` in `benchmarks/bench.rb`, the
  summary table, artifacts, and Bencher reporting can be updated together. Update the `K6_TREND_STATS` constant
  (introduced as a prerequisite of the first implementation PR) so the percentile set is changed in one place.
- Require repeated or overlapping alerts before opening an issue or failing CI.

## Local Verification Before CI

Every benchmark PR should include:

- a local command that runs the benchmark subset
- expected output shape
- a short note explaining what changed in the measured surface
- proof that the benchmark can run without unrelated app servers or ports already running

If a benchmark requires generated assets, the command should build those assets explicitly so CI and local runs use the
same mode.

Until benchmark-specific contributor docs exist, put this checklist in each benchmark implementation PR description. The
implementation work should then create `benchmarks/README.md` or a benchmark-specific pull request template so
reviewers have one stable compliance checklist.

## Acceptance Criteria

- The OSS suite covers client-only rendering, traditional SSR, and at least one cache path.
- The Pro suite covers streaming SSR and RSC payload rendering where the Node Renderer is available. Streaming-specific
  TTFB/response-end thresholds are only introduced after those metrics are captured in artifacts and reporting.
- Results include enough metadata to compare runs meaningfully.
- CI behavior is advisory until noise controls are proven.
- Regression detection favors sustained movement over single-run spikes and uses the current `p50`, `p90`, `p99`, and
  `max` metrics until `p95` is added explicitly.
- Contributor documentation in `benchmarks/README.md` (or the benchmark-specific pull request template referenced under
  Local Verification Before CI) tells contributors which benchmark to run for each rendering area.

## Rollback / Abort Criteria

If the noise controls in this plan still leave shared-runner variance too high to establish a stable baseline, treat
the rollout as a rollback signal rather than continuing to lower thresholds:

- If two consecutive benchmark runs on the same commit (no code changes) disagree by more than the largest threshold
  the plan would set for any tracked metric, pause adding new routes and document the variance in the issue tracker.
- If, after applying forward-then-reverse passes and the metadata artifact, single-commit variance still exceeds the
  bands established in `internal/planning/library-benchmarking.md`, defer hard CI gates indefinitely and revisit the
  approach (dedicated runner, longer sampling windows, or relocating the benchmark out of the shared CI job).
- Until the abort criteria are clearly satisfied, keep all benchmark CI behavior advisory and do not block merges on
  benchmark deltas.

## See Also

- `benchmarks/bench.rb`
- `benchmarks/k6.ts`
- `benchmarks/bench-node-renderer.rb`
- `.github/workflows/benchmark.yml`
- `internal/planning/library-benchmarking.md`
