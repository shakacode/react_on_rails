# PPR settle-criterion experiments (evidence code for #4852 / #4885)

The 15 standalone scripts in this directory are the experiments behind the
three PPR evidence documents cited by the plan of record
(`internal/planning/ppr-plan.md` → "Evidence base"):

| Experiments | Findings document |
| ----------- | ----------------- |
| 01–08 | [`internal/analysis/ppr-settle-criterion-findings.md`](../../ppr-settle-criterion-findings.md) (Appendix A summarizes them) |
| 09–12 | [`internal/analysis/ppr-settle-by-example.md`](../../ppr-settle-by-example.md) ("Source experiments: experiments 9–12") |
| 13–15 | [`internal/analysis/ppr-rsc-payload-by-example.md`](../../ppr-rsc-payload-by-example.md) ("Real output from experiment 15") |

**Experiment 8 is load-bearing for plan decision D2** (v1 settle criterion):
it is the proof that real I/O a bare timing-based abort does not track is
silently demoted to a fallback hole — the reason v1 ships the fixed-timeout
abort *with a documented explicit-await contract* instead of claiming the
timeout alone is safe.

## Provenance

- Written and run 2026-08-08 for issue #4852 (PR #4855) in the
  `4852-ppr-define-settle-criterion-for-prerender-abort` worktree, which was
  deleted after that PR merged — only the findings documents landed on
  `main`, not the scripts.
- Recovered 2026-08-31 from the #4852 research-session transcript by
  replaying the file-write operations (each file was written exactly once
  and never edited). Fidelity was cross-checked against the stack-trace
  line/column numbers captured in the original run logs, and all 15 scripts
  were re-run and reproduce the documented results (Node v22.12.0,
  react/react-dom 19.2.8 — experiment 8 reproduces
  "✗ PREMATURE ABORT" untracked vs "✓ Deep fallback" tracked).
- The scripts are committed **byte-faithful to what actually ran**; that is
  why this directory is excluded from ESLint/Prettier (see
  `eslint.config.ts` `globalIgnores` and `.prettierignore`).

## Running

```bash
cd internal/analysis/experiments/settle-criterion
npm install   # pins react/react-dom 19.2.8 — the versions the findings were measured on
node 08-untracked-io.mjs   # or any other NN-*.mjs
```

## The experiments

| # | Script | Question it answers |
| - | ------ | ------------------- |
| 1 | `01-fallback-reachability.mjs` | Does aborting `prerender` emit the fallback for a pending boundary? |
| 2 | `02-deep-nested-async.mjs` | Do inner boundaries revealed by a resolving outer component get reached before abort? |
| 3 | `03-async-client-components.mjs` | How do mixed sync/async children settle inside one boundary? |
| 4 | `04-cache-signal-simulation.mjs` | Does Next.js-style CacheSignal tracking abort at the right moment? |
| 5 | `05-setimmediate-vs-settle.mjs` | Is a single `setImmediate` enough to catch cascading async work? |
| 6 | `06-microtask-gap.mjs` | Does microtask-resolved work (pre-filled cache) beat the abort? |
| 7 | `07-without-tracking.mjs` | What breaks with a bare `setImmediate` abort and no tracking? |
| 8 | `08-untracked-io.mjs` | **The critical one:** untracked real I/O (cross-process cache read) is silently missed by timing-based aborts |
| 9 | `09-untracked-microtask.mjs` | Untracked async at different speeds — which durations survive? |
| 10 | `10-real-world-patterns.mjs` | Realistic component patterns, tracked vs untracked |
| 11 | `11-suspense-nesting.mjs` | Which Suspense fallback wins for nested pending boundaries? |
| 12 | `12-fallback-suspend.mjs` | Can a fallback itself suspend, and what happens then? |
| 13 | `13-flight-payload-basics.mjs` | What prelude/postponed output looks like for sync/async/suspended trees |
| 14 | `14-prerender-vs-stream.mjs` | `prerender()` vs `renderToPipeableStream()` output differences |
| 15 | `15-postponed-resume.mjs` | The complete prerender → postpone → resume lifecycle |
