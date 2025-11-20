# Monorepo Migration - Comprehensive Task Checklist

## Executive Summary
The monorepo migration is in **Phase 2 (Git Merger) - COMPLETE**. We've successfully merged repositories but need to complete Phases 3-7 to achieve the final monorepo structure with proper YALC publishing, directory organization, and CI/CD consolidation.

## 🚨 Critical Issues to Address First

### 1. YALC Publishing - All Packages
**Priority: CRITICAL** ⚠️
- [ ] Fix `package-scripts.yml` path reference from `node_package/lib/` to `packages/react-on-rails/lib/`
- [ ] Implement YALC publishing for ALL packages:
  - [ ] `packages/react-on-rails` (open-source core)
  - [ ] `packages/react-on-rails-pro` (Pro features)
  - [ ] `packages/react-on-rails-pro-rsc` (React Server Components)
- [ ] Create unified `yalc:publish:all` script in root package.json
- [ ] Test with: `yarn workspaces run yalc:publish`
- [ ] Verify packages are published to correct yalc store locations
- [ ] Document yalc workflow for all packages

### 2. Evaluate YALC Alternatives
**Priority: HIGH**
- [ ] Research npm/yarn link improvements in recent versions
- [ ] Evaluate Verdaccio (local npm registry)
- [ ] Consider yarn workspaces with `file:` protocol
- [ ] Test pnpm's superior linking capabilities
- [ ] Document pros/cons of each approach
- [ ] Create migration plan if switching tools

### 3. Directory Restructuring - Siblings Not Nested
**Priority: HIGH**
- [ ] Create new structure:
  ```
  /packages/
    /react-on-rails/         # Open source package
    /react-on-rails-pro/     # Pro package (NOT nested)
    /react-on-rails-pro-rsc/ # RSC package
  ```
- [ ] Move `react_on_rails_pro/` from nested to sibling
- [ ] Update all import paths and references
- [ ] Maintain license boundaries between packages
- [ ] Update workspace configuration in root package.json
- [ ] Verify no cross-package file access violations

## 📋 Phase 3: Pre-Monorepo Structure Preparation

### Path Reference Updates
- [ ] Update `package-scripts.yml` all paths
- [ ] Fix `package.json` "main", "exports", "files" fields
- [ ] Update `.github/workflows/*.yml` cache and artifact paths
- [ ] Fix `rakelib/node_package.rake` task paths
- [ ] Update `lib/generators/**/templates/**` generated code paths
- [ ] Fix webpack configs output paths
- [ ] Search and replace ALL `node_package/` references
- [ ] Verify with: `grep -r "node_package" . --exclude-dir=node_modules`

### Build System Validation
- [ ] Test `yarn run prepack` succeeds
- [ ] Test `yarn run yalc.publish` for each package
- [ ] Verify `yarn build` outputs to correct directories
- [ ] Check `ls -la packages/*/lib/*.js` shows all artifacts
- [ ] Test clean install: `rm -rf node_modules && yarn install`
- [ ] Validate `rake node_package` generates correct structure

### Testing Infrastructure
- [ ] Run full test suite: `rake`
- [ ] Test dummy app: `rake run_rspec:dummy`
- [ ] Test examples: `rake run_rspec:example_basic`
- [ ] Verify Playwright E2E tests pass
- [ ] Test with both minimum and latest CI configurations
- [ ] Validate Pro package tests independently

## 📋 Phase 4: Final Monorepo Restructuring

### Package Organization
- [ ] Consolidate duplicate Pro configurations:
  - [ ] Merge `react_on_rails_pro/` and `packages/react-on-rails-pro/`
  - [ ] Remove redundant config files
  - [ ] Unify linting/formatting rules
- [ ] Implement workspace-level scripts:
  - [ ] `test:all` - run all package tests
  - [ ] `build:all` - build all packages
  - [ ] `lint:all` - lint all packages
  - [ ] `publish:all` - publish all packages
- [ ] Set up inter-package dependencies correctly
- [ ] Verify independent versioning works

### CI/CD Consolidation
- [ ] Merge CircleCI configuration into GitHub Actions
- [ ] Create matrix builds for all packages
- [ ] Set up parallel testing for packages
- [ ] Implement smart caching for workspaces
- [ ] Add package-specific test triggers
- [ ] Verify all CI checks pass

### Documentation Updates
- [ ] Update `CONTRIBUTING.md`:
  - [ ] New setup instructions for monorepo
  - [ ] Package development workflow
  - [ ] Testing procedures for each package
