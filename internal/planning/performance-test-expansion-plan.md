# Performance Test Expansion Plan

## Purpose

Plan expanded performance coverage for [Issue 2169](https://github.com/shakacode/react_on_rails/issues/2169) while
explicitly mitigating CI runtime noise.

The goal is to compare React on Rails rendering operations against their own historical baselines, not to produce broad
marketing benchmarks from noisy shared runners.

## Operations Matrix

Start with a small, representative matrix before adding more routes:

| Area                  | Operation                                 | Primary metric              | Notes                                       |
| --------------------- | ----------------------------------------- | --------------------------- | ------------------------------------------- |
| Client rendering      | `react_component` with `prerender: false` | mount and hydration timing  | Measures browser-side startup overhead      |
| Traditional SSR       | `react_component` with `prerender: true`  | server render duration      | Covers ExecJS and Node Renderer paths       |
| Hash SSR              | `react_component_hash`                    | render duration and payload | Covers render-functions returning objects   |
| Streaming SSR         | `stream_react_component`                  | TTFB, response end, LCP     | Requires Suspense-friendly examples         |
| RSC payload rendering | `rsc_payload_react_component`             | payload bytes and duration  | Pro-only path, benchmark separately         |
| Fragment caching      | cached component hit and miss             | hit latency and miss cost   | Separates cache effectiveness from SSR cost |

## First PR Scope

The first implementation PR should add only one or two routes per category and should reuse existing dummy app examples
where possible. Avoid building a large benchmark suite until the noise profile is understood.

Recommended first slice:

1. Client-only component route
2. Traditional SSR route with the same component and props
3. Streaming route with a small Suspense boundary
4. Cached SSR route with explicit hit and miss measurements

## Noise Controls

Use these controls before treating results as regressions:

- Warm each route before measuring.
- Run alternating route order instead of grouped route order so cache and process state are less biased.
- Record sample count, runner type, Ruby version, Node version, React version, and bundle mode with every result.
- Track median and p95, not only averages.
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

- The expanded suite covers client-only rendering, traditional SSR, streaming SSR, and at least one cache path.
- Results include enough metadata to compare runs meaningfully.
- CI behavior is advisory until noise controls are proven.
- Regression detection favors sustained movement over single-run spikes.
- Documentation tells contributors which benchmark to run for each rendering area.
