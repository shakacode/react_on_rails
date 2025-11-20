# Concrete CLAUDE.md Updates Based on CI Breakage Analysis

## Table of Contents

- [Executive Summary of What Went Wrong](#executive-summary-of-what-went-wrong)
- [High Priority Updates](#high-priority-add-these-3-sections-immediately)
  - [Section 1: Testing Build and Package Scripts](#section-1-testing-build-and-package-scripts)
  - [Section 2: Master Branch Health Monitoring](#section-2-master-branch-health-monitoring)
  - [Section 3: Managing File Paths in Configuration](#section-3-managing-file-paths-in-configuration)
- [Medium Priority Updates](#medium-priority-enhanced-merge-conflict-resolution)
- [Implementation Plan](#implementation-plan)
- [Validation](#validation)
- [Key Takeaways](#key-takeaways-for-claudemd-philosophy)

## Executive Summary of What Went Wrong

**Root Cause Chain:**

1. PR #1830 (Sep 29) moved `node_package/` → `packages/react-on-rails/`
2. Path in `package-scripts.yml` was updated to `packages/react-on-rails/lib/ReactOnRails.full.js`
3. Later, structure was partially reverted to `lib/` at root, but `package-scripts.yml` wasn't updated
4. This broke `yalc publish` silently for ~7 weeks
5. When fixed in PR #2054, the CI safety check created a circular dependency
6. The safety check had a bug: checked `run.conclusion` which never updates after reruns

**Key Failures:**

- ❌ No verification that paths in package-scripts.yml were correct after structure change
- ❌ No manual testing of yalc publish to catch the breakage
- ❌ No monitoring of master health - failure went unnoticed for weeks
- ❌ CI safety mechanism created circular dependency instead of helping

---

## HIGH PRIORITY: Add These 3 Sections Immediately

### Section 1: Testing Build and Package Scripts

Add this new section to CLAUDE.md (both root and .conductor/london-v1):

````markdown
## Testing Build and Package Scripts

**CRITICAL: Build scripts are infrastructure code that MUST be tested manually:**

### Why This Matters

- The `prepack`/`prepare` scripts in package.json/package-scripts.yml run during:
  - `npm install` / `yarn install` (for git dependencies)
  - `yalc publish` (critical for local development)
  - `npm publish`
  - Package manager prepare phase
- If these fail, users can't install or use the package
- Failures are often silent - they don't show up in normal CI

### Mandatory Testing After ANY Changes

**If you modify package.json, package-scripts.yml, or build configs:**

1. **Test the prepack script:**
   ```bash
   yarn run prepack
   # Should succeed without errors
   ```
````

2. **Test yalc publish (CRITICAL):**

   ```bash
   yarn run yalc.publish
   # Should publish successfully
   ```

3. **Verify build artifacts exist at expected paths:**

   ```bash
   # Check the path referenced in package-scripts.yml
   ls -la lib/ReactOnRails.full.js

   # If package-scripts.yml references packages/*, check that too
   ls -la packages/*/lib/*.js
   ```

4. **Test clean install:**
   ```bash
   rm -rf node_modules
   yarn install
   # Should install without errors
   ```

### When Directory Structure Changes

If you rename/move directories that contain build artifacts:

1. **Update ALL path references in package-scripts.yml**
2. **Test yalc publish BEFORE pushing**
3. **Test in a fresh clone to ensure no local assumptions**
4. **Consider adding a CI job to validate artifact paths**

### Real Example: What Went Wrong

In Sep 2024, we moved `node_package/` → `packages/react-on-rails/`. The path in
package-scripts.yml was updated to `packages/react-on-rails/lib/ReactOnRails.full.js`.
Later, the structure was partially reverted to `lib/` at root, but package-scripts.yml
wasn't updated. This broke yalc publish silently for 7 weeks. Manual testing of
`yarn run yalc.publish` would have caught this immediately.

````

### Section 2: Master Branch Health Monitoring

Add this new section to CLAUDE.md (both versions):

```markdown
## Master Branch Health Monitoring

**CRITICAL: Master staying broken affects the entire team. Don't let it persist.**

### Immediate Actions After Your PR Merges

Within 30 minutes of your PR merging to master:

1. **Check CI status:**
   ```bash
   # View the merged PR's CI status
   gh pr view <your-pr-number> --json statusCheckRollup

   # Or check recent master runs
   gh run list --branch master --limit 5
````

2. **If you see failures:**
   - Investigate IMMEDIATELY
   - Don't assume "someone else will fix it"
   - You are responsible for ensuring your PR doesn't break master

### When You Discover Master is Broken

1. **Determine if it's from your PR:**

   ```bash
   gh run list --branch master --limit 10
   ```

2. **Take immediate action:**
   - If your PR broke it: Submit a fix PR within the hour, OR revert and resubmit
   - If unsure: Investigate and communicate with team
   - Never leave master broken overnight

### Silent Failures are Most Dangerous

Some failures don't show up in standard CI:

- yalc publish failures
- Build artifact path issues
- Package installation problems

**Always manually test critical workflows:**

- If you changed package structure → test `yarn run yalc.publish`
- If you changed build configs → test `yarn build && ls -la lib/`
- If you changed generators → test `rake run_rspec:example_basic`

### Understanding Workflow Reruns

**Important limitation:**

- Re-running a workflow does NOT change its `conclusion` in the GitHub API
- GitHub marks a run as "failed" even if a manual rerun succeeds
- Our CI safety checks (as of PR #2062) now handle this correctly
- But be aware: old commits with failed reruns may still block docs-only commits

**What this means:**

- If master workflows fail, reruns alone won't fix the circular dependency
- You need a new commit that passes to establish a clean baseline
- See PR #2065 for an example of breaking the cycle

````

### Section 3: Managing File Paths in Configuration

Add this new section to CLAUDE.md (both versions):

```markdown
## Managing File Paths in Configuration Files

**CRITICAL: Hardcoded paths are a major source of bugs, especially after refactors.**

### Before Committing Path Changes

1. **Verify the path actually exists:**
   ```bash
   ls -la <the-path-you-just-added>
````

2. **Test operations that use the path:**

   ```bash
   # If it's a build artifact path in package-scripts.yml:
   yarn run prepack
   yarn run yalc.publish

   # If it's a webpack output path:
   yarn build && ls -la <output-path>
   ```

3. **Search for ALL references to old paths if renaming:**
   ```bash
   # Example: if renaming node_package/ to packages/
   grep -r "node_package" . --exclude-dir=node_modules --exclude-dir=.git
   grep -r "packages/react-on-rails" . --exclude-dir=node_modules
   ```

### Files That Commonly Have Path References

**Always check these after directory structure changes:**

- `package-scripts.yml` - build artifact paths in prepack/prepare scripts
- `package.json` - "files", "main", "types", "exports" fields
- `webpack.config.js` / `config/webpack/*` - output.path, resolve.modules
- `.github/workflows/*.yml` - cache paths, artifact paths, working directories
- `lib/generators/**/templates/**` - paths in generated code
- Documentation files - example paths and installation instructions

### Post-Refactor Validation Checklist

After any directory structure change, run this checklist:

```bash
# 1. Find any lingering references to old paths
grep -r "old/path/name" . --exclude-dir=node_modules --exclude-dir=.git

# 2. Verify build artifacts are in expected locations
yarn build
find . -name "ReactOnRails.full.js" -type f
find . -name "package.json" -type f

# 3. Test package scripts
yarn run prepack
yarn run yalc.publish

# 4. Test clean install
rm -rf node_modules && yarn install

# 5. Run full test suite
rake
```

### Real Example: The package-scripts.yml Bug

**What happened:**

- Path was changed from `node_package/lib/` to `packages/react-on-rails/lib/`
- Later, the actual directory structure was reverted to `lib/` at root
- But package-scripts.yml still referenced `packages/react-on-rails/lib/`
- This caused yalc publish to fail silently for 7 weeks

**How to prevent:**

1. After changing directory structure, search for ALL references to old paths
2. Always run `yarn run yalc.publish` manually to verify it works
3. Check that paths in package-scripts.yml match actual file locations
4. Use `ls -la <path>` to verify paths exist before committing

````

---

## MEDIUM PRIORITY: Enhanced Merge Conflict Resolution

Update the existing "Merge Conflict Resolution Workflow" section with this addition:

```markdown
### Merge Conflict Resolution Workflow
**CRITICAL**: When resolving merge conflicts, follow this exact sequence:

1. **Resolve logical conflicts only** - don't worry about formatting
2. **VERIFY FILE PATHS** - if the conflict involved directory structure:
   - Check if any hardcoded paths need updating
   - Run: `grep -r "old/path" . --exclude-dir=node_modules`
   - Pay special attention to package-scripts.yml, webpack configs, package.json
   - **Test affected scripts:** If package-scripts.yml changed, run `yarn run prepack`
3. **Add resolved files**: `git add .` (or specific files)
4. **Auto-fix everything**: `rake autofix`
5. **Add any formatting changes**: `git add .`
6. **Continue rebase/merge**: `git rebase --continue` or `git commit`
7. **TEST CRITICAL SCRIPTS if build configs changed:**
   ```bash
   yarn run prepack          # Test prepack script
   yarn run yalc.publish     # Test yalc publish if package structure changed
   rake run_rspec:gem        # Run relevant test suites
````

**❌ NEVER manually format during conflict resolution** - this causes formatting wars.
**❌ NEVER blindly accept path changes** - verify they're correct for current structure.
**❌ NEVER skip testing after resolving conflicts in build configs** - silent failures are dangerous.

```

---

## Implementation Plan

### Week 1 (Immediate)
- [ ] Add Section 1: Testing Build and Package Scripts to both CLAUDE.md files
- [ ] Add Section 2: Master Branch Health Monitoring to both CLAUDE.md files
- [ ] Add Section 3: Managing File Paths in Configuration to both CLAUDE.md files

### Week 2
- [ ] Update merge conflict resolution section in both CLAUDE.md files
- [ ] Add checklist for large refactors (optional - can wait)

### Future Improvements
- [ ] Consider adding a CI job that validates build artifact paths
- [ ] Consider pre-commit hook to validate package-scripts.yml paths exist
- [ ] Document this incident in team knowledge base

---

## Validation

After adding these sections, verify they work by:

1. Having a team member review the new sections
2. Testing that the instructions are clear and actionable
3. Referencing these sections during next PR that touches build configs
4. Updating based on feedback after first real-world use

---

## Key Takeaways for CLAUDE.md Philosophy

**What makes good CLAUDE.md content:**
- ✅ Specific commands to run, not vague advice
- ✅ Real examples of what went wrong and how to prevent it
- ✅ Checklists and step-by-step instructions
- ✅ Clear "why this matters" context
- ✅ Mandatory testing after specific types of changes

**What to avoid:**
- ❌ Generic advice like "be careful with paths"
- ❌ Unclear responsibilities ("someone should check")
- ❌ Assumptions that CI will catch everything
- ❌ Missing the "silent failure" scenarios
```
