# Monorepo Migration - Current Status & Remaining Work

**Last Updated:** 2025-11-19
**Branch:** justin808/monorepo-completion

## Executive Summary

The monorepo migration is **~60% complete**. The major JavaScript package separation is done, but critical structural issues remain that need to be addressed before the migration can be considered complete.

### ✅ Completed Phases (1-4)

- **Phase 1:** License cleanup & documentation
- **Phase 2:** Git repository merger (react_on_rails_pro as subdirectory)
- **Phase 3:** Core NPM package workspace structure (`packages/react-on-rails/`)
- **Phase 4:** JS Pro code separation (`packages/react-on-rails-pro/`)
- **Bonus:** CircleCI to GitHub Actions migration (from Phase 7)

### 🚧 Remaining Phases (5-8)

- **Phase 5:** Add Pro Node Renderer Package ⚠️ **CRITICAL**
- **Phase 6:** Restructure Ruby Gems (make pro a sibling) ⚠️ **CRITICAL**
- **Phase 7:** Final CI/CD polish (mostly done, minor items remain)
- **Phase 8:** Documentation & examples cleanup

## Critical Issues Identified

### 1. YALC Publish Incomplete ⚠️

**Current State:**
- Root `yarn yalc:publish` only publishes 2 packages via workspace:
  - `packages/react-on-rails/` ✅
  - `packages/react-on-rails-pro/` ✅
  - **Missing:** `react_on_rails_pro/packages/node-renderer/` ❌

**Impact:** Pro node-renderer package cannot be locally tested with yalc.

**Root Cause:** Node-renderer is NOT in the workspace (still in `react_on_rails_pro/packages/`)

### 2. Confusing Directory Structure ⚠️

**Current State:**
```
react_on_rails/                          # Root (MIT)
├── packages/
│   ├── react-on-rails/                  # ✅ MIT NPM package
│   └── react-on-rails-pro/              # ✅ Pro NPM package
├── lib/
│   └── react_on_rails/                  # ✅ MIT Ruby gem code
└── react_on_rails_pro/                  # ⚠️ SUBDIRECTORY (confusing!)
    ├── lib/react_on_rails_pro/          # ❌ Pro Ruby gem (should be at lib/ root)
    ├── packages/node-renderer/          # ❌ Pro node-renderer NPM (should be in packages/)
    ├── react_on_rails_pro.gemspec       # ❌ Pro gemspec (should be at root)
    └── spec/                            # ❌ Pro specs (should be with gem code)
```

**Target State (from MONOREPO_MERGER_PLAN.md):**
```
react_on_rails/                          # Root
├── packages/
│   ├── react-on-rails/                  # MIT NPM
│   ├── react-on-rails-pro/              # Pro NPM
│   └── react-on-rails-pro-node-renderer/  # Pro node-renderer NPM ✨
├── lib/
│   ├── react_on_rails/                  # MIT Ruby gem
│   └── react_on_rails_pro/              # Pro Ruby gem ✨
├── react_on_rails.gemspec               # MIT gemspec
└── react_on_rails_pro.gemspec           # Pro gemspec ✨
```

**Why This Matters:**
- Current structure suggests react_on_rails_pro is "owned by" react_on_rails
- Target structure makes them equal partners in the monorepo
- Licensing boundaries are clearer
- Easier to understand and navigate

### 3. YALC Alternatives Worth Considering

**Current Issues with YALC:**
- Requires manual `yalc publish` after changes
- Not automatic/integrated into monorepo workflow
- Additional tool dependency

**Better Alternatives:**

#### Option A: **pnpm Workspaces** (Recommended)
- Native monorepo support with automatic linking
- Faster installs, better disk usage
- No separate publish step needed
- `pnpm --filter` for selective builds
- Migration: `npx pnpm import` (converts yarn.lock)

#### Option B: **yarn workspaces + yarn link**
- Already using yarn workspaces
- Could use `yarn link` instead of yalc for local dev
- Simpler, one less dependency

#### Option C: **npm workspaces** (if migrating to npm)
- Native to npm 7+
- `npm install --workspace=<name>`
- Simpler if standardizing on npm

**Recommendation:** Stay with yarn workspaces but use `yarn link` instead of yalc OR migrate to pnpm for better monorepo support.

