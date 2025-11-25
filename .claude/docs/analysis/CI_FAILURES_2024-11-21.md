# CI Failure Analysis - Branch justin808/monorepo-completion

**Date**: 2025-11-21
**PR**: #2069
**Analyst**: Claude Code Review
**Status**: 🔴 NOT READY TO MERGE - Multiple Test Failures

---

## ⚠️ CRITICAL DISCLAIMER

**This analysis contains UNTESTED hypotheses only.**

**Environment**: Analysis performed in Conductor isolated workspace with limited capabilities:

- ❌ Cannot run full Rails application
- ❌ Cannot execute integration tests
- ❌ Cannot test webpack build pipeline
- ❌ Cannot verify fixes against actual failing tests
- ✅ Can analyze CI logs and source code
- ✅ Can identify suspicious commits
- ✅ Can provide reproduction steps

**What this means**:

- All "fixes" below are **hypotheses that MUST be tested locally**
- Do NOT assume any proposed fix will work without verification
- All investigation is based on log analysis and code inspection only
- Actual root causes may differ from analysis after local testing

**Before implementing any fix**: Test it locally in the actual React on Rails repository first.

---

## Executive Summary

**All tests PASSED on merge base** (`5e033c716` - v16.2.0.beta.12) ✅
**Current Status**: 3 test suites FAILING, 1 test suite HUNG (80+ minutes)

This is a **REGRESSION** introduced by changes in this branch related to:

1. Monorepo restructuring (Phase 5: Pro Node Renderer extraction)
2. `buildConsoleReplay` parameter order fix
3. Workspace dependency changes

---

## Failing Test Suites

### 1. Integration Tests - JavaScript Asset Loading ❌

**Configurations**: Both `minimum` (Ruby 3.2, Node 20) and `latest` (Ruby 3.4, Node 22)
**Duration**: Failed after 2m26s - 2m36s
**Failed Examples**: 21 failures

#### Error Pattern

```text
Uncaught SyntaxError: Unexpected token '<'
```

At line numbers: 167, 199, 211, 226, 239, 253, 267, 274 in HTML pages

#### Root Cause Analysis

JavaScript files returning HTML (404 pages) instead of JavaScript code. The browser attempts to execute HTML as JavaScript, causing syntax errors.

**Evidence**:

- ✅ Webpack bundles restored from cache successfully
- ✅ `yarn install` completes without errors
- ✅ Some webpack files load correctly (e.g., `/webpack/test/js/890.js`)
- ❌ Most component-specific bundles fail to load

**What This Means**:
The webpack infrastructure partially works, but specific bundles aren't being generated or served correctly. This suggests:

1. Build artifacts may not be created during `yarn install` (prepare scripts)
2. Asset paths may be incorrect after monorepo restructuring
3. Rails may be looking for bundles in the wrong location

#### Sample Failing Tests

```text
Pages/Index when rendering All in one page
  with Server Rendered/Cached React/Redux Component
    ✗ is expected to have visible css "div#ReduxApp-react-component-0"
    ✗ changes name in message according to input
  with Server Rendered/Cached React Component Without Redux
    ✗ is expected to have visible css "div#HelloWorld-react-component-1"
    ✗ changes name in message according to input
  with Simple Client Rendered Component
    ✗ is expected to have visible css "div#HelloWorldApp-react-component-2"
    ✗ changes name in message according to input
```

**Total Impact**: All React component rendering tests fail

---

### 2. Pro Node Renderer Tests - Console Replay Format ❌

**Configuration**: Ruby 3.3.7
**Duration**: Failed after 4m58s
**Failed Examples**: 1 failure

#### Error Details

```ruby
Failure/Error: expect(script_line).to eq(expected_line)

  expected: "console.log.apply(console, [\"[SERVER] RENDERED ReduxSharedStoreApp to dom node with id: ReduxSharedStoreApp-react-component-0\"]);"
       got: "<script id=\"consoleReplayLog\">"
```

**Test File**: `react_on_rails_pro/spec/dummy/spec/requests/renderer_console_logging_spec.rb:52`

#### Root Cause Analysis

The test uses Nokogiri to extract text content from `<script id="consoleReplayLog">` tags:

```ruby
script_nodes = html_nodes.css("script#consoleReplayLog")
script_text = script_nodes.map(&:text).join("\n")
script_lines = script_text.split("\n")
```

**Expected behavior**: `script_lines[0]` should be the first console statement
**Actual behavior**: `script_lines[0]` is `"<script id=\"consoleReplayLog\">"`

**Possible Causes**:

1. HTML structure changed - Nokogiri not finding the correct nodes
2. buildConsoleReplay output format changed
3. Node renderer not correctly processing console replay
4. Test parsing logic broken

#### Related Changes

Commit `09f8c27cb` - "Fix buildConsoleReplay parameter order":

- Changed signature: `(consoleHistory, messages)` → `(messages, consoleHistory, nonce)`
- Updated Pro call site in `streamingUtils.ts`
- May have inadvertently changed output format

---

### 3. Pro Package JS Tests - HUNG ⏳

