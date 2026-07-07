# CI Optimization Guide

This document explains the React on Rails PR CI policy for humans and agents.

## Goals

CI should give fast feedback during review without weakening merge safety:

1. Local machines catch routine failures before a push.
2. Every PR update gets a stable required check: `ci-required / required-pr-gate`.
3. Hosted GitHub Actions run only after local validation, on merge queue, on
   `main`, on `release/*` pushes, on same-repository non-Dependabot
   release-target PRs, or by explicit manual dispatch.
4. Optimized hosted CI stays path-selected by `script/ci-changes-detector`.
5. Force-full hosted CI is a separate maintainer decision that bypasses
   optimized suite selection.
6. Required checks do not depend on workflow-level `paths` or `paths-ignore`
   filters that can leave branch protection waiting on a skipped workflow.

## Required PR Gate

`.github/workflows/ci-required.yml` is the branch-protection-friendly gate. It
always starts for PR updates, label changes, merge queue, and manual dispatch.

The `required-pr-gate` job intentionally stays lightweight:

- validates workflow YAML can be loaded by Ruby
- syntax-checks CI shell helpers
- checks mirrored Ruby/TypeScript protocol blocks with `bin/lint-mirrored-blocks`
- runs `script/ci-changes-detector`
- fails ordinary pull requests with generator-sensitive changes until hosted CI
  is requested
- on `merge_group`, waits for the package JS minimum Node check
  (`JS unit tests for Renderer package / build (20)`) when JS tests are relevant
- checks basic repository structure

Repository branch protection should require `ci-required / required-pr-gate`.
Do not require heavyweight hosted jobs for ordinary review pushes unless the
repository intentionally wants every PR update to allocate hosted runners.
Generator-sensitive changes are the standing exception: when
`script/ci-changes-detector` sets `run_generators=true`, the required gate
blocks ordinary pull requests until `+ci-run-hosted`, `bin/request-hosted-ci`,
or a maintainer/user-token `ready-for-hosted-ci` label requests hosted CI.
Merge queue, push-to-main, `release/*` pushes, and same-repository
non-Dependabot release-target PRs already satisfy hosted eligibility.
Dependabot release-target PRs require trusted current-head `+ci-run-hosted` or
`+ci-force-full` dispatch proof before hosted jobs are enabled.

## Hosted CI Modes

Hosted workflows start cheap detector jobs, then use job-level conditions.

Optimized hosted CI runs when one of these is true:

- the event is a push to `main`
- the event is a push to `release/*`
- the event is `merge_group`
- the workflow is manually dispatched
- a same-repository non-Dependabot PR targets a release branch (`release/*`,
  `releases/*`, or `release-*`)
- the PR has `ready-for-hosted-ci`
- the PR has `force-full-hosted-ci`

Dependabot PRs are the exception: hosted CI labels and release-target base
branches are honored only after a write/admin maintainer uses `+ci-run-hosted`
or `+ci-force-full` and the selector sees the current-head dispatch success
comment.

Optimized hosted CI still uses `script/ci-changes-detector` to decide which
suites are applicable. This is the normal remote confirmation path after local
validation.

Force-full hosted CI runs when one of these is true:

- the PR has `force-full-hosted-ci`
- a workflow is dispatched with `force_full_hosted: true`

Force-full hosted CI bypasses optimized selection and marks every hosted suite
as applicable. Use it only when a maintainer intentionally wants broad matrix
coverage or when path selection itself is part of the risk.

## Dependency Profile Matrix

| Profile       | Force-full hosted | Latest local CI |
| ------------- | ----------------- | --------------- |
| Ruby versions | 3.3, 4.0          | 4.0 only        |
| Node versions | 20, 22            | 22 only         |
| Dependencies  | minimum, latest   | latest only     |

## Requesting Hosted CI

Choose the request path that matches the actor making the request.

Human or local user token:

```bash
bin/request-hosted-ci
```

Human or local user token:

```bash
gh pr edit <number> --add-label ready-for-hosted-ci
```

Maintainer PR comment:

```text
+ci-run-hosted
```

The comment command dispatches hosted workflows for the current head SHA before
adding `ready-for-hosted-ci`, because labels added by a workflow's
`GITHUB_TOKEN` do not start new `pull_request` workflow runs by themselves.

To request the broad hosted matrix:

```text
+ci-force-full
```

This dispatches workflows with `force_full_hosted: true` and adds both
`ready-for-hosted-ci` and `force-full-hosted-ci`.

To stop hosted CI on future commits:

```text
+ci-stop-hosted
```

To stop only the force-full override while leaving optimized hosted CI enabled:

```text
+ci-stop-full
```

To record a SHA-bound hosted-CI waiver:

```text
+ci-skip-hosted docs-only change; markdown checks are enough
```

For fork PRs, comment-command hosted CI does not dispatch same-repository
workflows or add persistent labels. A maintainer should push a trusted branch in
the base repository when release-target, Pro, or secret-backed CI is required.

## Local CI Contract

Before pushing review-comment fixes or CI-sensitive changes, run:

```bash
bin/ci-local
```

