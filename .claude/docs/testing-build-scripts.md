# Testing Build and Package Scripts

**CRITICAL: Build scripts are infrastructure code that MUST be tested manually:**

## Why This Matters

- The `prepack`/`prepare` scripts in package.json run during:
  - `npm install` / `pnpm install` (for git dependencies)
  - `yalc publish` (critical for local development)
  - `npm publish`
  - Package manager prepare phase
- If these fail, users can't install or use the package
- Failures are often silent - they don't show up in normal CI

## Before You Start: Check CI Status

**CRITICAL: Before investigating failures, check if they're pre-existing:**

```bash
# 1. Check if master is passing for the same workflow
gh run list --workflow="Integration Tests" --branch master --limit 5 --json conclusion,createdAt --jq '.[] | "\(.createdAt) \(.conclusion)"'

# 2. Check your PR branch history for this workflow
gh run list --workflow="Integration Tests" --branch your-branch --limit 10 --json conclusion,headSha,createdAt --jq '.[] | "\(.createdAt) \(.headSha[0:7]) \(.conclusion)"'

# 3. Find when failures started vs when your commits were made
git log --oneline --all | grep your-commit-sha

# 4. Check all failing workflows on current PR
gh pr view --json statusCheckRollup | jq '.statusCheckRollup[] | select(.conclusion == "FAILURE") | .name'
```

**Key Questions to Answer:**

1. **Is master passing?** If yes, the failures are PR-specific
2. **When did failures start?** Compare timestamps of failing runs vs your commits
3. **Did your commits introduce the failures?** If failures started AFTER your commits, they're not from your changes

**Don't waste time debugging pre-existing failures.** If the tests were already failing before your changes, document this and focus on your actual changes.

## Mandatory Testing After ANY Changes

**If you modify package.json or build configs:**

### Step 1: ALWAYS Test Clean Install First

This is the **MOST CRITICAL** test - it's what CI does first, and installation failures block everything else.

```bash
# Remove node_modules to simulate CI environment
rm -rf node_modules

# Test the exact command CI uses
pnpm install --frozen-lockfile

# If this fails, STOP and fix it before testing anything else
```

**Why this matters:** Your local `node_modules` may mask dependency issues. CI starts fresh, so you must too.

### Step 2: Test Build Scripts

```bash
# Build all packages
pnpm run build

# Should succeed without errors
```

### Step 3: Test Package-Specific Scripts

```bash
# Test prepack/prepare scripts work
pnpm run prepack

# Test yalc publish (CRITICAL for local development)
pnpm run yalc:publish

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
pnpm start format.listDifferent
```

## When Directory Structure Changes

If you rename/move directories that contain build artifacts:

1. **Update ALL path references in package.json**
2. **Test yalc publish BEFORE pushing**
3. **Test in a fresh clone to ensure no local assumptions**
4. **Consider adding a CI job to validate artifact paths**

## Workspace Dependencies: PNPM

**CRITICAL: This project uses PNPM (v9+)**

Check `package.json` for: `"packageManager": "pnpm@9.x.x"`

### Correct Workspace Dependency Syntax

For PNPM workspaces:

```json
{
  "dependencies": {
    "react-on-rails": "workspace:*"
  }
}
```

**DO NOT USE:**

- `"*"` - This is Yarn Classic v1.x syntax
- `"file:../react-on-rails"` - This bypasses workspace resolution

### Why `workspace:*` Works

In PNPM workspaces:

- `"workspace:*"` tells PNPM to resolve to the local workspace package
- PNPM automatically links to the workspace version
- This is the official PNPM workspace syntax

### Testing Workspace Changes

When modifying workspace dependencies in package.json:

```bash
# 1. Remove node_modules to test fresh install
rm -rf node_modules

# 2. Test CI command - this will fail immediately if syntax is wrong
pnpm install --frozen-lockfile

# 3. Verify workspace linking worked
pnpm -r list

# 4. Test that packages can import each other
pnpm run build
```

## Real Examples: What Went Wrong

### Example 1: Path Reference Issue (Sep 2024)

We moved `node_package/` → `packages/react-on-rails/`. The path in
package.json was updated to `packages/react-on-rails/lib/ReactOnRails.full.js`.
Later, the structure was partially reverted to `lib/` at root, but package.json
wasn't updated. This broke yalc publish silently for 7 weeks. Manual testing of
`pnpm run yalc:publish` would have caught this immediately.

### Example 2: Workspace Protocol Migration (2024)

When migrating from Yarn to PNPM, workspace dependencies needed to change from `"*"` to `"workspace:*"`.

**Root cause:** Different package managers use different workspace protocols:

- Yarn Classic v1.x uses `"*"` for workspace dependencies
- PNPM uses `"workspace:*"` for workspace dependencies
- Yarn Berry v2+ also uses `"workspace:*"`

**Lesson:** ALWAYS test `pnpm install --frozen-lockfile` after modifying workspace dependencies.
Your local node_modules masked the issue - CI starts fresh and caught it immediately.
