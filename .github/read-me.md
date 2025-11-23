# GitHub Actions CI/CD Configuration

This directory contains GitHub Actions workflows for continuous integration and deployment.

## PR Comment Commands

### `/run-skipped-ci` (or `/run-skipped-tests`) - Run Full CI Suite

When you open a PR, CI automatically runs a subset of tests for faster feedback (latest Ruby/Node versions only). To run the **complete CI suite** including all dependency combinations, add a comment to your PR:

```
/run-skipped-ci
# or use the shorter alias:
/run-skipped-tests
```

This command will trigger:

- ✅ Main test suite with both latest and minimum supported versions
- ✅ All example app generator tests
- ✅ React on Rails Pro integration tests
- ✅ React on Rails Pro package tests

The bot will:

1. React with a 🚀 to your comment
2. Post a confirmation message with links to the triggered workflows
3. Start all CI jobs on your PR branch

### Why This Exists

By default, PRs run a subset of CI jobs to provide fast feedback:

- Only latest dependency versions (Ruby 3.4, Node 22)
- Skips example generator tests
- Skips some Pro package tests

This is intentional to keep PR feedback loops fast. However, before merging, you should verify compatibility across all supported versions. The `/run-skipped-ci` (or `/run-skipped-tests`) command makes this easy without waiting for the PR to be merged to master.

### Security & Access Control

**Only repository collaborators with write access can trigger full CI runs.** This prevents:

- Resource abuse from external contributors
- Unauthorized access to Pro package tests
- Potential DoS attacks via repeated CI runs

If an unauthorized user attempts to use `/run-skipped-ci` or `/run-skipped-tests`, they'll receive a message explaining the restriction.

### Concurrency Protection

Multiple `/run-skipped-ci` or `/run-skipped-tests` comments on the same PR will cancel in-progress runs to prevent resource waste and duplicate results.

## Testing Comment-Triggered Workflows

**Important**: Comment-triggered workflows (`issue_comment` event) only execute from the **default branch** (master). This creates a chicken-and-egg problem when developing workflow changes.

### Recommended Testing Approach

1. **Develop the workflow**: Create/modify the workflow in your feature branch
2. **Test locally**: Validate YAML syntax and logic as much as possible
3. **Merge to master**: The workflow must be in master to be triggered by comments
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
- **`pro-package-tests.yml`** - Pro package unit tests
- **`pro-lint.yml`** - Pro package linting

### Utility Workflows

- **`run-skipped-ci.yml`** - Triggered by `/run-skipped-ci` or `/run-skipped-tests` comment on PRs
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
- `pull-requests: write` - To post comments and reactions
- `actions: write` - To trigger other workflows

## Required Secrets for Pro Workflows

Workflows that test React on Rails Pro features require the following repository secret:

### `REACT_ON_RAILS_PRO_LICENSE_V2`

This secret contains the Pro license key needed to run Pro features during CI. It must be configured as a repository secret in GitHub Actions.

**Workflows that require this secret:**

- `examples.yml` - When generating/testing examples with Pro features
- `integration-tests.yml` - When running integration tests that may use Pro features
- Any workflow that runs example apps or tests that might invoke Pro functionality

**Setting up the secret:**

1. Go to repository Settings → Secrets and variables → Actions
2. Add a new secret named `REACT_ON_RAILS_PRO_LICENSE_V2`
3. Set the value to a valid React on Rails Pro license key

**When adding new workflows:**
If your workflow runs any Rails application that might have the Pro gem available (example apps, dummy apps, integration tests), add this environment variable:

```yaml
env:
  REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.REACT_ON_RAILS_PRO_LICENSE_V2 }}
```

This prevents license validation failures during test runs in the monorepo where both MIT and Pro packages are present.

## Conditional Execution

Many workflows use change detection to skip unnecessary jobs:

- Runs all jobs on pushes to `master`
- Runs only relevant jobs on PRs based on changed files
- Can be overridden with `workflow_dispatch` or `/run-skipped-ci` (or `/run-skipped-tests`) command

See `script/ci-changes-detector` for the change detection logic.
