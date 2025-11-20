# Phase 5: Add Pro Node Renderer Package - Detailed Checklist

**Goal:** Extract node-renderer from `react_on_rails_pro/packages/` to workspace at `packages/react-on-rails-pro-node-renderer/`

**Branch:** `add-pro-node-renderer`

**Estimated Time:** 2-3 days

---

## Pre-Phase Verification

- [ ] Verify current state:
  ```bash
  # Should exist:
  ls -la react_on_rails_pro/packages/node-renderer/

  # Should NOT exist yet:
  ls -la packages/react-on-rails-pro-node-renderer/
  ```

- [ ] Create feature branch:
  ```bash
  git checkout -b add-pro-node-renderer
  ```

---

## Step 1: Create Package Structure

### 1.1: Create Directory
```bash
mkdir -p packages/react-on-rails-pro-node-renderer/{src,tests}
```

- [ ] Create `packages/react-on-rails-pro-node-renderer/` directory
- [ ] Create `packages/react-on-rails-pro-node-renderer/src/` directory
- [ ] Create `packages/react-on-rails-pro-node-renderer/tests/` directory
- [ ] Verify directories created:
  ```bash
  ls -la packages/react-on-rails-pro-node-renderer/
  ```

### 1.2: Create package.json

- [ ] Create `packages/react-on-rails-pro-node-renderer/package.json` with:

```json
{
  "name": "react-on-rails-pro-node-renderer",
  "version": "16.2.0-beta.10",
  "description": "React on Rails Pro Node Renderer for server-side rendering",
  "type": "module",
  "main": "lib/index.js",
  "scripts": {
    "build": "yarn run clean && yarn run tsc",
    "build-watch": "yarn run clean && yarn run tsc --watch",
    "clean": "rm -rf ./lib",
    "test": "jest tests",
    "type-check": "yarn run tsc --noEmit --noErrorTruncation",
    "prepack": "nps build.prepack",
    "prepare": "nps build.prepack",
    "prepublishOnly": "yarn run build",
    "yalc:publish": "yalc publish",
    "yalc": "yalc"
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/shakacode/react_on_rails.git"
  },
  "keywords": [
    "react",
    "react-on-rails",
    "node-renderer",
    "server-side-rendering",
    "ssr"
  ],
  "author": "justin.gordon@gmail.com",
  "license": "UNLICENSED",
  "dependencies": {
    "react-on-rails": "16.2.0-beta.10",
    "react-on-rails-pro": "16.2.0-beta.10"
  },
  "peerDependencies": {
    "react": ">= 16",
    "react-dom": ">= 16"
  },
  "files": [
    "lib/**/*.js",
    "lib/**/*.d.ts"
  ],
  "bugs": {
    "url": "https://github.com/shakacode/react_on_rails/issues"
  },
  "homepage": "https://github.com/shakacode/react_on_rails#readme"
}
```

- [ ] Verify package.json is valid JSON:
  ```bash
  cat packages/react-on-rails-pro-node-renderer/package.json | jq .
  ```

### 1.3: Create tsconfig.json

