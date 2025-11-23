# PR Testing Guide

**Companion to:** [PR Testing Agent](pr-testing-agent.md)

This guide shows you **how to use** the PR Testing Agent with Claude Code, including workflows, checklists, templates, and real-world examples.

## Quick Navigation

**Jump to Section:**

- [When to Use This Agent](#when-to-use-this-agent)
- [Using with Claude Code](#using-with-claude-code)
- [Integration with Workflows](#integration-with-existing-workflows)
- [Pre-Merge Testing Checklist](#pre-merge-testing-checklist)
- [Communicating Test Status](#communicating-test-status)
- [Real-World Scenarios](#real-world-testing-scenarios)

**Related Documentation:**

- **[PR Testing Agent](pr-testing-agent.md)** - Core agent behavior and requirements
- [Testing Build Scripts](testing-build-scripts.md) - Build/package testing requirements
- [CI Config Switching](../../SWITCHING_CI_CONFIGS.md) - Testing minimum vs latest dependencies
- [CLAUDE.md](../../CLAUDE.md) - Full development guide

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

## Using with Claude Code

### Quick Start

**The easiest way to use this agent with Claude Code is to explicitly reference it in your prompts:**

```
"Use the PR Testing Agent from .claude/docs/pr-testing-agent.md to validate my testing"

"I changed package.json. According to PR Testing Agent Section 3, what testing is required?"

"Generate a testing checklist for my changes using the PR Testing Agent Pre-Merge Checklist"
```

### Common Workflows

#### 1. Before Creating a PR

```
# After making changes and committing:
"I modified lib/react_on_rails/helper.rb. According to the PR Testing Agent,
what testing do I need before creating a PR?"

# Claude Code will reference Section 1 (Ruby Code Changes) and provide checklist
```

#### 2. Validating Your Testing

```
"Based on PR Testing Agent success criteria, is my testing adequate?
Here's what I tested: [paste your test output]"

# Claude Code will check against the 7 Success Criteria
```

#### 3. Generating PR Testing Documentation

```
"Generate a Testing Status section for my PR description using the
PR Testing Agent template from 'Communicating Test Status'"

# Claude Code will create formatted testing documentation
```

#### 4. Investigating CI Failures

```
"CI is failing on integration tests. Help me reproduce locally following
PR Testing Agent process."

# Claude Code will guide you through Section 5 (CI Configuration Changes)
```

#### 5. Code Review

```
"Review this PR description and identify missing testing according to
PR Testing Agent standards"

# Claude Code applies skeptical stance and identifies gaps
```

### Referencing Specific Sections

**For targeted help, reference specific sections by number or name:**

```
# By section number:
"Show me the MANDATORY testing checklist from PR Testing Agent Section 3"

# By change type:
"I modified webpack.config.js. Use PR Testing Agent Section 4
(Webpack/Shakapacker Configuration Changes) to tell me what to test"

# By checklist:
"Generate the Pre-Merge Testing Checklist for build configuration changes"

# By success criteria:
"Does this PR meet PR Testing Agent Success Criteria #4 (Testing Documentation)?"
```

### Complete Example Workflow

Here's a full example of using the agent throughout the PR lifecycle:

```bash
# 1. Make changes
vim lib/react_on_rails/helper.rb
git add .
git commit -m "Fix helper method"

# 2. Ask Claude Code for testing guidance
```

**Prompt to Claude Code:**

```
"I changed lib/react_on_rails/helper.rb. According to PR Testing Agent
Section 1 (Ruby Code Changes), what testing do I need?"
```

**Claude Code responds with checklist:**

````markdown
Based on PR Testing Agent Section 1, you need:

### Automated (will run in CI):

- ✅ RSpec unit tests
- ✅ RuboCop linting
- ✅ RBS type validation

### Manual verification required:

- [ ] Run unit tests locally: `bundle exec rake run_rspec:gem`
- [ ] If helper affects browser behavior: Test in dummy app
- [ ] Ensure RuboCop passes: `bundle exec rubocop`

### Before declaring "fixed":

```bash
bundle exec rubocop
bundle exec rake run_rspec:gem
bundle exec rake rbs:validate
```
````

````

```bash
# 3. Complete the testing
bundle exec rubocop
bundle exec rake run_rspec:gem
# (tests pass)

# 4. Ask for validation
````

**Prompt to Claude Code:**

```
"Based on PR Testing Agent Success Criteria, is my testing adequate?
I ran: bundle exec rubocop (0 violations), rake run_rspec:gem (all passed)"
```

**Claude Code validates:**

```markdown
Checking against PR Testing Agent Success Criteria:

✅ 1. Automated Testing - RuboCop and RSpec passed
✅ 2. Local Verification - Tests run before pushing
⚠️ 3. Manual Testing - Did you test in browser if helper affects UI?
❌ 4. Testing Documentation - Need to document in PR description
...

Recommendation: Add testing documentation to PR description before creating PR.
```

```bash
# 5. Generate PR documentation
```

**Prompt to Claude Code:**

```
"Generate a Testing Status section for my PR using PR Testing Agent template"
```

**Claude Code provides:**

```markdown
## Testing Status

### ✅ Verified Locally

- [x] RuboCop: 0 violations
- [x] RSpec unit tests: 15 examples, 0 failures
- [x] RBS validation: Types valid

### Manual Testing

- [x] Unit tests cover helper method changes
- [x] No browser-facing changes - UI testing not required

### CI Status

- All checks pending (will run after push)
```

```bash
# 6. Create PR with documentation
git push
gh pr create  # Include generated testing section

# 7. If CI fails, investigate
```

**Prompt to Claude Code:**

```
"CI failing on dummy app integration tests. Use PR Testing Agent to help
me reproduce locally."
```

**Claude Code guides:**

```bash
# Following PR Testing Agent Section 5 (CI Configuration Changes):

# Step 1: Check if pre-existing
gh run list --workflow="Integration Tests" --branch master --limit 5

# Step 2: Reproduce locally
bin/ci-rerun-failures

# Step 3: If specific failures
pbpaste | bin/ci-run-failed-specs
```

### Tips for Effective Use

**1. Be specific about sections:**

```
✅ "Use PR Testing Agent Section 3 Build Configuration checklist"
❌ "What testing do I need?"
```

**2. Reference by change type:**

```
✅ "I changed package.json. PR Testing Agent guidelines?"
❌ "Should I test this?"
```

**3. Ask for validation:**

```
✅ "Does this meet PR Testing Agent Success Criteria?"
❌ "Is this good enough?"
```

**4. Request templates:**

```
✅ "Generate testing documentation using PR Testing Agent template"
❌ "Write a testing section"
```

### What Claude Code Can Do

**Claude Code can:**

- ✅ Read the PR Testing Agent document directly when referenced
- ✅ Apply guidelines to your specific changes
- ✅ Generate checklists based on files you modified
- ✅ Validate testing against the 7 Success Criteria
- ✅ Create formatted testing documentation
- ✅ Identify testing gaps using the skeptical approach
- ✅ Suggest specific commands from the relevant section

**Claude Code cannot:**

- ❌ Automatically run the tests for you (you still need to execute commands)
- ❌ Access your browser to verify UI changes
- ❌ Know if tests passed without you providing the output
- ❌ Push commits or create PRs automatically

### Automatic Context

**The PR Testing Agent guidelines are automatically available when:**

- You reference `.claude/docs/pr-testing-agent.md` in prompts
- You mention "PR Testing Agent" or "testing checklist"
- You ask about testing requirements for specific file types
- CLAUDE.md is loaded (which references this documentation)

**No special setup needed** - just reference it in your prompts!

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

- Testing build scripts: [testing-build-scripts.md](testing-build-scripts.md)
- CI debugging: [CLAUDE.md](../../CLAUDE.md) "Replicating CI Failures Locally"
- Config switching: [SWITCHING_CI_CONFIGS.md](../../SWITCHING_CI_CONFIGS.md)
- Local testing issues: [spec/dummy/TESTING_LOCALLY.md](../../spec/dummy/TESTING_LOCALLY.md)
- Master health: [master-health-monitoring.md](master-health-monitoring.md)
