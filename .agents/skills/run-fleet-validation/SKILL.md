---
name: run-fleet-validation
description: Generate and coordinate parallel React on Rails release fleet validation from internal/contributor-info/demo-fleet.yml. Use when a maintainer wants to validate the latest RC or beta, split fleet work across machines or agent sessions, inspect fleet progress, or prepare repeatable per-lane prompts without hand-partitioning repositories.
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

The generator reads only `tier: hard_gate` repositories, adds the monorepo generator/install
gate required by `internal/contributor-info/rc-testing-plan.md`, balances weighted lanes across
the named machines, and includes effective commands after manifest defaults are applied. It also
creates a unique pack ID. Every replacement candidate needs a freshly generated pack and ID; pass
`--pack-id ID` only when regenerating files for the same exact candidate run.

## Launch and coordinate

1. Read `tmp/fleet-validation-prompts/INDEX.md`.
2. Start all prompt files simultaneously, three per machine for the default six-prompt/two-machine
   layout. Prompt 1 publishes the exact candidate/RSC snapshot for the pack; the other five wait
   for that marker before mutating anything. Each prompt is a separate top-level coordinator task
   and must use its bounded subagents as written. Do not launch the six prompts as children of one
   shared four-slot agent tree.
3. Keep each lane in a separate checkout or worktree. Do not share mutable app checkouts between
   lanes.
4. Let lane coordinators create or update bump PRs and post idempotent evidence comments, but do
   not let them merge or make the final release decision.
5. Require an authoritative coordination claim for every mutable app target before its execution
   subagent starts. A status read is not a lock. A refused claim or unknown claim outcome is
   non-passing and must not produce a competing worktree or branch. Reuse live candidate ownership
   first; generated fallback claim targets are only for genuinely fresh lanes and are stable by
   resolved candidate plus repository so separately generated packs cannot race.
6. Treat the release tracking issue plus its newest candidate-specific comments as the public
   source of truth. The issue body can describe an earlier candidate in the same release cycle;
   do not mistake that for the current candidate when a newer explicit RC section exists. A hard
   gate remains pending until it has exact install, build, test, smoke, and required-CI evidence,
   or an explicit waiver allowed by the RC plan.
7. Generate a fresh pack for every replacement candidate, even when the manifest is unchanged.
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

## Validate changes to this skill

Run both checks after changing the generator or prompt contract:

```bash
ruby .agents/skills/run-fleet-validation/scripts/generate_prompts_test.rb
python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py" \
  .agents/skills/run-fleet-validation
```
