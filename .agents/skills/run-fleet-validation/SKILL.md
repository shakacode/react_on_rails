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
regenerating files for the same exact candidate run. Same-pack regeneration preserves the result
ledger only when a pinned release selector matches the ledger's resolved candidate and the complete
manifest fingerprint still matches. Once a dynamic `latest RC or beta` pack has resolved its
candidate, reuse its existing generated files or create a fresh pack; regeneration cannot safely
prove that the dynamic selector still resolves to the same candidate. A changed candidate or
policy/inventory manifest fails closed. Generate a fresh pack in a fresh output directory; one pack
must never replace another pack's durable result ledger.

## Launch and coordinate

1. Read `tmp/fleet-validation-prompts/INDEX.md` and start prompt 1 in snapshot/read-only mode.
   It publishes the exact candidate/RSC snapshot and generator-matrix evidence without starting its
   assigned app mutation.
2. Run `PREFLIGHT.md` against that snapshot, then start the remaining prompt coordinators.
   No app mutation worker may start before the
   pack ledger has `preflight.app_work_allowed: true` (the explicit `APP_WORK_ALLOWED` marker),
   backed by terminal-green exact-commit CI, artifacts, and the
   standard/Pro/Pro+RSC generator matrix, or an explicit policy-allowed public-safe waiver.
   Before any remote maker starts, publish the generated pack-bound preflight marker on the release
   tracker with the exact candidate tag/commit, manifest snapshot fingerprint, barrier timestamp,
   and public-safe terminal gate evidence. Every remote coordinator must read and cross-check that
   unique marker; launch timing alone never proves `APP_WORK_ALLOWED`. Record the verified marker
   in `preflight.public_marker` with `status: unique`, the exact pack/candidate/commit/fingerprint/
   opened-at fields, and replayable public-safe evidence.
   Record `preflight.opened_at` when opening the barrier and each mutable target's
   `work_started_at`; closeout rejects missing or reversed ordering evidence. The validation-only
   monorepo generator gate may run before the mutation barrier.
   If an owned release-wide blocker makes the barrier impossible to open, use the terminal blocked
   preflight path instead: retain its durable `blocker_id` and public-safe `blocker_evidence`, keep
   `APP_WORK_ALLOWED` false, leave every app target untouched while preserving any read-only
   package-lock probes, keep `preflight.public_marker` pristine and unpublished, audit with an empty
   maker list, and keep aggregate merge/reachability and tracker promotion blocked.
3. Run `REPORT-ONLY.md` so every soft track receives a disposition without a bump or merge.
   Its terminal report must retain the package versions/sources and exact-head evidence for every
   check; those are observed target versions and need not equal the release snapshot. `pending` and
   `unknown` do not count as report-only closeout. An owned blocker referenced exclusively by soft
   tracks makes the verdict `PARTIAL` but does not block promotion; the same blocker becomes
   release-gating when preflight, a hard gate, or a required path references it.
4. Each prompt is a separate top-level coordinator task and must use its bounded subagents as
   written. Do not launch the six prompts as children of one shared four-slot agent tree.
5. Require each lane to write its complete schema-valid inventory fragment to its generated
   `lane-result-N.json` path and return the exact JSON in its final response when it cannot access
   the shared pack checkout. Only the explicitly designated single ledger writer may merge those
   fragments into `result-ledger.json`, under the pack lock and with an atomic file replacement.
   Prose summaries are not ledger evidence.
6. Keep each lane in a separate checkout or worktree. Do not share mutable app checkouts between
   lanes.
7. Let lane coordinators create or update bump PRs and post idempotent evidence comments. Merge
   remains a generated closeout task and requires explicit authority plus a fresh mode/freeze read.
8. Require an authoritative coordination claim for every mutable app target before its execution
   subagent starts. A status read is not a lock. A refused claim or unknown claim outcome is
   non-passing and must not produce a competing worktree or branch. Reuse live candidate ownership
   first; generated fallback claim targets are only for genuinely fresh lanes and are stable by
   resolved candidate plus repository so separately generated packs cannot race.
9. Treat the release tracking issue plus its newest candidate-specific comments as the public
   source of truth. The issue body can describe an earlier candidate in the same release cycle;
   do not mistake that for the current candidate when a newer explicit RC section exists. A hard
   gate remains pending until it has exact install, build, test, smoke, and required-CI evidence,
   or an explicit waiver allowed by the RC plan.
10. Generate a fresh pack for every replacement candidate, even when the manifest is unchanged.
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
  --expected-pack-id PACK_ID \
  --expected-release-selector "GENERATED_RELEASE_SELECTOR" \
  --expected-candidate vX.Y.Z.rc.N \
  --expected-candidate-commit CANDIDATE_COMMIT_SHA \
  --expected-policy-commit POLICY_COMMIT_SHA \
  --expected-tracker-mode TRACKER_MODE \
  --render-tracker tmp/fleet-validation-prompts/tracker-closeout.md
```

The expected pack ID, generated release selector, candidate tag, candidate source commit, policy
commit, and tracker mode come from the checker-held launch record, not from the ledger under review.
The tracker output path must be distinct from the ledger path. The validator fails closed on stale
pack IDs, selectors, candidates, candidate commits, policy commits, or tracker modes,
missing/duplicate/mismatched public
preflight markers, product package versions that do not normalize to
the selected candidate, incomplete inventory, premature app work, `UNKNOWN` capabilities or
review-app state, candidate-managed hard-gate package versions that differ from the resolved release
snapshot, resolved snapshots that name unpublished package sources,
check/review evidence that does not match the immutable audited/reviewed/current target revision,
mutable-app check evidence that does not match the reconciled current base revision,
missing package/check/baseline evidence, unowned
blockers, inactive blockers still referenced by blocked outcomes, blockers whose status remains
`UNKNOWN`, release blockers paired with `hold` or `recommend` promotion, `blocked` promotion without
a release blocker, private-only fields, missing required paths,
non-independent audit, base movement,
authority/freeze conflict, and missing default reachability/tree parity.
The monorepo generator/install smoke is a first-class hard-gate ledger row in addition to the seven
hard-gate app repositories. A blocker-owned terminal `BLOCKED` run can close without inventing a
merge or post-merge reachability evidence; merge-eligible runs still require both. A blocked
required path records its lane, failure evidence, and `blocker_id`. Waived or deferred blockers
retain a durable owner and record a structured disposition with the gate, authority, evidence URL,
and public-safe reason.
Unrelated baseline defects require the same structured waiver before promotion. Each mutable target
records a canonical nonblank maker identity so the independent audit can prove complete maker
coverage and compare the checker against every maker without whitespace aliases. The
validation-only core gate retains the OSS, Pro, node-renderer, RSC, and generator CLI package
versions it exercises and binds all evidence to the pack's exact candidate commit, but does not
fabricate per-target merge or reachability evidence.
Hard-gate snapshot comparison covers those candidate-managed product packages and the separately
resolved RSC package; independently versioned Shakapacker or Control Plane Flow dependencies retain
their target-observed versions. Report-only package locks are evidence of the inspected target, not
a requirement to adopt the candidate.
Every mutable target records its own merge authority, freeze state, merge commit, and evidence.
The validator rejects a merged row when that same target retains a blocked result/check, candidate
regression, or broken/blocked review app; another lane's blocker does not erase a landed lane's
evidence, but a target's own failed gate can never authorize its merge.
The aggregate merge/reachability state is derived from those rows, so a partial fleet closeout
retains proofs for every landed lane without fabricating them for blocked lanes. The independent
audit also records replayable public-safe evidence.

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
