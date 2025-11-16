# CI Optimization Guide

This document explains the CI optimization strategy implemented for React on Rails.

## Overview

The CI pipeline has been optimized to:

1. **Skip unnecessary workflows** for documentation-only changes
2. **Run reduced test matrices on PRs** (full matrix only on master)
3. **Provide local CI tooling** to run appropriate tests before pushing

## Optimization Strategies

### 1. Path-Based Filtering

All workflows now use `paths-ignore` to skip when only certain files change:

```yaml
on:
  pull_request:
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

**Benefits:**

- Documentation changes don't trigger CI
- Workflows skip when irrelevant files change
- Reduces GitHub Actions minutes usage

### 2. Change Detection

The main test workflow includes a `detect-changes` job that:

- Analyzes which files changed
- Determines if tests are needed
- Skips downstream jobs for docs-only changes

**Example:**

```yaml
jobs:
  detect-changes:
    runs-on: ubuntu-22.04
    outputs:
      skip_tests: ${{ steps.changes.outputs.skip_tests }}
    steps:
      - name: Detect changes
        # ... analyzes git diff
```

### 3. Reduced Test Matrix on PRs

On PRs, we run a reduced test matrix for faster feedback:

| Environment   | Master Branch   | Pull Requests |
| ------------- | --------------- | ------------- |
| Ruby versions | 3.2, 3.4        | 3.4 only      |
| Node versions | 20, 22          | 22 only       |
| Dependencies  | minimum, latest | latest only   |

**Benefits:**

- ~75% reduction in CI time for PRs
- Faster feedback for developers
- Full coverage still runs on master before release

**Implementation:**

```yaml
matrix:
  ruby-version: ${{ github.ref == 'refs/heads/master' && fromJSON('["3.2", "3.4"]') || fromJSON('["3.4"]') }}
  node-version: ${{ github.ref == 'refs/heads/master' && fromJSON('["20", "22"]') || fromJSON('["22"]') }}
```

### 4. Smart Path Filtering per Workflow

Each workflow ignores paths that don't affect its tests:

- **JS tests**: Skip when only Ruby files change (`lib/**`, `spec/react_on_rails/**`)
- **Ruby tests**: Skip when only JS files change (`packages/react-on-rails/src/**`)
- **All tests**: Skip for docs-only changes

## Local CI Tools

### `bin/ci-local` - Smart Local CI Runner

Runs appropriate CI checks based on your changes:

```bash
# Auto-detect what to test based on changes
bin/ci-local

# Run all CI checks (same as master)
bin/ci-local --all

# Run only fast checks
bin/ci-local --fast

# Compare against specific branch
bin/ci-local origin/develop
```

**Features:**

- Analyzes your git diff
- Skips unnecessary tests
- Shows clear success/failure summary
- Provides feedback before pushing

### `script/ci-changes-detector` - Change Analysis Tool

Analyzes which files changed and recommends CI jobs:

```bash
# Check changes since master
script/ci-changes-detector origin/master

# Check changes between any refs
script/ci-changes-detector origin/develop HEAD
```

**Output:**

```
=== CI Changes Analysis ===
Changed file categories:
  • Ruby source code
  • JavaScript/TypeScript code

Recommended CI jobs:
  ✓ Lint (Ruby + JS)
  ✓ RSpec gem tests
  ✓ JS unit tests
  ✓ Dummy app integration tests
```

### `/run-ci` Claude Command

Claude Code command for interactive CI execution:

```
/run-ci
```

Claude will:

1. Analyze your changes
2. Show recommended CI jobs
3. Ask which option you prefer
4. Execute and report results

## CI Workflow Reference

### Workflows and Their Triggers

| Workflow                   | Runs On           | Skips For        | Matrix Reduction       |
| -------------------------- | ----------------- | ---------------- | ---------------------- |
| `main.yml`                 | Code changes      | Docs only        | Yes (75% faster)       |
| `lint-js-and-ruby.yml`     | Code changes      | Docs only        | No (already fast)      |
| `examples.yml`             | Generator changes | Docs only        | Yes (50% faster)       |
| `package-js-tests.yml`     | JS changes        | Docs, Ruby files | Yes (50% faster)       |
| `rspec-package-specs.yml`  | Ruby changes      | Docs, JS files   | Yes (75% faster)       |
| `check-markdown-links.yml` | Markdown changes  | Non-docs         | No (already optimized) |

## Expected Time Savings

### Before Optimization

- PR with code changes: ~45 minutes (all matrices)
- PR with docs changes: ~45 minutes (unnecessary)
- Total CI time per day: High

### After Optimization

- PR with code changes: ~12 minutes (reduced matrix)
- PR with docs changes: 0 minutes (skipped)
- Master merge: ~45 minutes (full matrix)
- Total CI time saved: ~70%

## Best Practices

### For Developers

1. **Run local CI before pushing:**

   ```bash
   bin/ci-local
   ```

2. **Use fast mode for quick checks:**

   ```bash
   bin/ci-local --fast
   ```

3. **Separate doc changes from code changes:**

   - Docs-only PRs skip CI entirely
   - Mixed PRs run full CI

4. **Trust the PR CI:**
   - Reduced matrix is sufficient for most changes
   - Master branch validates full matrix before release

### For Maintainers

1. **Monitor CI performance:**

   - Check GitHub Actions usage
   - Identify slow tests
   - Adjust matrix as needed

2. **Update path filters:**

   - Add new file patterns as project evolves
   - Keep filters accurate

3. **Review master CI failures:**
   - Master runs full matrix
   - Catches edge cases not found in PR CI

## Troubleshooting

### CI not skipping for docs changes

Check if:

- Changes are truly docs-only (use `git diff --name-only`)
- Path patterns match your files
- Workflow has correct `paths-ignore`

### CI taking too long on PRs

- Ensure you're not on master branch
- Check if matrix reduction is working
- Use `bin/ci-local --fast` for local testing

### Tests pass locally but fail in CI

- Different dependency versions
- Environment differences
- Run `bin/ci-local --all` to match CI exactly

## Future Improvements

Potential further optimizations:

1. **Parallel test execution** within jobs
2. **Smarter caching** of dependencies
3. **Test splitting** for faster execution
4. **Conditional job dependencies** based on changes
5. **Reusable workflows** to reduce duplication

## Related Files

- `script/ci-changes-detector` - Change detection script
- `bin/ci-local` - Local CI runner
- `.claude/commands/run-ci.md` - Claude command
- `.github/workflows/*.yml` - All CI workflows
