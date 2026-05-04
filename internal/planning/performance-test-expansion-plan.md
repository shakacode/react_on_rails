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

| Area                  | Operation                                 | Primary metric              | Notes                                                                                    |
| --------------------- | ----------------------------------------- | --------------------------- | ---------------------------------------------------------------------------------------- |
| Client rendering      | `react_component` with `prerender: false` | route RPS and HTTP latency  | Uses existing HTTP benchmark output; browser mount timing is follow-up instrumentation   |
| Traditional SSR       | `react_component` with `prerender: true`  | server render duration      | Covers ExecJS and Node Renderer paths                                                    |
| Hash SSR              | `react_component_hash`                    | render duration and payload | Covers render-functions returning objects                                                |
| Streaming SSR         | `stream_react_component`                  | TTFB, response end, LCP     | Pro-only path; requires Node Renderer and Suspense-friendly examples                     |
| RSC payload rendering | `rsc_payload_react_component`             | payload bytes and duration  | Pro-only path; needs static route or explicit target because required params are skipped |
| Fragment caching      | cached component hit and miss             | hit latency and miss cost   | Separates cache effectiveness from SSR cost                                              |

## First PR Scope

The first implementation PR should add only one or two routes per category and should reuse existing dummy app examples
where possible. Avoid building a large benchmark suite until the noise profile is understood.

Recommended OSS first slice:

1. Client-only component route
2. Traditional SSR route with the same component and props
3. Cached SSR route with explicit hit and miss measurements

Recommended Pro slice, tracked separately from the OSS implementation PR:

1. Streaming route with a small Suspense boundary
2. RSC payload route with representative payload size measurements. Use a static benchmark route with no required URL
   params, teach `benchmarks/bench.rb` how to provide a default component name, or run `benchmarks/k6.ts` with an explicit
   `TARGET_URL`; automatic route discovery currently skips required-parameter routes such as `/rsc_payload/:component_name`.

## Noise Controls

Use these controls before treating results as regressions:

- Warm each route before measuring.
- Implement alternating route order in `benchmarks/bench.rb`; routes currently run in `rails routes` order, so this is a
  prerequisite before using route ordering as a noise-control signal.
- Record sample count, runner type, Ruby version, Node version, React version, and bundle mode with every result.
- Keep the current max-rate throughput baseline from `internal/planning/library-benchmarking.md`.
- Preserve the existing `benchmarks/bench.rb` summary metrics (`RPS`, `p50`, `p90`, `p99`, and `max`) and make sure CI
  summaries, artifacts, and Bencher reporting surface those values consistently. The current runner intentionally uses
  `p90` and `p99` instead of `p95`; adding `p95` should update the k6 trend stats, summary table, artifacts, and Bencher
  reporting together.
- Require repeated or overlapping alerts before opening an issue or failing CI.
- Keep hard CI gates disabled until the benchmark gate tuning in
  [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169) has a stable baseline.

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
- Regression detection favors sustained movement over single-run spikes.
- Documentation tells contributors which benchmark to run for each rendering area.

## See Also

- `benchmarks/bench.rb`
- `benchmarks/k6.ts`
- `benchmarks/bench-node-renderer.rb`
- `.github/workflows/benchmark.yml`
- `internal/planning/library-benchmarking.md`
