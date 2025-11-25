# PR Splitting Strategy for CI Failures

## When to Split a Large PR

### Indicators That Splitting Makes Sense

1. **Multiple Independent Test Failures**
   - Different test suites failing for different reasons
   - Failures span multiple subsystems (integration, unit, Pro package, etc.)
   - Each failure requires significant debugging time

2. **Long Git History**
   - 50+ commits in the branch
   - Multiple feature changes mixed together
   - Hard to bisect or identify which commit broke what

3. **Mixed Concerns**
   - Infrastructure changes + feature changes
   - Multiple unrelated fixes bundled together
   - Refactoring mixed with new functionality

4. **Time Investment vs. Value**
   - Estimated fix time > 8 hours
   - Unknown number of additional failures lurking
   - Blocking other work that depends on parts of the PR

### Example: The Monorepo Completion PR

**Original PR #2069**: 52 commits, multiple failures

- Integration tests failing (JavaScript asset loading)
- Pro Node Renderer tests failing (console replay format)
- Pro JS tests hung (80+ minutes)
- Mix of: monorepo restructuring, buildConsoleReplay fix, workspace dependency changes

**Why it's a good candidate for splitting**:

- ✅ Multiple independent failures
- ✅ 52 commits make bisecting difficult
- ✅ Contains both infrastructure (monorepo) and bug fixes (buildConsoleReplay)
- ✅ Some parts might work independently
- ✅ Estimated 4-8 hours to fix all issues

---

## Strategy for Splitting

### Step 1: Identify Independent Commits

Look for commits that:

- ✅ Can stand alone without dependencies
- ✅ Have passing tests on their own
- ✅ Provide value independently
- ✅ Don't break existing functionality

**Example groups from PR #2069**:

```
Group 1 (Documentation & Analysis):
- CI failure analysis documents
- Testing requirement documentation
- CLAUDE.md updates

Group 2 (Build Console Replay Fix):
- buildConsoleReplay parameter order fix
- Test updates for new parameter order
- Related Pro package updates

Group 3 (Workspace Dependencies):
- Yarn Classic workspace syntax fixes
- Package.json prepare script updates
- Build path updates

Group 4 (Monorepo Node Renderer):
- Extract node-renderer package
- Update build workflows
- CI configuration changes
```

### Step 2: Determine Merge Order

**Principle**: Merge least risky changes first

1. **Documentation-only changes** (safest)
   - No code changes
   - No risk of breaking tests
   - Provides value immediately

2. **Bug fixes with tests** (safe if tests pass)
   - Clear, focused changes
   - Well-tested
   - Doesn't change infrastructure

3. **Refactoring with no behavior change** (moderate risk)
   - Keep tests passing
   - No API changes
   - Can be verified by running existing tests

4. **Infrastructure changes** (highest risk)
   - Save for last
   - Requires most careful testing
   - Most likely to have cascading effects

### Step 3: Create Split PRs

**For Each Independent Group**:

1. **Create new branch from master**

   ```bash
   git checkout master
   git pull --rebase
   git checkout -b feature/specific-focused-change
   ```

2. **Cherry-pick relevant commits**

   ```bash
   # Pick commits for this specific feature
   git cherry-pick <commit-hash>
   git cherry-pick <commit-hash>
   # etc.
   ```

3. **Test locally**

   ```bash
   # Ensure tests pass
   bundle exec rspec
   yarn test

   # Ensure linting passes
   bundle exec rubocop
   yarn run lint
   ```

4. **Create focused PR**
   ```bash
   git push -u origin feature/specific-focused-change
   gh pr create --title "Focused change description" --body "..."
   ```

### Step 4: Handle the Original PR

**Option A: Close and Replace**

- Close original PR with note: "Split into smaller PRs for easier review"
- Link to all new PRs
- Advantage: Clean history, easier to review

**Option B: Rebase and Reduce**

- Remove commits that went into other PRs
- Rebase remaining commits
- Update PR description
- Advantage: Preserves PR number and discussion

---

## Splitting Example: PR #2069

### Original PR Issues

- 52 commits
- 3 failing test suites + 1 hung
- Mix of documentation, bug fixes, infrastructure
- Unknown how long to fix

### Proposed Split

#### PR 1: Documentation & Testing Requirements (MERGE FIRST) ✅

**Branch**: `docs/testing-requirements-and-ci-analysis`
**Commits**: 2 commits

- Add comprehensive CI failure analysis
- Document testing requirements for hypothetical vs tested fixes

**Why merge first**:

- Zero code changes
- No risk of breaking anything
- Provides value to team immediately
- Documents current state

**Testing**: None needed (documentation only)

---

#### PR 2: Build Console Replay Parameter Order Fix

**Branch**: `fix/build-console-replay-parameter-order`
**Commits**: ~5 commits

- Fix buildConsoleReplay parameter signature
- Update all call sites (open source + Pro)
- Update tests for new parameter order
- Add TSDoc documentation

**Why second**:

- Focused bug fix
- Clear before/after
- Can be tested independently
- Might fix Pro Node Renderer test failure

**Testing Required**:

```bash
# Open source tests
bundle exec rspec spec/react_on_rails/
yarn test packages/react-on-rails/tests/buildConsoleReplay.test.js

# Pro tests
cd react_on_rails_pro/spec/dummy
bundle exec rspec spec/requests/renderer_console_logging_spec.rb
```

**Success Criteria**: All buildConsoleReplay-related tests pass

---

#### PR 3: Workspace Dependencies Yarn Classic Fix

**Branch**: `fix/workspace-dependencies-yarn-classic`
**Commits**: ~3 commits

- Change "workspace:_" to "_" for Yarn Classic compatibility
- Document in testing-build-scripts.md
- Add validation steps

**Why third**:

