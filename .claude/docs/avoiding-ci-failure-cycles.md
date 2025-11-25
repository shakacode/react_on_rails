# Avoiding CI Failure Cycles

**Last Updated**: 2024-11-24
**Context**: Lessons learned from monorepo restructure PR #2114

## The Problem: CI Failure Whack-a-Mole

### What It Looks Like

```
commit: "Fix path in workflow"          → CI fails (different error)
commit: "Fix RSpec config"              → CI fails (another error)
commit: "Fix gitignore patterns"        → CI fails (yet another error)
commit: "Fix examples workflow"         → CI fails (still more errors)
commit: "Fix bundle commands"           → CI fails (...)
... 20+ "fix" commits later ...
```

**Real Data from PR #2114**:

- 30 commits total
- 19 were "Fix" commits (63%)
- Multiple workflows failing repeatedly
- Pattern: push → CI fail → fix → push → CI fail → fix...

### Why This Happens

1. **Large-scale changes made without comprehensive testing**
   - Directory structure changes affect MANY files
   - Not understanding full scope of impact

2. **Using CI as the test environment**
   - Treating CI like a linter that tells you what to fix
   - Not running equivalent tests locally first

3. **Incremental fixing without holistic testing**
   - Fix one thing, break another
   - Each fix tested in isolation
   - Missing interaction effects

4. **Not leveraging available tools**
   - CI replication tools exist but not used
   - Local test commands available but not run

## ⚠️ CRITICAL: Large-Scale Change Checklist

Use this **BEFORE pushing any commit** that touches infrastructure, configs, or multiple directories.

### Phase 1: Plan and Understand Impact

**Before changing ANYTHING**:

```bash
# 1. Identify all files that reference what you're changing
grep -r "old/path" . --exclude-dir=node_modules --exclude-dir=.git

# 2. List all affected file types
# - Workflows: .github/workflows/*.yml
# - Configs: *.config.*, .eslintrc*, .rubocop.yml, etc.
# - Build scripts: package.json, package-scripts.yml, Rakefile
# - Tests: spec/**/*_spec.rb, **/*.test.js
# - Documentation: *.md
```

**Document your findings**:

- Create a checklist of files to update
- Identify which CI workflows will be affected
- List which local commands test each affected area

### Phase 2: Make Changes in Testable Chunks

**DO NOT change everything at once**. Break into logical units:

```
✅ Good:
  1. Update directory structure
  2. Test locally
  3. Update workflows
  4. Test locally
  5. Update configs
  6. Test locally

❌ Bad:
  1. Change everything
  2. Push
  3. Wait for CI
  4. Fix what breaks
  5. Repeat
```

### Phase 3: Local Testing (MANDATORY)

**NEVER push without running these first**:

#### A. Linting (Fast - Always Run)

```bash
# Ruby
bundle exec rubocop

# JavaScript/TypeScript
yarn run lint

# Or both
rake lint
```

#### B. Build Scripts (If you changed package.json, configs, or paths)

```bash
# CRITICAL: Clean install test
rm -rf node_modules
yarn install --frozen-lockfile

# Build all packages
yarn run build

# Test yalc publish
yarn run yalc:publish

# Verify artifacts exist
ls -la packages/*/lib/*.js
```

**See**: [testing-build-scripts.md](testing-build-scripts.md) for details.

#### C. Unit Tests (If you changed code)

```bash
# Ruby tests
bundle exec rake run_rspec:gem

# JavaScript tests
yarn run test
```

#### D. Integration Tests (If you changed configs, workflows, or infrastructure)

```bash
# Dummy app tests
bundle exec rake run_rspec:dummy

# Example generation (if you changed generators)
bundle exec rake run_rspec:shakapacker_examples
```

#### E. CI Simulation (For large changes)

```bash
# Use the tools! Don't wait for CI!
bin/ci-rerun-failures --help

# Or run specific CI job equivalents
# See CLAUDE.md "Replicating CI Failures Locally" section
```

### Phase 4: Commit Strategy

**Single Logical Units**:

```bash
✅ Good Commits:
  - "Update directory structure for monorepo"
  - "Update all workflow paths for new structure"
  - "Update configs for new structure"

❌ Bad Commits:
  - "Fix path in one workflow"
  - "Fix another path"
  - "Fix RSpec config"
  - "Fix another config"
  ... (20 more "fix" commits)
```

**Commit Messages Should Indicate Testing**:

```
✅ "Update workflows for monorepo structure

Tested with:
- bin/ci-rerun-failures (all checks passed)
- yarn build && yarn run yalc:publish (verified)
- bundle exec rake run_rspec:gem (all tests pass)"

❌ "Fix workflow paths"
```

### Phase 5: Push Strategy

**Before Pushing**:

1. ✅ All local tests passed
2. ✅ Linting passed
3. ✅ Build scripts tested (if relevant)
4. ✅ Commit message documents what was tested

**After Pushing**:

```bash
# Poll CI status every 30 seconds until completion
while true; do
  gh pr view --json statusCheckRollup --jq '.statusCheckRollup | group_by(.conclusion) | map({conclusion: .[0].conclusion, count: length})'
  sleep 30
done

# Or use the automated tool (polls every 30s):
bin/ci-rerun-failures

# If failures occur:
# 1. Check if they're new (not pre-existing)
# 2. Reproduce locally FIRST
# 3. Fix and test locally
# 4. Don't push "hopeful" fixes
```