## Detailed Remaining Work

### Phase 5: Add Pro Node Renderer Package

**Goal:** Extract `react_on_rails_pro/packages/node-renderer/` to workspace

**Tasks:**
- [ ] Create `packages/react-on-rails-pro-node-renderer/` directory
- [ ] Move `react_on_rails_pro/packages/node-renderer/src/` → `packages/react-on-rails-pro-node-renderer/src/`
- [ ] Move `react_on_rails_pro/packages/node-renderer/tests/` → `packages/react-on-rails-pro-node-renderer/tests/`
- [ ] Create `packages/react-on-rails-pro-node-renderer/package.json`:
  - `"name": "react-on-rails-pro-node-renderer"`
  - `"license": "UNLICENSED"`
  - Dependencies: react-on-rails, react-on-rails-pro
  - Scripts: build, test, type-check, yalc:publish
- [ ] Create `packages/react-on-rails-pro-node-renderer/tsconfig.json`
- [ ] Update root `package.json` workspaces to include new package
- [ ] Update all import paths referencing node-renderer
- [ ] Update LICENSE.md to include new package path
- [ ] Test workspace builds all 3 packages
- [ ] Test yalc publish works for all 3 packages
- [ ] Update CI to test node-renderer package
- [ ] Remove empty `react_on_rails_pro/packages/` directory

**Acceptance Criteria:**
- `yarn yalc:publish` publishes all 3 NPM packages
- All 3 packages build independently
- No broken imports

### Phase 6: Restructure Ruby Gems to Final Layout

**Goal:** Make react_on_rails_pro a sibling directory structure, not nested

**Tasks:**

#### 6.1: Move Pro Ruby Gem Code
- [ ] Move `react_on_rails_pro/lib/react_on_rails_pro/` → `lib/react_on_rails_pro/`
- [ ] Move `react_on_rails_pro/spec/` → `lib/react_on_rails_pro/spec/` (or keep at `spec/pro/`)
- [ ] Update all Ruby require paths
- [ ] Update RSpec configuration for pro specs location

#### 6.2: Move Pro Gemspec
- [ ] Move `react_on_rails_pro/react_on_rails_pro.gemspec` → `react_on_rails_pro.gemspec` (root)
- [ ] Update gemspec file paths (relative to new location)
- [ ] Update gemspec dependency on core gem
- [ ] Test both gems build from root: `gem build *.gemspec`

#### 6.3: Update Gemfile
- [ ] Update root `Gemfile` to include both gemspecs:
  ```ruby
  gemspec name: "react_on_rails"
  gemspec name: "react_on_rails_pro"
  ```
- [ ] Run `bundle install` and verify dependencies resolve

#### 6.4: Update LICENSE.md
- [ ] Remove `react_on_rails_pro/` directory from Pro license section
- [ ] Add final paths:
  ```md
  ## MIT License applies to:
  - lib/react_on_rails/ (including specs)
  - packages/react-on-rails/ (including tests)

  ## React on Rails Pro License applies to:
  - lib/react_on_rails_pro/ (including specs)
  - packages/react-on-rails-pro/ (including tests)
  - packages/react-on-rails-pro-node-renderer/ (including tests)
  ```

#### 6.5: Remove Empty Pro Directory
- [ ] Verify `react_on_rails_pro/` directory is empty
- [ ] Remove `react_on_rails_pro/` directory
- [ ] Update all paths in scripts/CI that reference old location
- [ ] Update all documentation references

#### 6.6: Update CI Configuration
- [ ] Update GitHub Actions workflows for new paths
- [ ] Update test paths in CI matrices
- [ ] Update RuboCop exclusions if needed
- [ ] Verify all CI jobs pass

**Acceptance Criteria:**
- Both gems build from root
- No `react_on_rails_pro/` subdirectory exists
- All tests pass
- Directory structure matches target architecture
- LICENSE.md accurate

### Phase 7: CI/CD Polish (Remaining Items)

**Completed:**
- ✅ CircleCI to GitHub Actions migration
- ✅ Unified workflow for both packages
- ✅ Matrix builds for Ruby/Node versions

