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

## Before You Start: Check CI Status

**CRITICAL: Before investigating failures, check if they're pre-existing:**

```bash
# Get the commit SHA before your changes
git log --oneline -20 | grep "your-branch-base"

# Check CI status for that commit
gh run list --commit <SHA> --json conclusion,workflowName

# Compare to current commit
gh run list --commit HEAD --json conclusion,workflowName

# Or check PR status changes over time
gh pr view --json statusCheckRollup | jq '.statusCheckRollup[] | select(.conclusion == "FAILURE") | .name'
```

**Don't waste time debugging pre-existing failures.** If the tests were already failing before your changes, document this and focus on your actual changes.

## Mandatory Testing After ANY Changes

**If you modify package.json, package-scripts.yml, or build configs:**

### Step 1: ALWAYS Test Clean Install First

This is the **MOST CRITICAL** test - it's what CI does first, and installation failures block everything else.

```bash
# Remove node_modules to simulate CI environment
rm -rf node_modules

# Test the exact command CI uses
yarn install --frozen-lockfile

# If this fails, STOP and fix it before testing anything else
```

**Why this matters:** Your local `node_modules` may mask dependency issues. CI starts fresh, so you must too.

### Step 2: Test Build Scripts

```bash
# Build all packages
yarn run build

# Should succeed without errors
```

### Step 3: Test Package-Specific Scripts

```bash
# Test prepack/prepare scripts work
yarn nps build.prepack

# Test yalc publish (CRITICAL for local development)
yarn run yalc:publish

# Should publish all workspace packages successfully
```

### Step 4: Verify Build Artifacts

```bash
# Check that build outputs exist at expected paths
ls -la packages/react-on-rails/lib/ReactOnRails.full.js
ls -la packages/react-on-rails-pro/lib/ReactOnRails.full.js
ls -la packages/react-on-rails-pro-node-renderer/lib/ReactOnRailsProNodeRenderer.js

# If any are missing, investigate why
```

### Step 5: Run Linting

```bash
# Ruby linting
bundle exec rubocop

# JS/TS formatting
yarn start format.listDifferent
```

## When Directory Structure Changes

If you rename/move directories that contain build artifacts:

1. **Update ALL path references in package-scripts.yml**
2. **Test yalc publish BEFORE pushing**
3. **Test in a fresh clone to ensure no local assumptions**
4. **Consider adding a CI job to validate artifact paths**

## Workspace Dependencies: Yarn Classic vs Yarn Berry

**CRITICAL: This project uses Yarn Classic (v1.x), not Yarn Berry (v2+)**

Check `package.json` for: `"packageManager": "yarn@1.22.22"`

### Correct Workspace Dependency Syntax

For Yarn Classic workspaces:

```json
{
  "dependencies": {
    "react-on-rails": "*"
  }
}
```

**DO NOT USE:**

- `"workspace:*"` - This is Yarn Berry v2+ syntax, will cause installation errors
- `"file:../react-on-rails"` - This bypasses workspace resolution

### Why `*` Works

In Yarn Classic workspaces:

- `"*"` tells Yarn to resolve to the local workspace package
- Yarn automatically links to the workspace version
- This is the official Yarn v1 workspace syntax

### Testing Workspace Changes

When modifying workspace dependencies in package.json:

```bash
# 1. Remove node_modules to test fresh install
rm -rf node_modules

# 2. Test CI command - this will fail immediately if syntax is wrong
yarn install --frozen-lockfile

# 3. Verify workspace linking worked
yarn workspaces info

# 4. Test that packages can import each other
yarn run build
```

## Real Examples: What Went Wrong

### Example 1: Path Reference Issue (Sep 2024)

We moved `node_package/` → `packages/react-on-rails/`. The path in
package-scripts.yml was updated to `packages/react-on-rails/lib/ReactOnRails.full.js`.
Later, the structure was partially reverted to `lib/` at root, but package-scripts.yml
wasn't updated. This broke yalc publish silently for 7 weeks. Manual testing of
`yarn run yalc.publish` would have caught this immediately.

### Example 2: Workspace Protocol Issue (Nov 2024)

Changed workspace dependencies from `"*"` to `"workspace:*"` without testing clean install.
This caused CI to fail with: `Couldn't find any versions for "react-on-rails" that matches "workspace:*"`

**Root cause:** Assumed `workspace:*` was standard, but it's only supported in Yarn Berry v2+.
This project uses Yarn Classic v1.x which requires `"*"` for workspace dependencies.

**Lesson:** ALWAYS test `yarn install --frozen-lockfile` after modifying workspace dependencies.
Your local node_modules masked the issue - CI starts fresh and caught it immediately.
