---
name: run-fleet-validation
description: Generate and coordinate the complete React on Rails release fleet lifecycle from internal/contributor-info/demo-fleet.yml. Use when a maintainer wants to validate the latest RC or beta, split fleet work across machines or agent sessions, inspect fleet progress, or run fail-closed release closeout from a durable result ledger.
---

# Run Fleet Validation

Generate the prompt pack from the manifest instead of copying repository lists into ad hoc prompts.

## Generate the lanes

From the React on Rails repository root, run:

```bash
ruby .agents/skills/run-fleet-validation/scripts/generate_prompts.rb \
  --machines local,m1 \
  --prompts 6 \
  --output-dir tmp/fleet-validation-prompts
```

Keep the default release selector, `latest RC or beta`, for a new validation run. Pass
`--release vX.Y.Z.rc.N` only for a rerun that must stay pinned to an older candidate.

The generator assigns only `tier: hard_gate` repositories to mutable maker prompts, adds the
monorepo generator/install gate required by `internal/contributor-info/rc-testing-plan.md`, and
balances weighted lanes across the named machines. The same pack also inventories every
`soft_track` repository as report-only and generates:

- `LIFECYCLE.md` — ordered snapshot-through-closeout phases and required release-path coverage;
- `PREFLIGHT.md` — the release-wide CI/artifact/generator and machine-capability barrier;
- `REPORT-ONLY.md` — the complete non-mutating soft-track pass;
- `CLOSEOUT.md` — independent audit, authority/freeze reconciliation, merge, reachability, tree parity, and tracker closeout;
- `result-ledger.json` and `result-ledger.schema.json` — the durable public-safe evidence contract.

Every replacement candidate needs a freshly generated pack and ID; pass `--pack-id ID` only when
regenerating files for the same exact candidate run.

## Launch and coordinate

1. Read `tmp/fleet-validation-prompts/INDEX.md` and start prompt 1 in snapshot/read-only mode.
   It publishes the exact candidate/RSC snapshot and generator-matrix evidence without starting its
   assigned app mutation.
2. Run `PREFLIGHT.md` against that snapshot, then start the remaining prompt coordinators.
   No app mutation worker may start before the
   pack ledger has `APP_WORK_ALLOWED`, backed by terminal-green exact-commit CI, artifacts, and the
   standard/Pro/Pro+RSC generator matrix, or an explicit policy-allowed public-safe waiver.
3. Run `REPORT-ONLY.md` so every soft track receives a disposition without a bump or merge.
4. Each prompt is a separate top-level coordinator task and must use its bounded subagents as
   written. Do not launch the six prompts as children of one shared four-slot agent tree.
5. Keep each lane in a separate checkout or worktree. Do not share mutable app checkouts between
   lanes.
6. Let lane coordinators create or update bump PRs and post idempotent evidence comments. Merge
   remains a generated closeout task and requires explicit authority plus a fresh mode/freeze read.
7. Require an authoritative coordination claim for every mutable app target before its execution
   subagent starts. A status read is not a lock. A refused claim or unknown claim outcome is
   non-passing and must not produce a competing worktree or branch. Reuse live candidate ownership
   first; generated fallback claim targets are only for genuinely fresh lanes and are stable by
   resolved candidate plus repository so separately generated packs cannot race.
8. Treat the release tracking issue plus its newest candidate-specific comments as the public
   source of truth. The issue body can describe an earlier candidate in the same release cycle;
   do not mistake that for the current candidate when a newer explicit RC section exists. A hard
   gate remains pending until it has exact install, build, test, smoke, and required-CI evidence,
   or an explicit waiver allowed by the RC plan.
9. Generate a fresh pack for every replacement candidate, even when the manifest is unchanged.
   Never reuse old prompt files or their snapshot marker for a new RC/beta. Within one exact
   candidate run, re-run only affected lanes and preserve that pack ID.

## Report status

When asked what remains, inspect the current release-gate tracking issue and linked PRs before
reporting. Classify every hard gate as `passed`, `blocked`, `pending`, or `unknown`:

- `blocked`: a confirmed candidate regression or non-waivable failed gate
- `pending`: work or required evidence is explicitly incomplete
- `unknown`: evidence cannot be reached or is stale
- `passed`: all required evidence is current for the resolved candidate

Never infer a pass from an open PR or a green subset of checks. Keep private HiChee details out of
public output; report only the high-level verdict, tester, date, and public issue link when one
exists.

## Validate and render closeout

The independent checker validates the exact ledger and renders the append-only tracker matrix from
that same file:

```bash
ruby .agents/skills/run-fleet-validation/scripts/validate_ledger.rb \
  --ledger tmp/fleet-validation-prompts/result-ledger.json \
  --expected-candidate vX.Y.Z.rc.N \
  --render-tracker tmp/fleet-validation-prompts/tracker-closeout.md
```

The validator fails closed on stale candidates, incomplete inventory, premature app work,
`UNKNOWN` capabilities or review-app state, missing package/check/baseline evidence, unowned
blockers, private-only fields, missing required paths, non-independent audit, base movement,
authority/freeze conflict, and missing default reachability/tree parity.

For the checked-in sanitized RC12 regression corpus:

```bash
ruby .agents/skills/run-fleet-validation/scripts/replay_rc12_lifecycle.rb
```

## Validate changes to this skill

Run both checks after changing the generator or prompt contract:

```bash
ruby .agents/skills/run-fleet-validation/scripts/generate_prompts_test.rb
ruby .agents/skills/run-fleet-validation/scripts/replay_rc12_lifecycle.rb
python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py" \
  .agents/skills/run-fleet-validation
```
