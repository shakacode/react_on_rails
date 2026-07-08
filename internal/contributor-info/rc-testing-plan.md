# RC Testing Plan

## Goal

Use one public `react_on_rails` tracking issue per final release target to decide whether the
current release candidate is ready to become the final release. The tracker records every RC
shipped to the hard-gate apps, the smoke evidence from those apps, any discovered regressions,
and the fresh final-version bump PRs after the final release ships.

This plan is contributor-only release process documentation. It lives in
`internal/contributor-info/` rather than public docs because it coordinates private release
validation, private app evidence, and maintainer-only go/no-go decisions.

## Release-Gate Model

### Hard Gates

The final release is blocked until every hard gate has passing smoke evidence, green required CI,
and no untriaged suspected RC regression.

| Gate                                            | Why It Blocks                                                                     | Minimum Evidence                                                                                                                                       |
| ----------------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `react_on_rails` generator/install smoke        | Replaces the archived manual RSC generator demo with direct generator validation. | Generator specs pass, package build passes, and install smoke from local gems completes or has a filed blocker.                                        |
| `shakacode/hichee`                              | Private production-like app signal.                                               | High-level public tracker note that install/build/smoke/CI passed, with tester and date. Do not paste private logs, URLs, screenshots, or app details. |
| `shakacode/react-on-rails-demo-flagship`        | Flagship Pro + RSC/streaming happy path.                                          | RC bump PR, dependency install, app build/smoke, and CI status. Do not paste private Pro source, install logs, URLs, screenshots, or app details.      |
| `shakacode/react-on-rails-demo-marketplace-rsc` | Public Marketplace RSC example.                                                   | RC bump PR, dependency install, app build/smoke, and CI status.                                                                                        |
| `shakacode/react-on-rails-demo-hacker-news-rsc` | Public Hacker News RSC example.                                                   | RC bump PR, dependency install, app build/smoke, and CI status.                                                                                        |
| `shakacode/react-on-rails-demo-gumroad-rsc`     | Public Gumroad RSC example.                                                       | RC bump PR, dependency install, app build/smoke, and CI status.                                                                                        |
| `shakacode/react-webpack-rails-tutorial`        | Public legacy tutorial reference.                                                 | RC bump PR, dependency install, primary tutorial route smoke, and CI status.                                                                           |
| `shakacode/react-on-rails-starter-tanstack`     | Public TanStack Pro + RSC starter example.                                        | RC bump PR, dependency install, starter build/smoke, and CI status.                                                                                    |

### Shelved Or Non-Gating Repos

Shelved repos are documented so they are remembered, but they do not block the final release and
do not require an RC bump unless someone explicitly chooses to work on them.

| Repo                                                       | Status                                                                                                        | Return-To-Gate Rule                                                                                                 |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `shakacode/react-on-rails-demo-ssr-hmr`                    | Shelved because it is very outdated. Follow-up: `shakacode/react-on-rails-demo-ssr-hmr#77`.                   | Modernize setup, dependencies, CI, and SSR/HMR smoke commands; then decide whether to promote it back to hard gate. |
| `shakacode/react-on-rails-example-migration`               | Shelved; value for the current final gate is uncertain.                                                       | Promote only if migration examples become a stated final-release gate.                                              |
| `shakacode/react-on-rails-example-open-flights`            | Shelved; useful reference, but not a current blocker.                                                         | Promote only after it has durable smoke coverage and maintainers want migration references to block final.          |
| `shakacode/react-on-rails-demo-v16-bundle-splitting`       | Shelved; inherited from an older RC spec, not part of the current public-example gate.                        | Promote only if it becomes a current major example again.                                                           |
| `shakacode/react_on_rails-demo-octochangelog-on-rails-pro` | Non-gating for the current plan; useful Pro/RSC signal but not part of the approved public-example hard gate. | Promote only if maintainers want this Pro demo to block final releases again.                                       |
| `shakacode/react-on-rails-rsc-demo`                        | Retired and archived; it mainly represented a manual generator run.                                           | Do not promote. Validate this surface through `react_on_rails` generator/install smoke instead.                     |

## Tracking Issue Lifecycle

Create one tracking issue per final release target, not one issue per RC.

Recommended title:

```text
Release gate: react_on_rails X.Y.Z
```

The issue stays open from the first RC through final-version bump completion. If there are
multiple RCs for the same final release, add a new RC section inside the same issue.

