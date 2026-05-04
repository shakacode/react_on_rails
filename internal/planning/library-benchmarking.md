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
If the hard gate has to return to warning mode, re-tune from the existing baseline window and overlap data first; start a
fresh 30-run baseline window only after benchmark workflow or runner changes invalidate the old history.

### Baseline Dependency

The Bencher reporting baseline fix from [PR 3148](https://github.com/shakacode/react_on_rails/pull/3148) landed on
2026-04-23. Do not re-enable the hard gate until at least 30 successful `Benchmark Workflow` runs on `main` have built
fresh history. Count only completed `benchmark` jobs triggered after that merge; exclude pre-merge runs, branch runs,
reruns, and docs-only pushes skipped by `script/ci-changes-detector`. Record each counted run ID and timestamp in
[Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169). Threshold tuning against missing or sparse
baseline history will mostly tune the noise.

### Current Bencher Configuration

The current Bencher invocation lives in `.github/workflows/benchmark.yml` inside the `run_bencher` function:

- `BOUNDARY=0.95`
- `MAX_SAMPLE=64`
- `--err` causes Bencher regression alerts to return a non-zero exit code
- each threshold uses `--threshold-test t_test` and `--threshold-max-sample-size $MAX_SAMPLE`
- `rps` uses `--threshold-lower-boundary $BOUNDARY`
- `p50_latency`, `p90_latency`, `p99_latency`, and `failed_pct` use `--threshold-upper-boundary $BOUNDARY`
- regression alerts currently warn on main in the `Warn if Bencher detected regression on main` step

### Tuning Sequence

1. Keep the gate in warning mode while gathering the new baseline.
2. Compare adjacent main runs by shared `(benchmark, measure)` alert pairs using the Bencher dashboard or the
   overlap-comparison method tracked in [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169). For two
   adjacent alert sets `A` and `B`, use Jaccard overlap: `|A intersect B| / |A union B|`. For example, two shared pairs
   across 10 total unique alert pairs gives `2 / 10 = 20%`. Overlap below `0.20` means runner noise is still dominating.
3. Prefer threshold changes that require stronger evidence before failure:
   - widen the Bencher boundary from `0.95` toward `0.99`
   - keep `--threshold-max-sample-size $MAX_SAMPLE` aligned with the available history; add a minimum-sample rule only
     if Bencher supports that flag for the configured threshold type
   - require external tracking to see the same `(benchmark, measure)` pair alert on at least 2 consecutive runs before
     filing or failing
4. If shared-runner noise remains high, move benchmark jobs to larger GitHub-hosted runners or dedicated runners before
   restoring the hard gate.

### Acceptance Criteria

- At least 5 consecutive qualifying main `Benchmark Workflow` runs pass the warning-mode check with the current code.
  A run qualifies when the triggering push modifies at least one file that `script/ci-changes-detector` does not classify
  as docs-only. Track the running count in [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169).
- External tracking requires the same `(benchmark, measure)` pair to alert on at least 2 consecutive runs before filing or
  failing; a single noisy run does not trigger the gate.
- A deliberately introduced local regression still triggers an alert under the tuned settings. The developer re-enabling
  the gate should add a temporary controller delay to a benchmarked route, verify an alert fires, and then revert the
  delay.
- The hard gate is restored only after the tuned settings meet the project false-positive target: no more than 1 noisy
  failure in 20 successful main `Benchmark Workflow` runs whose triggering commits do not intentionally change benchmark
  performance. Treat an alert as noisy when it does not recur for the same `(benchmark, measure)` pair in the next
  qualifying run and has no matching performance-sensitive code change. If the gate later exceeds this rate on main,
  revert it to warning mode and re-tune thresholds before trying to re-enable it again.

See [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169) for the tracking discussion and historical
alert-overlap evidence.
