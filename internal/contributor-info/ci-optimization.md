# CI Optimization Guide

This document explains the React on Rails PR CI policy.

## Goals

CI should give fast feedback during review without weakening merge safety:

1. Local machines catch routine failures before a push.
2. Every PR update gets a stable required check: `ci-required / required-pr-gate`.
3. Heavy GitHub CI runs only when the PR is ready for full validation, on merge queue, on `main`, on release-target PRs, or by manual dispatch.
4. Required checks do not depend on workflow-level `paths` or `paths-ignore` filters that can leave branch protection waiting on a skipped workflow.

## Required PR Gate

`.github/workflows/ci-required.yml` is the branch-protection-friendly gate. It always starts for PR updates, label changes, merge queue, and manual dispatch.

The `required-pr-gate` job intentionally stays lightweight:

- validates workflow YAML can be loaded by Ruby
- syntax-checks CI shell helpers
- runs `script/ci-changes-detector`
- checks basic repository structure

Repository branch protection should require `ci-required / required-pr-gate`. Do not require heavyweight jobs for ordinary review pushes unless the repository policy intentionally wants every PR update to run full CI.

## Full CI Triggers

Heavy workflows start but keep expensive jobs behind job-level conditions. Full CI jobs run when any of these is true:

- the event is a push to `main`
- the event is `merge_group`
- the workflow is manually dispatched
- the PR targets a release branch (`release/*`, `releases/*`, or `release-*`)
- the PR has `ready-for-full-ci`

The legacy `full-ci` label is still accepted as an alias so older comments and labels do not break. New automation should use `ready-for-full-ci`.

## Requesting Full CI

There are three supported request paths. Choose the one that matches the actor
making the request:

- **Human or local user token**: run the helper from a PR branch:

```bash
bin/request-full-ci
```

- **Human or local user token**: add the label directly:

```bash
gh pr edit <number> --add-label ready-for-full-ci
```

- **Maintainer PR comment**: comment on the PR:

```text
+ci-run-full
```

Legacy slash aliases still work for maintainers:

```text
/run-skipped-ci
```

Human/user-token label writes start the `pull_request` label event, so direct
labeling and `bin/request-full-ci` can wake the heavyweight workflows. Comment
commands are different: `+ci-run-full` and `/run-skipped-ci` run from a workflow,
so they dispatch the full-CI-capable workflows for the current head SHA, create
`ready-for-full-ci` if needed, and add the label for future pushes. That explicit
dispatch is required because labels added by a workflow's `GITHUB_TOKEN` do not
start new `pull_request` workflow runs.

To return a PR to fast-gate mode for future commits:

```text
+ci-stop-full
```

or:

```text
/stop-run-skipped-ci
```

For fork PRs, comment-command full CI does not dispatch same-repository
workflows or add the persistent label. A maintainer should either push a trusted
branch in the base repository or use the normal maintainer review path for the
limited fork-safe checks.

## Known Tradeoffs And Guardrails

- Heavy workflows still start their cheap detector jobs on ordinary PR updates
  and label changes. Expensive jobs stay behind job-level conditions, but the
  workflow startup overhead remains so label changes, merge queue, and manual
  dispatch can be handled consistently.
- `ready-for-full-ci` is persistent. Once present, future commits keep running
  full CI until `+ci-stop-full` or `/stop-run-skipped-ci` removes it.
- Branch protection is a repository setting, not a file in this PR. After this
  policy lands, require `ci-required / required-pr-gate` and avoid requiring
  heavyweight PR jobs unless the repository intentionally wants every update to
  run full CI.
- `+ci-skip-full [reason]` is a SHA-bound waiver comment. It does not skip the
  fast required gate and does not apply after another push.

## Local CI Contract

Before pushing review-comment fixes or CI-sensitive changes, run:

```bash
bin/ci-local
```

For narrow changes, this equivalent alias documents the intent:

```bash
bin/ci-local --changed
```

Use the detector directly when you need to inspect routing:

```bash
script/ci-changes-detector origin/main
```

See `internal/contributor-info/local-ci-contract.md` for the short AI/dev contract.

## Merge Safety

If GitHub merge queue is enabled, keep the full-CI-capable workflows on `merge_group`. That gives merge candidates a full validation pass even when ordinary PR review pushes only ran the fast gate.

If merge queue is not enabled, maintainers should add `ready-for-full-ci` and wait for full CI to pass before merging. Branch protection should still require `ci-required / required-pr-gate` so every PR update has a stable required check.

## Rerunning Failures

Use:

```bash
bin/ci-rerun-failures
```

The script maps common GitHub check names to local commands, including the required PR gate. Some Pro dummy-app checks do not have exact local equivalents; use the matching GitHub workflow or `bin/ci-local --all` when a local reproduction is not precise.

## Adding A Full-CI-Capable Workflow

When adding or changing an expensive PR workflow, keep the workflow, command
dispatcher, and docs in sync:

1. Include `pull_request` events for normal PR updates and label changes:
   `opened`, `synchronize`, `reopened`, `ready_for_review`, `labeled`, and
   `unlabeled`.
2. Include `push` to `main`, `merge_group`, and `workflow_dispatch` when the
   workflow is part of merge or release confidence.
3. Avoid workflow-level `paths` or `paths-ignore` when branch protection or full
   CI policy depends on the workflow starting. Use job-level conditions after
   checkout and change detection instead.
4. If the workflow uses `.github/actions/check-full-ci-label`, grant the detector
   job `issues: read` so it can list PR labels.
5. Gate heavyweight jobs on the full-CI cases: `push` to `main`, `merge_group`,
   `workflow_dispatch`, release-target PRs, or `ready-for-full-ci` / legacy
   `full-ci`.
6. If `+ci-run-full` should run the workflow for the exact current head SHA,
   add it to the dispatch lists in `.github/workflows/ci-commands.yml` and
   `.github/workflows/run-skipped-ci.yml`, including `force_run: 'true'` when
   the workflow supports that input.
7. Update `.github/read-me.md`, `CONTRIBUTING.md`, and agent-facing docs so
   humans and agents know whether the workflow is label-driven, manually
   dispatched, merge-queue-only, benchmark-only, or intentionally excluded.

## Related Files

- `.github/workflows/ci-required.yml` - fast required gate
- `.github/actions/check-full-ci-label/action.yml` - accepts `ready-for-full-ci` and legacy `full-ci`
- `script/ci-changes-detector` - changed-file classification
- `bin/ci-local` - local changed-files CI runner
- `bin/request-full-ci` - adds `ready-for-full-ci`
- `bin/ci-rerun-failures` - maps failed checks to local commands
