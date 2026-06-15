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

Use the helper from a PR branch:

```bash
bin/request-full-ci
```

Or add the label directly:

```bash
gh pr edit <number> --add-label ready-for-full-ci
```

Maintainers can also comment:

```text
+ci-run-full
```

Legacy slash aliases still work:

```text
/run-skipped-ci
```

Both command paths dispatch the full-CI-capable workflows for the current head SHA, create `ready-for-full-ci` if needed, and add it so future pushes keep running full CI. This explicit dispatch is required because labels added by a workflow's `GITHUB_TOKEN` do not start new `pull_request` workflow runs.

To return a PR to fast-gate mode for future commits:

```text
+ci-stop-full
```

or:

```text
/stop-run-skipped-ci
```

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

## Related Files

- `.github/workflows/ci-required.yml` - fast required gate
- `.github/actions/check-full-ci-label/action.yml` - accepts `ready-for-full-ci` and legacy `full-ci`
- `script/ci-changes-detector` - changed-file classification
- `bin/ci-local` - local changed-files CI runner
- `bin/request-full-ci` - adds `ready-for-full-ci`
- `bin/ci-rerun-failures` - maps failed checks to local commands
