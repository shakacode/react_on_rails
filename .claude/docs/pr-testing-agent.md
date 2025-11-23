# PR Testing Agent

**Role:** Specialized agent for comprehensive PR testing validation before merge.

**Core Principle:** Be deeply suspicious of claims that tests passed unless you have concrete evidence. Assume automated tests have gaps. Manual testing is often required.

## Quick Reference

**Related Documentation:**

- [Testing Build Scripts](.claude/docs/testing-build-scripts.md) - Build/package testing requirements
- [CI Config Switching](../SWITCHING_CI_CONFIGS.md) - Testing minimum vs latest dependencies
- [Local Testing Issues](../spec/dummy/TESTING_LOCALLY.md) - Environment-specific testing issues
- [Master Health Monitoring](.claude/docs/master-health-monitoring.md) - Post-merge CI monitoring
- [CLAUDE.md](../CLAUDE.md) - Full development guide with CI debugging

**Jump to Section:**

- [When to Use This Agent](#when-to-use-this-agent)
- [Testing Requirements by Change Type](#testing-requirements-by-change-type)
- [Pre-Merge Testing Checklist](#pre-merge-testing-checklist)
- [Success Criteria](#success-criteria-well-tested-pr)
- [Real-World Scenarios](#real-world-testing-scenarios)

## When to Use This Agent

### Automatic Invocation (Recommended)

**Invoke this agent automatically when:**

- Creating a PR (before `gh pr create`)
- Responding to PR review comments about testing
- CI failures occur and need investigation
- Asked to verify if a PR is "ready to merge"

### Manual Invocation

**Explicitly request this agent when:**

- Validating testing claims in PR descriptions
- Reviewing someone else's PR for testing adequacy
- Unsure what testing is needed for specific changes
- Need a comprehensive testing checklist

### How to Invoke

**This is a documentation reference, not an automated tool.** Use it by:

1. **Manual reference**: Read this document when creating PRs or reviewing testing
2. **AI assistant prompt**: Ask your AI coding assistant to "follow the PR Testing Agent guidelines" or "validate testing using PR Testing Agent criteria"
3. **Code review checklist**: Reference specific sections during PR reviews
4. **CI failure investigation**: Use the testing checklists when debugging failures

**Example prompts for AI assistants:**

```
"Use the PR Testing Agent guidelines to validate my testing before I create this PR"

"Following the PR Testing Agent checklist, what testing is missing for these build config changes?"

"Apply PR Testing Agent criteria: Is this PR ready to merge from a testing perspective?"
```

## Integration with Existing Workflows

### Relationship to Code Review

**This agent complements but does not replace:**

- Standard code review for logic, design, and maintainability
- The `code-reviewer` agent (focuses on code quality, security)
- CI automated checks (provides guidance when they fail)

**This agent specializes in:**

- Testing verification and validation
- Identifying untested code paths
- Catching silent failures in build/infrastructure
- Providing testing checklists based on change type
- Translating CI failures to local reproduction steps

### Integration with Development Workflow

**Pre-commit:**

- Git hooks handle linting/formatting automatically
- Agent focuses on which tests to run manually

**Pre-push:**

- Agent validates testing claims before PR creation
- Generates comprehensive testing checklist
- Identifies environmental testing limitations

**During CI:**

- Agent helps reproduce CI failures locally
- Distinguishes pre-existing vs. new failures
- Maps CI failures to local test commands

**Pre-merge:**

- Agent validates all testing completed
- Ensures manual testing gaps documented
- Reviews PR description for testing claims

### Workflow Example

```bash
# 1. Make code changes
vim lib/react_on_rails/helper.rb

# 2. Run relevant tests locally (agent suggests which)
bundle exec rspec spec/react_on_rails/helper_spec.rb

# 3. Commit (hooks auto-lint)
git commit -m "Fix helper method"

# 4. Before pushing, consult agent
# "What testing do I need before creating a PR for helper.rb changes?"
# Agent responds with checklist

# 5. Complete testing checklist
cd spec/dummy
bin/dev
# Test in browser...

# 6. Create PR with testing documentation
git push
gh pr create  # Include testing summary from agent

# 7. If CI fails, consult agent again
# "CI is failing on integration tests, help me reproduce locally"
# Agent provides exact commands

# 8. Before merge, final validation
# "Is this PR ready to merge from a testing perspective?"
# Agent reviews what was tested vs. what's still needed
```

## Agent Behavior

### Default Stance: Skeptical

**ALWAYS assume:**

- ✅ Claims like "tests pass" need verification
- ✅ CI passing doesn't mean comprehensive testing occurred
- ✅ Automated tests have blind spots
- ✅ Build scripts, package changes, and infrastructure require manual testing
- ✅ "Should work" is not the same as "verified working"

### Communication Style

**Be crystal clear about:**

- What was tested vs. what wasn't
- What MUST be manually tested before merge
- Testing gaps in CI
- Environmental limitations (Conductor workspace, missing services, etc.)

**Use explicit language:**

- ❌ DON'T: "Tests pass" (vague)
- ✅ DO: "Unit tests pass locally. Integration tests require manual verification (see checklist below)"

- ❌ DON'T: "This should fix it"
- ✅ DO: "UNTESTED FIX - Requires manual verification: Run `rake run_rspec:dummy` and confirm no SSL errors"

## Testing Requirements by Change Type

### 1. Ruby Code Changes

**Automated (CI covers):**

- ✅ RSpec unit tests (`rake run_rspec:gem`)
- ✅ RuboCop linting (`bundle exec rubocop`)
- ✅ RBS type validation (`rake rbs:validate`)

**Manual verification required:**

- ⚠️ Runtime type checking disabled? (`DISABLE_RBS_RUNTIME_CHECKING=true`)
- ⚠️ Changes to Rails engine behavior (test in dummy app)
- ⚠️ Generator changes (test actual generation: `rake run_rspec:example_basic`)

**Before declaring "fixed":**

```bash
# MUST run locally:
bundle exec rubocop                    # Zero violations
bundle exec rake run_rspec:gem         # All unit tests pass
bundle exec rake rbs:validate          # Type signatures valid

# If working in Conductor workspace, CLEARLY STATE:
# "UNTESTED - requires full Rails environment not available in Conductor workspace"
```

### 2. JavaScript/TypeScript Changes

**Automated (CI covers):**

- ✅ Jest unit tests (`yarn run test`)
- ✅ TypeScript compilation (`yarn run type-check`)
- ✅ ESLint (`yarn run lint`)
- ✅ Prettier formatting (`yarn start format.listDifferent`)

**Manual verification required:**

- ⚠️ Browser-side behavior (visual inspection in dummy app)
- ⚠️ Server-side rendering works (check SSR output in browser)
- ⚠️ Component registration (`ReactOnRails.register({ ... })`)

**Before declaring "fixed":**

```bash
# MUST run locally:
yarn run test                          # All JS tests pass
yarn run type-check                    # TypeScript compiles
yarn run build                         # Build succeeds
bundle exec rake autofix               # Formatting applied

# MUST test in browser:
cd spec/dummy
bin/dev                                # Start servers
# Visit http://localhost:3000/hello_world
# Open browser console - check for errors
```

### 3. Build Configuration Changes

**CRITICAL: These changes REQUIRE extensive manual testing**

Changes to any of these files trigger **MANDATORY manual testing checklist:**

- `package.json` (workspace config, dependencies, scripts)
- `package-scripts.yml` (prepack, prepare, yalc scripts)
- `webpack.config.js` / `config/webpack/*`
- `Gemfile` / `Gemfile.development_dependencies`
- `.github/workflows/*` (CI configuration)

**MANDATORY Manual Testing Checklist:**

```bash
# Step 1: Clean install (MOST CRITICAL)
rm -rf node_modules yarn.lock
yarn install --frozen-lockfile
# ❌ STOP if this fails - nothing else matters

# Step 2: Test build scripts
yarn run build
ls -la packages/react-on-rails/lib/ReactOnRails.full.js
# ❌ STOP if artifact missing

# Step 3: Test prepack
yarn nps build.prepack
# ❌ STOP if this fails

# Step 4: Test yalc publish (critical for local dev)
yarn run yalc:publish
# ❌ STOP if this fails

# Step 5: Test package structure
yarn workspaces info
# Verify workspace linking

# Step 6: Run test suite
bundle exec rake
```

**Why this matters:**

- See `.claude/docs/testing-build-scripts.md` for real examples of silent failures
- Build scripts run during `npm install`, `yalc publish`, and package installation
- Failures are often SILENT in CI but break users completely

**If working in Conductor workspace:**

```
❌ CANNOT test build scripts in isolated workspace
⚠️  MANUAL TESTING REQUIRED before merge:
    1. Clone PR branch in full repo environment
    2. Run complete checklist above
    3. Document results in PR comment
```

### 4. Webpack/Shakapacker Configuration Changes

**Manual verification REQUIRED:**

```bash
# Create debug script to inspect config:
cd spec/dummy
cat > debug-webpack.js << 'EOF'
const { generateWebpackConfig } = require('shakapacker');
const config = generateWebpackConfig();
console.log('Rules:', config.module.rules.length);
config.module.rules.forEach((rule, i) => {
  if (rule.test) {
    console.log(`Rule ${i}:`, rule.test,
      'matches .scss:', rule.test.test?.('file.scss'),
      'matches .module.scss:', rule.test.test?.('file.module.scss')
    );
  }
});
EOF

NODE_ENV=test RAILS_ENV=test node debug-webpack.js
rm debug-webpack.js

# Then test in browser:
bin/dev
# Visit app, check CSS modules work, check console for errors
```

**Common issues:**

- CSS modules breaking after Shakapacker upgrade
- Loader options not applied correctly
- Rules matching wrong file patterns

See CLAUDE.md "Debugging Webpack Configuration Issues" for full details.

### 5. CI Configuration Changes

**Check for pre-existing failures FIRST:**

```bash
# Before investigating ANY CI failure:
gh run list --workflow="Integration Tests" --branch master --limit 5 --json conclusion,createdAt

# Compare to PR branch:
gh run list --workflow="Integration Tests" --branch <pr-branch> --limit 10 --json conclusion,headSha,createdAt

# Key question: Did MY commits break it, or was it already broken?
```

**See `.claude/docs/testing-build-scripts.md` "Before You Start: Check CI Status"**

**Reproduce failures locally:**

```bash
# Check current config:
bin/ci-switch-config status

# Switch to minimum (if that's where failure is):
bin/ci-switch-config minimum
cd <project-root>  # Reload shell
ruby --version     # Verify 3.2.x
node --version     # Verify v20.x

# Run exact failing tests:
bin/ci-rerun-failures
# OR
pbpaste | bin/ci-run-failed-specs
```

**See `SWITCHING_CI_CONFIGS.md` for full details**

### 6. Generator Changes

**Manual testing REQUIRED:**

```bash
# Test generator in isolation:
rake run_rspec:example_basic

# Test in real Rails app:
cd /tmp
rails new test-ror --skip-javascript --database=postgresql
cd test-ror
# Add local gem path to Gemfile
bundle install
bin/rails generate react_on_rails:install
bin/dev
# Visit http://localhost:3000/hello_world
```

**Check:**

- ✅ Generated files have correct content
- ✅ Templates rendered properly
- ✅ bin/dev starts without errors
- ✅ Example component renders in browser

### 7. Playwright E2E Testing Changes

**When E2E tests are required:**

Changes affecting user-facing behavior require Playwright E2E verification:

- React component rendering/behavior changes
- Server-side rendering modifications
- React on Rails integration features (component registry, store registry)
- Rails view helpers (`react_component`, `react_component_hash`)
- Generator changes that affect generated code behavior

**Running Playwright tests:**

```bash
cd spec/dummy

# Install browsers (one-time setup):
yarn playwright install --with-deps

# Run all E2E tests (Rails server auto-starts):
yarn test:e2e

# Run in UI mode (interactive debugging):
yarn test:e2e:ui

# Run specific test file:
yarn test:e2e e2e/playwright/e2e/react_on_rails/basic_components.spec.js
```

**What to verify:**

- [ ] Components render in browser
- [ ] Server-side rendering produces correct HTML
- [ ] Client-side hydration works
- [ ] No JavaScript console errors
- [ ] Component interactions work as expected

**See CLAUDE.md "Playwright E2E Testing" section for:**

- Writing new tests with Rails integration
- Using factory_bot and database cleanup
- Debugging test failures

### 8. Rails Engine Changes

**Engine-specific testing:**

Changes to `lib/react_on_rails/engine.rb` or rake tasks require:

```bash
# Test rake task loading (not duplicate execution):
cd spec/dummy
bundle exec rake -T | grep react_on_rails
# Should see each task ONCE, not duplicated

# Test initializers run correctly:
bundle exec rails runner "puts ReactOnRails::VERSION"

# Test in host app context:
rake run_rspec:dummy
```

**Common pitfalls:**

- Rake tasks loaded twice (see Rails Engine Development Nuances in CLAUDE.md)
- Initializers run at wrong time
- Autoloading issues

## Environment-Specific Testing Limitations

### Conductor Workspace Limitations

**CANNOT test in Conductor workspace:**

- ❌ Full Rails app integration
- ❌ Browser-based testing
- ❌ Webpack/Shakapacker compilation
- ❌ Playwright E2E tests
- ❌ Build script failures that require clean install
- ❌ yalc publish workflows

**CAN test in Conductor workspace:**

- ✅ RuboCop linting
- ✅ RSpec unit tests (gem-only)
- ✅ Prettier formatting
- ✅ TypeScript compilation
- ✅ Jest unit tests

**When blocked by environment, CLEARLY STATE:**

```
⚠️  UNTESTED - Requires environment not available in Conductor workspace

MANUAL TESTING REQUIRED before merge:
1. Clone PR in full repo: git clone https://github.com/shakacode/react_on_rails.git
2. Checkout PR branch: gh pr checkout <PR-NUMBER>
3. Run: [exact commands needed]
4. Document results in PR comment

Cannot proceed without manual verification.
```

### Ruby 3.4.3 + OpenSSL 3.6 Limitations

**Known issue affecting local testing:**

- System tests may fail with SSL certificate errors
- Does NOT indicate code issues
- CI uses containerized environment and passes

**Workaround:**

```bash
# Switch to Ruby 3.2 for system tests:
mise use ruby@3.2
bundle install
cd spec/dummy
bundle exec rspec spec/system/integration_spec.rb
```

**See `spec/dummy/TESTING_LOCALLY.md` for details**

## Pre-Merge Testing Checklist

**Generate this checklist for EVERY PR:**

### Automated Tests (CI verifies)

- [ ] RuboCop passes (`bundle exec rubocop`)
- [ ] RSpec unit tests pass (`rake run_rspec:gem`)
- [ ] Jest tests pass (`yarn run test`)
- [ ] TypeScript compiles (`yarn run type-check`)
- [ ] RBS validation passes (`rake rbs:validate`)
- [ ] Prettier formatting applied (`rake autofix`)

### Manual Testing Required

**Based on files changed, check applicable items:**

#### If Ruby files changed:

- [ ] Run unit tests locally: `bundle exec rake run_rspec:gem`
- [ ] If helper.rb changed: Test in browser (dummy app)
- [ ] If engine.rb changed: Verify no duplicate rake tasks
- [ ] If generators changed: Test actual generation

#### If JS/TS files changed:

- [ ] Run tests locally: `yarn run test`
- [ ] Build succeeds: `yarn run build`
- [ ] Test in browser: `cd spec/dummy && bin/dev`
- [ ] Check browser console for errors
- [ ] If SSR code changed: Verify SSR output in page source

#### If build configs changed:

- [ ] **MANDATORY**: Clean install test: `rm -rf node_modules && yarn install --frozen-lockfile`
- [ ] **MANDATORY**: Build test: `yarn run build && ls -la packages/react-on-rails/lib/`
- [ ] **MANDATORY**: Prepack test: `yarn nps build.prepack`
- [ ] **MANDATORY**: yalc publish test: `yarn run yalc:publish`
- [ ] Workspace linking: `yarn workspaces info`
- [ ] Full test suite: `bundle exec rake`

#### If webpack configs changed:

- [ ] Create debug script to inspect webpack config
- [ ] Test in browser with `bin/dev`
- [ ] Check CSS modules work
- [ ] Check console for webpack errors

#### If CI configs changed:

- [ ] Verify not pre-existing failures: `gh run list --branch master`
- [ ] Reproduce failures locally: `bin/ci-rerun-failures`
- [ ] Test both configs if needed: `bin/ci-switch-config minimum`

#### If generators changed:

- [ ] Test in example: `rake run_rspec:example_basic`
- [ ] Test in fresh Rails app (see checklist above)

#### If user-facing behavior changed (React components, SSR, view helpers):

- [ ] Run Playwright E2E tests: `cd spec/dummy && yarn test:e2e`
- [ ] Verify components render in browser
- [ ] Check server-side rendering in view source
- [ ] No JavaScript console errors
- [ ] Component interactions work as expected

#### If Rails engine changed:

- [ ] Check rake tasks not duplicated: `bundle exec rake -T | grep react`
- [ ] Test initializers: `bundle exec rails runner "puts ReactOnRails::VERSION"`
- [ ] Integration tests: `rake run_rspec:dummy`

### Environment Limitations

**Mark any testing blocked by environment:**

```markdown
⚠️ **UNTESTED** - Blocked by [Conductor workspace / Ruby 3.4 SSL / missing service]

**Required before merge:**

1. [Specific testing steps]
2. [Environment requirements]
3. [Expected results]

**Reviewer**: Please verify these items manually.
```

## Success Criteria: Well-Tested PR

**A PR is well-tested when it meets ALL of these criteria:**

### 1. Automated Testing

✅ **All CI checks pass:**

- RuboCop: 0 violations
- RSpec unit tests: All passing
- Jest tests: All passing
- TypeScript: Compiles without errors
- RBS validation: Types valid
- Prettier: All files formatted

### 2. Local Verification

✅ **Tests run locally before pushing:**

- Relevant test suite executed (unit, integration, or E2E based on changes)
- Test results documented in PR description or commit message
- Any test failures investigated and resolved

### 3. Manual Testing (Change-Dependent)

✅ **Appropriate manual testing completed:**

- **For build changes**: Clean install, prepack, yalc publish tested
- **For UI changes**: Browser testing with visual inspection
- **For SSR changes**: View source to verify HTML output
- **For generator changes**: Tested generation in fresh Rails app
- **For webpack changes**: Debug script created, config verified

### 4. Testing Documentation

✅ **PR includes clear testing documentation:**

```markdown
## Testing

### Automated Tests

- [x] RuboCop: 0 violations
- [x] RSpec: 42 examples, 0 failures
- [x] Jest: 15 tests passed

### Manual Testing

- [x] Tested in browser: Components render correctly
- [x] Server-side rendering verified in view source
- [x] No console errors

### Environment Limitations

- [ ] Integration tests require full Rails app (not available in Conductor)
      Documented commands for reviewer verification below
```

### 5. Clear Communication

✅ **Testing status is explicit and honest:**

- Uses "UNTESTED" label when verification not possible
- Distinguishes verified fixes from hypothetical fixes
- Documents environmental limitations clearly
- Provides exact reproduction steps for reviewers

### 6. No Regressions

✅ **Changes don't break existing functionality:**

- Existing tests still pass
- No new console errors introduced
- Build artifacts still generated correctly
- No performance degradation (if measurable)

### 7. CI Failure Investigation

✅ **If CI fails, proper investigation done:**

- Checked if failures pre-existed on master
- Reproduced failures locally (or documented why not possible)
- Identified root cause (not just "fixed randomly")
- Verified fix locally before pushing

## Communicating Test Status

### In PR Comments

**Template for test status comment:**

```markdown
## Testing Status

### ✅ Verified Locally

- [x] RuboCop: 0 violations
- [x] RSpec unit tests: 127 examples, 0 failures
- [x] Jest tests: 42 passed
- [x] Build artifacts present at expected paths

### ⚠️ Requires Manual Verification

**Build scripts** - CRITICAL: Clean install test in full environment

    rm -rf node_modules && yarn install --frozen-lockfile
    yarn run yalc:publish

**Browser testing** - Dummy app visual inspection

    cd spec/dummy && bin/dev
    # Visit http://localhost:3000/hello_world
    # Check console for errors

### ❌ Cannot Test (Environment Limitation)

- Integration tests require full Rails app (not available in Conductor workspace)
- Documented exact commands for reviewer verification above

### 📋 CI Status

- Latest workflow: [link]
- Known pre-existing failures: None (master passing)
- New failures introduced: None
```

### In Commit Messages

**Document what was tested:**

```
Fix webpack CSS modules configuration for Shakapacker 9

- Override namedExport: false to maintain compatibility
- Set exportLocalsConvention to camelCase

Tested locally:
- Created debug script to verify loader options
- Confirmed CSS modules import as default export
- Verified in browser: styles apply correctly
- No console errors

Requires manual verification:
- Full webpack build in production mode
- Test in actual app with Shakapacker 9.3.0
```

## Real-World Testing Scenarios

### Scenario 1: "I fixed the RSpec failures"

❌ **Insufficient:**

> "Fixed the RSpec failures by updating the matcher syntax"

✅ **Required:**

````markdown
Fixed RSpec failures in helper_spec.rb

Changes:

- Updated matcher syntax for RSpec 3.12 compatibility

Verified locally:

```bash
$ bundle exec rspec spec/react_on_rails/helper_spec.rb
42 examples, 0 failures
```
````

CI Status: All checks passing (see run #1234)

````

### Scenario 2: "I updated package.json dependencies"

❌ **Insufficient:**
> "Updated React to 19.0.0, tests pass"

✅ **Required:**
```markdown
Update React to 19.0.0

Verified locally:
- [x] Clean install: `rm -rf node_modules && yarn install --frozen-lockfile` ✅
- [x] Build: `yarn run build` ✅
- [x] Artifacts: `ls -la packages/react-on-rails/lib/ReactOnRails.full.js` ✅
- [x] yalc publish: `yarn run yalc:publish` ✅
- [x] Tests: `yarn run test` (42 passed) ✅
- [x] Browser: Dummy app renders correctly ✅

Tested in dummy app:
```bash
cd spec/dummy
bin/dev
# Visited http://localhost:3000/hello_world
# ✅ Component renders
# ✅ No console errors
# ✅ React DevTools shows React 19.0.0
````

````

### Scenario 3: "CI is failing but I can't reproduce locally"

❌ **Insufficient:**
> "Not sure why CI fails, works for me"

✅ **Required:**
```markdown
Investigating CI failures in Integration Tests workflow

Status: Cannot reproduce locally in Conductor workspace

Pre-existing failure check:
```bash
$ gh run list --workflow="Integration Tests" --branch master --limit 5
# Result: Master passing ✅
# Conclusion: Failures introduced by this PR
````

Environment limitation:
⚠️ Working in Conductor isolated workspace - cannot run full Rails app

Required manual testing (for reviewer or local environment):

```bash
# Clone PR in full environment:
gh pr checkout 1234

# Test integration:
bundle exec rake run_rspec:dummy

# Expected: All integration tests pass
# If fails: [describe failure and potential fix]
```

Hypothesis: [Your analysis of what might be wrong]
Proposed fix: [Your fix with UNTESTED label if not verified]

````

## Integration with Existing Tools

**Use the project's testing tools:**

```bash
# Check CI failures:
bin/ci-rerun-failures

# Run specific failed examples:
pbpaste | bin/ci-run-failed-specs

# Switch CI configs to reproduce:
bin/ci-switch-config minimum

# View CI status:
gh pr view --json statusCheckRollup
````

**Reference documentation:**

- Testing build scripts: `.claude/docs/testing-build-scripts.md`
- CI debugging: `CLAUDE.md` "Replicating CI Failures Locally"
- Config switching: `SWITCHING_CI_CONFIGS.md`
- Local testing issues: `spec/dummy/TESTING_LOCALLY.md`
- Master health: `.claude/docs/master-health-monitoring.md`

## Summary: Agent Mindset

**Always assume:**

1. "Tests pass" needs verification (show me the output)
2. CI passing ≠ comprehensive testing (check what CI actually tests)
3. Build changes need manual testing (ALWAYS)
4. Environment matters (Conductor ≠ full Rails app)
5. "Should work" ≠ "verified working" (test it or mark UNTESTED)

**Always communicate:**

1. What you tested vs. what you didn't
2. What needs manual verification before merge
3. Environmental limitations blocking testing
4. Exact commands to reproduce/verify
5. Clear distinction between verified fixes and hypothetical fixes

**Before saying "ready to merge":**

- ✅ All automated tests pass
- ✅ All manual testing completed OR clearly documented as required
- ✅ No environmental limitations blocking critical tests OR workaround documented
- ✅ PR comment clearly states what was tested and what needs review
