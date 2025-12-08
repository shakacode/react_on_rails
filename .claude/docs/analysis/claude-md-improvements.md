# Recommended CLAUDE.md Improvements

Based on the CI breakage analysis, here are specific additions to prevent similar issues:

## 1. Add Section on Large Refactors and Directory Structure Changes

**CRITICAL: When working on PRs that change directory structure or move files:**

1. **Create a comprehensive checklist** of all places that reference the old paths:
   - Search for hardcoded paths in all config files (grep -r "old/path" .)
   - Check package.json, package-scripts.yml, webpack configs, CI workflows
   - Check documentation and example code
   - Check generator templates

2. **Run ALL test suites** after directory changes:
   - `rake` (all tests)
   - `rake run_rspec:example_basic` (generator tests)
   - Manual test of `yalc publish` if changing package structure
   - Build and test in a fresh clone to catch path issues

3. **Add temporary validation** in CI:
   - Add a CI job that explicitly tests the changed paths
   - Keep this validation for 2-3 releases after the refactor

4. **Document the change** in CHANGELOG.md with migration instructions

5. **Consider breaking large refactors into smaller PRs**:
   - PR 1: Prepare new structure (create new dirs, copy files)
   - PR 2: Update references
   - PR 3: Remove old structure
   - This makes it easier to catch issues and roll back if needed

## 2. Add Section on Build Script Testing

**CRITICAL: Build scripts in package.json and package-scripts.yml need validation:**

1. **The prepack/prepare scripts are CRITICAL** - they run during:
   - `npm install` / `yarn install` (for git dependencies)
   - `yalc publish`
   - `npm publish`
   - Package manager prepare phase

2. **Always test these scripts manually after changes:**

   ```bash
   # Test the prepack script
   pnpm run prepack

   # Test yalc publish (critical for local development)
   pnpm run yalc:publish

   # Verify build artifacts exist at expected paths
   ls -la lib/ReactOnRails.full.js
   ls -la packages/*/lib/
   ```

3. **If you change directory structure:**
   - Update ALL path checks in package-scripts.yml
   - Test with a clean install: `rm -rf node_modules && pnpm install`
   - Test yalc publish to ensure it works for users

4. **Add tests for critical build paths:**
   - Consider adding a CI job that validates expected build artifacts exist
   - Add tests that verify package.json/package-scripts.yml paths are correct

## 3. Add Section on Monitoring Master Health

**CRITICAL: Don't let master stay broken:**

1. **If CI fails on master after your PR merges:**
   - Check GitHub Actions within 30 minutes of merge
   - Run `gh pr view <pr-number> --json statusCheckRollup` after merge
   - Set up GitHub notifications for master branch failures

2. **If you discover master is broken:**
   - Investigate IMMEDIATELY - don't assume "someone else will fix it"
   - Use `gh run list --branch master --limit 10` to see recent failures
   - Check if it's a recurring failure or a new issue
   - If the failure is from your PR, either:
     - Submit a fix PR immediately, OR
     - Consider reverting your PR and re-submitting with the fix

3. **Silent failures are the most dangerous:**
   - yalc publish failures won't show up in most CI runs
   - Build artifact path issues may only surface during actual usage
   - Always test the actual use case (yalc publish, npm install from git, etc.)

4. **When manually re-running workflows:**
   - Re-running a workflow DOES NOT change its conclusion in the GitHub API
   - Our CI safety checks now handle this, but be aware of the limitation
   - If a rerun succeeds, monitor that subsequent commits don't get blocked

## 4. Update the Merge Conflict Resolution Section

**Enhancement to existing section:**