- [ ] Update `CLAUDE.md`:
  - [ ] Workspace structure documentation
  - [ ] Package boundaries and rules
  - [ ] Build and test commands
- [ ] Update `README.md`:
  - [ ] Installation from monorepo
  - [ ] Package descriptions
  - [ ] Development setup
- [ ] Create `packages/*/README.md` for each package
- [ ] Update all code examples with new paths

## 📋 Phase 5: Testing & Validation

### Integration Testing
- [ ] Test fresh clone and setup
- [ ] Verify all packages build independently
- [ ] Test cross-package imports work correctly
- [ ] Validate license boundaries enforced
- [ ] Test publishing workflow (dry-run)
- [ ] Verify backward compatibility maintained

### Performance Testing
- [ ] Benchmark build times vs old structure
- [ ] Test CI/CD pipeline performance
- [ ] Measure install times for consumers
- [ ] Verify tree-shaking still works
- [ ] Check bundle sizes haven't increased

### User Acceptance Testing
- [ ] Test with real-world app using yalc
- [ ] Verify Pro features work correctly
- [ ] Test RSC package functionality
- [ ] Validate generator output works
- [ ] Test upgrade path from old structure

## 📋 Phase 6: Release Preparation

### Version Management
- [ ] Decide on versioning strategy:
  - [ ] Independent versions per package?
  - [ ] Synchronized versions?
  - [ ] Version constraints between packages?
- [ ] Update version bump scripts
- [ ] Create changelog generation for each package
- [ ] Set up automated release notes

### Publishing Pipeline
- [ ] Configure npm publishing for each package
- [ ] Set up GitHub releases for monorepo
- [ ] Create publish checklist/automation
- [ ] Test publishing to npm (dry-run)
- [ ] Verify package contents correct
- [ ] Validate installation from npm works

### Migration Guide
- [ ] Create migration guide for users
- [ ] Document breaking changes
- [ ] Provide upgrade scripts if needed
- [ ] Create rollback procedures
- [ ] Test migration on sample apps

## 📋 Phase 7: Production Deployment

### Final Validation
- [ ] Run comprehensive test suite
- [ ] Perform security audit
- [ ] Check for license compliance
- [ ] Verify all documentation updated
- [ ] Get team sign-off

### Deployment
- [ ] Tag release candidate
- [ ] Deploy to staging/beta channel
- [ ] Monitor for issues (1-2 weeks)
- [ ] Address any reported problems
- [ ] Tag final release
- [ ] Publish to npm
- [ ] Announce release

### Post-Deployment
- [ ] Monitor npm downloads
- [ ] Track GitHub issues
- [ ] Gather user feedback
- [ ] Plan next improvements
- [ ] Archive old repository structure

## 🔍 Success Criteria

### Must Have
- ✅ All packages publish via YALC successfully
- ✅ Pro and open-source are sibling directories
- ✅ All tests pass in new structure
- ✅ CI/CD fully functional
- ✅ Documentation completely updated
- ✅ No breaking changes for users
- ✅ License boundaries maintained

### Nice to Have
- ✅ Improved build performance
- ✅ Better developer experience
- ✅ Cleaner separation of concerns
- ✅ Easier to maintain
- ✅ Simplified release process

## 🚀 Quick Wins (Can Do Now)

1. **Fix package-scripts.yml path** (5 minutes)
2. **Test current YALC publishing** (10 minutes)
3. **Create workspace scripts** (30 minutes)
4. **Update CLAUDE.md paths** (20 minutes)
5. **Run full test suite** (1 hour)

## 📝 Notes and Considerations

### YALC vs Alternatives
- **YALC Pros**: Battle-tested, works with current setup, good isolation
- **YALC Cons**: Extra tool, requires manual publishing, can be confusing
- **Consider**: yarn 2+ workspaces, pnpm, Verdaccio, or npm workspaces

### Directory Structure Philosophy
- Siblings show equal importance and independence
- Clearer license boundaries
- Easier to split repositories later if needed
- Better for CI/CD matrix builds
- Clearer mental model for developers

### Risk Mitigation
- Keep backward compatibility during transition
- Test extensively before merging to master
- Have rollback plan ready
- Communicate changes clearly to users
- Consider beta/canary releases first

## 📅 Suggested Timeline

**Week 1-2**: Critical fixes and YALC improvements
**Week 3-4**: Directory restructuring and path updates
**Week 5-6**: CI/CD consolidation and testing
**Week 7-8**: Documentation and release preparation
**Week 9-10**: Beta testing and feedback
**Week 11-12**: Final release

This timeline is aggressive but achievable with focused effort. Adjust based on team availability and priority.
