# CI Optimization Guide

This document explains the fast, safe CI cycle for React on Rails pull requests.

## Goals

The CI setup optimizes for two things:

1. Fast PR review iteration.
2. Reliable merge safety.

Routine feedback should happen locally and through a small required GitHub check. Expensive GitHub test suites run when a PR is ready for final validation, when code reaches merge-sensitive events, or when a maintainer manually requests them.

## PR CI Model

Every PR update runs the always-required check:

```text
ci-required / required-pr-gate
```

This gate is intentionally lightweight. It validates workflow YAML syntax, shell script syntax for CI helper scripts, the changed-files detector, and a few repository sanity checks. It does not install the full dependency graph or run the full test matrix.

Full CI jobs run on PRs only when one of these is true:

- The PR has the `ready-for-full-ci` label.
- The PR targets a release branch matching `release/*`, `releases/*`, or `release-*`.
- A maintainer manually dispatches the workflow.

The legacy `full-ci` label is still accepted as a compatibility alias, but new automation and docs should use `ready-for-full-ci`.

## Merge Safety

Full CI still runs for merge-sensitive events:

- `push` to `main`
- `merge_group`
- `workflow_dispatch`

Docs-only pushes to `main` keep the existing `ensure-main-docs-safety` guard so a documentation-only commit does not hide a previously broken main branch. For code changes, main and merge queue events run the full suites.

## Required Checks

Do not make required checks depend on workflow-level `paths`, `paths-ignore`, or branch filters that can leave checks skipped or pending.

Preferred pattern:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review, labeled, unlabeled]

jobs:
  expensive-job:
    if: >
      github.event_name == 'push' ||
      github.event_name == 'merge_group' ||
      github.event_name == 'workflow_dispatch' ||
      needs.detect-changes.outputs.has_full_ci_label == 'true'
```

The workflow starts, then job-level `if:` logic decides whether expensive work should run.

## Requesting Full CI

Preferred helper:

```bash
bin/request-full-ci
```

To request full CI for a specific PR:

```bash
bin/request-full-ci 2818
```

Maintainers can also add the label directly:

```bash
gh pr edit 2818 --add-label ready-for-full-ci
```

If the label does not exist yet:

```bash
gh label create ready-for-full-ci --description "Run full GitHub CI for this PR" --color 0E8A16
```

The older PR comment command still works:

```text
/run-skipped-ci
```

It now adds `ready-for-full-ci` for future commits. To return a PR to the fast review loop:

```text
/stop-run-skipped-ci
```

This removes both `ready-for-full-ci` and the legacy `full-ci` label if present.

## Local CI Contract

Before pushing review-comment fixes, run local CI. See:

```text
internal/contributor-info/local-ci-contract.md
```

Common commands:

```bash
bin/ci-local
bin/ci-local --changed
bin/ci-local --fast
```

For a full local pass:

```bash
bin/ci-local --all
```

## Rerunning Failures Locally

Use:

```bash
bin/ci-rerun-failures
```

The script reads GitHub check results and maps known check names to local commands. It includes the required gate, core Ruby/JS/integration jobs, examples, precompile, and known Pro job names.

## Safety Notes

Do not configure a personal MacBook or other persistent personal machine as a public self-hosted runner for untrusted public PR code.

If self-hosted runners are added later:

- Use them only for trusted branches or internal repositories.
- Do not expose secrets to fork PRs.
- Prefer ephemeral runners.
- Keep the GitHub-hosted `ci-required / required-pr-gate` as the public PR default.

## Related Files

- `.github/workflows/ci-required.yml`
- `.github/workflows/*`
- `.github/actions/check-full-ci-label/action.yml`
- `bin/ci-local`
- `bin/request-full-ci`
- `bin/ci-rerun-failures`
- `script/ci-changes-detector`
