# Phases 7 & 8: Final Polish - Quick Checklist

**Status:** Mostly complete, minor items remaining

---

## Phase 7: CI/CD Polish

### ✅ Already Completed
- CircleCI to GitHub Actions migration
- Unified workflows for both packages
- Matrix builds for Ruby/Node versions

### Remaining Tasks

#### 7.1: Add Automated License Compliance Check

- [ ] Create `.github/workflows/license-check.yml`:

```yaml
name: License Compliance

on: [push, pull_request]

jobs:
  license-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Verify Pro files have license headers
        run: |
          EXIT_CODE=0

          echo "🔍 Checking Pro license headers..."

          # Check Ruby files
          find lib/react_on_rails_pro packages/react-on-rails-pro* -name "*.rb" | \
          while read file; do
            if ! head -20 "$file" | grep -q "Pro License\|UNLICENSED\|frozen_string_literal"; then
              echo "❌ Missing license header: $file"
              EXIT_CODE=1
            fi
          done

          # Check JS/TS files
          find packages/react-on-rails-pro* -name "*.js" -o -name "*.ts" -o -name "*.tsx" | \
          while read file; do
            if ! head -20 "$file" | grep -q "Pro License\|UNLICENSED"; then
              echo "❌ Missing license header: $file"
              EXIT_CODE=1
            fi
          done

          if [ $EXIT_CODE -eq 0 ]; then
            echo "✅ All Pro files have proper license headers"
          fi

          exit $EXIT_CODE

      - name: Verify no Pro code in MIT directories
        run: |
          echo "🔍 Checking for Pro code in MIT directories..."

          # Check for "pro" mentions in MIT code
          if find lib/react_on_rails packages/react-on-rails -type f \
            \( -name "*.rb" -o -name "*.js" -o -name "*.ts" \) \
            -exec grep -l "ReactOnRailsPro\|react-on-rails-pro" {} \; | \
            grep -v "test\|spec" | grep .; then
            echo "❌ Found Pro references in MIT code"
            exit 1
          else
            echo "✅ No Pro code in MIT directories"
          fi

      - name: Verify LICENSE.md lists all Pro directories
        run: |
          echo "🔍 Verifying LICENSE.md completeness..."

          # List of Pro directories that must be in LICENSE.md
          REQUIRED_DIRS=(
            "lib/react_on_rails_pro"
            "packages/react-on-rails-pro"
            "packages/react-on-rails-pro-node-renderer"
            "spec/pro"
          )

          EXIT_CODE=0
          for dir in "${REQUIRED_DIRS[@]}"; do
            if [ -d "$dir" ] && ! grep -q "$dir" LICENSE.md; then
              echo "❌ LICENSE.md missing Pro directory: $dir"
              EXIT_CODE=1
            fi
          done

          if [ $EXIT_CODE -eq 0 ]; then
            echo "✅ LICENSE.md lists all Pro directories"
          fi

          exit $EXIT_CODE
```

#### 7.2: Add License Check to Release Process

- [ ] Update release script to verify licenses before publishing:
  ```bash
  # In script/release.sh or equivalent
  echo "Checking license compliance..."
  .github/workflows/scripts/check-licenses.sh || exit 1
  ```

#### 7.3: Add Pre-Commit License Check (Optional)

- [ ] Add to `.lefthook.yml`:
  ```yaml
  pre-commit:
    commands:
      license-check:
        run: |
          # Check license headers on staged Pro files
          git diff --cached --name-only --diff-filter=ACM | \
          grep -E "(lib/react_on_rails_pro|packages/react-on-rails-pro)" | \
          while read file; do
            if ! head -20 "$file" | grep -q "Pro License\|UNLICENSED"; then
              echo "❌ Missing license header: $file"
              exit 1
            fi
          done
  ```

#### 7.4: Update Status Badges (If Needed)

- [ ] Check if README.md has correct CI badge:
  ```markdown
  [![CI](https://github.com/shakacode/react_on_rails/actions/workflows/main.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions)
  ```

