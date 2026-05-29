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

Standing instructions while this plan is in effect:

- **Wait for history before tuning.** Do not tune thresholds before the full 30-run window exists; sparse history trains
  on noise rather than signal.
- **Fallback if the gate flips back.** If the hard gate has to return to warning mode, re-tune from the existing baseline
  window and overlap data first rather than starting over.
- **Baseline reset exception.** Start a fresh 30-run baseline window only after benchmark workflow or runner changes
  invalidate the old history.
- **Archive when done.** Once the hard gate has been restored and held for 30 or more qualifying runs without breaching
  the false-positive target, delete the entire `## Main Gate Re-Enablement Plan` section (this heading and every
  subsection through the end of the file, including the trailing Issue 3169 link) in a follow-up commit; the executed
  plan then lives only in git history.

### Baseline Dependency

The Bencher reporting baseline fix from [PR 3148](https://github.com/shakacode/react_on_rails/pull/3148) landed on
2026-04-23. Do not re-enable the hard gate until at least 30 successful `Benchmark Workflow` runs on `main` have built
fresh history. Count only completed `benchmark` jobs triggered after that merge; exclude pre-merge runs, branch runs,
reruns of any kind (manual workflow reruns or automatic GitHub retries), and docs-only pushes skipped by
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
- a separate main-branch step creates or updates a GitHub issue labeled `performance-regression` and links to the
  regression run
- operational Bencher failures already hard-fail via `Fail on non-regression Bencher error on main`, so only regression
  alerts are soft while the gate is in warning mode
- restoring the hard gate means changing the warning step to exit with `$BENCHER_EXIT_CODE` after the false-positive
  target is met, not removing `--err`

> **Note:** The values above are a snapshot of the workflow at the time of writing and capture only the tuning-relevant
> flags; operational flags such as `--quiet` and `--format html` are intentionally omitted because they do not affect
> threshold behavior. Verify against `.github/workflows/benchmark.yml` (`run_bencher` function) before tuning because the
> workflow is the source of truth.

### Tuning Sequence

1. Keep the gate in warning mode while gathering the new baseline.
2. Compare adjacent qualifying main runs by shared `(benchmark, measure)` alert pairs:
   - **Data source:** Use the Bencher HTML report in the workflow run summary. If browser access to Bencher is available,
     the history URL is `https://bencher.dev/perf/react-on-rails-t8a9ncxo`; otherwise use the overlap-comparison method
     tracked in [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169).
   - **Qualifying run:** A push that modifies at least one file that
     [`script/ci-changes-detector`](../../script/ci-changes-detector) does not classify as docs-only.
   - **Jaccard overlap formula:** For adjacent alert sets `A` and `B`, compute `|A intersect B| / |A union B|`. For
     example, two shared pairs across 10 total unique alert pairs gives `2 / 10 = 20%`.
   - **When to start:** Begin overlap analysis once at least 5 adjacent qualifying-run pairs exist (i.e., at least 6
     qualifying runs because each pair shares one run with its neighbor).
   - **Noise floor (`0.20`):** Overlap below this means runner noise is still dominating; keep collecting runs.
   - **Signal threshold (`0.40`):** Proceed to step 3 only after the full 30-run baseline window exists **and** overlap is
     at least `0.40` for 3 consecutive adjacent qualifying-run pairs. The gap between `0.20` and `0.40` avoids flip-flopping
     between noise and signal states; the thresholds were chosen empirically from the alert-overlap evidence in Issue 3169
     and should be revisited if the alert distribution changes significantly.
   - **Small-sample caveat:** If a comparison has fewer than 5 unique alert pairs, record it in Issue 3169 and keep
     collecting runs.

3. Prefer threshold changes that require stronger evidence before failure:
   - widen the Bencher boundary from `0.95` toward `0.99` using the boundary tuning cadence below
   - keep `--threshold-max-sample-size $MAX_SAMPLE` aligned with the available history; add a minimum-sample rule only
     if Bencher supports that flag for the configured threshold type
   - require manual tracking in Issue 3169 to see the same `(benchmark, measure)` pair alert on at least 2 consecutive
     runs before filing or failing (restated as Acceptance Criterion 2 below — the same gate, viewed from the tuning side)

   **Boundary tuning cadence.** Widen the boundary in fixed `0.01` increments, dwelling at each setting long enough to
   judge whether the widening is still reducing noise:
   1. **Dwell.** Collect 10 qualifying main runs at the current boundary value before any advance/lock decision. The
      initial 30-run baseline window (collected at `0.95`) counts as the dwell for `0.95`, so do not collect a separate
      10-run dwell there; the first advance/lock decision uses overlap from the most recent 5 adjacent pairs within that
      window. Do not re-collect a 30-run window at any widened boundary — each boundary past `0.95` gets the standard
      10-run dwell. Boundary changes alone never trigger a baseline reset (see the Baseline reset exception above).
   2. **Measure.** After the dwell, compute the mean Jaccard overlap across the most recent 5 adjacent qualifying-run
      pairs at the current boundary, using the overlap method from Tuning Sequence step 2 above.
   3. **Advance.** If mean overlap is below `0.40`, raise the boundary by `0.01` and return to step 1 of this cadence at
      the new value: noise is still dominating, so requiring a wider boundary should help.
   4. **Lock.** If mean overlap is at least `0.40`, stop widening and keep the current boundary; recurring alerts now
      dominate the set, and widening further risks masking real regressions. Proceed to the Acceptance Criteria.
   5. **Ceiling.** If the boundary reaches `0.99` and mean overlap is still below `0.40` after the dwell, do not widen
      further; escalate to step 4 (larger or dedicated runners). Noise that survives the widest boundary is a
      runner-environment problem, not a threshold problem.
   6. **Small-sample fallback.** If a dwell window yields fewer than 5 unique alert pairs (so Jaccard is undefined or
      unstable), extend that dwell by 5 more qualifying runs at the same boundary before deciding, mirroring the
      small-sample caveat in Tuning Sequence step 2. If 5 unique pairs still cannot be formed after the extension, keep
      collecting in 5-run increments until they can.

   Record each boundary value, its dwell run IDs, and the resulting overlap in
   [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169). End to end this is at most 5 boundary values
   (`0.95` through `0.99`); it locks earlier if overlap reaches `0.40` sooner.

   **Interaction with the false-positive target and real regressions during tuning:**
   - The 1-in-20 false-positive target (Acceptance Criteria 4 and 5) is evaluated only after the hard gate is restored, so
     it does not gate cadence advancement — the overlap criterion above does. Still, before locking a candidate boundary,
     sanity-check the noisy-alert rate at that setting: if overlap reads at least `0.40` but the noisy-alert rate is still
     far worse than the target (for example, more than 5 noisy alerts per 20 runs), a few chronic flakes are probably
     dominating the overlap rather than real recurring regressions, so keep widening (up to the `0.99` ceiling in step 5
     above) and record the exception in Issue 3169. If the boundary is already at `0.99` when this override applies, there
     is nowhere left to widen: record the exception in Issue 3169 and escalate to step 4 (larger or dedicated runners)
     rather than locking on chronically noisy alerts.
   - If a real regression is identified mid-cadence (manual recurrence check plus a matching performance-sensitive
     commit), exclude the affected runs — and the runs for the commit that reverts it, which is itself
     performance-sensitive — from the most-recent-5-pairs overlap computation, then continue the cadence. This is the
     same exclusion the false-positive accounting applies to intentional-perf-change commits (Acceptance Criterion 5).
   - Rollback at a locked boundary reuses Acceptance Criterion 5: if the restored hard gate later breaches the 1-in-20
     target, revert to warning mode and re-enter this cadence at the most recently locked boundary (starting a fresh
     10-run dwell at that boundary) rather than restarting the widening from `0.95`.

4. If shared-runner noise remains high, move benchmark jobs to larger GitHub-hosted runners or dedicated runners before
   restoring the hard gate.

### Acceptance Criteria

1. Before restoring the hard gate, verify it can detect real regressions: add a temporary controller delay to a benchmarked
   SSR route large enough to cause at least 20% degradation versus the current baseline median for that route, confirm an
   alert fires under the tuned settings, then revert the delay. The 20% magnitude reflects the project's stated detection
   goal (see "Why We Chose Max Rate" above) and the fact that GitHub-hosted runner noise under `BOUNDARY=0.95` with the
   t-test masks smaller deltas; recalibrate this floor downward if the gate later moves to dedicated runners or boundary
   widening reduces the noise floor. If no alert fires, re-tune before proceeding.
2. As a pre-condition for starting the 5-run clean-run count below, the tuned settings must require manual tracking in
   Issue 3169 to show the same `(benchmark, measure)` pair alerting on at least 2 consecutive runs before filing or
   failing; a single noisy run does not trigger the gate. This is a manual gate: Bencher still alerts on the first run,
   and the requirement is that a reviewer confirms recurrence in Issue 3169 before acting on it. (This is the same gate
   stated in Tuning Sequence step 3; restated here because it is also a pre-condition for the 5-run clean-run count.)
3. Only after steps 1 and 2 pass, at least 5 consecutive qualifying main `Benchmark Workflow` runs complete with no
   Bencher regression alert; that means `BENCHER_HAS_ALERT` stays `0` with the current code (a value of `1` is what
   triggers the warning step and the regression-issue update). A run qualifies when the
   triggering push modifies at least one file that [`script/ci-changes-detector`](../../script/ci-changes-detector) does
   not classify as docs-only. Track the running count in [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169).
4. Restore the hard gate once criteria 1-3 pass; those checks establish the project false-positive target of no more than
   1 noisy failure in 20 successful main `Benchmark Workflow` runs whose triggering commits do not intentionally change
   benchmark performance. Criterion 5 below defines who tracks this rate after re-enabling and the review cadence that
   triggers reverting to warning mode if the target is breached.
5. After re-enabling, record each main gate failure in Issue 3169 with a noisy/real classification. Treat an alert as noisy
   when it does not recur for the same `(benchmark, measure)` pair in the next qualifying run and has no matching
   performance-sensitive code change. The 1-in-20 window is rolling: count the most recent 20 such qualifying runs (the
   same cohort defined in criterion 4), and exclude intentional-perf-change commits from both the numerator (noisy
   failures) and the denominator (the 20-run total) rather than counting them as either real or noisy.
   Review the running rate after every 5 gate-triggering runs or at least monthly, whichever comes first. If the gate later
   exceeds the 1-in-20 noisy-failure rate on main, revert it to warning mode and re-tune thresholds from the existing
   baseline window and overlap data before trying to re-enable it again.

See [Issue 3169](https://github.com/shakacode/react_on_rails/issues/3169) for the tracking discussion and historical
alert-overlap evidence. The boundary tuning cadence in Tuning Sequence step 3 was specified in response to
[Issue 3260](https://github.com/shakacode/react_on_rails/issues/3260).