**Remaining:**
- [ ] Add automated license compliance check to CI:
  ```yaml
  license-check:
    runs-on: ubuntu-latest
    steps:
      - name: Verify Pro License Headers
        run: |
          # Check all pro files have proper license headers
          find lib/react_on_rails_pro packages/react-on-rails-pro* \
            -name "*.rb" -o -name "*.js" -o -name "*.ts" | \
          while read file; do
            if ! grep -q "Pro License\|UNLICENSED" "$file"; then
              echo "❌ Missing license header: $file"
              exit 1
            fi
          done
  ```
- [ ] Add license verification to release process
- [ ] Create script to verify LICENSE.md lists all pro directories
- [ ] Add check that no pro code exists in MIT directories
- [ ] Update status badges in README if needed

### Phase 8: Documentation & Polish

**Completed:**
- ✅ MONOREPO_MERGER_PLAN.md created
- ✅ JS_PRO_PACKAGE_SEPARATION_PLAN.md created
- ✅ CONTRIBUTING.md updated for monorepo

**Remaining:**

#### 8.1: Update Main README.md
- [ ] Add clear licensing section showing package breakdown
- [ ] Update installation instructions for monorepo structure
- [ ] Add section on monorepo development workflow
- [ ] Update architecture diagram if exists

#### 8.2: Create Package READMEs
- [ ] `packages/react-on-rails/README.md` (MIT package)
- [ ] `packages/react-on-rails-pro/README.md` (Pro package)
- [ ] `packages/react-on-rails-pro-node-renderer/README.md` (Pro node-renderer)
- [ ] Each README should clearly state license

#### 8.3: Create Migration Guide
- [ ] Create `docs/monorepo-migration-guide.md` for existing users
- [ ] Document what changed and what didn't
- [ ] Provide step-by-step upgrade instructions
- [ ] Add troubleshooting section

#### 8.4: Update Examples
- [ ] Verify all example apps work with new structure
- [ ] Update example app documentation
- [ ] Ensure examples respect license boundaries

#### 8.5: Update CHANGELOG
- [ ] Create comprehensive changelog entry for monorepo migration
- [ ] Document breaking changes (if any)
- [ ] List new package structure
- [ ] Add migration guide link

## Priority Order for Completion

### 🔴 **Critical Path (Do First):**
1. **Phase 5: Add Pro Node Renderer Package** (fixes YALC publish)
2. **Phase 6: Restructure Ruby Gems** (fixes confusing directory structure)
3. **Test everything works end-to-end**

### 🟡 **High Priority (Do Next):**
4. **Phase 7: License compliance automation**
5. **Phase 8: Documentation updates**

### 🟢 **Nice to Have (Do Later):**
6. Consider YALC alternatives (pnpm migration)
7. Additional CI optimizations
8. Example app improvements

## Risks & Mitigation

### Risk: Breaking Changes During Restructure
**Mitigation:**
- Make incremental commits
- Test after each major file move
- Keep detailed rollback notes

### Risk: License Compliance Violations
**Mitigation:**
- Update LICENSE.md immediately when moving files
- Run automated license checks
- Review all moved files for proper headers

### Risk: CI Failures
**Mitigation:**
- Test locally before pushing
- Use CI matrix to test multiple configurations
- Have rollback plan ready

## Questions to Resolve

1. **YALC vs Alternatives:** Should we migrate to pnpm now or wait until after restructure?
2. **Pro Specs Location:** Keep at `spec/pro/` or move to `lib/react_on_rails_pro/spec/`?
3. **Breaking Changes:** Are we OK with requiring users to update paths if any?
4. **Release Timeline:** When to release the monorepo version?

## Next Steps

1. Review this document and approve approach
2. Create feature branch for Phase 5
3. Execute Phase 5 checklist
4. Create feature branch for Phase 6
5. Execute Phase 6 checklist
6. Final testing and documentation
7. Merge to master
8. Release new versions

---

**Related Documents:**
- [MONOREPO_MERGER_PLAN.md](docs/MONOREPO_MERGER_PLAN.md) - Complete 8-phase plan
- [JS_PRO_PACKAGE_SEPARATION_PLAN.md](docs/JS_PRO_PACKAGE_SEPARATION_PLAN.md) - Phase 4 implementation details
- [LICENSE.md](LICENSE.md) - Current licensing structure