- [ ] Remove any CircleCI badges if they exist

---

## Phase 8: Documentation & Polish

### 8.1: Update Main README.md

- [ ] Add clear licensing section:

```markdown
## 📄 Licensing

This monorepo contains packages under different licenses:

### 🆓 MIT Licensed (Free & Open Source)

- **Ruby Gem:** `react_on_rails` - [View on RubyGems](https://rubygems.org/gems/react_on_rails)
- **NPM Package:** `react-on-rails` - [View on npm](https://www.npmjs.com/package/react-on-rails)
- **Location:** `lib/react_on_rails/`, `packages/react-on-rails/`

### 💎 Pro Licensed (Commercial License Required)

- **Ruby Gem:** `react_on_rails_pro` - Enhanced performance features
- **NPM Packages:**
  - `react-on-rails-pro` - React Server Components support
  - `react-on-rails-pro-node-renderer` - Advanced SSR engine
- **Location:** `lib/react_on_rails_pro/`, `packages/react-on-rails-pro*/`

Pro features include:
- React Server Components (RSC)
- Advanced caching and optimization
- Node-based renderer for better SSR performance

[Learn more about Pro →](https://www.shakacode.com/react-on-rails-pro)

See [LICENSE.md](LICENSE.md) for full details.
```

- [ ] Update installation instructions to mention monorepo structure

- [ ] Add monorepo development section:

```markdown
## 🛠 Monorepo Development

This project uses Yarn workspaces to manage multiple packages:

\`\`\`bash
# Install all dependencies
yarn install

# Build all packages
yarn build

# Run all tests
yarn test

# Work on specific package
yarn workspace react-on-rails build
yarn workspace react-on-rails-pro test
\`\`\`
```

### 8.2: Create Package READMEs

#### packages/react-on-rails/README.md

- [ ] Create with:
  - Package description
  - Installation instructions
  - Basic usage
  - Link to main docs
  - License (MIT)

#### packages/react-on-rails-pro/README.md

- [ ] Create with:
  - Pro features overview
  - Installation instructions
  - How to get Pro license
  - Basic usage examples
  - License (UNLICENSED)

#### packages/react-on-rails-pro-node-renderer/README.md

- [ ] Create with:
  - Purpose explanation
  - "Installed automatically with react-on-rails-pro"
  - Configuration options
  - License (UNLICENSED)

### 8.3: Create Migration Guide

- [ ] Create `docs/guides/monorepo-migration.md`:

```markdown
# Monorepo Migration Guide

This guide helps existing React on Rails users understand the monorepo structure.

## What Changed?

### For Users (No Action Required)

**Good news:** If you use React on Rails as a gem/package, nothing changes!

- Gem names are the same: `react_on_rails`, `react_on_rails_pro`
- Package names are the same: `react-on-rails`, `react-on-rails-pro`
- APIs are unchanged
- Installation instructions are the same

### For Contributors

The repository structure changed significantly:

**Old Structure:**
\`\`\`
react_on_rails/
├── lib/react_on_rails/
├── node_package/src/
└── react_on_rails.gemspec
\`\`\`

**New Structure:**
\`\`\`
react_on_rails/
├── lib/
│   ├── react_on_rails/          # MIT gem
│   └── react_on_rails_pro/      # Pro gem
├── packages/
│   ├── react-on-rails/          # MIT package
│   ├── react-on-rails-pro/      # Pro package
│   └── react-on-rails-pro-node-renderer/
├── react_on_rails.gemspec
└── react_on_rails_pro.gemspec
\`\`\`

## Updating Your Local Clone

If you contribute to React on Rails:

\`\`\`bash
# Pull latest changes
git pull origin master

# Clean old node_modules
rm -rf node_modules packages/*/node_modules

# Reinstall
yarn install

# Rebuild
yarn build
\`\`\`

## New Development Commands

\`\`\`bash
# Build specific package
yarn workspace react-on-rails build

# Test specific package
yarn workspace react-on-rails-pro test

# Lint everything
yarn lint
\`\`\`

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for full details.
```