The tracking issue is the single source of truth for:

- package versions under test
- hard-gate PR links
- smoke commands and evidence
- required CI status
- advisory AI review status
- suspected RC regressions
- explicit waivers for unrelated failures
- fresh final-version bump PRs
- final go/no-go decision

## RC Validation Workflow

### Fast parallel launch

Use the repo-local `$run-fleet-validation` skill to avoid hand-copying the fleet or pinning a
candidate into six separate prompts. Its generator reads the hard gates from `demo-fleet.yml`,
adds the monorepo generator/install gate, and emits six self-contained coordinator prompts
balanced three-per-machine by default:

From the repository root, run:

```bash
ruby .agents/skills/run-fleet-validation/scripts/generate_prompts.rb \
  --machines local,m1 \
  --prompts 6 \
  --output-dir tmp/fleet-validation-prompts
```

The default prompt contract resolves the **latest RC or beta** when each lane starts. Use
`--release vX.Y.Z.rc.N` only for a deliberately pinned rerun. Launch every prompt listed in
`tmp/fleet-validation-prompts/INDEX.md` simultaneously. Each prompt coordinates bounded subagents:
one read-only live-evidence pass plus one isolated execution worker per assigned target. With the
default partition, no coordinator receives more than two execution targets. Run each prompt as a
separate top-level task; do not place all six under one shared four-slot agent tree.

Prompt 1 is the release-snapshot leader. It resolves the latest product RC/beta and the separately
versioned `react-on-rails-rsc` pin once, then posts the pack's unique snapshot marker. The other
five prompts may start simultaneously but must wait for that exact marker before mutation. This
prevents a newly published candidate from splitting a staggered launch across versions.

Each lane must acquire or resume an authoritative coordination claim before creating a mutable app
checkout. It must reuse live candidate ownership first and use the pack's generated fallback claim
target only when no lane exists. Fallback identity is stable by resolved candidate plus repository,
not pack ID, so independently generated packs cannot race. Each lane then reuses or updates existing bump PRs and posts one
idempotent marker comment per stable target identity to the tracking issue. Lanes must not
concurrently rewrite the issue body. Generate a fresh pack and snapshot identity for every
replacement candidate, even when the manifest is unchanged. Within one exact-candidate run, reuse
that pack ID and rerun only the prompt files that own affected targets.

The generated prompts accelerate the fleet hard gates; they do not replace the independent
behavioral lanes in `release-verification-runbook.md` or the maintainer's final go/no-go decision.

1. Cut the RC packages.
2. Create or update the release-gate tracking issue from
   `.github/ISSUE_TEMPLATE/rc-release-tracking.yml`.
3. Open RC bump PRs in every hard-gate app that consumes the changed package.
4. Run local smoke where practical before relying on CI.
5. Run the behavioral verification lanes in
   [`release-verification-runbook.md`](release-verification-runbook.md) (upgrade dry-run,
   debut-feature abuse pass, stress/soak, changelog and artifact audits) and post each lane
   report to the tracking issue.
6. Record evidence in the tracking issue for each hard gate.
7. File issues for every suspected RC regression or blocked smoke path.
8. Treat AI review checks as advisory unless they identify a real bug.
9. Make the final go/no-go call only after every hard gate is green or explicitly waived, and
   every behavioral lane is green or explicitly waived (Lane 4b artifact defects cannot be
   waived).

### RC.10 Copy/Paste Demo-Fleet Prompts

These prompts are filled for the current release and can be pasted without replacing placeholders.
They use the manifest for inventory while preserving this document as the authority for
release-gate policy.

#### Codex Task Settings

| Setting     | Value            |
| ----------- | ---------------- |
| Project     | `react_on_rails` |
| Model       | 5.6 Sol          |
| Reasoning   | Extra High       |
| Permissions | Full access      |

These are the Codex task labels used by maintainers in July 2026. If the UI changes, choose the
strongest available model and highest reasoning level. Open the regular `react_on_rails` project,
not an individual demo app.

Everything beyond this table—including worker-model routing, worktrees, concurrency, coordination,
validation, review, privacy, and tracker evidence—is handled by the prompts.
`Sol` and `Terra` are portable route classes defined by the installed `$pr-batch` workflow, not
additional UI model names. `MODEL_ESCALATION_REQUEST` is that workflow's evidence-bearing request
for coordinator-approved promotion from a cheaper worker route to Sol/xhigh.

