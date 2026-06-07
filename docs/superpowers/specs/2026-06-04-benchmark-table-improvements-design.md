# Benchmark summary table improvements (#3601)

- **Status:** Implemented ([PR #3627](https://github.com/shakacode/react_on_rails/pull/3627))
- **Date:** 2026-06-04
- **Follows:** [#3586](https://github.com/shakacode/react_on_rails/issues/3586) — Consume Bencher reports as JSON for summary-table significance
- **Related:** [#3602](https://github.com/shakacode/react_on_rails/issues/3602) — Fix `PostsPage` Pro route (drives the Fail% decision)

## Background

After #3586 the Pro/Core benchmark summary table renders:

```markdown
| Benchmark                                | RPS     | p50(ms) | p90(ms) | Fail% | Status    |
| ---------------------------------------- | ------- | ------- | ------- | ----- | --------- |
| Pro Node Renderer: simple_eval (non-RSC) | 2895.81 | 3.13    | 3.99    | 0.0   | 200=86878 |
```

It bolds + tags 🔴/🟢 only the tracked cells that crossed a Bencher boundary. Each
`BencherReport::Boundary` already carries the `baseline`, but the table never shows
it. Issue #3601 asks for four improvements; all four are in scope for this work.

## Decisions

| Decision     | Choice                                                                          |
| ------------ | ------------------------------------------------------------------------------- |
| Scope        | All four issue items in one PR                                                  |
| Layout       | Baseline + delta **inline in the same cell** (no column doubling)               |
| Links        | **One perf link per benchmark name** (not per metric cell)                      |
| p90 baseline | Send `p90_latency` to Bencher **boundary-less**; value-only fallback            |
| Fail%        | **Drop the display column, keep the `failed_pct` threshold** (alert safety net) |

## Final rendered table

```markdown
| Benchmark                         | RPS                          | p50(ms)           | p90(ms) | Status    |
| --------------------------------- | ---------------------------- | ----------------- | ------- | --------- |
| [simple_eval (non-RSC)](perf_url) | 2895.81 ▲2.3% (2830.0)       | 3.13 ▼1.3% (3.17) | 3.99    | 200=86878 |
| [react_ssr (non-RSC)](perf_url)   | **2472.91** 🔴 8.4% (2700.0) | 3.65 ▲1.0% (3.61) | 4.70    | 200=74197 |
```

## Cell rendering rules (RPS, p50, p90)

| Case                                 | Render                                                                                                |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| nil value                            | `—`                                                                                                   |
| non-numeric rps (`FAILED`/`MISSING`) | plain text, no delta                                                                                  |
| numeric, **no baseline** in report   | value only (e.g. `3.99`) — the expected p90 case                                                      |
| numeric, baseline, not significant   | `value ▲N.N% (baseline)` — ▲ up / ▼ down; `%` = magnitude                                             |
| numeric, baseline, **significant**   | `**value** 🔴 N.N% (baseline)` (regression) / `🟢` (improvement) — emoji replaces arrow, value bolded |
| value == baseline exactly            | `value 0.0% (baseline)` — explicit exact/near-zero match, no misleading arrow                         |

- Delta `%` rounded to 1 decimal; baseline rounded to 2.
- Arrow/emoji marks the **direction of the raw value change** (▲ = value rose). For a
  significant move the 🔴/🟢 replaces the arrow; combined with the column's
  known direction (RPS higher-is-better, latency lower-is-better) it implies up/down.
- The **benchmark name** is the only linked cell → that benchmark's Bencher perf plot.
- Legend: `▲/▼ non-zero change vs baseline · 0.0% exact/near-zero match · 🔴 significant regression · 🟢 significant improvement (tracked measures) · (n) = baseline`.

## Code changes (all under `benchmarks/`)

1. **`lib/bmf_helpers.rb`** — `to_bmf` emits `p90_latency` (boundary-less: Bencher
   records history, never alerts). Drop the now-unused `failed_pct` from
   `display_rows`. Update the p90 "summary-only" comment (it now reaches Bencher).
2. **`lib/bencher_report.rb`** — leniently extract perf-URL primitives (project slug,
   branch + testbed UUIDs, per-benchmark + per-measure UUIDs, start/end time) and add
   `perf_url(benchmark_name)` that builds the URL defensively (returns `nil` if any
   primitive is missing → name renders unlinked). Strict regression/boundary parsing is
   untouched; URL fields follow the existing "informational → read leniently, never
   raise" rule. Expose the per-(name, measure) baseline for the renderer (via the
   existing `boundary`).
3. **`lib/benchmark_table.rb`** — `COLUMNS` drops Fail%, gives p90 a `p90_latency`
   measure key (baseline lookup only — never significant, no threshold). Name cell links
   via `perf_url`; metric cells render value + delta + `(baseline)` from
   `boundary(name, measure).baseline` and `significance(...)`. Update legend. Keep
   the existing Markdown escaping.
4. **`track_benchmarks.rb`** — `THRESHOLDS` **unchanged** (rps, p50_latency, failed_pct
   still alert; p90 not added). No display column for failed_pct.
5. **Specs / fixtures** — update `benchmark_table_spec`, `bencher_report_spec`
   (+ `fixtures/bencher_report_sample.json` gains a p90 measure and URL primitives),
   `bmf_collector_spec` (p90 in BMF, display-row shape), `report_table_integration_spec`,
   and the `track_benchmarks_spec` lockstep test → `failed_pct` is
   **tracked-but-not-displayed** (intentional; rps/p50 still require a highlightable column).
6. **`.github/workflows/benchmark.yml`** — no functional change; comment only if the
   p90/Fail% rationale needs noting.

## Risks / CI-only verification

- **Perf URL format** and whether the JSON report exposes the UUIDs/times can only be
  confirmed on the first benchmark CI run — hence the defensive `nil`→unlinked fallback,
  so a wrong/absent field never breaks the table.
- **p90 baseline** likely stays `nil` (boundary-less measure) → p90 shows value-only; if
  Bencher returns one, the delta appears automatically. Either way the table is correct.
- Sending `p90_latency` creates a new measure in the Bencher project (intended).

## Testing

- `bundle exec rspec benchmarks/spec` and `bundle exec rubocop benchmarks` locally — the
  parser/renderer/sidecar are fully unit-testable against fixtures.
- The live `bencher run` link/baseline behavior is validated on the PR's first benchmark
  CI run.