### 8.4: Update CHANGELOG.md

- [ ] Add comprehensive entry for monorepo migration:

```markdown
## [Unreleased]

### Changed

#### Monorepo Restructuring (Contributors Only)

**Impact:** Internal restructuring only. Users see no changes.

The repository has been restructured as a monorepo:

- **New:** Yarn workspaces manage 3 NPM packages
- **New:** Both Ruby gems coexist at repository root
- **Improved:** Clearer separation between MIT and Pro licensed code
- **Improved:** Easier local development with automatic package linking

**For contributors:** See [Monorepo Migration Guide](docs/guides/monorepo-migration.md)

**For users:** No action required. Gem/package names and APIs unchanged.

Related PRs: #XXXX (Phase 3), #XXXX (Phase 4), #XXXX (Phase 5), #XXXX (Phase 6)
```

### 8.5: Update Example Apps (If Applicable)

- [ ] Verify example apps still work with new structure
- [ ] Update example app READMEs if needed
- [ ] Test that examples install correctly

### 8.6: Update CONTRIBUTING.md

- [ ] Add monorepo development section:

```markdown
## Monorepo Structure

This repository is organized as a monorepo containing:

- **2 Ruby Gems:** `react_on_rails` (MIT), `react_on_rails_pro` (Pro)
- **3 NPM Packages:** `react-on-rails` (MIT), `react-on-rails-pro` (Pro), `react-on-rails-pro-node-renderer` (Pro)

### Working with the Monorepo

\`\`\`bash
# Install dependencies for all packages
yarn install

# Build all packages
yarn build

# Run all tests
yarn test

# Work on specific package
yarn workspace <package-name> <command>
\`\`\`

### Package Locations

- Ruby Gems: `lib/react_on_rails/`, `lib/react_on_rails_pro/`
- NPM Packages: `packages/react-on-rails/`, `packages/react-on-rails-pro*/`
- Tests: `spec/`, `spec/pro/`, `packages/*/tests/`

### License Compliance

When adding code:

- MIT code goes in: `lib/react_on_rails/`, `packages/react-on-rails/`
- Pro code goes in: `lib/react_on_rails_pro/`, `packages/react-on-rails-pro*/`

All Pro files must have proper license headers.
```

---

## Testing Checklist

Before considering Phases 7 & 8 complete:

### Documentation Review
- [ ] README.md clearly explains licensing
- [ ] All package READMEs created
- [ ] Migration guide is helpful and accurate
- [ ] CONTRIBUTING.md reflects monorepo structure

### CI Verification
- [ ] License check workflow created and passing
- [ ] All CI badges updated
- [ ] No references to CircleCI remain

### User Experience
- [ ] Installation instructions are clear
- [ ] No breaking changes for gem/package users
- [ ] Examples work correctly

### Contributor Experience
- [ ] Development setup is documented
- [ ] Workspace commands are clear
- [ ] License boundaries are obvious

---

## Quick Wins (Do These First)

1. **Update README.md** (30 min) - Most visible to users
2. **Create package READMEs** (1 hour) - Quick and valuable
3. **Add license CI check** (1 hour) - Prevents future issues
4. **Update CHANGELOG** (30 min) - Documents the changes

---

## Total Time Estimate

- **Phase 7:** 2-3 hours
- **Phase 8:** 4-6 hours
- **Total:** ~1 day of focused work

---

## Success Criteria ✅

Phases 7 & 8 complete when:

- [ ] Automated license compliance checking in CI
- [ ] All documentation reflects monorepo structure
- [ ] Clear migration guide for contributors
- [ ] Package READMEs created
- [ ] CHANGELOG updated
- [ ] README.md has licensing section
- [ ] No confusing or outdated docs remain

---

**Note:** These phases are mostly polish and documentation. They're important for long-term maintainability but can be done incrementally after Phases 5 & 6.