#### Published RC.10 Values

| Release input     | Exact value                                                        |
| ----------------- | ------------------------------------------------------------------ |
| GitHub tag        | `v17.0.0.rc.10`                                                    |
| Release commit    | `d09328988dd5caa7e358f262174141d0a84b7f94`                         |
| Ruby gems         | `react_on_rails` and `react_on_rails_pro` `17.0.0.rc.10`           |
| npm packages      | Four React on Rails packages at `17.0.0-rc.10`                     |
| RSC package       | `react-on-rails-rsc` `19.2.1-rc.1`                                 |
| Tracking issue    | `shakacode/react_on_rails#3823`                                    |
| Public reused PRs | Flagship #25, HN #69, Marketplace #131, Gumroad #78, TanStack #192 |
| Other hard gates  | Resume the private HiChee handoff; Tutorial is the only fresh PR   |

The four npm packages are `react-on-rails`, `react-on-rails-pro`,
`react-on-rails-pro-node-renderer`, and `create-react-on-rails-app`. The Ruby spelling uses
`.rc.10`; npm uses `-rc.10`; RSC has its own React-aligned version.

RC.10 is not promotable: its tagged generator, Pro peer/dev metadata, node-renderer/runtime floor,
workspace overrides, lockfile, tests, and docs retain RSC rc.1. After stable 19.2.1 publishes,
replace or clear every prerelease-specific RSC reference on `release/17.0.0`, regenerate locks/docs,
cut and fully validate a new RC, then promote only it.

For the next release, regenerate this entire copy/paste section rather than editing only the
release blocks. Search for every RC-specific literal and update the section heading, values table,
release versions and SHA, tracker, reuse/fresh PR plan, dates, batch titles, thread handles, batch
IDs, generator gate target, combined-audit target, and post-final hard/soft targets. Re-measure every
prompt before publishing the documentation. This prevents an apparently current prompt from
retaining an RC.10 branch, PR, or commit.

#### Recommended Launch Plan

Run hard-gate Batches A and B concurrently in separate Codex tasks or on separate machines. Run the
RC.10 behavioral verification beside them: Lane 0 first; then mandatory Lane 1, Lane 2 per debut
feature, Lane 3, and Lane 4b in parallel; after findings are fixed or explicitly waived, run final
Lane 4a. Start Batch C only after A/B hand off and current exact-RC.10 reports for Lanes 0, 1, 2, 3,
4a, and 4b are posted to #3823. After the stable final packages are published, run one shared
exact-final artifact preflight. Only after its Lane 4a result is COMPLETE and Lane 4b result is CLEAN
may required hard-gate Batch D and optional shelved-app Batch E run concurrently. Batch D must
finish before the tracker closes. Shelved apps do not justify
repeated RC churn unless an RC changes a feature uniquely covered by one of them; Batch E failures
create follow-up issues but do not block the release or tracker closeout.

Before launching A or B, re-read the tracker and targeted private coordination state. If an RC.10
batch already owns any hard-gate lane, resume or hand off through its existing batch ID, owner,
claim, branch, and worktree; do not launch a second worker, take a second claim, infer cancellation
from a stale/missing heartbeat, or cancel/release another lane. Use the A/B prompts as new launches
only when targeted coordination confirms their lanes are both unclaimed and incomplete, or a
maintainer explicitly cancels and relaunches the prior batch. A completed RC.10 handoff satisfies
A/B and feeds Batch C instead of restarting the lane.

Never copy live ownership from this file; the tracker and targeted coordination backend are the
only authorities for current lane state. Reconcile terminal/report-complete soft handoffs, let live
report-only owners finish, and open no RC soft PRs. Park only never-started mutation lanes. A
stale/missing heartbeat alone never authorizes takeover. Dead-lane recovery requires backend TTL
proof, an unrecoverable original session, inspected branch/PR state, no possible unpushed work, and
a recorded fenced takeover before a fresh claim; otherwise keep the lane blocked. Shelved bumps
remain final Batch E.

