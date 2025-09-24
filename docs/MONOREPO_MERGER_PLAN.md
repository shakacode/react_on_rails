# React on Rails Monorepo Merger Plan

**Version:** 1.0
**Date:** 2025-09-24
**Status:** Planning Phase
**GitHub Issue:** [#1765](https://github.com/shakacode/react_on_rails/issues/1765)

## Overview

This document provides the complete implementation plan for merging the `react_on_rails` and `react_on_rails_pro` repositories into a unified monorepo while maintaining separate package identities and proper license compliance.

## Executive Summary

### Objectives

- Merge two repositories into a single monorepo for unified development
- Maintain separate packages (2 Ruby gems + 3 NPM packages)
- Preserve git history from both repositories
- Ensure strict license compliance (MIT vs Pro) throughout the process
- Maintain CI integrity at every step

### Key Constraints

- **CI Safety First**: Every PR must pass all CI checks before proceeding
- **License Compliance**: Pro files must never end up in MIT-licensed directories
- **Package Independence**: Maintain separate versioning and distribution
- **No Breaking Changes**: Existing users should not be affected

### Timeline

**Estimated Duration:** 4-5 weeks across 7 phases

## Current State Analysis

### react_on_rails Repository Structure

```
react_on_rails/
├── lib/react_on_rails/           # Core Ruby (MIT)
├── node_package/src/             # Core JS/TS + pro/ subdirectory
├── spec/                         # Tests
├── react_on_rails.gemspec        # Core gem
├── .github/workflows/            # GitHub Actions CI
└── package.json                  # Core NPM package
```

### react_on_rails_pro Repository Structure

```
react_on_rails_pro/
├── lib/react_on_rails_pro/       # Pro Ruby
├── packages/node-renderer/       # Pro Node renderer
├── spec/                         # Pro tests
├── react_on_rails_pro.gemspec    # Pro gem
├── .circleci/                    # CircleCI CI
└── package.json                  # Pro NPM package
```

### License Structure Analysis

- **MIT Licensed**: Core react_on_rails functionality
- **Pro Licensed**: All react_on_rails_pro functionality + `node_package/src/pro/`
- **Current License Issues**: react_on_rails_pro/LICENSE references older license version

## Target Architecture

### Final Repository Structure

```
react_on_rails/ (monorepo root)
├── lib/
│   ├── react_on_rails/           # Core Ruby (MIT)
│   └── react_on_rails_pro/       # Pro Ruby (Pro license)
├── packages/                     # NPM packages (yarn workspace)
│   ├── react-on-rails/           # Core JS/TS (MIT)
│   ├── react-on-rails-pro/       # Pro JS/TS (Pro license)
│   └── react-on-rails-pro-node-renderer/  # Pro node renderer
├── spec/
│   ├── ruby/                     # Ruby specs organized by package
│   │   ├── react_on_rails/
│   │   └── react_on_rails_pro/
│   └── packages/                 # JS specs organized by package
│       ├── react-on-rails/
│       ├── react-on-rails-pro/
│       └── react-on-rails-pro-node-renderer/
├── tools/                        # Shared development tools
├── docs/                         # Unified documentation
├── react_on_rails.gemspec        # Core gem
├── react_on_rails_pro.gemspec    # Pro gem
├── package.json                  # Workspace manager
├── Gemfile                       # Both gems
├── LICENSE.md                    # MIT license + pro exclusions
├── REACT-ON-RAILS-PRO-LICENSE.md # Pro license
└── README.md
```

### Final Package Output

**Ruby Gems (2 separate):**

1. `react_on_rails` gem (MIT License)
2. `react_on_rails_pro` gem (Pro License, depends on react_on_rails)

**NPM Packages (3 separate):**

1. `react-on-rails` (MIT License)
2. `react-on-rails-pro` (Pro License, depends on react-on-rails)
3. `react-on-rails-pro-node-renderer` (Pro License)

## Implementation Plan

### Phase 1: Pre-Merger Preparation

#### PR #1: License Cleanup & Documentation

**Branch:** `prepare-licenses`
**Target:** Both repositories (separate PRs)

**Objectives:**

- Standardize license versions across repositories
- Document merger plan and licensing approach
- Prepare community for upcoming changes

**Tasks:**

- [ ] Update `react_on_rails_pro/LICENSE` to reference v2.0 license consistently
- [ ] Add this merger plan document to react_on_rails repo
- [ ] Update CONTRIBUTING.md to mention upcoming merger
- [ ] Create FAQ.md about licensing post-merger
- [ ] Verify all pro files have proper license headers
- [ ] Ensure license file references are correct
- [ ] Document which directories will be under which license

**Success Criteria:** ✅ All existing CI checks pass + License compliance verified

**Estimated Duration:** 2-3 days

**Developer Notes:**

- Double-check that all pro files have appropriate license headers
- Ensure license documentation accurately reflects current directory structure
- This is preparatory work - no structural changes yet

---

### Phase 2: Git Subtree Merger (Keep Original Structure)

#### PR #2: Merge react_on_rails_pro via Git Subtree + Fix CI

**Branch:** `merge-pro-subtree-with-ci`
**Target:** react_on_rails repository

**Objectives:**

- Merge repositories while preserving git history
- Establish dual CI system (temporary)
- Create working state with both packages in one repo

**Git Strategy:**

```bash
# Add react_on_rails_pro as remote
git remote add pro-origin https://github.com/shakacode/react_on_rails_pro.git
git fetch pro-origin

# Merge using subtree (preserves history)
git subtree add --prefix=react_on_rails_pro pro-origin/main --squash
```

**Tasks:**

- [ ] Execute git subtree merge into `react_on_rails_pro/` directory
- [ ] **CRITICAL: Update CI to run tests for both packages**
- [ ] Keep GitHub Actions for core package tests
- [ ] Keep CircleCI for pro package tests (temporarily)
- [ ] Update root scripts to test both packages
- [ ] Ensure both packages build independently
- [ ] Update root LICENSE.md to list `react_on_rails_pro/` as Pro-licensed
- [ ] Verify all pro files remain under `react_on_rails_pro/` directory
- [ ] Update .gitignore if needed

**Expected Directory Structure After Merge:**

```
react_on_rails/ (root)
├── lib/react_on_rails/              # Original core
├── node_package/                    # Original core JS
├── spec/                            # Original core tests
├── react_on_rails.gemspec           # Original core
├── package.json                     # Original core
├── .github/workflows/               # UPDATED - tests core
│
├── react_on_rails_pro/             # ADDED - Complete pro repo
│   ├── lib/react_on_rails_pro/
│   ├── packages/node-renderer/
│   ├── spec/
│   ├── react_on_rails_pro.gemspec
│   ├── package.json
│   └── .circleci/                   # Keep temporarily
```

**Updated LICENSE.md Section:**

```md
## React on Rails Pro License applies to:

- `react_on_rails_pro/` (entire directory)

All other files are licensed under MIT License.
```

**Success Criteria:** ✅ **ALL CI jobs pass for both core and pro packages independently**

**Estimated Duration:** 3-5 days

**Risk Level:** High (first major structural change)

**Developer Notes:**

- This is the most critical step - creates the foundation for all subsequent work
- After subtree merge, ensure the entire `react_on_rails_pro/` directory is listed in LICENSE.md as Pro-licensed
- Verify no pro files accidentally ended up in MIT-licensed directories during the merge
- Both CI systems (GitHub Actions + CircleCI) must pass independently

---

### Phase 3: Pre-Monorepo Structure Preparation

#### PR #3: Prepare Core Package for Workspace Structure

**Branch:** `prepare-core-workspace`

**Objectives:**

- Migrate core NPM package to workspace structure
- Establish yarn workspace foundation
- Maintain backward compatibility

**Tasks:**

- [ ] Create `packages/react-on-rails/` directory
- [ ] Move `node_package/src/` to `packages/react-on-rails/src/` (excluding pro/ subdirectory)
- [ ] Create `packages/react-on-rails/package.json` with correct configuration
- [ ] Update root `package.json` to workspace manager (packages/react-on-rails only)
- [ ] Update build scripts and import paths
- [ ] Update TypeScript configurations
- [ ] Keep `react_on_rails_pro/` directory unchanged
- [ ] Update CI to build via workspace
- [ ] Update LICENSE.md to include new package path

**License Compliance:**

- [ ] **CRITICAL: Verify NO pro files moved to MIT-licensed core package**
- [ ] Ensure `packages/react-on-rails/src/` contains ONLY MIT-licensed code
- [ ] Update LICENSE.md to reflect new paths:

  ```md
  ## MIT License applies to:

  - `lib/react_on_rails/`
  - `packages/react-on-rails/` (new path)

  ## React on Rails Pro License applies to:

  - `react_on_rails_pro/` (entire directory)
  ```

**Success Criteria:** ✅ All CI checks pass + No pro code in MIT directories + Workspace builds successfully

**Estimated Duration:** 2-3 days

**Developer Notes:**

- When moving core files to `packages/react-on-rails/`, carefully verify that no pro files (especially from `node_package/src/pro/`) accidentally get moved to the MIT-licensed directory
- Update LICENSE.md to reflect the new `packages/react-on-rails/` path
- Ensure workspace configuration only includes core package initially

---

#### PR #4: Prepare Pro Package for Workspace Structure

**Branch:** `prepare-pro-workspace`

**Objectives:**

- Extract pro NPM packages to workspace structure
- Create separate pro packages
- Establish full workspace configuration

**Tasks:**

- [ ] Move `react_on_rails_pro/packages/node-renderer/` to `packages/react-on-rails-pro-node-renderer/`
- [ ] Extract pro JS features from `node_package/src/pro/` to `packages/react-on-rails-pro/src/`
- [ ] Create individual `package.json` files for both pro packages:
  - `packages/react-on-rails-pro/package.json` with `"license": "UNLICENSED"`
  - `packages/react-on-rails-pro-node-renderer/package.json` with `"license": "UNLICENSED"`
- [ ] Update root workspace to include all 3 NPM packages
- [ ] Update CI to test all packages
- [ ] Setup proper dependencies between packages
- [ ] Move JS specs to organized structure

**License Compliance:**

- [ ] **CRITICAL: Update LICENSE.md for new pro directory paths:**

  ```md
  ## MIT License applies to:

  - `lib/react_on_rails/`
  - `packages/react-on-rails/`

  ## React on Rails Pro License applies to:

  - `lib/react_on_rails_pro/`
  - `packages/react-on-rails-pro/` (NEW)
  - `packages/react-on-rails-pro-node-renderer/` (NEW)
  - `react_on_rails_pro/` (remaining files)
  ```

- [ ] Add Pro license headers to moved files
- [ ] Verify all pro packages have `"license": "UNLICENSED"` in package.json

**Success Criteria:** ✅ All CI checks pass + All pro files properly licensed + License paths updated + All 3 NPM packages build

**Estimated Duration:** 3-4 days

**Risk Level:** Medium-High (complex file movements)

**Developer Notes:**

- This is a critical step for license compliance!
- When creating new pro directories (`packages/react-on-rails-pro/` and `packages/react-on-rails-pro-node-renderer/`), immediately update LICENSE.md to include these new paths
- Ensure all moved pro files retain their Pro license headers
- Verify new package.json files have `"license": "UNLICENSED"`
- Test all workspace commands thoroughly

---

### Phase 4: Final Monorepo Restructuring

#### PR #5: Restructure Ruby Gems to Final Layout

**Branch:** `restructure-ruby-gems`

**Objectives:**

- Finalize Ruby gem structure
- Complete directory reorganization
- Establish final license boundaries

**Tasks:**

- [ ] Move `react_on_rails_pro/lib/react_on_rails_pro/` to `lib/react_on_rails_pro/`
- [ ] Move `react_on_rails_pro/react_on_rails_pro.gemspec` to root as `react_on_rails_pro.gemspec`
- [ ] Move all Ruby specs to organized structure:
  - `spec/ruby/react_on_rails/` (core specs)
  - `spec/ruby/react_on_rails_pro/` (pro specs)
- [ ] Move JS specs to organized structure:
  - `spec/packages/react-on-rails/`
  - `spec/packages/react-on-rails-pro/`
  - `spec/packages/react-on-rails-pro-node-renderer/`
- [ ] Update root `Gemfile` to include both gemspecs
- [ ] Remove empty `react_on_rails_pro/` directory
- [ ] Update all require paths in Ruby code
- [ ] Update gemspec file paths and dependencies

**License Compliance:**

- [ ] **Update LICENSE.md to final directory structure:**

  ```md
  ## MIT License applies to:

  - `lib/react_on_rails/`
  - `packages/react-on-rails/`
  - `spec/ruby/react_on_rails/`
  - `spec/packages/react-on-rails/`

  ## React on Rails Pro License applies to:

  - `lib/react_on_rails_pro/`
  - `packages/react-on-rails-pro/`
  - `packages/react-on-rails-pro-node-renderer/`
  - `spec/ruby/react_on_rails_pro/`
  - `spec/packages/react-on-rails-pro/`
  - `spec/packages/react-on-rails-pro-node-renderer/`
  ```

- [ ] Update both gemspec files with correct license:

  ```ruby
  # react_on_rails.gemspec
  s.license = "MIT"

  # react_on_rails_pro.gemspec
  s.license = "UNLICENSED"  # Pro license
  ```

- [ ] Verify no pro files accidentally moved to MIT directories

**Success Criteria:** ✅ All CI checks pass + Final license structure verified + Both gems build from root

**Estimated Duration:** 2-3 days

**Developer Notes:**

- This step finalizes the directory structure, so it's crucial to update LICENSE.md with all final pro paths
- When moving `react_on_rails_pro/lib/react_on_rails_pro/` to `lib/react_on_rails_pro/`, ensure you update the LICENSE.md path from the temporary location to the final location
- Double-check that pro specs moved to `spec/ruby/react_on_rails_pro/` and not `spec/ruby/react_on_rails/`
- This creates the final monorepo structure

---

### Phase 5: CI/CD & Tooling Unification

#### PR #6: Unify CI/CD Configuration

**Branch:** `unify-cicd`

**Objectives:**

- Consolidate to single CI system
- Establish unified build/test/release process
- Remove duplicate configurations

**Decision Point: Choose Final CI System**

- **Option A:** GitHub Actions (Recommended)
  - Native GitHub integration
  - Free for open source
  - Better community adoption
  - Matrix builds for multiple versions
- **Option B:** CircleCI
  - Superior caching system
  - Better resource management
  - More advanced workflow features
- **Option C:** Hybrid Approach
  - GitHub Actions for most tests
  - CircleCI for specific pro features

**Tasks:**

- [ ] **Make CI system decision** based on project needs
- [ ] Implement chosen CI strategy with unified workflow
- [ ] Create matrix builds for Ruby gems (both gems, multiple Ruby versions)
- [ ] Create matrix builds for NPM packages (all 3 packages, multiple Node versions)
- [ ] Setup integration tests between core and pro packages
- [ ] Remove duplicate CI configurations (either .github/workflows or .circleci)
- [ ] Update build and release scripts for monorepo
- [ ] Add independent package release workflows
- [ ] Update status badges in README

**License Compliance:**

- [ ] Add automated license checking to CI pipeline:
  ```yaml
  license-check:
    runs-on: ubuntu-latest
    steps:
      - name: Verify Pro License Headers
        run: |
          find lib/react_on_rails_pro packages/react-on-rails-pro* -name "*.rb" -o -name "*.js" -o -name "*.ts" | \
          xargs grep -L "Pro License\|UNLICENSED" && exit 1 || echo "✅ All pro files properly licensed"
  ```
- [ ] Add license verification to release process
- [ ] Ensure CI fails if pro files missing license headers

**Success Criteria:** ✅ All CI checks pass + Automated license enforcement in place + Single CI system operational

**Estimated Duration:** 2-3 days

**Developer Notes:**

- When consolidating CI configurations, ensure any new build scripts or release processes respect license boundaries
- If you create any new directories during CI setup, verify they're properly classified as MIT or Pro in LICENSE.md
- Test the full CI pipeline thoroughly before removing the old system

---

### Phase 6: Documentation & Polish

#### PR #7: Update Documentation & Examples

**Branch:** `update-docs-examples`

**Objectives:**

- Complete documentation for monorepo
- Update all examples and guides
- Provide migration path for users

**Tasks:**

- [ ] Update main README.md for monorepo with clear licensing section
- [ ] Create individual READMEs for each package:
  - `packages/react-on-rails/README.md`
  - `packages/react-on-rails-pro/README.md`
  - `packages/react-on-rails-pro-node-renderer/README.md`
- [ ] Create comprehensive migration guide for existing users
- [ ] Update installation and setup instructions
- [ ] Update all example applications to work with new structure
- [ ] Update CONTRIBUTING.md for monorepo workflow
- [ ] Update changelog with merger information
- [ ] Create release notes for the merger
- [ ] Update version numbers if needed

**License Compliance:**

- [ ] **Document licensing clearly in main README.md:**

  ```md
  ## 📄 Licensing

  This monorepo contains packages under different licenses:

  ### MIT Licensed (Free & Open Source):

  - `react_on_rails` Ruby gem
  - `react-on-rails` NPM package
  - Core functionality in `lib/react_on_rails/` and `packages/react-on-rails/`

  ### Pro Licensed (Subscription Required for Production):

  - `react_on_rails_pro` Ruby gem
  - `react-on-rails-pro` NPM package
  - `react-on-rails-pro-node-renderer` NPM package
  - Pro functionality in `lib/react_on_rails_pro/` and `packages/react-on-rails-pro*/`

  See [LICENSE.md](LICENSE.md) and [REACT-ON-RAILS-PRO-LICENSE.md](REACT-ON-RAILS-PRO-LICENSE.md)
  ```

- [ ] Update individual package READMEs with appropriate license info
- [ ] Create LICENSE.md symlinks in package directories if needed
- [ ] Verify all examples respect license boundaries
- [ ] Ensure example code with pro features is clearly marked

**Success Criteria:** ✅ All CI checks pass + Complete and accurate documentation + Migration guide available

**Estimated Duration:** 2-3 days

**Developer Notes:**

- When updating documentation and examples, ensure any new example files or documentation directories are properly placed
- If examples use pro features, make sure they're clearly marked and that any example code respects the license boundaries
- Update the main README.md to accurately list all current pro directory paths
- Focus on making the monorepo approachable for new contributors

---

## License Compliance Framework

### Critical License Rules

1. **Directory Classification:**

   - **MIT Licensed:** `lib/react_on_rails/`, `packages/react-on-rails/`, core specs
   - **Pro Licensed:** All directories explicitly listed in LICENSE.md under "React on Rails Pro License"

2. **LICENSE.md Updates:**

   - Must be updated whenever pro directories are moved or renamed
   - Must accurately reflect current directory structure
   - Pro directories must be explicitly listed

3. **File Movement Verification:**
   - After moving files, verify no pro code ended up in MIT directories
   - After creating new directories, classify them in LICENSE.md immediately
   - All pro files must retain appropriate license headers

### Automated License Enforcement

#### License Checker Script

Location: `script/check-license-compliance.rb`

```ruby
#!/usr/bin/env ruby
# Script to verify license compliance across the monorepo

PRO_DIRECTORIES = %w[
  lib/react_on_rails_pro
  packages/react-on-rails-pro
  packages/react-on-rails-pro-node-renderer
  spec/ruby/react_on_rails_pro
  spec/packages/react-on-rails-pro
  spec/packages/react-on-rails-pro-node-renderer
].freeze

MIT_DIRECTORIES = %w[
  lib/react_on_rails
  packages/react-on-rails
  spec/ruby/react_on_rails
  spec/packages/react-on-rails
].freeze

def check_pro_license_headers
  puts "🔍 Checking pro files have correct license headers..."
  PRO_DIRECTORIES.each do |dir|
    next unless Dir.exist?(dir)

    files = Dir.glob("#{dir}/**/*.{rb,js,ts,tsx}")
    files.each do |file|
      content = File.read(file)
      unless content.match?(/Pro License|UNLICENSED|React on Rails Pro/i)
        puts "⚠️  WARNING: Pro file missing license header: #{file}"
      end
    end
  end
  puts "✅ Pro license headers verified"
end

def verify_license_md_accuracy
  puts "🔍 Verifying LICENSE.md lists all pro directories..."
  license_content = File.read('LICENSE.md')

  PRO_DIRECTORIES.each do |dir|
    next unless Dir.exist?(dir)

    unless license_content.include?(dir)
      puts "❌ CRITICAL: Pro directory not listed in LICENSE.md: #{dir}"
      exit 1
    end
  end
  puts "✅ LICENSE.md accurately lists all pro directories"
end

check_pro_license_headers
verify_license_md_accuracy
puts "🎉 License compliance check passed!"
```

#### CI Integration

```yaml
license-compliance:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Run License Compliance Check
      run: ruby script/check-license-compliance.rb
```

## Risk Management

### High-Risk Phases

1. **PR #2 (Git Subtree Merge)** - First major structural change
2. **PR #4 (Pro Package Workspace)** - Complex file movements with license implications
3. **PR #6 (CI Unification)** - Could break automated testing

### Risk Mitigation Strategies

1. **Thorough Testing:** Each PR must pass all CI checks
2. **Incremental Changes:** Each PR makes minimal necessary changes
3. **Rollback Capability:** Each phase creates a stable state to return to
4. **License Verification:** Automated checking prevents compliance issues
5. **Documentation:** Clear instructions for each step

### Rollback Procedures

- Each PR branch maintained until next phase is stable
- Git tags at each successful merge point
- Backup of both original repositories
- Clear identification of changes in each PR for targeted rollback

## Development Workflow

### Setup After Merger

```bash
# Clone the monorepo
git clone https://github.com/shakacode/react_on_rails.git
cd react_on_rails

# Install dependencies
bundle install  # Ruby gems
yarn install    # NPM packages (workspace)

# Build all packages
yarn build      # NPM packages
rake build:gems # Ruby gems

# Run tests
yarn test       # NPM package tests
bundle exec rspec spec/ruby  # Ruby tests

# Development commands
yarn workspace react-on-rails build    # Build core package
yarn workspace react-on-rails-pro test # Test pro package
cd packages/react-on-rails && yarn dev  # Development server
```

### Release Process

- **Independent Versioning:** Each package maintains its own version
- **Coordinated Releases:** Core and pro packages can be released together
- **Automated Publishing:** CI handles gem and NPM package publishing
- **Release Notes:** Combined changelog for all packages

## Success Metrics

### Technical Metrics

- [ ] All existing functionality preserved
- [ ] No breaking changes for existing users
- [ ] All CI checks pass throughout process
- [ ] Both gems build and install correctly from root
- [ ] All 3 NPM packages build and publish correctly
- [ ] Workspace commands function properly
- [ ] License compliance verified automatically

### User Experience Metrics

- [ ] Installation instructions remain simple
- [ ] Example applications work without changes
- [ ] Documentation is clear and complete
- [ ] Migration path is straightforward
- [ ] Community can contribute easily

### Operational Metrics

- [ ] Single CI system operational
- [ ] Build times reasonable
- [ ] Development workflow efficient
- [ ] Release process streamlined
- [ ] Maintenance overhead reduced

## Post-Merger Activities

### Immediate (Week 1)

- [ ] Monitor CI stability
- [ ] Address any immediate issues from community
- [ ] Verify all packages publish correctly
- [ ] Update external documentation and tutorials

### Short Term (Month 1)

- [ ] Community feedback collection
- [ ] Performance optimization if needed
- [ ] Additional automation opportunities
- [ ] Archive old react_on_rails_pro repository

### Long Term (Quarter 1)

- [ ] Evaluate monorepo tooling improvements
- [ ] Consider additional shared tooling
- [ ] Assess contributor experience
- [ ] Plan future architectural improvements

## Context for AI Agents

This document serves as the definitive context for implementing the React on Rails monorepo merger. AI agents working on this plan should:

### Core Principles

1. **Follow the PR sequence exactly** - each phase builds on the previous
2. **Ensure CI passes** at every step - this is non-negotiable
3. **Maintain strict license compliance** - update LICENSE.md whenever pro directories change
4. **Preserve package independence** - creating a monorepo, not merging packages
5. **Document all changes** - update READMEs, guides, and examples
6. **Preserve git history** - use subtree merge, not squashed commits

### Implementation Guidelines

- **License First:** Always consider license implications before moving files
- **Test Early:** Run CI checks frequently during development
- **Document Changes:** Update LICENSE.md immediately when directories change
- **Verify Compliance:** Use automated tools to check license boundaries
- **Communicate Progress:** Update issue status and document decisions

### Emergency Procedures

- **License Violation:** Immediately stop and fix LICENSE.md
- **CI Failure:** Do not proceed to next phase until resolved
- **Breaking Changes:** Rollback and reassess approach
- **Community Concerns:** Pause and address feedback

### Success Indicators

- All existing tests pass
- New automated tests for license compliance pass
- Both repositories' functionality preserved
- Clear path for users to migrate
- Community can contribute effectively

## Conclusion

This merger plan balances the benefits of a monorepo (shared tooling, unified development) with the need for separate packages (independent licensing, versioning, and distribution). The phased approach ensures CI safety and license compliance throughout the process.

The key to success is maintaining strict license boundaries while creating a unified development experience. Each phase has clear success criteria and rollback procedures to ensure the project never enters a broken state.

**⚠️ Critical Success Factor:** License compliance is not optional - every file movement must be accompanied by appropriate LICENSE.md updates and verification that no pro code enters MIT-licensed directories.
