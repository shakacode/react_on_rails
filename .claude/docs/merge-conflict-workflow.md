# Merge Conflict Resolution Workflow

**CRITICAL**: When resolving merge conflicts, follow this exact sequence:

1. **Resolve logical conflicts only** - don't worry about formatting
2. **VERIFY FILE PATHS** - if the conflict involved directory structure:
   - Check if any hardcoded paths need updating
   - Run: `grep -r "old/path" . --exclude-dir=node_modules`
   - Pay special attention to package.json, webpack configs
   - **Test affected scripts:** If package.json changed, run `pnpm start build.prepack`
3. **Add resolved files**: `git add .` (or specific files)
4. **Auto-fix everything**: `rake autofix`
5. **Add any formatting changes**: `git add .`
6. **Continue rebase/merge**: `git rebase --continue` or `git commit`
7. **TEST CRITICAL SCRIPTS if build configs changed:**
   ```bash
   pnpm start build.prepack  # Test prepack script
   pnpm run yalc:publish     # Test yalc publish if package structure changed
   rake run_rspec:gem        # Run relevant test suites
   ```

**NEVER manually format during conflict resolution** - this causes formatting wars between tools.
**NEVER blindly accept path changes** - verify they're correct for current structure.
**NEVER skip testing after resolving conflicts in build configs** - silent failures are dangerous.
