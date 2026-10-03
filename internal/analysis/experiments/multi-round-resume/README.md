# Multi-round Fizz prerender/resume experiments (evidence code for #4770 / #4885)

The scripts in this directory establish, on **stable** React 19.2.8, what the
plan of record (`internal/planning/ppr-plan.md` §1.3) cites as the upstream
bound on chaining prerender/resume:

- **Chaining works** — `prerender` → `resumeAndPrerender` → … → `resume`
  succeeds *if* each round completes all prior holes and new pauses appear
  only in newly rendered subtrees ("progressive deepening").
- **The hard limit** — a boundary carried over in postponed state that is
  still pending when the next round aborts throws
  `"It should not be possible to postpone at the root"`
  (`replaySuspenseBoundary` creates replayed boundaries with
  `tracked: null`, and `trackPostponedBoundary` throws). This is the
  "re-postponing a carried-over pending boundary crashes" bound in the plan —
  a limit on multi-round chaining, **not** on v1's single prerender→resume
  cycle.
- **Workaround (verified)** — postponed-state surgery: prune the not-ready
  hole's ReplayNode before resume, graft it back afterwards, preserving the
  original `rootSegmentID` so shell `B:` ids still match.
- **Parallel fan-out (verified)** — split one postponed state into per-hole
  states with disjoint `nextSegmentId` ranges, resume concurrently,
  concatenate preludes in completion order; no duplicate `B:`/`S:` ids.

## Provenance

- Written and run 2026-08-04 to 2026-08-07 during the scroll-priority/PPR
  plan-validity research (issue #4770), in a scratch project outside the
  repository; committed here 2026-08-31 so the plan's §1.3 citation has
  in-repo evidence code. All scripts re-run on Node v22.12.0 with
  react/react-dom 19.2.8 before committing: 8 behave as documented and
  `multi-resume-test.jsx` **crashes by design** — it is the repro for the
  hard limit above.
- Committed byte-faithful to what ran; the directory is excluded from
  ESLint/Prettier (see `eslint.config.ts` `globalIgnores` and
  `.prettierignore`).

## Running

```bash
cd internal/analysis/experiments/multi-round-resume
npm install
npx tsx progressive-test.jsx     # multi-round chaining that works
npx tsx multi-resume-test.jsx    # the naive approach — crashes by design
```

## The experiments

| Script | What it shows |
| ------ | ------------- |
| `progressive-test.jsx` | Progressive-deepening multi-round chain — each round completes all previous holes; works |
| `multi-resume-test.jsx` | The naive chain (round 2 aborts with a carried-over hole still pending) — **crashes by design** with the root-postpone error |
| `carryover-test.jsx` | Postponed-state surgery (prune/graft) that keeps an unready hole across rounds without crashing |
| `parallel-test.jsx` | Parallel fan-out: two holes resumed independently off the same base state, preludes concatenated |
