# React on Rails Monorepo Migration Analysis

## Executive Summary

The React on Rails monorepo migration is currently in **Phase 2 (Git Merger) - COMPLETE** with the following status:

- Git repository merger completed successfully
- Both open-source and Pro packages now exist in a single repository
- Monorepo workspace structure partially migrated (conductor/surabaya-v1 branch shows full migration)
- Main repository still uses legacy node_package structure
- YALC publishing working in both configurations
- CI/CD systems implemented for monorepo

**Current State**: The master branch maintains backward compatibility with `node_package/` while conductor branches show the target monorepo structure with `packages/` workspace.

---

## 1. Directory Structure & Package Organization

### Current Production Structure (Master Branch)

```
react_on_rails/
├── lib/
│   ├── react_on_rails/           # Core Ruby gem (MIT)
│   └── react_on_rails_pro/       # Pro Ruby gem (Pro License)
├── node_package/
│   ├── src/                      # TypeScript source
│   │   ├── (core files)
│   │   └── pro/                  # Pro-only features
│   ├── lib/                      # Compiled JavaScript (49 files)
│   ├── scripts/
│   └── tests/
├── react_on_rails_pro/
│   ├── lib/react_on_rails_pro/   # Pro Ruby gem
│   ├── packages/
│   │   └── node-renderer/        # Pro Node renderer
│   ├── spec/
│   └── (separate Pro package config)
├── spec/dummy/                   # Rails dummy app for testing
├── package.json                  # Root workspace (points to node_package/lib)
└── package-scripts.yml          # Build scripts
```

### Target Migration Structure (Surabaya-v1 Conductor)

```
react_on_rails/
├── lib/
│   ├── react_on_rails/           # Core Ruby gem (MIT)
│   └── react_on_rails_pro/       # Pro Ruby gem (Pro License)
├── packages/                     # Yarn workspace root
│   ├── react-on-rails/           # Core JS/TS package
│   │   ├── src/
│   │   ├── lib/
│   │   ├── tests/
│   │   └── package.json
│   └── react-on-rails-pro/       # Pro JS/TS package
│       ├── src/
│       ├── lib/
│       ├── tests/
│       └── package.json
├── react_on_rails_pro/           # Pro Ruby gem (legacy, to be deprecated)
├── spec/dummy/                   # Rails dummy app
├── package.json                  # Root workspace (Yarn workspaces)
└── package-scripts.yml
```

**Key Differences:**

- Master: `node_package/src/` + `node_package/lib/` (single package at root)
- Migration: `packages/react-on-rails/` + `packages/react-on-rails-pro/` (separate workspace packages)

---

## 2. YALC Publishing Configuration

### Current Setup

**Root package.json (Master)**:

```json
{
  "main": "node_package/lib/ReactOnRails.full.js",
  "exports": {
    ".": {
      "react-server": "./node_package/lib/pro/ReactOnRailsRSC.js",
      "default": "./node_package/lib/ReactOnRails.full.js"
    },
    "./client": "./node_package/lib/ReactOnRails.client.js"
  },
  "files": ["node_package/lib"],
  "scripts": {
    "prepack": "nps build.prepack",
    "prepare": "nps build.prepack"
  }
}
```

**Pro package.json**:

```json
{
  "name": "@shakacode-tools/react-on-rails-pro-node-renderer",
  "version": "4.0.0",
  "exports": {
    ".": {
      "types": "./packages/node-renderer/dist/ReactOnRailsProNodeRenderer.d.ts",
      "default": "./packages/node-renderer/dist/ReactOnRailsProNodeRenderer.js"
    }
  },
  "files": ["packages/node-renderer/dist"],
  "scripts": {
    "preinstall": "yarn run link-source && yalc add --link react-on-rails",
    "link-source": "cd ../ && yarn && yalc publish"
  }
}
```

**Migration Target (Surabaya-v1)**:

```json
{
  "name": "react-on-rails-workspace",
  "private": true,
  "type": "module",
  "workspaces": ["packages/react-on-rails", "packages/react-on-rails-pro"],
  "scripts": {
    "build": "yarn workspace react-on-rails run build && yarn workspace react-on-rails-pro run build",
    "yalc:publish": "yarn workspaces run yalc:publish"
  }
}
```

### CI Integration

**GitHub Actions (main.yml)**:

