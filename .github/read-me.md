# GitHub Actions CI/CD Configuration

This directory contains GitHub Actions workflows for continuous integration and deployment.

## PR Comment Commands

### `+ci-run-full` - Run Full CI Suite

When you open a PR, CI automatically runs a subset of tests for faster feedback (latest Ruby/Node versions only). To run the **complete CI suite** including all dependency combinations, add a comment to your PR:

```
+ci-run-full
```

Post one CI command per comment. If a comment contains multiple `+ci-*` commands, the command workflow handles only the first one.

This command will trigger:

- ✅ Main test suite with both latest and minimum supported versions
- ✅ All example app generator tests
- ✅ React on Rails Pro integration tests
- ✅ React on Rails Pro package tests

`+ci-run-full` dispatches this manually maintained workflow map:

- **Lint JS and Ruby** (`lint-js-and-ruby.yml`)
- **JS unit tests for Renderer package** (`package-js-tests.yml`)
- **Rspec test for gem** (`gem-tests.yml`)
- **Integration Tests** (`integration-tests.yml`)
- **Assets Precompile Check** (`precompile-check.yml`)
- **Generator tests** (`examples.yml`)
- **React on Rails Pro - Integration Tests** (`pro-integration-tests.yml`)
- **React on Rails Pro - Package Tests** (`pro-test-package-and-gem.yml`)

When adding or removing a full-CI-capable workflow, update both this list and the `workflowMap` in `ci-commands.yml`.

The bot will:

1. React to your comment (`rocket` when workflows are triggered, `confused` when the command cannot run)
2. Post a confirmation message with links to the triggered workflows
3. Start all CI jobs on your PR branch

### Why This Exists

By default, PRs run a subset of CI jobs to provide fast feedback:

- Only latest dependency versions (Ruby 4.0, Node 22)
- Skips example generator tests
- Skips some Pro package tests

This is intentional to keep PR feedback loops fast. However, before merging high-risk changes, you should verify compatibility across all supported versions. The `+ci-run-full` command makes this easy without waiting for the PR to be merged to main.

For low-risk or docs-only changes where a maintainer intentionally does not want full CI, use:

```
+ci-skip-full docs-only change; markdown checks are enough
```

The reason is optional. The bot records the current PR head SHA so the waiver is auditable and does not apply after another push. It does not cancel or block workflow runs.

### Security & Access Control

**Only repository collaborators with write access can trigger full CI runs.** This prevents:

- Resource abuse from external contributors
- Unauthorized access to Pro package tests
- Potential DoS attacks via repeated CI runs

The workflow first filters comment authors to `OWNER`, `MEMBER`, or `COLLABORATOR` associations to avoid allocating runners for obvious external mentions. The script still verifies repository write access before executing any command. If an unauthorized associated user attempts to use `+ci-run-full`, they'll receive a message explaining the restriction.

### Concurrency Protection

Multiple CI command comments on the same PR run one at a time so a status/help command cannot interrupt a full-CI dispatch.

## Testing Comment-Triggered Workflows

**Important**: Comment-triggered workflows (`issue_comment` event) only execute from the **default branch** (main). This creates a chicken-and-egg problem when developing workflow changes.

### Recommended Testing Approach

1. **Develop the workflow**: Create/modify the workflow in your feature branch
2. **Test locally**: Validate YAML syntax and logic as much as possible
3. **Merge to main**: The workflow must be in main to be triggered by comments
4. **Test on a PR**: Create a test PR and use the comment command to verify

### Why This Limitation Exists

GitHub Actions workflows triggered by `issue_comment` events always use the workflow definition from the default branch, not the PR branch. This is a security feature to prevent malicious actors from modifying workflows through PRs.

For more details, see [GitHub's documentation on issue_comment events](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#issue_comment).

## Available Workflows

### CI Workflows (Triggered on Push/PR)

- **`main.yml`** - Main test suite (dummy app integration tests)
- **`lint-js-and-ruby.yml`** - Linting for JavaScript and Ruby code
- **`package-js-tests.yml`** - JavaScript unit tests for the package
- **`rspec-package-specs.yml`** - RSpec tests for the Ruby package
- **`examples.yml`** - Generator tests for example apps
- **`playwright.yml`** - Playwright E2E tests
- **`pro-integration-tests.yml`** - Pro package integration tests
- **`pro-test-package-and-gem.yml`** - Pro package unit tests and Pro Ruby/RBS/TypeScript linting

### Utility Workflows

- **`ci-commands.yml`** - Triggered by `+ci-*` comments on PRs
- **`run-skipped-ci.yml`** - Legacy workflow triggered by `/run-skipped-ci` or `/run-skipped-tests` comment on PRs
- **`pr-welcome-comment.yml`** - Auto-comments on new PRs with helpful info
- **`detect-changes.yml`** - Detects which parts of the codebase changed

### Code Review Workflows

- **`claude.yml`** - Claude AI code review
- **`claude-code-review.yml`** - Additional Claude code review checks

### Other Workflows

- **`check-markdown-links.yml`** - Validates markdown links

## Workflow Permissions

Most workflows use minimal permissions. The comment-triggered workflows require:

- `contents: read` - To read the repository code
- `pull-requests: read` - To inspect PR metadata and changed files
- `issues: write` - To post comments, labels, and reactions
- `actions: write` - To trigger other workflows

## Conditional Execution

Many workflows use change detection to skip unnecessary jobs:

- Runs all jobs on pushes to `main`
- Runs only relevant jobs on PRs based on changed files
- Can be overridden with `workflow_dispatch` or `+ci-run-full`

See `script/ci-changes-detector` for the change detection logic.