```markdown
### Merge Conflict Resolution Workflow

**CRITICAL**: When resolving merge conflicts, follow this exact sequence:

1. **Resolve logical conflicts only** - don't worry about formatting
2. **VERIFY FILE PATHS** - if the conflict involved directory structure:
   - Check if any hardcoded paths need updating
   - Grep for old paths: `grep -r "old/path" .`
   - Pay special attention to package-scripts.yml, webpack configs
3. **Add resolved files**: `git add .` (or specific files)
4. **Auto-fix everything**: `rake autofix`
5. **Add any formatting changes**: `git add .`
6. **Continue rebase/merge**: `git rebase --continue` or `git commit`
7. **TEST CRITICAL SCRIPTS**: If package-scripts.yml or build configs changed:
   - Run `pnpm run prepack` to verify build scripts work
   - Run `pnpm run yalc:publish` if package structure changed
   - Run relevant test suites

**❌ NEVER manually format during conflict resolution** - this causes formatting wars.
**❌ NEVER blindly accept path changes** - verify they're correct for current structure.
```

## 5. Add Section on Path Management

**NEW SECTION:**

````markdown
## Managing File Paths in Configuration

**CRITICAL: Hardcoded paths are a major source of bugs:**

1. **Before committing changes to any config file with paths:**
   - Verify the path actually exists: `ls -la <path>`
   - Test that operations using the path work
   - If changing package structure, search for ALL references to old paths

2. **Common files with path references:**
   - `package-scripts.yml` - build artifact paths
   - `package.json` - "files", "main", "types" fields
   - Webpack configs - output.path, resolve.modules
   - `.github/workflows/*.yml` - cache paths, artifact paths
   - Generator templates - paths in generated code
   - Documentation - example paths

3. **After any directory structure change:**

   ```bash
   # Find potential hardcoded paths (adjust as needed)
   grep -r "node_package" . --exclude-dir=node_modules --exclude-dir=.git
   grep -r "packages/react-on-rails" . --exclude-dir=node_modules

   # Verify build artifacts are in expected locations
   yarn build
   find . -name "ReactOnRails.full.js" -type f
   ```
````

4. **Use variables/constants when possible:**
   - In JavaScript/TypeScript, use `__dirname` or import.meta.url
   - In Ruby, use `Rails.root` or `File.expand_path`
   - Avoid hardcoding relative paths in config files when possible

```

---

## Root Cause of This CI Breakage

**What happened:**

1. PR #1830 (Sep 29) changed directory from `node_package/` to `packages/react-on-rails/`
2. The path in `package-scripts.yml` was updated to `packages/react-on-rails/lib/ReactOnRails.full.js`
3. Later, the directory structure was partially reverted back to `lib/` at the root
4. But `package-scripts.yml` wasn't updated, leaving the wrong path
5. This made yalc publish fail silently for weeks
6. When the path was fixed in PR #2054, the CI safety check blocked it due to previous failures
7. The safety check had a bug: it checked `run.conclusion` which never updates after reruns

**What we learned:**

- ✅ Large refactors need comprehensive path audits
- ✅ Build scripts (prepack/prepare) need manual testing
- ✅ Silent failures (yalc publish) are dangerous
- ✅ CI safety mechanisms need to handle manual reruns correctly
- ✅ Master health needs active monitoring

**How the recommendations prevent this:**

1. Section 1 (Large Refactors) - Would have caught incomplete path updates
2. Section 2 (Build Scripts) - Would have caught yalc publish failure early
3. Section 3 (Master Health) - Would have alerted team to broken master
4. Section 4 (Merge Conflicts) - Would prevent path regressions during merges
5. Section 5 (Path Management) - Would have caught the incorrect path

---

## Implementation Priority

**High Priority** (add to CLAUDE.md this week):
- Section 2: Testing Build and Package Scripts
- Section 3: Master Branch Health Monitoring
- Section 5: Managing File Paths in Configuration

**Medium Priority** (add within 2 weeks):
- Section 1: Large Refactors and Directory Structure Changes
- Section 4: Enhanced Merge Conflict Resolution

**Future Improvements** (consider later):
- Automated tests for path validation
- CI job to verify build artifacts exist at expected paths
- Pre-commit hook to validate package-scripts.yml paths
```