**Configuration**: Ubuntu 22.04, Node.js, Redis 6.2.6
**Status**: Running for 80+ minutes (normal: 1-3 minutes)
**Command**: `yarn workspace react-on-rails-pro-node-renderer run ci`

#### Test Configuration

```yaml
services:
  redis:
    image: cimg/redis:6.2.6
    ports:
      - 6379:6379
```

**Jest Command**: `jest --ci --runInBand --reporters=default --reporters=jest-junit`

#### Possible Causes

1. **Test waiting for timeout** - Infinite loop or stuck async operation
2. **Redis connection issue** - Tests hanging on Redis operations
3. **Missing build artifacts** - Tests can't import required modules
4. **Jest configuration** - `--runInBand` runs serially; one hung test blocks all

**Note**: Logs unavailable while test is running

#### Recommendation

🛑 **CANCEL CI RUN** - it's wasting resources after 80 minutes

---

## Suspicious Commits

### High Priority Suspects

#### 1. `09f8c27cb` - Fix buildConsoleReplay parameter order ⚠️

**When**: 3 hours ago
**Changes**:

- Fixed parameter order in `buildConsoleReplay()`
- Updated Pro package call in `streamingUtils.ts`

**Why Suspicious**:

- **Directly related** to Pro Node Renderer console replay test failure
- Changed function signature and all call sites
- May have changed output format

**Code Changes**:

```typescript
// Before
buildConsoleReplay(consoleHistory, previouslyReplayedConsoleMessages);

// After
buildConsoleReplay(previouslyReplayedConsoleMessages, consoleHistory, nonce);
```

---

#### 2. `c124df6c0` - Fix workspace dependencies and build scripts ⚠️⚠️

**When**: 2 hours ago
**Changes**:

- Modified `package-scripts.yml` paths
- Changed prepare scripts in package.json files
- Added conditional: `"prepare": "[ -f lib/ReactOnRails.full.js ] || yarn run build"`

**Why Suspicious**:

- **Most likely cause** of integration test asset failures
- Changed how/when packages are built
- Modified critical infrastructure code

**Files Changed**:

```text
package-scripts.yml (path updates)
packages/react-on-rails-pro-node-renderer/package.json
packages/react-on-rails-pro/package.json
packages/react-on-rails/package.json
```

---

#### 3. `002d07423` - Update react_on_rails_pro build paths ⚠️

**Why Suspicious**:

- Updated Pro package build paths after node-renderer extraction
- Could have broken asset path resolution
- Related to monorepo restructuring

---

### Medium Priority Suspects

- `6ae74c2b8` - Phase 5: Add Pro Node Renderer Package to workspace
- `83b21f217` - Fix node-renderer package.json and knip configuration
- `82021be66` - Remove invalid exports from react_on_rails_pro/package.json
- `e7befce71` - don't use yalc in a yarn workspace

---

## What Still Works ✅

**22 checks passing**:

- ✅ Linting (JS and Ruby)
- ✅ Markdown link checks
- ✅ RSpec gem specs
- ✅ Package tests (non-Pro)
- ✅ Examples generation
- ✅ Build processes
- ✅ Pro lint
- ✅ Dummy app webpack bundle building

**Local verification**:

- ✅ `packages/react-on-rails/lib/` contains all built files
- ✅ `buildConsoleReplay.js` has correct function signature
- ✅ TypeScript compilation successful

**CI verification**:

- ✅ Webpack bundles cached and restored
- ✅ Node modules installed successfully
- ✅ Bundles present in `spec/dummy/public/webpack`

---

## Debugging Strategy

### Step 1: Reproduce Locally

From `.claude/docs/testing-build-scripts.md`:

```bash
# Test clean install (CRITICAL)
rm -rf node_modules packages/*/lib
yarn install --frozen-lockfile

# Verify build artifacts created
ls -la packages/react-on-rails/lib/ReactOnRails.full.js
ls -la packages/react-on-rails-pro/lib/ReactOnRails.full.js
ls -la packages/react-on-rails-pro-node-renderer/lib/ReactOnRailsProNodeRenderer.js

# Test prepare scripts
yarn nps build.prepack

# Test yalc publish
yarn run yalc:publish

# Run failing integration tests
cd spec/dummy
bundle exec rspec spec/system/integration_spec.rb

# Run failing Pro tests
cd react_on_rails_pro/spec/dummy
bundle exec rspec spec/requests/renderer_console_logging_spec.rb

# Test hung Pro JS tests
cd packages/react-on-rails-pro-node-renderer
timeout 5m yarn run ci
```

### Step 2: Compare with Base Commit

```bash
# Checkout base commit
git checkout 5e033c716

# Run same tests
cd spec/dummy
bundle exec rspec spec/system/integration_spec.rb

# Note differences in:
# - Generated HTML
# - Asset paths
# - Console replay output
# - Webpack bundle locations
```

### Step 3: Bisect Breaking Commit

```bash
# Binary search through 52 commits
git bisect start
git bisect bad HEAD
git bisect good 5e033c716

# For each bisect step:
yarn install --frozen-lockfile
cd spec/dummy
bundle exec rspec spec/system/integration_spec.rb:23
git bisect good/bad
```

---

