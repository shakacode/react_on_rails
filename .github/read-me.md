# GitHub Actions CI/CD Configuration

This directory contains GitHub Actions workflows for continuous integration and
deployment.

## PR Comment Commands

Post one CI command per PR comment. If a comment contains multiple `+ci-*`
commands, the command workflow handles only the first one.

### `+ci-run-hosted` - Request Optimized Hosted CI

Use this after local validation when a PR is ready for GitHub Actions
confirmation:

```text
+ci-run-hosted
```

The command dispatches hosted workflows for the current head SHA, creates
`ready-for-hosted-ci` if needed, and adds it so future pushes on the PR keep
running optimized hosted CI. Hosted CI is still path-selected by
`script/ci-changes-detector`; it does not automatically run every hosted suite.

### `+ci-force-full` - Request Force-Full Hosted CI

Use this only when a maintainer intentionally wants to bypass optimized suite
selection:

```text
+ci-force-full
```

The command dispatches the same hosted workflows with `force_full_hosted: true`,
creates `ready-for-hosted-ci` and `force-full-hosted-ci`, and keeps future pushes
in force-full mode until `+ci-stop-full` removes the override.

### Stop And Waiver Commands

```text
+ci-stop-hosted
```

Removes both hosted labels so future commits return to the required gate only.

```text
+ci-stop-full
```

Removes only `force-full-hosted-ci`. If `ready-for-hosted-ci` remains, future
commits keep running optimized hosted CI.

```text
+ci-skip-hosted docs-only change; markdown checks are enough
```

Records a SHA-bound hosted-CI waiver. The waiver does not cancel or block any
workflow run and does not apply after another push.

`+ci-status` summarizes labels, the current SHA, the docs-only heuristic, and
whether a waiver exists for the current SHA. `+ci-help` prints the command list.

## Human, Agent, And Workflow-Token Paths

Actor matters because GitHub Actions ignores `pull_request` label events created
by a workflow's `GITHUB_TOKEN`:

- A maintainer or local user token can run `bin/request-hosted-ci` from a PR
  branch or add `ready-for-hosted-ci` directly. That user-token label event can
  start the hosted `pull_request` workflows.
- `+ci-run-hosted` and `+ci-force-full` run inside GitHub Actions. They dispatch
  workflows for the current head SHA first, then add labels for future pushes.
- Agents should prefer comment commands at the final readiness gate because they
  leave a PR-visible audit trail. During active implementation churn, use
  `+ci-status` first and avoid starting hosted runs prematurely.

Fork PRs cannot use comment-command hosted CI to dispatch same-repository
workflows or add persistent labels. A maintainer should push a trusted branch to
this repository when release-target, Pro, or secret-backed CI is required.

## Dependency Profiles

- Only latest dependency versions (Ruby 4.0, Node 22) are used by the latest
  local CI profile and latest hosted Ruby-package matrix entries.
- Minimum dependency coverage stays explicit in matrix jobs that validate the
  supported floor.

## Why This Exists

PRs should not spend hosted runner time before local checks have caught routine
failures. The required gate stays fast and stable for every PR update; optimized
hosted CI confirms the ready branch; force-full hosted CI is a separate
maintainer decision for broad matrix coverage. Draft PRs are still useful for
early review and bots, but draft/open/ready-for-review state is not the hosted CI
trigger.

## Security And Access Control

Only repository collaborators with write access can trigger hosted CI commands.
This prevents resource abuse, unauthorized access to Pro package tests, and
repeated runner allocation from external comments.

The workflow first filters comment authors to `OWNER`, `MEMBER`, or
`COLLABORATOR` associations, then verifies repository write access before
executing a command. The job-level `contains('+ci-')` prefilter is intentionally
broad because GitHub Actions expressions do not support regular expressions;
the script strips quoted/code blocks and only executes commands at the start of
a comment line.

## Testing Comment-Triggered Workflows

Comment-triggered workflows (`issue_comment`) execute from the default branch
(`main`), not from the PR branch. When changing `ci-commands.yml`, validate the
YAML and script locally, merge the workflow change, then test commands on a
follow-up PR.

## Post-Merge Exercise Follow-Ups

Semantic changes to `.github/workflows/**` or `.github/actions/**` require a
linked `Follow-up:` issue before merge. The follow-up exists to prove behavior
that cannot be fully exercised from the original PR branch, especially
default-branch event handling such as `issue_comment`.

Use this title:

```text
Follow-up: Exercise GitHub Actions changes from PR #NNNN
```

The issue body must include:

- Source PR
- Changed workflow/action files
- Exact post-merge event, command, or secondary verification PR to exercise
- Expected evidence, such as run links, PR comments, labels, artifacts, or check
  conclusions