- [ ] Create `packages/react-on-rails-pro-node-renderer/tsconfig.json`:

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./lib",
    "rootDir": "./src",
    "composite": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "lib", "tests"]
}
```

---

## Step 2: Move Source Files

### 2.1: Move Source Code

- [ ] Count files to move:
  ```bash
  find react_on_rails_pro/packages/node-renderer/src -type f | wc -l
  ```

- [ ] Move source files with git mv (preserves history):
  ```bash
  git mv react_on_rails_pro/packages/node-renderer/src/* \
         packages/react-on-rails-pro-node-renderer/src/
  ```

- [ ] Verify files moved:
  ```bash
  ls -la packages/react-on-rails-pro-node-renderer/src/
  git status
  ```

### 2.2: Move Test Files

- [ ] Count test files:
  ```bash
  find react_on_rails_pro/packages/node-renderer/tests -type f | wc -l
  ```

- [ ] Move test files with git mv:
  ```bash
  git mv react_on_rails_pro/packages/node-renderer/tests/* \
         packages/react-on-rails-pro-node-renderer/tests/
  ```

- [ ] Verify test files moved:
  ```bash
  ls -la packages/react-on-rails-pro-node-renderer/tests/
  ```

### 2.3: Move Configuration Files (if any)

- [ ] Check for additional config files:
  ```bash
  ls -la react_on_rails_pro/packages/node-renderer/
  ```

- [ ] Move any .eslintrc, .prettierrc, etc. if they exist
- [ ] Move any README or docs if they exist

---

## Step 3: Update Import Paths

### 3.1: Update Imports in Moved Files

- [ ] Find all imports that need updating:
  ```bash
  grep -r "from ['\"]react-on-rails" packages/react-on-rails-pro-node-renderer/src/
  ```

- [ ] Update imports from relative `../../../` paths to package imports
- [ ] Update any internal relative imports that may have broken

### 3.2: Update Imports in Other Packages

- [ ] Find files importing node-renderer:
  ```bash
  grep -r "node-renderer" packages/react-on-rails-pro/src/
  grep -r "node-renderer" react_on_rails_pro/lib/
  ```

- [ ] Update import paths to use new package name:
  ```typescript
  // Old:
  import { something } from '../packages/node-renderer/...'

  // New:
  import { something } from 'react-on-rails-pro-node-renderer'
  ```

---

## Step 4: Update Workspace Configuration

### 4.1: Add to Root Workspace

- [ ] Update root `package.json` workspaces array:
  ```json
  "workspaces": [
    "packages/react-on-rails",
    "packages/react-on-rails-pro",
    "packages/react-on-rails-pro-node-renderer"
  ]
  ```

- [ ] Verify workspace is recognized:
  ```bash
  yarn workspaces info
  ```

### 4.2: Install Dependencies

- [ ] Install dependencies for new package:
  ```bash
  yarn install
  ```

- [ ] Verify no errors in dependency resolution

---

## Step 5: Update Build Configuration

### 5.1: Update Root Build Script

- [ ] Update root `package.json` build script to include node-renderer:
  ```json
  "build": "yarn workspace react-on-rails run build && yarn workspace react-on-rails-pro run build && yarn workspace react-on-rails-pro-node-renderer run build"
  ```

### 5.2: Test Package Builds

- [ ] Test node-renderer builds:
  ```bash
  cd packages/react-on-rails-pro-node-renderer
  yarn build
  ```

- [ ] Verify output in `lib/` directory:
  ```bash
  ls -la packages/react-on-rails-pro-node-renderer/lib/
  ```

- [ ] Test from workspace root:
  ```bash
  yarn workspace react-on-rails-pro-node-renderer run build
  ```

- [ ] Test full workspace build:
  ```bash
  yarn build
  ```

---

## Step 6: Update License Compliance

### 6.1: Update LICENSE.md

- [ ] Open LICENSE.md
- [ ] Add new package to Pro license section:
  ```md
  ## React on Rails Pro License applies to:

  - packages/react-on-rails-pro/ (including tests)
  - packages/react-on-rails-pro-node-renderer/ (including tests) **NEW**
  - react_on_rails_pro/ (remaining files)
  ```

- [ ] Verify no pro code in MIT sections

### 6.2: Verify License Headers

- [ ] Check all moved files have Pro license headers:
  ```bash
  find packages/react-on-rails-pro-node-renderer/src -name "*.ts" -o -name "*.js" | \
  while read file; do
    if ! grep -q "Pro License\|UNLICENSED" "$file"; then
      echo "Missing license header: $file"
    fi
  done
  ```

- [ ] Add license headers to any missing files

---

## Step 7: Update CI Configuration

### 7.1: Update GitHub Actions

- [ ] Find CI workflows that test packages:
  ```bash
  grep -r "packages/react-on-rails" .github/workflows/
  ```

- [ ] Update workflows to include node-renderer package testing
- [ ] Add node-renderer to build matrix if applicable

### 7.2: Update Test Scripts

- [ ] Ensure root `yarn test` includes node-renderer tests
- [ ] Update any test aggregation scripts

---

## Step 8: Update YALC Publish

### 8.1: Test Individual YALC Publish

- [ ] Test node-renderer yalc publish:
  ```bash
  cd packages/react-on-rails-pro-node-renderer
  yarn yalc:publish
  ```

- [ ] Verify package published to .yalc store:
  ```bash
  ls -la ~/.yalc/packages/react-on-rails-pro-node-renderer/
  ```

### 8.2: Test Workspace YALC Publish

- [ ] Test from root:
  ```bash
  yarn yalc:publish
  ```

- [ ] Verify all 3 packages published:
  ```bash
  ls -la ~/.yalc/packages/
  # Should see:
  # - react-on-rails
  # - react-on-rails-pro
  # - react-on-rails-pro-node-renderer
  ```

---

## Step 9: Clean Up Old Structure

### 9.1: Remove Old Directories

- [ ] Verify old directory is empty:
  ```bash
  ls -la react_on_rails_pro/packages/node-renderer/
  # Should only show src/, tests/ as empty
  ```

- [ ] Remove old node-renderer directory:
  ```bash
  git rm -r react_on_rails_pro/packages/node-renderer/
  ```

- [ ] Check if packages/ directory is now empty:
  ```bash
  ls -la react_on_rails_pro/packages/
  ```

- [ ] If empty, remove it:
  ```bash
  git rm -r react_on_rails_pro/packages/
  ```

### 9.2: Update References

- [ ] Find any remaining references to old path:
  ```bash
  grep -r "react_on_rails_pro/packages/node-renderer" .
  ```

- [ ] Update any documentation, comments, or scripts

---

## Step 10: Testing & Validation

### 10.1: Build Tests

- [ ] Clean and rebuild all packages:
  ```bash
  yarn clean
  yarn build
  ```

- [ ] Verify all 3 packages built successfully:
  ```bash
  ls -la packages/*/lib/
  ```

### 10.2: Unit Tests

- [ ] Run node-renderer tests:
  ```bash
  yarn workspace react-on-rails-pro-node-renderer run test
  ```

- [ ] Run all workspace tests:
  ```bash
  yarn test
  ```

### 10.3: Type Checking

- [ ] Run type check on node-renderer:
  ```bash
  yarn workspace react-on-rails-pro-node-renderer run type-check
  ```

- [ ] Run type check on all packages:
  ```bash
  yarn type-check
  ```

### 10.4: Linting

- [ ] Run linting:
  ```bash
  yarn lint
  ```

- [ ] Fix any linting issues:
  ```bash
  yarn autofix
  ```

### 10.5: Integration Testing

- [ ] Test in Pro dummy app:
  ```bash
  cd react_on_rails_pro/spec/dummy
  yarn install
  yarn build
  ```

- [ ] Test server-side rendering still works
- [ ] Check for any console errors

---

## Step 11: Documentation

### 11.1: Create Package README

- [ ] Create `packages/react-on-rails-pro-node-renderer/README.md`:

```md
# React on Rails Pro Node Renderer

