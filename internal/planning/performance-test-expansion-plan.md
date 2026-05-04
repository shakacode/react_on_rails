# Performance Test Expansion Plan

## Purpose

Plan expanded performance coverage for [Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169) while
explicitly mitigating CI runtime noise.

The goal is to compare React on Rails rendering operations against their own historical baselines, not to produce broad
marketing benchmarks from noisy shared runners.

This plan extends the existing benchmark infrastructure in `benchmarks/bench.rb`, `benchmarks/k6.ts`,
`benchmarks/bench-node-renderer.rb`, and `.github/workflows/benchmark.yml`; it should stay aligned with the max-rate
strategy in `internal/planning/library-benchmarking.md`. Pro Node Renderer paths should build on the existing Vegeta
HTTP/2 Cleartext benchmark rather than duplicating that transport setup in k6.

## Operations Matrix

Start with a small, representative matrix before adding more routes:

| Area                  | Operation                                 | Primary metric          | Notes                                                                                                  |
| --------------------- | ----------------------------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------ |
| Client rendering      | `react_component` with `prerender: false` | RPS, p50, p90, p99, max | Uses existing HTTP benchmark output; browser mount timing is follow-up instrumentation                 |
| Traditional SSR       | `react_component` with `prerender: true`  | RPS, p50, p90, p99, max | Covers ExecJS and Node Renderer paths; server render duration requires separate instrumentation        |
| Hash SSR              | `react_component_hash`                    | RPS, p50, p90, p99, max | Covers render-functions returning objects; payload-size capture requires tooling extension             |
| Streaming SSR         | `stream_react_component`                  | TTFB, response end      | Pro-only path; LCP requires separate browser instrumentation such as Playwright or Lighthouse          |
| RSC payload rendering | `rsc_payload_react_component`             | RPS, p50, p90, p99, max | Pro-only path; needs static route or explicit target, and payload-size capture needs tooling extension |
| Fragment caching      | cached component hit and miss             | hit latency, miss cost  | Separates cache effectiveness from SSR cost                                                            |

## First PR Scope

The first implementation PR should add only one or two routes per category and should reuse existing dummy app examples
where possible. Avoid building a large benchmark suite until the noise profile is understood.

Recommended OSS first slice for [Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169):

1. Client-only component route
2. Traditional SSR route with the same component and props
3. Cached SSR route with explicit hit and miss measurements

Hash SSR is deferred to a follow-on PR after the initial OSS noise profile is understood.

Recommended Pro slice, tracked separately from the OSS implementation PR under
[Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169):

1. Streaming route with a small Suspense boundary
2. RSC payload route with representative payload size measurements. Use a static benchmark route with no required URL
   params, teach `benchmarks/bench.rb` how to provide a default component name, or run `benchmarks/k6.ts` with an explicit
   `TARGET_URL`; automatic route discovery currently skips required-parameter routes such as `/rsc_payload/:component_name`.

Use `benchmarks/bench.rb`/`benchmarks/k6.ts` for Rails HTTP routes such as streaming SSR. Use
`benchmarks/bench-node-renderer.rb` for direct Pro Node Renderer transport coverage unless that script is extended to cover
full Rails streaming behavior.

## Noise Controls

Use these controls before treating results as regressions.

Already in place:

- Keep the existing per-route warm-up before k6 measurement and expand it if routes need more stable startup behavior.
- Keep the current max-rate throughput baseline from `internal/planning/library-benchmarking.md`.
- Keep hard CI gates disabled until the benchmark gate tuning in
  [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169) has a stable baseline.

To implement as part of the benchmark expansion:

- Add alternating route order in `benchmarks/bench.rb`; routes currently run in `rails routes` order, so this is a
  prerequisite before using route ordering as a noise-control signal.
- Record sample count, runner type, Ruby version, Node version, React version, and bundle mode with every result.
- Preserve the existing `benchmarks/bench.rb` summary metrics (`RPS`, `p50`, `p90`, `p99`, and `max`) and make sure CI
  summaries, artifacts, and Bencher reporting surface those values consistently. The current runner intentionally uses
  `p90` and `p99` instead of `p95`; adding `p95` should update the k6 trend stats, summary table, artifacts, and Bencher
  reporting together.
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
- The Pro suite covers streaming SSR and RSC payload rendering where the Node Renderer is available.
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