Manifest closeout is separate from app bumps. Public lanes return field evidence/corrections for
one `react_on_rails` metadata PR; clear `verify: true` only after repo inspection, dependency-review
CI confirmation, and a real review-app name or `review_app: null`. HiChee evidence/corrections stay
private: clear its flag only when a private maintainer confirms every published field is accurate
and disclosure-approved, and publish no operational evidence. If an accurate required value cannot
be public, leave the flag set and file a private-overlay design issue before automation treats the
entry as authoritative. Leave other unconfirmed flags set and file follow-ups.

#### Batch A: Core, HiChee, Flagship, and Tutorial

```text
/goal
Use $pr-batch to finish React on Rails 17 RC.10 Batch A.
Batch title: ROR A 07-13 15:17 - RC10 core hard gates.
Thread handle: ror-a-core-koa. Batch id: ror-17-rc10-a. merge_authority: ask.

Release facts: tag v17.0.0.rc.10; commit d09328988dd5caa7e358f262174141d0a84b7f94;
react_on_rails and react_on_rails_pro gems 17.0.0.rc.10; react-on-rails,
react-on-rails-pro, react-on-rails-pro-node-renderer, and create-react-on-rails-app npm packages
17.0.0-rc.10; react-on-rails-rsc 19.2.1-rc.1. Tracker: shakacode/react_on_rails#3823.

Lanes: exact-tag generator gate; resume the private HiChee RC.10 handoff; update Flagship #25;
Tutorial is the only fresh PR.

Fetch all refs and the tracker. Use v17.0.0.rc.10 for shipped code, package coverage, changelog, and
generator behavior; use current defaults only for policy, fleet inventory, and target bases. If
they conflict on what shipped or a repo consumes, stop that lane BLOCKED/UNKNOWN; never mix
snapshots. Verify registry tags, release SHA/changelog/exact-commit CI once. One isolated claimed
worktree per repo; respect remote claims. Reuse a completed RC.10 handoff for Batch C. Otherwise
resume existing ownership or a fenced handoff; launch only when coordination says the lane is
unclaimed and incomplete. Workers read target AGENTS.md, confirm
verify-marked manifest metadata, update only consumed packages and lockfiles, then
install/build/test/smoke. Open/update the PR, request and wait for all required hosted CI, and, where
the manifest has a non-null `review_app.cpflow_app_name`, wait for deployment and run every declared
smoke path. Hosted CI and review-app smoke must both pass when that real app name is configured. Fix
actionable reviews and finish each lane.

Smoke is behavioral, not path-only. For each applicable app, verify the declared routes load,
expected SSR content is present in the initial response, the manifest headline's RSC/client
interaction works, and the browser console has no new red errors. A 2xx response alone does not
pass. Record these results in the RC test report; keep private-app details out of the public tracker.

Run the generator/install gate in a separate clean react_on_rails worktree at v17.0.0.rc.10. Verify
HEAD is d09328988dd5caa7e358f262174141d0a84b7f94 before running the documented commands; never run
this gate from main or the documentation worktree.

Published mode matrix, in a scratch directory with no local overrides: `--standard` = core only,
no Pro/RSC, `/hello_world`; no setup-mode flag = core+Pro, no RSC, working Pro SSR; `--rsc` =
core+Pro+RSC, streamed and interactive HelloServer route. Generate all three through exact
create-react-on-rails-app@17.0.0-rc.10 and assert exact 17.0.0.rc.10 gem, 17.0.0-rc.10 npm, and
19.2.1-rc.1 RSC locks where applicable. Any extra/missing package, wrong route, or fallback is
BLOCKED. Keep Pro/RSC logs private.

Routes: coordinator/checker Sol/xhigh; mechanical Terra/high; uncertain/QA Sol/high; escalate only
after evidenced MODEL_ESCALATION_REQUEST.

Never expose private HiChee/Pro logs, URLs, screenshots, app details, tokens, secret names, or
private repository SHAs. Keep HiChee evidence private; clear verify only for accurate public fields.
Re-read #3823 before posting append-only, public-safe evidence. Include
exact base/head/merge SHAs for public gates only; report only high-level pass/fail, tester, and date
for HiChee. Do not change Agent Release Mode. Suspected RC regressions block their lane; unrelated
defects get focused follow-up issues. Report PASS/PARTIAL/BLOCKED/UNKNOWN as evidence only;
preserve UNKNOWN for unverifiable facts and treat it as non-passing. Hand the
completed evidence to Batch C. Do not request, recommend, or perform final promotion.
```

#### Batch B: Public RSC Demos

