# Library Benchmarking Strategy

## Current Approach

We use **max rate benchmarking** - each route is tested at maximum throughput to measure its capacity.

### Configuration

- `RATE=max` - Tests maximum throughput
- `CONNECTIONS=10` - Concurrent connections
- `DURATION=30s` - Test duration per route

## Trade-offs: Max Rate vs Fixed Rate

### Max Rate (Current)

**Pros:**

- Measures actual throughput capacity
- Self-adjusting - no need to maintain per-route rate configs
- Identifies bottlenecks and ceilings

**Cons:**

- Results vary with CI runner performance
- Harder to compare across commits when capacity changes significantly
- Noise from shared CI infrastructure

### Fixed Rate

**Pros:**

- Consistent baseline across runs
- Latency comparisons are meaningful
- Detects regressions at a specific load level

**Cons:**

- Must be set below the slowest route's capacity
- If route capacity changes, historical data becomes incomparable
- Requires maintaining rate configuration per route

## Why We Chose Max Rate

Different routes have vastly different capacities:

- `/empty` - ~1500 RPS
- SSR routes - ~50-200 RPS depending on component complexity

A fixed rate low enough for all routes would under-utilize fast routes. A per-route fixed rate config would be painful to maintain and would break comparisons when capacity changes.

For library benchmarking in CI, we accept some noise and focus on detecting significant regressions (>15-20%).

## Future Considerations

Options to improve accuracy if needed:

1. **Multiple samples** - Run each benchmark 2-3 times, average results, flag high variance
2. **Adaptive rate** - Quick max-rate probe, then benchmark at 70% capacity
3. **Per-route fixed rates** - Maintain target RPS config (high maintenance burden)
4. **Dedicated benchmark runners** - Reduce CI noise with consistent hardware

## Main Gate Re-Enablement Plan

The benchmark workflow currently treats main-regression alerts as warnings because single-run Bencher alerts on
GitHub-hosted runners have been dominated by environmental noise. The goal is to make a fired alert much more likely
to represent a real regression before restoring a hard gate, where CI fails the job instead of posting a warning.

### Baseline Dependency

The Bencher reporting baseline fix from [PR 3148](https://github.com/shakacode/react_on_rails/pull/3148) landed on
2026-04-23. Do not re-enable the hard gate until at least 30 post-merge main runs have built fresh history. Runs count
whether or not they fire alerts because the goal is history volume, not a clean streak. Threshold tuning against missing
or sparse baseline history will mostly tune the noise.

### Tuning Sequence

1. Keep the gate in warning mode while gathering the new baseline.
2. Compare adjacent main runs by shared `(benchmark, measure)` alert pairs using the Bencher dashboard or the
   overlap-comparison method tracked in [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169). A
   near-disjoint alert set means runner noise is still dominating.
3. Prefer threshold changes that require stronger evidence before failure:
   - widen the Bencher boundary from `0.95` toward `0.99`
   - add a `--threshold-min-sample-size` once each `(branch, benchmark, measure)` pair has enough history
   - require the same `(benchmark, measure)` pair to alert across consecutive runs before filing or failing
4. If shared-runner noise remains high, move benchmark jobs to larger GitHub-hosted runners or dedicated runners before
   restoring the hard gate.

### Acceptance Criteria

- At least 5 consecutive non-docs main pushes, meaning pushes that modify files outside `docs/`, `*.md`, and
  `internal/`, pass the warning-mode check with the current code. Track the running count in
  [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169).
- Bencher is configured to require the same `(benchmark, measure)` pair to alert on consecutive runs before filing or
  failing; a single noisy run does not trigger the gate.
- A deliberately introduced local regression still triggers an alert under the tuned settings. The developer re-enabling
  the gate should add a temporary controller delay to a benchmarked route, verify an alert fires, and then revert the
  delay.
- The hard gate is restored only after the tuned settings meet the project false-positive target: no more than 1 noisy
  failure in 20 unchanged-performance runs.

See [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169) for the tracking discussion and historical
alert-overlap evidence.