Server-side rendering engine for React on Rails Pro.

## License

This package is licensed under the React on Rails Pro License.
See [REACT-ON-RAILS-PRO-LICENSE.md](../../REACT-ON-RAILS-PRO-LICENSE.md).

## Installation

This package is automatically installed as a dependency of `react-on-rails-pro`.

## Development

Build:
\`\`\`bash
yarn build
\`\`\`

Test:
\`\`\`bash
yarn test
\`\`\`
```

### 11.2: Update Main Documentation

- [ ] Update MONOREPO_MERGER_PLAN.md to mark Phase 5 as complete
- [ ] Update MONOREPO_MIGRATION_STATUS.md
- [ ] Update any architecture diagrams

---

## Step 12: Final Verification

### 12.1: Pre-Commit Checks

- [ ] Run full test suite:
  ```bash
  bundle exec rake
  ```

- [ ] Verify git status is clean of unintended changes:
  ```bash
  git status
  ```

- [ ] Review all file changes:
  ```bash
  git diff --staged
  ```

### 12.2: License Compliance Check

- [ ] Verify LICENSE.md is accurate
- [ ] Check all pro files have headers
- [ ] Ensure no pro code in MIT directories

---

## Commit & Push

- [ ] Commit changes:
  ```bash
  git add -A
  git commit -m "Phase 5: Add Pro Node Renderer Package to workspace

  - Move react_on_rails_pro/packages/node-renderer/ to packages/react-on-rails-pro-node-renderer/
  - Create package.json with UNLICENSED license
  - Update workspace configuration to include 3rd NPM package
  - Update import paths throughout codebase
  - Update LICENSE.md with new package path
  - Fix yalc:publish to publish all 3 packages
  - Remove old packages/node-renderer directory

  Closes Phase 5 of monorepo migration plan."
  ```

- [ ] Push branch:
  ```bash
  git push -u origin add-pro-node-renderer
  ```

---

## Create Pull Request

- [ ] Create PR:
  ```bash
  gh pr create --title "Phase 5: Add Pro Node Renderer Package" \
               --body "$(cat <<'EOF'
  ## Summary

  Completes Phase 5 of the monorepo migration by extracting the Pro node-renderer package to the workspace.

  ### Changes

  - Moved `react_on_rails_pro/packages/node-renderer/` to `packages/react-on-rails-pro-node-renderer/`
  - Created proper package.json with dependencies
  - Updated all import paths
  - **Fixed:** `yarn yalc:publish` now publishes all 3 NPM packages
  - Updated LICENSE.md
  - Removed old directory structure

  ### Test Plan

  - [x] All packages build successfully
  - [x] All tests pass
  - [x] YALC publish works for all 3 packages
  - [x] Pro dummy app still works
  - [x] No broken imports

  ### Related

  - Part of monorepo migration plan (Phase 5)
  - Resolves YALC publish issue
  - Prepares for Phase 6 (Ruby gem restructure)

  EOF
  )"
  ```

---

## Success Criteria ✅

Before merging, verify:

- [ ] All CI checks pass
- [ ] All 3 NPM packages build independently
- [ ] `yarn yalc:publish` publishes all 3 packages
- [ ] All tests pass
- [ ] No broken imports
- [ ] LICENSE.md is accurate
- [ ] Pro functionality still works in dummy app
- [ ] Code review approved

---

## Rollback Plan

If issues arise:

```bash
# Revert the commit
git revert HEAD

# Or reset to before the change
git reset --hard origin/master
```

---

**Next Phase:** Phase 6 - Restructure Ruby Gems to Final Layout