```text
/goal
Use $pr-batch to finish React on Rails 17 RC.10 Batch B.
Batch title: ROR B 07-13 15:17 - RC10 public RSC hard gates.
Thread handle: ror-b-rsc-nalu. Batch id: ror-17-rc10-b. merge_authority: ask.

Release facts: tag v17.0.0.rc.10; commit d09328988dd5caa7e358f262174141d0a84b7f94;
react_on_rails and react_on_rails_pro gems 17.0.0.rc.10; react-on-rails,
react-on-rails-pro, react-on-rails-pro-node-renderer, and create-react-on-rails-app npm packages
17.0.0-rc.10; react-on-rails-rsc 19.2.1-rc.1. Tracker: shakacode/react_on_rails#3823.

Own only these lanes:
1. shakacode/react-on-rails-demo-hacker-news-rsc: safely update PR #69.
2. shakacode/react-on-rails-demo-marketplace-rsc: safely update PR #131.
3. shakacode/react-on-rails-demo-gumroad-rsc: safely update PR #78.
4. shakacode/react-on-rails-starter-tanstack: safely update PR #192.

Fetch all refs and the tracker. Use v17.0.0.rc.10 for shipped code, package coverage, changelog, and
generator behavior; use current defaults only for policy, fleet inventory, and target bases. If
they conflict on what shipped or a repo consumes, stop that lane BLOCKED/UNKNOWN; never mix
snapshots. Verify the release facts once and reuse the evidence. One isolated claimed worktree per
repo; respect remote claims.
Reuse a completed RC.10 handoff for Batch C. Otherwise resume existing ownership or a fenced
handoff; launch only when coordination says the lane is unclaimed and incomplete. Workers read
target AGENTS.md, confirm
verify-marked manifest metadata, update only consumed packages and lockfiles, then
install/build/test/smoke. Open/update the PR, request and wait for all required hosted CI, and, where
the manifest has a non-null `review_app.cpflow_app_name`, wait for deployment and run every declared
smoke path. Hosted CI and review-app smoke must both pass when that real app name is configured. Fix
actionable reviews and finish each lane.

Smoke is behavioral, not path-only. For each applicable app, verify the declared routes load,
expected SSR content is present in the initial response, the manifest headline's RSC/client
interaction works, and the browser console has no new red errors. A 2xx response alone does not
pass. Record these results in the RC test report.

Routes: coordinator and fresh independent checker Sol/xhigh; mechanical workers Terra/high;
uncertain workers and routine QA Sol/high. A worker may request stronger help by reporting
MODEL_ESCALATION_REQUEST with evidence; only the coordinator may move it to Sol/xhigh.

Do not expose private Pro data. Re-read #3823 before posting append-only evidence with exact
base/head/merge SHAs; do not change Agent Release Mode. Suspected RC regressions block their lane;
unrelated defects get focused follow-up issues. Report PASS/PARTIAL/BLOCKED/UNKNOWN as evidence
only; preserve UNKNOWN for unverifiable facts and treat it as non-passing. Hand the completed
evidence to Batch C. Do not request, recommend, or perform final promotion.
```

#### Batch C: Fresh Combined Evidence Audit

Run this in a new Codex task after Batches A and B finish and all required exact-RC.10 behavioral
lane reports are posted.

