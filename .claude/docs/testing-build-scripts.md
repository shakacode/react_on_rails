# Testing Build and Package Scripts

**CRITICAL: Build scripts are infrastructure code that MUST be tested manually:**

## Why This Matters

- The `prepack`/`prepare` scripts in package.json/package-scripts.yml run during:
  - `npm install` / `yarn install` (for git dependencies)
  - `yalc publish` (critical for local development)
  - `npm publish`
  - Package manager prepare phase
- If these fail, users can't install or use the package
- Failures are often silent - they don't show up in normal CI

## Mandatory Testing After ANY Changes

**If you modify package.json, package-scripts.yml, or build configs:**

1. **Test the prepack script:**

   ```bash
   yarn run prepack
   # Should succeed without errors
   ```

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

## When Directory Structure Changes

If you rename/move directories that contain build artifacts:

1. **Update ALL path references in package-scripts.yml**
2. **Test yalc publish BEFORE pushing**
3. **Test in a fresh clone to ensure no local assumptions**
4. **Consider adding a CI job to validate artifact paths**

## Real Example: What Went Wrong

In Sep 2024, we moved `node_package/` → `packages/react-on-rails/`. The path in
package-scripts.yml was updated to `packages/react-on-rails/lib/ReactOnRails.full.js`.
Later, the structure was partially reverted to `lib/` at root, but package-scripts.yml
wasn't updated. This broke yalc publish silently for 7 weeks. Manual testing of
`yarn run yalc.publish` would have caught this immediately.