- Small, focused infrastructure fix
- Well documented issue
- Easy to test

**Testing Required**:

```bash
rm -rf node_modules packages/*/lib
yarn install --frozen-lockfile
# Verify no errors about "workspace:*"
# Verify packages built correctly
ls packages/*/lib/
```

**Success Criteria**: Clean install works, no workspace protocol errors

---

#### PR 4: Monorepo Node Renderer Package (DEFER)

**Branch**: `feature/monorepo-node-renderer-v2`
**Commits**: Remaining commits

- Extract node-renderer as separate package
- Update build workflows
- Fix integration test asset loading

**Why defer**:

- Most complex changes
- Most failing tests
- Needs significant debugging
- Can benefit from PRs 1-3 being merged first

**Before attempting**:

1. Merge PRs 1-3
2. Rebase on updated master
3. Re-run tests to see what's still broken
4. Debug integration test failures locally
5. Consider further splitting if still too complex

---

## Benefits of This Approach

### For Reviewers

- ✅ Smaller PRs are easier to review thoroughly
- ✅ Clear, focused changes
- ✅ Less cognitive load
- ✅ Faster review cycles

### For the Codebase

- ✅ Incremental progress
- ✅ Each merge adds value
- ✅ Easier to revert if needed
- ✅ Better git history

### For Debugging

- ✅ Easier to identify which change broke what
- ✅ Can bisect smaller ranges
- ✅ Test failures more clearly attributed
- ✅ Less interference between changes

### For Team Velocity

- ✅ Unblock parts of work sooner
- ✅ Other work can build on merged PRs
- ✅ Reduce risk of merge conflicts
- ✅ Maintain momentum even with complex issues

---

## Anti-Patterns to Avoid

### ❌ Don't Split Too Much

**Problem**: Creating 20+ micro-PRs
**Result**: Review fatigue, PR dependency hell
**Better**: 3-5 focused PRs maximum

### ❌ Don't Split Dependent Changes

**Problem**: PR 2 needs PR 1's changes to work
**Result**: Can't test or merge independently
**Better**: Keep dependent changes together

### ❌ Don't Leave Original PR in Limbo

**Problem**: Original PR still open, new PRs also open
**Result**: Confusion about what to review, duplicated work
**Better**: Close original with clear migration plan

### ❌ Don't Split Without Testing

**Problem**: Assume split PRs will pass CI without verification
**Result**: Multiple broken PRs instead of one
**Better**: Test each split PR locally before creating

---

## Decision Tree

```
Is PR failing CI?
├─ YES → Continue
└─ NO → No need to split

Are there multiple independent failures?
├─ YES → Consider splitting
└─ NO → Fix the one failure

Can failures be attributed to distinct commits/features?
├─ YES → Good candidate for splitting
└─ NO → May need to debug as-is

Are there commits that can merge independently with value?
├─ YES → Split those out first
└─ NO → Fix failures in original PR

Is estimated fix time > 8 hours?
├─ YES → Strongly consider splitting
└─ NO → May be faster to fix in place

Will splitting unblock other work?
├─ YES → Split to unblock
└─ NO → Evaluate other factors
```

---

## Template: PR Split Announcement

**For closing original PR**:

```markdown
## PR Split Decision

This PR has been split into smaller, more focused PRs for easier review and debugging.

### Why Split?

- [x] Multiple independent test failures
- [x] 52 commits make debugging difficult
- [x] Mix of documentation, bug fixes, and infrastructure
- [x] Estimated 4-8 hours to fix all issues
- [x] Some parts provide value independently

### New PRs (in merge order):

1. **#XXXX: Documentation & Testing Requirements** ✅ READY
   - CI failure analysis
   - Testing requirement documentation
   - Zero risk (docs only)

2. **#YYYY: Build Console Replay Parameter Fix** 🔄 IN REVIEW
   - Focused bug fix
   - All tests passing
   - Addresses one of the three failures

3. **#ZZZZ: Workspace Dependencies Fix** ⏳ DRAFT
   - Yarn Classic compatibility
   - Small infrastructure fix
   - Easy to verify

4. **#AAAA: Monorepo Node Renderer v2** 📋 PLANNED
   - Will rebase on master after PRs 1-3 merge
   - Re-evaluate test failures after rebase
   - May split further if needed

### Benefits:

- Easier code review
- Incremental progress
- Can merge low-risk changes immediately
- Better attribution if issues arise
- Unblocks dependent work

Closing this PR in favor of the focused PRs above.
```

---

## Real-World Example Timeline

**Week 1**:

- Day 1: Identify PR #2069 has complex CI failures
- Day 2: Analyze and document failures (this becomes PR 1)
- Day 3: Create PR 1 (docs) - merged same day ✅

**Week 2**:

- Day 1: Cherry-pick buildConsoleReplay commits to PR 2
- Day 2: Test PR 2 locally, fix issues, open for review
- Day 3: Address review comments, merge ✅

**Week 3**:

- Day 1: Create PR 3 for workspace dependencies
- Day 2: Test, merge ✅
- Day 3: Rebase PR 4 (node renderer) on latest master

**Week 4**:

- Day 1-2: Debug PR 4 with PRs 1-3 merged (fewer variables)
- Day 3: Find that integration tests now pass! Only need minor fix
- Day 4: Merge PR 4 ✅

**Total**: 4 weeks with incremental progress vs. potentially 4 weeks stuck on one PR

---

## Key Takeaway

**Big PRs with multiple failures are a red flag, not a requirement.**

When you see:

- Multiple test suites failing
- Long commit history
- Mixed concerns
- Uncertain fix time

Ask yourself: **"Can I provide value incrementally by splitting this?"**

If yes, split it. Your reviewers, your codebase, and your future self will thank you.