```text
/goal
Independently audit React on Rails 17 RC.10 release evidence; make no repository changes or merges.
Batch title: ROR C 07-13 15:17 - RC10 combined evidence audit.
Thread handle: ror-c-audit-niu. Batch id: ror-17-rc10-audit. merge_authority: none.

Use a fresh Sol/xhigh checker that made none of the changes. Verify tag v17.0.0.rc.10 and commit
d09328988dd5caa7e358f262174141d0a84b7f94, exact-tag CI, changelog, registry artifacts (gems
17.0.0.rc.10; four npm packages 17.0.0-rc.10; RSC 19.2.1-rc.1), the generator/install gate, and
all seven hard-gate repos in internal/contributor-info/demo-fleet.yml.
The tag controls shipped/package coverage; current defaults control policy/inventory/bases.
Conflicts are BLOCKED/UNKNOWN; never mix snapshots.

Audit the current RC.10 reports for Lane 0 and mandatory Lanes 1, 2, 3, 4a, and 4b in
release-verification-runbook.md. Apply each lane's pass criteria, require Lane 4b CLEAN, and never
accept a waiver for an artifact defect.

RC.10 is BLOCKED from final: generator, Pro/node metadata/runtime ranges, overrides, locks, tests,
and docs retain RSC rc.1. Replace/clear every prerelease RSC ref for stable 19.2.1, then cut and fully
validate a new RC; never defer this to final-only work.

Before auditing, require a current exact-RC.10 report for every listed behavioral lane. If one is
missing, stale, or covers another RC, do not produce it from this read-only audit; return it to its
owner and report UNKNOWN/PARTIAL rather than continuing toward final go/no-go.

Re-fetch PRs/defaults. Require current-head install, lock, build, CI, smoke, and no untriaged RC
regression. Open PR: record base/head; require base ancestry or an exact-parent hosted/synthetic
merge with full checks and smoke on its merge SHA—head-only CI fails. Merged PR: require GitHub's
merge OID reachable from current default and its tree containing the patch; squash heads need not
be reachable. Missing current-base evidence or actionable review is BLOCKED and returned with exact
remediation. This auditor never edits, pushes, reruns CI, or resolves threads.
For every hard gate, require evidence matching each Smoke Evidence item in the RC test report:
route load, expected SSR output, the repo's headline RSC/client interaction, and a browser console
with no new red errors. Path-only or 2xx-only evidence is insufficient. A demonstrated failure is
BLOCKED; missing or unverifiable behavioral evidence is UNKNOWN and non-passing. Mark an interaction
not applicable only with a concrete repo-specific explanation.
Re-read shakacode/react_on_rails#3823, then post one append-only public-safe audit comment without
changing Agent Release Mode. Record exact SHAs only for public gates; keep HiChee repository
metadata private and report only its high-level result. Report PASS/PARTIAL/BLOCKED/UNKNOWN
evidence only. Preserve UNKNOWN for unverifiable facts; it is non-passing and cannot support final
promotion. Aggregate as BLOCKED for a known blocker; otherwise UNKNOWN when any required fact is
unknown; otherwise PARTIAL when known work remains incomplete; use PASS only when every required
fact passes. Ask the maintainer for the final go/no-go. Never recommend or perform promotion.
```

#### Batch D: Hard-Gate Apps After Final Publication

Paste this only after the registries contain the stable `17.0.0` packages and stable
`react-on-rails-rsc` `19.2.1`. This batch is required before closing the tracker.

```text
/goal
Use $pr-batch to finish the React on Rails 17.0.0 final hard-gate app bumps.
Batch title: ROR D 07-13 15:17 - final hard-gate bumps.
Thread handle: ror-d-final-moa. Batch id: ror-17-final-hard. merge_authority: ask.

Preflight: require tag v17.0.0; stable react_on_rails and react_on_rails_pro gems 17.0.0; stable
react-on-rails, react-on-rails-pro, react-on-rails-pro-node-renderer, and
create-react-on-rails-app npm packages 17.0.0; and stable react-on-rails-rsc 19.2.1. Verify the tag,
registry dist-tags, changelog, and exact-tag CI. Stop without changing apps if any artifact is
missing, prerelease-tagged, or incoherent. Tracker: shakacode/react_on_rails#3823.

Before changing any app, use a fresh independent checker and a clean checkout at v17.0.0 to run the
final-promotion Lane 4a audit and Lane 4b version/coherence subset from
release-verification-runbook.md against the final tag and actual published artifacts. Reuse existing
reports only after verifying their exact-final scope, evidence, and freshness; otherwise produce
them. Post both to #3823. Continue only when Lane 4a is COMPLETE and Lane 4b is CLEAN; on GAPS,
DEFECTS, missing, or stale evidence, stop app changes and report BLOCKED. If runtime or packaging
content differs from the accepted RC, stop for a broader release gate instead of treating the subset
as sufficient.

Repeat the published three-mode matrix through exact create-react-on-rails-app@17.0.0: `--standard`
is core-only; no flag is core+Pro/no RSC with working Pro SSR; `--rsc` is core+Pro+RSC with a
streamed, interactive HelloServer. Require exact stable 17.0.0 locks in every mode and
react-on-rails-rsc 19.2.1 only for `--rsc`; any package missing or extra for its mode, wrong route,
or fallback is BLOCKED.

Open fresh final-version PRs in all seven hard-gate apps from current default branches: HiChee,
Flagship, Hacker News RSC, Marketplace RSC, Gumroad RSC, Tutorial, and TanStack. Do not rename or
reuse RC PRs unless a maintainer explicitly chooses one for unusual review history. One claimed
worktree and worker per repo; read target AGENTS.md, verify manifest data, update only consumed
packages/lockfiles, install/build/test/smoke, and open the PR. Request and wait for all required
hosted CI; where the manifest has a non-null `review_app.cpflow_app_name`, also wait for deployment
and run every declared smoke path. Hosted CI and review-app smoke must both pass when that real app
name is configured. Address actionable review.

Smoke is behavioral, not path-only. For each applicable app, verify the declared routes load,
expected SSR content is present in the initial response, the manifest headline's RSC/client
interaction works, and the browser console has no new red errors. A 2xx response alone does not
pass. Record these results in the RC test report; keep private-app details out of the public tracker.

Use Terra/high for mechanical work, Sol/high for uncertain work/QA, and Sol/xhigh only after an
evidenced MODEL_ESCALATION_REQUEST. A fresh Sol/xhigh checker audits current-head results. Re-read
#3823 before appending evidence. Publish exact PR/CI/smoke SHAs only for public gates; for HiChee,
publish only high-level pass/fail, tester, and date—never private URLs, logs, app details, or SHAs.
Do not change Agent Release Mode. Finish only when every hard-gate final PR is merged or has an
explicit focused follow-up issue accepted by a maintainer.
```