**IMPORTANT: Poll every 30 seconds, NOT 180 seconds.** CI jobs typically complete in 3-15 minutes, so 30-second polling gives responsive feedback.

**See**: [master-health-monitoring.md](master-health-monitoring.md)

## Red Flags: When to STOP and Test More

**If you see these patterns, STOP pushing and test comprehensively**:

🚩 **Multiple "Fix" commits in a row**

- You're using CI as a test environment
- Switch to local testing

🚩 **CI keeps failing on different tests**

- You're breaking things you didn't know about
- Run broader local test suite

🚩 **"This should fix it" without local verification**

- You're guessing
- Test before pushing

🚩 **Changing configs without testing build**

- Silent failures are dangerous
- Test the full build pipeline

🚩 **Path changes without comprehensive grep**

- You're missing references
- Search the entire codebase

## Tool Arsenal: Use Before Asking CI

### Finding All References

```bash
# Find all references to a path
grep -r "old/path" . --exclude-dir=node_modules --exclude-dir=.git

# Find all config files
find . -name "*.config.*" -o -name ".*rc*" -o -name "*.yml"

# Find all workflow files
ls -la .github/workflows/
```

### Testing Before Pushing

```bash
# Replicate CI locally
bin/ci-rerun-failures

# Run specific failed examples
bin/ci-run-failed-specs

# Switch to minimum dependencies
bin/ci-switch-config minimum
bundle exec rake run_rspec:gem
bin/ci-switch-config latest

# Test examples generation
bundle exec rake run_rspec:shakapacker_examples
```

### Monitoring After Push

```bash
# Check PR CI status
gh pr view --json statusCheckRollup

# View specific run
gh run view <run-id>

# Rerun failed jobs
bin/ci-rerun-failures
```

## Case Study: PR #2114 Monorepo Restructure

### What Went Wrong

**Initial Approach**:

1. Made massive directory structure change
2. Pushed without comprehensive local testing
3. Discovered issues via CI
4. Fixed issues incrementally
5. Each fix introduced new issues
6. 19 "Fix" commits over several days

**Root Causes**:

- Didn't grep for all path references before starting
- Didn't test build scripts locally
- Didn't test example generation locally
- Used CI failures as a TODO list instead of testing locally
- Fixed things in isolation without testing interactions

### What Should Have Happened

**Better Approach**:

**Phase 1: Planning**

```bash
# Before touching anything:
grep -r "lib/" . --exclude-dir=node_modules --exclude-dir=.git > path-references.txt
grep -r "spec/dummy" . --exclude-dir=node_modules --exclude-dir=.git > dummy-references.txt
# ... analyze all references ...
```

**Phase 2: Comprehensive Testing**

```bash
# After making changes, before first push:
rm -rf node_modules && yarn install --frozen-lockfile
yarn run build
yarn run yalc:publish
bundle exec rubocop
bundle exec rake run_rspec:gem
bundle exec rake run_rspec:dummy
bundle exec rake run_rspec:shakapacker_examples
```

**Phase 3: Single Large Commit**

```
"Restructure monorepo with two top-level product directories

Move react_on_rails gem into react_on_rails/ subdirectory.
Update all paths, configs, workflows, and build scripts.

Tested with:
- Clean install and yalc publish: ✅
- Full RSpec suite (gem, dummy, examples): ✅
- Linting (RuboCop, ESLint): ✅
- Build artifacts verification: ✅
```

**Result**: 1 commit instead of 20, CI passes on first try.

## The 15-Minute Rule

**BEFORE pushing any commit, ask yourself**:

> "If I spent 15 more minutes testing locally, would I discover this issue before CI does?"

If the answer is **YES**, spend the 15 minutes.

**Why?**

- Local iteration: seconds to minutes
- CI iteration: 10-30 minutes per cycle
- Context switching cost: high
- Interrupted flow: breaks concentration
- Team impact: broken master blocks others

**15 minutes of local testing saves hours of CI iteration**

## Summary: The Virtuous Cycle

```
❌ Vicious Cycle (What Not To Do):
   Change → Push → CI Fails → Fix → Push → CI Fails → Fix → ...

✅ Virtuous Cycle (Do This):
   Change → Test Locally → Fix → Test Locally → Push → CI Passes
```

**Key Principles**:

1. **Understand impact before changing** (grep, analyze, document)
2. **Test comprehensively before pushing** (not just linting)
3. **Use available tools** (CI replication, local test commands)
4. **Commit logical units** (not incremental fixes)
5. **Monitor after push** (check CI within 30 minutes)

**Remember**: CI is for **verification**, not **development**. Do your testing locally.

---

## Related Documentation

- [testing-build-scripts.md](testing-build-scripts.md) - Build script testing requirements
- [master-health-monitoring.md](master-health-monitoring.md) - Post-merge monitoring
- [pr-testing-agent.md](pr-testing-agent.md) - Comprehensive PR testing guide
- [CLAUDE.md](../../CLAUDE.md) - Full development guide
- [SWITCHING_CI_CONFIGS.md](../../SWITCHING_CI_CONFIGS.md) - Testing minimum vs latest