- Cleanup instructions for any verification-only PR
- Owner, if known

This requirement applies to trigger, permission, job, matrix, condition,
concurrency, secret, reusable-action, command-parsing, workflow-dispatch, and
CI-routing behavior changes. It does not apply to comments, docs, typo fixes,
formatting-only changes, or non-semantic actionlint cleanup when the PR evidence
documents that classification.

## Available Workflows

### CI Workflows

- `ci-required.yml` - Fast required PR gate
- `lint-js-and-ruby.yml` - JavaScript and Ruby lint/type checks
- `package-js-tests.yml` - JavaScript unit tests for packages
- `gem-tests.yml` - RSpec tests for the Ruby package
- `integration-tests.yml` - Dummy app integration tests
- `precompile-check.yml` - Assets precompile validation
- `examples.yml` - Generator tests for example apps
- `playwright.yml` - Playwright E2E tests
- `pro-integration-tests.yml` - Pro package integration tests
- `pro-test-package-and-gem.yml` - Pro package tests and linting

### Utility Workflows

- `ci-commands.yml` - Handles `+ci-*` PR comments
- `detect-invalid-ci-commands.yml` - Guides users away from old slash commands
- `pr-welcome-comment.yml` - Auto-comments on new PRs with helpful info
- `check-markdown-links.yml` - Validates markdown links

### Code Review Workflows

- `claude.yml` - Claude AI code review
- `claude-code-review.yml` - Additional Claude code review checks

## Workflow Permissions

Most workflows use minimal permissions. Comment-triggered workflows require:

- `contents: read` - read repository code
- `pull-requests: read` - inspect PR metadata and changed files
- `issues: write` - post comments, labels, and reactions
- `actions: write` - dispatch hosted workflows for comment commands

## Conditional Execution

Hosted workflows use the shared `.github/actions/hosted-ci-selectors` action and
job-level conditions:

- Ordinary PR updates run the required gate only unless `ready-for-hosted-ci`,
  `force-full-hosted-ci`, a same-repository non-Dependabot release-target base
  branch, a trusted Dependabot `+ci-*` dispatch, or a release-branch push allows
  hosted jobs.
- Generator-sensitive PRs are stricter: if change detection sets
  `run_generators=true`, `ci-required / required-pr-gate` fails on ordinary PRs
  until hosted CI is requested.
- `ready-for-hosted-ci` permits hosted jobs, but the change detector still
  selects applicable suites.
- `force-full-hosted-ci` or `workflow_dispatch` with `force_full_hosted: true`
  bypasses optimized selection and marks every suite as applicable.
- Pushes to `main`, pushes to release branches, merge queue, and
  same-repository non-Dependabot release-target PRs may use broad
  version/dependency matrices, but still respect detector outputs unless
  force-full hosted CI is active. Dependabot PRs need trusted current-head
  `+ci-run-hosted` or `+ci-force-full` dispatch proof before hosted jobs are
  enabled.

Release-target names are centralized in the selector action: `release/*`,
`releases/*`, and `release-*` for PR base branches. Release-train push events
use `refs/heads/release/*`.

## Hosted Workflow Maintenance Checklist

When adding or changing an expensive PR workflow, update the workflow, command
dispatcher, and docs together:

1. Keep the fast required gate in `ci-required.yml`; do not make heavyweight
   jobs the only required PR signal.
2. Include `pull_request` events for normal PR updates and label changes:
   `opened`, `synchronize`, `reopened`, `ready_for_review`, `labeled`, and
   `unlabeled`.
3. Include `push` to `main` and release branches, `merge_group`, and
   `workflow_dispatch` when the workflow is part of merge or release confidence.
4. Avoid workflow-level `paths` or `paths-ignore` when branch protection or
   hosted CI policy depends on the workflow starting. Use job-level conditions
   after checkout and change detection.
5. Use `.github/actions/hosted-ci-selectors` in the detector job and grant
   `issues: read` so it can inspect PR labels.
6. Gate heavyweight jobs on both hosted eligibility and detector outputs, for
   example `should_run_hosted_ci == 'true' && run_js_tests == 'true'`.
7. Use `should_use_full_matrix` only for matrix breadth decisions; do not treat
   `ready-for-hosted-ci` as a request to bypass optimized selection.
8. Add the workflow to `.github/workflows/ci-commands.yml` when
   `+ci-run-hosted` or `+ci-force-full` should dispatch it for the exact current
   head SHA.
9. Update `internal/contributor-info/ci-optimization.md`, `CONTRIBUTING.md`,
   `AGENTS.md`, and `.agents/workflows/pr-processing.md` when the request or
   readiness process changes.