#### Batch E: Shelved Apps After Final Publication

This optional batch may run beside Batch D after the same stable-artifact preflight.

```text
/goal
Use $pr-batch to refresh the non-gating React on Rails demo fleet after final publication.
Batch title: ROR E 07-13 15:17 - final shelved-app refresh.
Thread handle: ror-e-shelved-mako. Batch id: ror-17-final-soft. merge_authority: ask.

Preflight: independently verify, or reuse a current shared #3823 report proving, final tag v17.0.0;
required 17.0.0 gem/npm artifacts and dist-tags; react-on-rails-rsc 19.2.1; changelog; exact-tag CI;
Lane 4a COMPLETE; and Lane 4b CLEAN artifact coherence. Verify reused evidence's exact-final scope
and freshness. On missing, prerelease, incoherent, stale, or UNKNOWN evidence, stop without changing
repos. Tracker: shakacode/react_on_rails#3823.

Own only the five soft-track repos in internal/contributor-info/demo-fleet.yml:
- shakacode/react_on_rails-demo-octochangelog-on-rails-pro
- shakacode/react-on-rails-demo-ssr-hmr
- shakacode/react-on-rails-demo-v16-bundle-splitting (report-only while archived)
- shakacode/react-on-rails-example-open-flights
- shakacode/react-on-rails-example-migration

Use one claimed worktree and worker per mutable repo. Workers read target AGENTS.md, verify manifest
data, update only consumed packages/lockfiles, install/build/test/smoke, open or update PRs, request
required hosted CI, and address actionable review. Treat the archived v16 bundle-splitting repo as
read-only: inspect and report whether a refresh is useful, but create no claim/worktree/branch/PR or
CI/review request unless a maintainer first unarchives it. Use Terra/high for mechanical work,
Sol/high for uncertain work/QA, and Sol/xhigh only after an evidenced MODEL_ESCALATION_REQUEST. A
fresh Sol/xhigh checker audits the results.

These repos never block the final release or tracker closeout. Record exact PR/CI/smoke evidence
and file focused follow-up issues for failures. Do not expose private Pro data or change tracker
Agent Release Mode.
```

## Required Pass Criteria

For each hard-gate app PR:

- dependency install succeeds for the repo's package manager
- lockfiles are updated consistently
- app build or asset compile succeeds
- the repo's required CI checks are green
- the release manager records exact smoke evidence in the tracking issue
- any suspected RC regression is filed as an issue before final

For the `react_on_rails` generator/install gate:

```bash
# Generator specs run in the react_on_rails/ gem bundle (its Gemfile provides Rails).
# Running them from the workspace root fails with `cannot load such file -- rails`,
# because the root workspace bundle does not include Rails.
(cd react_on_rails && bundle exec rspec spec/react_on_rails/generators)
pnpm run build
CREATE_ROR_SMOKE_SCOPE=oss packages/create-react-on-rails-app/scripts/smoke-test-local-gems.sh
```

