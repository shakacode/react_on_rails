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
fresh 30-run baseline window only after benchmark workflow or runner changes invalidate the old history. Do not tune
thresholds before the full 30-run window exists because sparse history trains on noise rather than signal.

### Baseline Dependency

The Bencher reporting baseline fix from [PR 3148](https://github.com/shakacode/react_on_rails/pull/3148) landed on
2026-04-23. Do not re-enable the hard gate until at least 30 successful `Benchmark Workflow` runs on `main` have built
fresh history. Count only completed `benchmark` jobs triggered after that merge; exclude pre-merge runs, branch runs,
reruns, and docs-only pushes skipped by
[`script/ci-changes-detector`](../../script/ci-changes-detector). Record each counted run ID and timestamp in
[Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169).

### Current Bencher Configuration

The current Bencher invocation lives in `.github/workflows/benchmark.yml` inside the `run_bencher` function:

- `BOUNDARY=0.95`
- `MAX_SAMPLE=64`
- `--err` causes Bencher regression alerts to return a non-zero exit code
- each threshold uses `--threshold-test t_test` and `--threshold-max-sample-size $MAX_SAMPLE`
- `rps` uses `--threshold-lower-boundary $BOUNDARY` and `--threshold-upper-boundary _` (which disables the upper bound)
  because higher RPS is better; a regression is a drop below the lower bound
- `p50_latency`, `p90_latency`, `p99_latency`, and `failed_pct` use `--threshold-lower-boundary _` (which disables the
  lower bound) and `--threshold-upper-boundary $BOUNDARY` because lower latency and failure rate are better; a regression
  is a rise above the upper bound
- on main, `run_bencher` captures Bencher's non-zero exit as `BENCHER_EXIT_CODE`; the
  `Warn if Bencher detected regression on main` step emits `::warning::` for regression alerts instead of exiting
- operational Bencher failures already hard-fail via `Fail on non-regression Bencher error on main`, so only regression
  alerts are soft while the gate is in warning mode
- restoring the hard gate means changing the warning step to exit with `$BENCHER_EXIT_CODE` after the false-positive
  target is met, not removing `--err`

> **Note:** The values above are a snapshot of the workflow at the time of writing. Verify against
> `.github/workflows/benchmark.yml` (`run_bencher` function) before tuning because the workflow is the source of truth.

### Tuning Sequence

1. Keep the gate in warning mode while gathering the new baseline.
2. Compare adjacent main runs by shared `(benchmark, measure)` alert pairs using the Bencher dashboard or the
   overlap-comparison method tracked in [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169). For two
   adjacent alert sets `A` and `B`, use Jaccard overlap: `|A intersect B| / |A union B|`. For example, two shared pairs
   across 10 total unique alert pairs gives `2 / 10 = 20%`. Overlap below `0.20` means runner noise is still dominating;
   proceed to step 3 only after overlap is at least `0.40` for 3 consecutive adjacent-run pairs. The gap between `0.20`
   and `0.40` avoids flip-flopping between noise and signal states. If a comparison has fewer than 5 unique alert pairs,
   record the small-sample caveat in Issue 3169 and keep collecting runs.
3. Prefer threshold changes that require stronger evidence before failure:
   - widen the Bencher boundary from `0.95` toward `0.99`
   - keep `--threshold-max-sample-size $MAX_SAMPLE` aligned with the available history; add a minimum-sample rule only
     if Bencher supports that flag for the configured threshold type
   - require manual tracking in Issue 3169 to see the same `(benchmark, measure)` pair alert on at least 2 consecutive
     runs before filing or failing
     If overlap remains below `0.40` after boundary widening, collect 5 more qualifying runs and re-evaluate from step 2
     before escalating to step 4.
4. If shared-runner noise remains high, move benchmark jobs to larger GitHub-hosted runners or dedicated runners before
   restoring the hard gate.

### Acceptance Criteria

- Before restoring the hard gate, verify it can detect real regressions: add a temporary controller delay to a benchmarked
  route, confirm an alert fires under the tuned settings, then revert the delay. If no alert fires, re-tune before
  proceeding.
- At least 5 consecutive qualifying main `Benchmark Workflow` runs complete with no Bencher regression alert after the
  deliberate-regression check above passes; that means `BENCHER_HAS_ALERT` stays `0` with the current code. A run
  qualifies when the triggering push modifies at least one file that
  [`script/ci-changes-detector`](../../script/ci-changes-detector) does not classify as docs-only. Track the running
  count in [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169).
- Manual tracking in Issue 3169 must show the same `(benchmark, measure)` pair alerting on at least 2 consecutive runs
  before filing or failing; a single noisy run does not trigger the gate.
- The hard gate is restored only after the tuned settings meet the project false-positive target: no more than 1 noisy
  failure in 20 successful main `Benchmark Workflow` runs whose triggering commits do not intentionally change benchmark
  performance. Treat an alert as noisy when it does not recur for the same `(benchmark, measure)` pair in the next
  qualifying run and has no matching performance-sensitive code change. If the gate later exceeds this rate on main,
  revert it to warning mode and re-tune thresholds from the existing baseline window and overlap data before trying to
  re-enable it again.

See [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169) for the tracking discussion and historical
alert-overlap evidence.