```yaml
- name: Install Node modules with Yarn for renderer package
  run: |
    yarn install --no-progress --no-emoji
    sudo yarn global add yalc

- name: yalc publish for react-on-rails
  run: yalc publish

- name: yalc add react-on-rails
  run: cd spec/dummy && yalc add react-on-rails
```

**Status**: Working in both configurations

- Master branch: Single `yalc publish` at root
- Surabaya-v1: `yarn workspaces run yalc:publish` for all packages

---

## 3. Build/Package Scripts

### Current Build System

**package-scripts.yml (Root)**:

```yaml
build:
  prepack:
    script: >
      [ -f node_package/lib/ReactOnRails.full.js ] ||
        (npm run build >/dev/null 2>&1 || true) &&
        [ -f node_package/lib/ReactOnRails.full.js ] ||
        { echo 'Building react-on-rails seems to have failed!'; }

format:
  listDifferent:
    script: prettier --check .
```

**rakelib/node_package.rake**:

```ruby
namespace :node_package do
  task :build do
    puts "Building Node Package and running 'yalc publish'"
    sh "yarn run build && yalc publish"
  end
end

desc "Prepares node_package by building and symlinking any example/dummy apps present"
task node_package: "node_package:build"
```

### Key Build Artifacts

**node_package/lib/** (49 files, 464 KB):

- `ReactOnRails.full.js` (main entry point)
- `ReactOnRails.client.js`
- `ReactOnRails.node.js`
- `pro/` subdirectory (Pro features)
- Individual modules (buildConsoleReplay.js, clientStartup.js, etc.)

### Package Scripts Validation

**Critical Issue Identified**:

- `package-scripts.yml` checks for `node_package/lib/ReactOnRails.full.js`
- If directory structure changes to `packages/react-on-rails/lib/`, this path **MUST be updated**
- Same issue for Pro package checking `packages/node-renderer/dist/ReactOnRailsProNodeRenderer.js`

---

## 4. Documentation Created

### Monorepo Migration Plan

- **File**: `/docs/MONOREPO_MERGER_PLAN.md`
- **Status**: Phase 2 - Git Merger (COMPLETE)
- **Phases**:
  1. ✅ Pre-Merger Preparation (License Cleanup)
  2. ✅ Git Repository Merger (Completed - PR #1824)
  3. 🔄 Pre-Monorepo Structure Preparation (In Progress)
  4. ⏳ Final Monorepo Restructuring
  5. ⏳ CI/CD & Tooling Unification
  6. ⏳ Documentation & Polish
  7. ⏳ Post-Migration Cleanup & Deprecation

### Related Documentation

- **CONTRIBUTING.md**: Updated with monorepo merger notice
- **CI_OPTIMIZATION_SUMMARY.md**: CI optimizations for monorepo
- **CI_FIXES_APPLIED.md**: Documentation of CI fixes
- **SWITCHING_CI_CONFIGS.md**: Guidance for CI configuration switching
- **Conductor CLAUDE.md**: Enhanced developer instructions

### Conductor Documentation Structure

```
.conductor/surabaya-v1/.claude/docs/
├── testing-build-scripts.md      # Critical for path verification
├── master-health-monitoring.md   # CI status checks
├── managing-file-paths.md        # Path validation after refactors
└── analysis/                     # Analysis documents
```

---

## 5. Migration-Related TODOs & Issues

### Completed Tasks ✅

- [x] Git repository merger (PR #1824)
- [x] License compliance setup
- [x] YALC publishing infrastructure
- [x] Dual CI system (GitHub Actions + CircleCI)
- [x] Monorepo documentation
- [x] Workspace configuration (surabaya-v1)

### Active/Pending Tasks 🔄

#### Path Migration Issues

**Critical**: When migrating from `node_package/` to `packages/react-on-rails/`:

1. **package-scripts.yml** references:

   - ❌ `[ -f node_package/lib/ReactOnRails.full.js ]` → ✅ `[ -f lib/ReactOnRails.full.js ]`
   - ❌ `[ -f packages/node-renderer/dist/ReactOnRailsProNodeRenderer.js ]` (already correct in Pro)

2. **package.json** "main" and "files" fields:

   - Master: `"main": "node_package/lib/ReactOnRails.full.js"`
   - Target: `"main": "lib/ReactOnRails.full.js"` (in packages/react-on-rails)

3. **Documentation updates needed**:
   - CONTRIBUTING.md path references (`node_package/` → `packages/react-on-rails/`)
   - CLAUDE.md build artifacts paths
   - GitHub Actions workflows

#### Workspace Integration Tasks

1. **Yarn workspaces validation**

   - Verify all workspace commands work correctly
   - Test cross-workspace dependencies
   - Validate yalc publish chain

2. **CI/CD Integration**

   - Update GitHub Actions for workspace structure
   - Verify separate package versioning works
   - Test independent package publishing

3. **Pro Package Migration**
   - Consolidate `react_on_rails_pro/` with `packages/react-on-rails-pro/`
   - Update Pro package build scripts
   - Ensure license boundaries maintained

#### Testing & Validation

- [ ] Run full test suite against new package structure
- [ ] Verify yalc publish works for both packages independently
- [ ] Test clean install with git dependencies
- [ ] Validate build artifact paths in all configs

### Known Issues

1. **Legacy node_package still present** - maintained for backward compatibility
2. **Dual CI systems** - GitHub Actions (core) + CircleCI (pro) temporary
3. **Path consistency** - need to validate all hardcoded paths after migration

---

## 6. CI/CD Configuration Analysis

### GitHub Actions (main.yml)

**Workflow Coverage**:

- Build webpack test bundles (Ruby 3.2/3.4, Node 20/22)
- Dummy app integration tests
- Gem tests (Ruby, RSpec)
- JS tests (Jest)
- Lint and formatting checks

**YALC Integration**:

```yaml
- name: Install Node modules with Yarn for renderer package
  run: |
    yarn install --no-progress --no-emoji ${{ matrix.dependency-level == 'latest' && '--frozen-lockfile' || '' }}
    sudo yarn global add yalc

- name: yalc publish for react-on-rails
  run: yalc publish

- name: yalc add react-on-rails
  run: cd spec/dummy && yalc add react-on-rails
```

**Current Limitation**:

- Single yalc publish command works for root package
- Need to test with workspace structure (`yarn workspaces run yalc:publish`)

### CircleCI (React on Rails Pro)

- Separate CI system for Pro package
- Test coverage for node-renderer package
- Independent from core package CI

**Migration Task**: Consolidate CI before full monorepo merge

---

## 7. What's Working Well

✅ **Successfully Implemented**:

1. **Git History Preserved** - Both repositories merged with full history
2. **License Boundaries** - Pro files contained in `react_on_rails_pro/` directory
3. **Package Independence** - Each package can be built/tested separately
4. **YALC Publishing** - Working in both configurations
5. **Documentation** - Comprehensive merger plan with 7 phases
6. **Backward Compatibility** - Master branch unchanged, migration on separate conductor branches
7. **Build Artifacts** - All compiled JavaScript properly generated
8. **Test Infrastructure** - Both RSpec and Jest tests functional

---

## 8. What Needs Attention

⚠️ **Critical Path Issues**:

1. **Path References** (HIGHEST PRIORITY)

   - [ ] Update all hardcoded `node_package/lib/` references
   - [ ] Verify `package-scripts.yml` paths after migration
   - [ ] Test `yalc publish` with new paths
   - **Impact**: Breaking yalc publish silently (as happened in Sept 2024)

2. **Workspace Integration** (HIGH)

   - [ ] Validate `yarn workspaces run yalc:publish`
   - [ ] Test cross-workspace dependency resolution
   - [ ] Verify package version management
   - **Impact**: Package installation failures for users

3. **CI/CD Consolidation** (HIGH)

   - [ ] Merge CircleCI into GitHub Actions workflow
   - [ ] Test all CI jobs with workspace structure
   - [ ] Update caching strategies for workspaces
   - **Impact**: Unpredictable CI behavior, missing test coverage

4. **Pro Package Migration** (MEDIUM)

   - [ ] Consolidate `react_on_rails_pro/` with `packages/react-on-rails-pro/`
   - [ ] Remove redundant configurations
   - [ ] Update build scripts
   - **Impact**: Maintenance overhead, confusion about package locations

5. **Documentation Sync** (MEDIUM)
   - [ ] Update CONTRIBUTING.md with workspace paths
   - [ ] Update CLAUDE.md build instructions
   - [ ] Verify all code examples reference correct paths
   - **Impact**: Developer confusion, incorrect setup instructions

---

## 9. Critical Dependencies & Interactions

### Package Dependencies

```
react-on-rails (core)
  ├── peer: react >= 16
  ├── peer: react-dom >= 16
  └── peer: react-on-rails-rsc 19.0.2 (optional)

react-on-rails-pro (in packages/)
  ├── depends: react-on-rails (local via yalc)
  ├── depends: @fastify/formbody ^7.4.0 || ^8.0.2
  ├── depends: fastify ^4.29.0 || ^5.2.1
  └── peer: @sentry/node (optional)

react-on-rails-pro-node-renderer (Pro only)
  ├── depends: react-on-rails-pro
  └── (separate npm package)
```

### Build Chain

```
yarn (root workspaces)
  └── build (all packages)
      ├── packages/react-on-rails
      │   └── TypeScript compile → lib/
      └── packages/react-on-rails-pro
          └── TypeScript compile → lib/
  └── yalc:publish (all packages)
      ├── yalc publish (core)
      └── yalc publish (pro)
```

### CI Chain

```
GitHub Actions
  ├── build-dummy-app-webpack-test-bundles
  │   ├── yarn install (root)
  │   ├── yalc publish
  │   ├── yarn add react-on-rails (spec/dummy)
  │   └── yarn install (spec/dummy)
  └── dummy-app-integration-tests
      ├── RSpec tests
      └── Jest tests
```

---

## 10. Key Files for Monitoring

### Config Files to Watch

- `package.json` (main + exports fields)
- `package-scripts.yml` (build paths)
- `.github/workflows/main.yml` (CI integration)
- `rakelib/node_package.rake` (build tasks)
- `.circleci/*` (Pro CI configs)

### Documentation Files

- `docs/MONOREPO_MERGER_PLAN.md` (authoritative migration plan)
- `CONTRIBUTING.md` (developer instructions)
- `CLAUDE.md` (project guidelines)
- `.conductor/surabaya-v1/.claude/docs/managing-file-paths.md` (path validation)

### Build Artifacts to Validate

- `node_package/lib/ReactOnRails.full.js` (master)
- `packages/react-on-rails/lib/ReactOnRails.full.js` (target)
- `react_on_rails_pro/packages/node-renderer/dist/` (Pro artifacts)

---

## 11. Recommendations for Next Steps

### Phase 3: Pre-Monorepo Structure Preparation

1. **Validate Current State**

   - [ ] Run full test suite on surabaya-v1
   - [ ] Verify yalc publish works with workspace structure
   - [ ] Test clean install scenarios

2. **Path Migration Checklist**

   - [ ] Update all `package-scripts.yml` paths
   - [ ] Update all CI workflow paths
   - [ ] Search codebase for hardcoded `node_package/` references
   - [ ] Run `yarn run yalc.publish` manually (critical!)

3. **Documentation Alignment**
   - [ ] Update CONTRIBUTING.md section on npm development
   - [ ] Update CLAUDE.md build artifact documentation
   - [ ] Update code examples to use correct paths

### Phase 4: Final Monorepo Restructuring

1. **Consolidate Pro Package**

   - [ ] Merge `react_on_rails_pro/` into monorepo structure
   - [ ] Remove redundant configurations
   - [ ] Update gemspec files

2. **CI/CD Consolidation**

   - [ ] Move CircleCI jobs to GitHub Actions
   - [ ] Update workspace cache strategies
   - [ ] Verify all test jobs pass

3. **Publish Strategy**
   - [ ] Test independent package publishing
   - [ ] Verify version management works
   - [ ] Document release process for monorepo

---

## 12. Success Criteria for Migration

✅ **Migration will be complete when**:

1. **Structure**

   - All JavaScript packages in `packages/` directory
   - Yarn workspaces configured and working
   - No references to `node_package/src/` in documentation

2. **Build & Package**

   - `yarn build` compiles all packages
   - `yarn yalc:publish` publishes all packages
   - `yarn run prepack` passes pre-publication checks
   - All build artifacts in expected locations

3. **Testing**

   - All RSpec tests pass (Ruby)
   - All Jest tests pass (JavaScript)
   - CI/CD pipeline fully operational
   - Clean install works for all package types

4. **Documentation**

   - All developer instructions updated
   - Path references accurate
   - Release process documented
   - License boundaries clearly marked

5. **Backward Compatibility**
   - Existing consumers unaffected
   - npm package exports unchanged
   - Ruby gem APIs unchanged
   - Undocumented/internal paths may change
