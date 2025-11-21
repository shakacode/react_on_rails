# React on Rails Monorepo Migration - Quick Reference

## Migration Phase Status

```
Phase 1: Pre-Merger Preparation              ✅ COMPLETE
Phase 2: Git Repository Merger              ✅ COMPLETE (PR #1824)
Phase 3: Pre-Monorepo Structure Prep        ✅ COMPLETE
Phase 4: Final Monorepo Restructuring       ✅ COMPLETE
Phase 5: Pro Node Renderer Package          ✅ COMPLETE (PR #2069)
Phase 6: Documentation & Polish             ⏳ PLANNED
Phase 7: Post-Migration Cleanup             ⏳ PLANNED
```

## Directory Structure Comparison

```
CURRENT (Master)                    TARGET (Surabaya-v1)
────────────────                    ────────────────────
node_package/src/         →         packages/react-on-rails/src/
node_package/lib/         →         packages/react-on-rails/lib/
node_package/tests/       →         packages/react-on-rails/tests/

react_on_rails_pro/       →         CONSOLIDATE + packages/react-on-rails-pro/
packages/node-renderer/   →         Keep (Pro only)
```

## YALC Publishing Workflow

### Current (Master)

```bash
yarn build
yalc publish                    # Single command at root
cd spec/dummy && yalc add react-on-rails
```

### Target (Surabaya-v1)

```bash
yarn build                      # Builds all workspaces
yarn yalc:publish              # Runs yalc:publish in all workspaces
cd spec/dummy && yalc add react-on-rails
```

## Build Scripts - Path Reference Guide

```
DANGER ZONE - These paths must be validated after any migration:

❌ OLD PATH                                    ✅ NEW PATH
─────────────────────────────────────          ───────────────────────────────────
node_package/lib/ReactOnRails.full.js    →    lib/ReactOnRails.full.js (in workspace)
node_package/lib/ReactOnRails.client.js  →    lib/ReactOnRails.client.js (in workspace)

In package-scripts.yml:
[ -f node_package/lib/ReactOnRails.full.js ] → [ -f lib/ReactOnRails.full.js ]

In package.json:
"main": "node_package/lib/ReactOnRails.full.js" → "main": "lib/ReactOnRails.full.js"
```

## Critical Files to Watch

### Configuration Files

```
📁 ROOT
├── package.json (main, exports, files, workspaces fields)
├── package-scripts.yml (build.prepack paths)
├── rakelib/node_package.rake (build task paths)
└── .github/workflows/main.yml (CI paths)

📁 PACKAGES
├── packages/react-on-rails/package.json
└── packages/react-on-rails-pro/package.json
```

### Build Artifacts to Validate

```
MASTER                              SURABAYA-V1
──────────────────────────────────  ───────────────────────────────────
node_package/lib/ (49 files)    →   packages/react-on-rails/lib/
react_on_rails_pro/packages/    →   packages/react-on-rails-pro/lib/
  node-renderer/dist/
```

## What's Working ✅

| Component            | Status | Details                              |
| -------------------- | ------ | ------------------------------------ |
| Git History          | ✅     | Both repos merged with full history  |
| YALC Publishing      | ✅     | Works in both master and surabaya-v1 |
| License Boundaries   | ✅     | Pro files properly isolated          |
| Package Independence | ✅     | Each package builds separately       |
| Build Artifacts      | ✅     | All files generated correctly        |
| CI/CD Integration    | ✅     | GitHub Actions working               |
| Documentation        | ✅     | Comprehensive migration plan exists  |
| Test Infrastructure  | ✅     | RSpec + Jest functional              |

## What Needs Attention ⚠️

| Priority | Issue                     | Impact                        | Action                             |
| -------- | ------------------------- | ----------------------------- | ---------------------------------- |
| CRITICAL | Path validation           | Silent yalc publish failures  | Test after every path change       |
| HIGH     | Workspace integration     | Package installation failures | Validate workspace commands        |
| HIGH     | CI/CD consolidation       | Unpredictable CI behavior     | Merge CircleCI into GitHub Actions |
| MEDIUM   | Pro package consolidation | Maintenance overhead          | Merge redundant configs            |
| MEDIUM   | Documentation sync        | Developer confusion           | Update all path references         |

## Testing Checklist Before Merging

```
Path Migration Testing
- [ ] Verify all paths in package-scripts.yml
- [ ] Test yarn run yalc.publish manually
- [ ] Check package.json main/exports/files fields
- [ ] Search for hardcoded node_package/ references

Workspace Testing
- [ ] yarn install (root)
- [ ] yarn build (all packages)
- [ ] yarn test (all packages)
- [ ] yarn yalc:publish (all packages)
- [ ] yarn workspaces run check

CI Testing
- [ ] Run GitHub Actions workflow locally
- [ ] Verify all test jobs pass
- [ ] Check build artifact paths in CI

Documentation Testing
- [ ] Follow CONTRIBUTING.md setup instructions
- [ ] Verify code examples work correctly
- [ ] Check that paths are accurate
```

## Key Metrics

| Metric                          | Value                                   |
| ------------------------------- | --------------------------------------- |
| Repositories Merged             | 2                                       |
| Ruby Gems                       | 2 (react_on_rails + react_on_rails_pro) |
| NPM Packages                    | 3 (core + pro + pro-node-renderer)      |
| Compiled JS Files               | 49 in lib/                              |
| Package-Scripts Paths to Update | 3-4                                     |
| CI Workflows to Update          | 2+                                      |
| Documentation Files Affected    | 5+                                      |

## Common Issues & Solutions

### Issue: yalc publish fails silently

**Root Cause**: Path in `package-scripts.yml` incorrect
**Solution**:

```bash
yarn run prepack  # Test prepack script
ls -la lib/ReactOnRails.full.js  # Verify path exists
yarn run yalc.publish  # Manual test
```

### Issue: Workspace packages not building

**Root Cause**: Missing workspace configuration
**Solution**:

```bash
yarn workspaces run build  # Build all
yarn workspaces run check  # Validate all
```

### Issue: CI fails on workspace structure

**Root Cause**: CI paths not updated
**Solution**:

```bash
# Update GitHub Actions to use workspace paths
# Test paths exist before CI runs
cd packages/react-on-rails && yarn build
```

## Documentation References

- 📖 **Main Plan**: `/docs/MONOREPO_MERGER_PLAN.md`
- 🔍 **Detailed Analysis**: `/.claude/docs/analysis/MONOREPO_MIGRATION_ANALYSIS.md`
- 📝 **Contributing Guide**: `/CONTRIBUTING.md`
- ⚙️ **Path Management**: `/.claude/docs/managing-file-paths.md`
- 🏗️ **Build Scripts**: `/.claude/docs/testing-build-scripts.md`

## Next Actions

### Immediate (This Sprint)

- [ ] Review complete analysis document
- [ ] Validate surabaya-v1 branch state
- [ ] Run full test suite on conductor branch
- [ ] Create Phase 3 task breakdown

### Short Term (Next Sprint)

- [ ] Update all path references
- [ ] Consolidate Pro package configuration
- [ ] Merge CI/CD systems
- [ ] Update developer documentation

### Medium Term (Following Sprints)

- [ ] Complete workspace integration
- [ ] Full CI/CD migration
- [ ] Remove legacy structures
- [ ] Release first monorepo version