Also run the published three-mode matrix from the candidate-specific section above in a separate
scratch directory with no local overrides. The gate does not pass unless `--standard`, default Pro,
and `--rsc` installs all build and smoke with the exact candidate locks and independently resolved RSC
lock where applicable.

If a command fails for an environmental reason, record the failure and file or link a follow-up
issue. Do not silently mark the gate as passed.

## Advisory Checks

AI review checks, including Claude, CodeRabbit, Cursor Bugbot, and similar tools, are advisory
unless they report a real actionable bug.

Use this rule:

- **Actionable product/build bug**: fix or file an issue before final.
- **Workflow/auth/tooling failure**: record in the tracker, file an issue if needed, and do not let
  it silently block or silently pass.
- **Style-only or noisy review**: record as advisory; it does not block final.

## Waivers

A hard gate can be waived only when the failure is proven unrelated to the RC or final package.
The tracker comment must include:

- gate name
- failed command or check
- why it is unrelated to the RC
- issue link for the unrelated failure
- maintainer/date approving the waiver

Do not self-certify ambiguous RSC, build, or generator failures. If the failure could plausibly be
caused by the RC, treat it as a release blocker until another maintainer agrees it is unrelated.

## Private Evidence Privacy Rule

`shakacode/hichee` is a private hard gate, and some hard gates consume private Pro source. The
tracker is public. The public tracker may name the repo and record high-level status, but it must
not expose private app or private Pro source details.

Allowed public evidence:

- PR link, if acceptable to maintainers; GitHub hides private PRs from people without access
- install/build/smoke/CI passed
- tester name and date
- a high-level note that a private issue was filed

Not allowed in the public tracker:

- private logs
- private URLs
- screenshots
- customer data
- internal app behavior details
- secrets or environment variable names that reveal sensitive infrastructure

## Final Release And Final Bumps

After the final `react_on_rails` release ships:

1. Open fresh final-version bump PRs in the hard-gate apps.
2. Do not rely on renamed RC PRs unless there is unusual review history worth preserving.
3. Re-run CI and minimum smoke on each final bump PR.
4. Merge final bump PRs.
5. Close the release-gate issue only after every hard-gate final bump is merged or has an explicit
   follow-up issue.

The clean default is two PRs per hard-gate app:

- an RC PR that proves readiness
- a final PR that proves the app is no longer pinned to an RC

## RC Test Report Template

Paste this into each hard-gate app PR body and fill it in as evidence arrives.

```markdown
## RC Test Report

Tracking issue: shakacode/react_on_rails#<issue-number>

### Versions

- react_on_rails gem:
- react-on-rails npm:
- react_on_rails_pro gem, if used:
- react-on-rails-pro npm, if used:
- shakapacker gem/npm, if changed:
- cpflow, if changed:

### Automated Checks

- [ ] Dependency install passes:
- [ ] Lockfile update is intentional:
- [ ] App build or asset compile passes:
- [ ] Required CI is green:
- [ ] Advisory AI review checks recorded:

### Smoke Evidence

- [ ] Primary route loads:
- [ ] Server-rendered output is present where expected:
- [ ] RSC or client interaction works for this repo's headline feature:
- [ ] Browser console has no new red errors:
- [ ] Any known unrelated failures are linked:

### Result

- [ ] Passed and linked in the release-gate tracker
- [ ] Blocked by suspected RC regression, issue:
- [ ] Waived as unrelated to RC, tracker comment:
```

## Tracking Issue Template

Use `.github/ISSUE_TEMPLATE/rc-release-tracking.yml` to create the release-gate issue. The issue
form intentionally asks for:

- final release target
- package versions under test
- hard-gate table
- shelved repo notes
- RC-by-RC results
- final bump status
- final go/no-go decision

## Automation Roadmap

The plan is intentionally manual-first. Automation should fill in evidence, not own release policy.

Future automation can:

- open or update hard-gate bump PRs
- fill automated CI and smoke sub-items in the tracking issue
- poll review-app URLs where available
- detect stale RC pins after final ships
- report advisory AI review status

Automation must not:

- make the final go/no-go decision
- hide private HiChee evidence in public logs
- promote shelved repos back to hard gate without maintainer approval
- waive suspected RC regressions without a maintainer comment