## Fix Recommendations

**⚠️ IMPORTANT: All recommendations below are UNTESTED hypotheses based on CI log analysis.**

**Testing Limitation**: This analysis was performed in a Conductor isolated workspace without:

- Full Rails application environment
- Webpack build pipeline
- Database/Redis services
- Integration test infrastructure

**All proposed fixes MUST be tested locally in the actual React on Rails repository before claiming they work.**

---

### Priority 1: Integration Test Asset Loading (CRITICAL) 🔥

**Status**: ⚠️ UNTESTED HYPOTHESIS

**Hypothesis**: Prepare scripts don't run correctly in workspace context, OR webpack output paths changed.

**Investigation**:

1. Check CI logs for prepare script execution during `yarn install`
2. Verify webpack output directory matches Rails expectations
3. Check if workspace-based builds work differently than monorepo root builds

**Potential Fixes**:

- Ensure prepare scripts execute during CI's `yarn install`
- Verify all package.json "prepare" scripts are correct
- Check if `yarn workspace` commands need different configuration
- Restore previous package-scripts.yml paths if incorrect

**Test After Fix**:

```bash
rm -rf node_modules packages/*/lib
yarn install --frozen-lockfile
cd spec/dummy
bundle exec rspec spec/system/integration_spec.rb:23
```

---

### Priority 2: Pro Console Replay Test 🟡

**Status**: ⚠️ UNTESTED HYPOTHESIS

**Hypothesis**: buildConsoleReplay parameter fix changed output format OR test HTML parsing broken.

**Investigation**:

1. Run test locally with verbose output
2. Inspect actual HTML generated
3. Check if `wrapInScriptTags` output changed
4. Verify Nokogiri extracts text correctly

**Potential Fixes**:

- Update test expectations if format intentionally changed
- Fix buildConsoleReplay if output is broken
- Debug why Nokogiri returns tag instead of text

**Test After Fix**:

```bash
cd react_on_rails_pro/spec/dummy
bundle exec rspec spec/requests/renderer_console_logging_spec.rb:13 --format documentation
```

---

### Priority 3: Hung Pro JS Tests 🟡

**Status**: ⚠️ UNTESTED HYPOTHESIS

**Immediate**: Cancel the 80+ minute CI run

**Investigation**:

```bash
cd packages/react-on-rails-pro-node-renderer
timeout 5m yarn run ci --verbose
```

**Potential Fixes**:

- Add Jest timeout configuration
- Check Redis connection in tests
- Verify all imports resolve correctly
- Add `--forceExit` flag temporarily
- Run with `--detectOpenHandles` to find hanging promises

**Test After Fix**:

```bash
yarn workspace react-on-rails-pro-node-renderer run ci
```

---

## Prevention Strategies

### Add CI Validation (from testing-build-scripts.md)

```yaml
# .github/workflows/validate-build.yml
- name: Validate workspace dependencies
  run: |
    ! grep -r '".*": "workspace:\*"' packages/*/package.json || {
      echo "ERROR: Use '*' not 'workspace:*' for Yarn Classic"
      exit 1
    }

- name: Validate prepare scripts create artifacts
  run: |
    rm -rf node_modules packages/*/lib
    yarn install --frozen-lockfile
    test -f packages/react-on-rails/lib/ReactOnRails.full.js
    test -f packages/react-on-rails-pro/lib/ReactOnRails.full.js
    test -f packages/react-on-rails-pro-node-renderer/lib/ReactOnRailsProNodeRenderer.js
```

### Document Build Path Changes

When changing directory structure:

1. Update ALL path references in configuration files
2. Search codebase: `grep -r "old/path"`
3. Test scripts: `yarn run prepack`, `yarn run yalc.publish`
4. Run full test suite before committing

---

## Timeline of Events

1. **Base commit** `5e033c716` - All tests passing ✅
2. **52 commits later** - Multiple test failures ❌
3. **Key commit** `09f8c27cb` - buildConsoleReplay parameter order fix
4. **Key commit** `c124df6c0` - Workspace dependencies and build scripts
5. **Current state** - 3 failing + 1 hung test suite

---

## Conclusion

This branch is **NOT READY TO MERGE**. The monorepo restructuring introduced regressions that need investigation and fixes:

1. **JavaScript asset loading broken** - Most critical, blocks all integration tests
2. **Console replay format issue** - Fixable, likely test expectation update needed
3. **Hung Jest tests** - Needs local reproduction and debugging

**Estimated Time to Fix**: 4-8 hours

- 2-4 hours: Reproduce and debug integration test asset issue
- 1-2 hours: Fix console replay test
- 1-2 hours: Debug hung Jest tests

**Risk Level**: Medium-High

- Changes affect core infrastructure (prepare scripts, build paths)
- Multiple interdependent failures suggest deeper architectural issue
- Long history (52 commits) makes bisecting time-consuming

**Recommendation**:

1. ❌ **DO NOT MERGE** until all tests pass
2. 🔍 Reproduce failures locally
3. 🐛 Debug systematically using bisect or commit-by-commit review
4. ✅ Add CI validations to prevent regression
5. 📝 Document any intentional breaking changes