`bin/ci-local` defaults to optimized local CI. It auto-detects the current PR's
base branch via `gh pr view` when available and falls back to `origin/main` or
`main`.

For narrow changes, this accepted alias documents the default intent:

```bash
bin/ci-local --changed
```

For broad local coverage where practical:

```bash
bin/ci-local --all
```

Use the detector directly only when you need to inspect routing:

```bash
script/ci-changes-detector origin/main
```

## Known Tradeoffs And Guardrails

- Hosted workflows still start cheap detector jobs on ordinary PR updates and
  label changes. Expensive jobs stay behind job-level conditions, but workflow
  startup overhead remains so labels, merge queue, and manual dispatch are
  handled consistently.
- `ready-for-hosted-ci` is persistent. Once present, future commits keep running
  optimized hosted CI until `+ci-stop-hosted` removes it.
- `force-full-hosted-ci` is persistent. Once present, future commits bypass
  optimized selection until `+ci-stop-full` or `+ci-stop-hosted` removes it.
- `+ci-skip-hosted [reason]` is a SHA-bound waiver comment. It does not skip the
  fast required gate and does not apply after another push.
- Opening a draft PR early is encouraged for collaboration and review bots, but
  draft/ready-for-review state is not the hosted CI trigger.

## Merge Queue

Merge queue is a repository setting, not a file in this PR. The repo-local
required gate enforces selected merge-group-only checks that run in separate
workflows by polling the current merge-group SHA. Today that includes the
package JS minimum Node lane, so a failing `build (20)` check blocks
`ci-required / required-pr-gate` and therefore blocks the merge queue even when
branch protection requires only the stable required gate context.

Directly requiring every hosted full-matrix check context remains an
administrator branch-protection setting. Use that setting only when maintainers
want GitHub branch protection itself, rather than the repo-local required gate,
to enumerate each heavyweight job.

If merge queue is not yet enabled, maintainers should request optimized hosted
CI with `+ci-run-hosted` before merging PRs that need remote confirmation. Use
`+ci-force-full` only when broad matrix coverage is intentionally required.
Branch protection should still require `ci-required / required-pr-gate` so every
PR update has a stable required check.

## Rerunning Failures

Use:

```bash
bin/ci-rerun-failures
```

The script maps common GitHub check names to local commands, including the
required PR gate. Some Pro dummy-app checks do not have exact local equivalents;
use the matching GitHub workflow or `bin/ci-local --all` when local reproduction
is not precise.

## Adding A Hosted-CI Workflow

When adding or changing an expensive PR workflow, keep the workflow, command
dispatcher, and docs in sync:

1. Include `pull_request` events for normal PR updates and label changes:
   `opened`, `synchronize`, `reopened`, `ready_for_review`, `labeled`, and
   `unlabeled`.
2. Include `push` to `main`, `merge_group`, and `workflow_dispatch` when the
   workflow is part of merge or release confidence.
3. Avoid workflow-level `paths` or `paths-ignore` when branch protection or
   hosted CI policy depends on the workflow starting. Use job-level conditions
   after checkout and change detection instead.
4. Use `.github/actions/hosted-ci-selectors` in the detector job and grant
   `issues: read` so it can list PR labels.
5. Export `should_run_hosted_ci`, `should_force_full_hosted_ci`, and
   `should_use_full_matrix` from the detector job when downstream jobs need
   them.
6. Gate heavyweight jobs on both hosted eligibility and detector outputs, for
   example `should_run_hosted_ci == 'true' && run_js_tests == 'true'`.
7. Use `should_use_full_matrix` only for matrix breadth. Do not treat
   `ready-for-hosted-ci` as a request to bypass optimized selection.
8. If `+ci-run-hosted` or `+ci-force-full` should dispatch the workflow for the
   exact current head SHA, add it to `.github/workflows/ci-commands.yml`.
9. Update `.github/read-me.md`, `CONTRIBUTING.md`, `AGENTS.md`, and
   `.agents/workflows/pr-processing.md` when the request or readiness process
   changes.

## Rollout For Existing Open PRs

After this change merges, post a short maintainer comment on open PRs that were
using or discussing the old CI command vocabulary:

```text
CI process update: this repo now uses `+ci-run-hosted` / `ready-for-hosted-ci`
for optimized hosted CI, and `+ci-force-full` / `force-full-hosted-ci` only when
a maintainer intentionally wants to bypass optimized selection. The old
`+ci-run-full`, `+ci-skip-full`, and slash aliases have been removed.
```

Do not create a cleanup issue just to rebase every open PR. Rebase active PRs
when they next need code changes, CI reruns, or merge-readiness work.

## Related Files

- `.github/workflows/ci-required.yml` - fast required gate
- `.github/actions/hosted-ci-selectors/action.yml` - shared hosted/force-full selector
- `.github/workflows/ci-commands.yml` - PR comment command dispatcher
- `script/ci-changes-detector` - changed-file classification
- `bin/ci-local` - local optimized CI runner
- `bin/request-hosted-ci` - adds `ready-for-hosted-ci`
- `bin/ci-rerun-failures` - maps failed checks to local commands
