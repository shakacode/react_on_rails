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

Here `p50` maps to k6's `med` stat and the `p50_latency` Bencher Metric Format measure.

## First PR Scope

The first implementation PR should add only one or two routes per category and should reuse existing dummy app examples
where possible. Avoid building a large benchmark suite until the noise profile is understood.

Recommended OSS first slice for [Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169):

1. Client-only component route
2. Traditional SSR route with the same component and props
3. Cached SSR route with explicit hit and miss measurements

Hash SSR is deferred to a follow-on PR after the initial OSS noise profile is understood. The cached SSR slice should
define separate cache-hit and cache-miss benchmark paths before comparing results. Use a dedicated cache adapter and
namespace for benchmark routes, such as `ActiveSupport::Cache::FileStore.new(Rails.root.join("tmp/benchmark_cache").to_s)`, instead of the
app's default store. The miss path should clear only that benchmark cache namespace before measurement, and the hit path
should clear that namespace, make one warm-up request to prime the fragment, then run k6 against the primed route. For
the dedicated `FileStore`, clear the exact store root, for example
`FileUtils.rm_rf(Rails.root.join("tmp/benchmark_cache"))`; do not clear `tmp/cache/assets` or the app's default cache
store. Avoid `Rails.cache.clear` on the application cache. Avoid relying on a shared Redis instance, environment-default
`:null_store`/`:memory_store` behavior, or manual cache state. To avoid mixing cold Rails-process noise into cache-miss
measurements, warm the Rails process with a route that does not populate the benchmark cache, then clear the dedicated
benchmark cache immediately before the cache-miss k6 measurement. For cache-hit measurements, clear the dedicated
benchmark cache, send one explicit cache-prime request to the measured route, then run the existing per-route k6 warm-up
and measurement against the primed route.

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
   discovery for that entry. If neither `TARGET_URL` nor `RSC_BENCHMARK_COMPONENT` is provided and no parameter-free RSC
   route exists, fail setup with an actionable error instead of silently skipping RSC coverage. Automatic route discovery
   currently skips required-parameter routes such as `/rsc_payload/:component_name`.

Use `benchmarks/bench.rb`/`benchmarks/k6.ts` for Rails HTTP routes such as streaming SSR and static RSC payload endpoint
checks. Use `benchmarks/bench-node-renderer.rb` for direct Pro Node Renderer transport coverage unless that script is
extended to cover full Rails streaming behavior.

Run Pro routes with `PRO=true`; `benchmarks/bench.rb` switches `APP_DIR` to `react_on_rails_pro/spec/dummy`. The current
Bencher suffix is `: Core` for OSS routes and `: Pro` for Pro routes, so cache-hit/cache-miss benchmark names should
preserve that suffix while adding the new cache-state distinction.

## Noise Controls

Use these controls before treating results as regressions.

Already in place:

- Keep the existing per-route warm-up before k6 measurement: 10 sequential requests with 0.5 seconds between requests, or
  about 5 seconds per route. Expand it if routes, especially streaming routes, need more stable startup behavior.
- Keep the current max-rate throughput baseline from `internal/planning/library-benchmarking.md`.
- Keep hard CI gates disabled until the benchmark gate tuning in
  [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169) has a stable baseline.

Prerequisites for the first implementation PR:

- Define forward-then-reverse route passes in `benchmarks/bench.rb` as two deterministic passes over the same route list:
  first in `rails routes` order, then in reverse order in the same job. Record the pass order with the per-route
  artifacts before using route ordering as a noise-control signal. This is large enough to land as its own prerequisite
  PR, and the first benchmark-routes PR can defer it if the route-order work blocks progress. Budget it intentionally
  because it roughly doubles route runtime: each route gets two k6 runs plus two warm-up phases, or about
  `2 * (DURATION + warm-up requests * warm-up sleep)` per route. With today's defaults and the hard-coded warm-up loop in
  `benchmarks/bench.rb`, that is `2 * (30s + 10 * 0.5s)` = 70 seconds. This estimate does not include the per-job
  `bundle exec rails routes` discovery call, server startup, or server warmdown time. Recalculate the estimate if
  `DURATION` changes or if the `benchmarks/bench.rb` warm-up loop changes.
- Record sample count, runner type, Ruby version, Node version, React version, renderer, and bundle mode in a
  `metadata.json` artifact and mirror the key fields in the `summary.txt` header. Capture runtime-dependent fields when
  the benchmark runs instead of hard-coding the example schema values: use `ruby --version` for `ruby_version`,
  `node --version` for `node_version`, and capture `react_version` by invoking Node from `APP_DIR` so OSS and Pro dummy
  apps report their own installed React package. The implementation PR must use a chdir-aware Ruby call so `require()`
  resolves against `APP_DIR/node_modules` rather than `Dir.pwd`. Preferred form (no global side effects):

  ```ruby
  react_version, _status = Open3.capture2(
    "node", "-e", "console.log(require('react/package.json').version)",
    chdir: APP_DIR
  )
  react_version = react_version.strip
  ```

  Equivalent block form using `Dir.chdir(APP_DIR) do ... end` is acceptable when the surrounding code already manages
  working directory state. If the `react_version` capture command fails (for example when `node_modules` is not yet
  installed in `APP_DIR`), record `react_version: "unknown"` and emit a warning rather than aborting the benchmark run. Capture `bundle_mode` from
  `ENV["NODE_ENV"]` (falling back to `"production"`) so the recorded mode reflects the actual build rather than silently
  lying when CI or local runs use a non-production mode.
  Define `sample_count` as the number of completed k6 measurement runs contributing to the route's reported summary. The
  first slice should start at one run per route. If a later implementation aggregates forward and reverse passes into a
  single route summary, record `sample_count: 2`; if it writes one summary per pass, keep each summary at
  `sample_count: 1`.

  Use these metadata keys as the minimum schema:

  ```json
  {
    "ruby_version": "<output of: ruby --version>",
    "node_version": "<output of: node --version>",
    "react_version": "<output of: Open3.capture2(\"node\", \"-e\", \"console.log(require('react/package.json').version)\", chdir: APP_DIR)>",
    "renderer": "<node_renderer when PRO=true, otherwise execjs>",
    "runner_type": "<RUNNER_OS/RUNNER_ARCH when available, otherwise local platform>",
    "bundle_mode": "<ENV[\"NODE_ENV\"] when set, otherwise production>",
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
  pass `max: max_latency` from the `bmf_collector.add` call in `benchmarks/bench.rb`. Updating the matching
  `bmf_collector.add` calls in `benchmarks/bench-node-renderer.rb` (inside the `non_rsc_tests.each` and
  `rsc_tests.each` blocks) is deferred to the Pro follow-on PR so the OSS first slice can land without changing Node
  Renderer benchmark output.

Follow-on enhancements:

- Add `p95` only when the k6 `--summary-trend-stats` flag, currently `med,max,p(90),p(99)` in `benchmarks/bench.rb`, the
  summary table, artifacts, and Bencher reporting can be updated together.
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
