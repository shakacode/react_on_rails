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

| Area                  | Operation                                 | Primary metric          | Notes                                                                                               |
| --------------------- | ----------------------------------------- | ----------------------- | --------------------------------------------------------------------------------------------------- |
| Client rendering      | `react_component` with `prerender: false` | RPS, p50, p90, p99, max | Uses existing HTTP benchmark output; browser mount timing is follow-up instrumentation              |
| Traditional SSR       | `react_component` with `prerender: true`  | RPS, p50, p90, p99, max | Covers ExecJS and Node Renderer paths; server render duration requires separate instrumentation     |
| Hash SSR              | `react_component_hash`                    | RPS, p50, p90, p99, max | Covers render-functions returning objects; payload-size capture requires tooling extension          |
| Streaming SSR         | `stream_react_component`                  | RPS, p50, p90, p99, max | Pro-only Rails HTTP path; TTFB/response-end reporting is a required extension before new thresholds |
| RSC payload rendering | `rsc_payload_react_component`             | RPS, p50, p90, p99, max | Pro-only endpoint throughput and payload-size path; not a streaming TTFB target                     |
| Fragment caching      | `react_component` with `cache: true`      | RPS, p50, p90, p99, max | Requires separate primed-hit and busted-miss paths or setup steps; k6 cannot infer cache state      |

## First PR Scope

The first implementation PR should add only one or two routes per category and should reuse existing dummy app examples
where possible. Avoid building a large benchmark suite until the noise profile is understood.

Recommended OSS first slice for [Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169):

1. Client-only component route
2. Traditional SSR route with the same component and props
3. Cached SSR route with explicit hit and miss measurements

Hash SSR is deferred to a follow-on PR after the initial OSS noise profile is understood. The cached SSR slice should
define separate cache-hit and cache-miss benchmark paths, or a deterministic priming and busting step, before comparing
results.

Recommended Pro slice for [Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169), implemented after the
OSS first slice or in a dedicated follow-up PR:

1. Streaming route with a small Suspense boundary. Start with the existing HTTP summary metrics, then add explicit
   TTFB/response-end capture in the k6 artifacts, CI summary, and Bencher output before defining streaming-specific
   thresholds. LCP remains separate browser instrumentation such as Playwright or Lighthouse.
2. RSC payload route with representative payload size measurements. Treat this as endpoint throughput and payload-size
   coverage rather than streaming TTFB measurement. Use a static benchmark route with no required URL params, teach
   `benchmarks/bench.rb` how to provide a default component name, or run `benchmarks/k6.ts` with an explicit `TARGET_URL`;
   automatic route discovery currently skips required-parameter routes such as `/rsc_payload/:component_name`.

Use `benchmarks/bench.rb`/`benchmarks/k6.ts` for Rails HTTP routes such as streaming SSR and static RSC payload endpoint
checks. Use `benchmarks/bench-node-renderer.rb` for direct Pro Node Renderer transport coverage unless that script is
extended to cover full Rails streaming behavior.

## Noise Controls

Use these controls before treating results as regressions.

Already in place:

- Keep the existing per-route warm-up before k6 measurement: 10 sequential requests with 0.5 seconds between requests, or
  about 5 seconds per route. Expand it if routes, especially streaming routes, need more stable startup behavior.
- Keep the current max-rate throughput baseline from `internal/planning/library-benchmarking.md`.
- Keep hard CI gates disabled until the benchmark gate tuning in
  [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169) has a stable baseline.

Prerequisites for the first implementation PR:

- Define alternating route order in `benchmarks/bench.rb` as two deterministic passes over the same route list: first in
  `rails routes` order, then in reverse order in the same job. Record the pass order with the per-route artifacts before
  using route ordering as a noise-control signal.
- Record sample count, runner type, Ruby version, Node version, React version, and bundle mode in a `metadata.json`
  artifact and mirror the key fields in the `summary.txt` header.
- Preserve the existing `benchmarks/bench.rb` summary metrics (`RPS`, `p50`, `p90`, `p99`, and `max`) and extend Bencher
  BMF reporting to include `max_latency` alongside the existing `rps`, `p50_latency`, `p90_latency`, `p99_latency`, and
  `failed_pct` measures. Today `max` appears in `summary.txt` but not in the BMF output.

Follow-on enhancements:

- Add `p95` only when the k6 trend stats, summary table, artifacts, and Bencher reporting can be updated together.
- Require repeated or overlapping alerts before opening an issue or failing CI.

## Local Verification Before CI

Every benchmark PR should include:

- a local command that runs the benchmark subset
- expected output shape
- a short note explaining what changed in the measured surface
- proof that the benchmark can run without unrelated app servers or ports already running

If a benchmark requires generated assets, the command should build those assets explicitly so CI and local runs use the
same mode.

## Acceptance Criteria

- The OSS suite covers client-only rendering, traditional SSR, and at least one cache path.
- The Pro suite covers streaming SSR and RSC payload rendering where the Node Renderer is available. Streaming-specific
  TTFB/response-end thresholds are only introduced after those metrics are captured in artifacts and reporting.
- Results include enough metadata to compare runs meaningfully.
- CI behavior is advisory until noise controls are proven.
- Regression detection favors sustained movement over single-run spikes and uses the current `p50`, `p90`, `p99`, and
  `max` metrics until `p95` is added explicitly.
- Documentation tells contributors which benchmark to run for each rendering area.

## See Also

- `benchmarks/bench.rb`
- `benchmarks/k6.ts`
- `benchmarks/bench-node-renderer.rb`
- `.github/workflows/benchmark.yml`
- `internal/planning/library-benchmarking.md`
