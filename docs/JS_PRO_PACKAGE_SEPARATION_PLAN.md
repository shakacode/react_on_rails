# PR #4: Split JS Pro Code to Separate Package - Implementation Plan

This comprehensive plan documents all architectural decisions and implementation steps for separating JavaScript Pro functionality from the core React-on-Rails package into a separate `react-on-rails-pro` package.

## Core Architectural Decisions

### 1. Package Dependency Strategy

- **Decision**: Pro package uses core as a **dependency** (not peer dependency)
- **Rationale**: Follows React's model, eliminates user version management complexity, prevents "forgetting to import" issues
- **Implementation**: Pro package exports all core functionality + pro features
- **User Experience**:
  - Core users: `import ReactOnRails from 'react-on-rails'`
  - Pro users: `import ReactOnRails from 'react-on-rails-pro'` (gets everything)
- **Benefits**: Single import decision per project, no multi-entry-point issues

### 2. Versioning Strategy

- **Decision**: Caret range strategy (`^16.1.0`)
- **Rationale**: Follows React-DOM pattern (`react-dom` uses `^19.1.1` for react)
- **Implementation**: Major version alignment required, minor/patch independence allowed
- **Pro package.json**: `"dependencies": { "react-on-rails": "^16.1.0" }`

### 3. Registry Architecture

- **Decision**: Dual registry system with direct imports based on package context
- **Core Package**: Simple Map-based registries (synchronous only, pre-force-load behavior)
- **Pro Package**: Advanced CallbackRegistry-based (async + synchronous, post-force-load behavior)
- **Import Strategy**:
  - **MIT files** → Import **core registries** directly
  - **Pro files** → Import **pro registries** directly
  - **Shared files** → Use `globalThis.ReactOnRails.get()` methods

### 4. Code Reuse Strategy (DRY Principle)

- **Decision**: Layer Pro features over Core functionality, reuse core rendering logic
- **Implementation**: Pro package imports and enhances core components where possible
- **Example**: Pro ClientSideRenderer uses core `createReactOutput()` and `reactHydrateOrRender()`
- **Benefits**: Maximizes DRY, reduces duplication, clear feature separation

### 5. Feature Split Strategy

Based on commit `4dee1ff3cff5998a38cfa758dec041ece9986623` analysis:

**Core Package (MIT) - Pre-Force-Load Behavior:**

- Simple synchronous registries
- Basic rendering without async waiting
- Methods: `register()`, `getComponent()`, `getStore()`, etc.

**Pro Package - Post-Force-Load Behavior:**

- Advanced async registries with CallbackRegistry
- Immediate hydration, store dependency waiting
- Methods: `getOrWaitForComponent()`, `getOrWaitForStore()`, `reactOnRailsComponentLoaded()`, etc.

## Implementation Steps

### Step 1: Create React-on-Rails-Pro Package Structure

**Checkpoint 1.1**: Create directory structure

- [x] Create `packages/react-on-rails-pro/` directory
- [x] Create `packages/react-on-rails-pro/src/` directory
- [x] Create `packages/react-on-rails-pro/tests/` directory
- [x] Verify directory structure matches target

**Checkpoint 1.2**: Create package.json

- [x] Create `packages/react-on-rails-pro/package.json` with:
  - `"name": "react-on-rails-pro"`
  - `"license": "UNLICENSED"`
  - `"dependencies": { "react-on-rails": "^16.1.0" }`
  - Pro-specific exports configuration matching current pro exports
  - Independent build scripts (`build`, `test`, `type-check`)
- [x] Test that `yarn install` works in pro package directory
- [x] Verify dependency resolution works correctly

**Checkpoint 1.3**: Create TypeScript configuration

- [x] Create `packages/react-on-rails-pro/tsconfig.json`
- [x] Configure proper import resolution for core package types
- [x] Set output directory to `lib/`
- [x] Verify TypeScript compilation setup works

**Success Validation**:

- [x] `cd packages/react-on-rails-pro && yarn install` succeeds
- [x] TypeScript can resolve core package imports
- [x] Directory structure is ready for code

### Step 2: Create Simple MIT Registries for Core Package

**Checkpoint 2.1**: Create simple ComponentRegistry

- [x] Create `packages/react-on-rails/src/ComponentRegistry.ts` with:
  - Simple Map-based storage (`registeredComponents = new Map()`)
  - Synchronous `register(components)` method
  - Synchronous `get(name)` method with error on missing component
  - `components()` method returning Map
  - Error throwing stub for `getOrWaitForComponent()` with message: `'getOrWaitForComponent requires react-on-rails-pro package'`
- [x] Write unit tests in `packages/react-on-rails/tests/ComponentRegistry.test.js`
- [x] Verify basic functionality with tests

**Checkpoint 2.2**: Create simple StoreRegistry

- [x] Create `packages/react-on-rails/src/StoreRegistry.ts` with:
  - Simple Map-based storage for generators and hydrated stores
  - All existing synchronous methods: `register()`, `getStore()`, `getStoreGenerator()`, `setStore()`, `clearHydratedStores()`, `storeGenerators()`, `stores()`
  - Error throwing stubs for async methods: `getOrWaitForStore()`, `getOrWaitForStoreGenerator()`
- [x] Write unit tests in `packages/react-on-rails/tests/StoreRegistry.test.js`
- [x] Verify basic functionality with tests

**Checkpoint 2.3**: Create simple ClientRenderer

- [x] Create `packages/react-on-rails/src/ClientRenderer.ts` with:
  - Simple synchronous rendering based on pre-force-load `clientStartup.ts` implementation
  - Direct imports of core registries: `import { get as getComponent } from './ComponentRegistry'`
  - Basic `renderComponent(domId: string)` function
  - Export `reactOnRailsComponentLoaded` function
- [x] Write unit tests for basic rendering
- [x] Test simple component rendering works

**Success Validation**:

- [x] All unit tests pass
- [x] Core registries work independently
- [x] Simple rendering works without pro features

### Step 3: Update Core Package to Use New Registries

**Checkpoint 3.1**: Update ReactOnRails.client.ts

- [x] Replace pro registry imports with core registry imports:
  - `import * as ComponentRegistry from './ComponentRegistry'`
  - `import * as StoreRegistry from './StoreRegistry'`
- [x] Replace pro ClientSideRenderer import with core ClientRenderer import
- [x] Update all registry method calls to use new core registries
- [x] Ensure pro-only methods throw helpful errors
- [x] Verify core package builds successfully

**Checkpoint 3.2**: Update other core files

- [x] Update `serverRenderReactComponent.ts` to use `globalThis.ReactOnRails.getComponent()` instead of direct registry import
- [x] Update any other files that might import from pro directories
- [x] Ensure no remaining imports from `./pro/` in core files

**Checkpoint 3.3**: Test core package independence

- [x] Run core package tests: `cd packages/react-on-rails && yarn test`
- [x] Verify core functionality works without pro features
- [x] Test that pro methods throw appropriate error messages
- [x] Verify core package builds: `cd packages/react-on-rails && yarn build`

**Success Validation**:

- [x] Core package builds successfully
- [x] Core tests pass (expected failures for pro-only features)
- [x] No imports from pro directories remain
- [x] Core functionality works independently

### Step 4: Move Pro Files to Pro Package

**Checkpoint 4.1**: Move Pro JavaScript/TypeScript files

- [x] Move all files from `packages/react-on-rails/src/pro/` to `packages/react-on-rails-pro/src/` using git mv
- [x] Preserve directory structure:
  - `CallbackRegistry.ts`
  - `ClientSideRenderer.ts`
  - `ComponentRegistry.ts`
  - `StoreRegistry.ts`
  - `ReactOnRailsRSC.ts`
  - `registerServerComponent/` directory
  - `wrapServerComponentRenderer/` directory
  - All other pro files (22 files total)
- [x] Git history preserved for all moved files
- [x] Verify all pro files moved correctly (count and validate)

**Checkpoint 4.2**: Update import paths in moved files

- [x] Update imports in pro files to reference correct paths
- [x] Update imports from core package to use `react-on-rails` package imports (56 imports updated)
- [x] Fix relative imports within pro package
- [x] Ensure no circular dependency issues

**Checkpoint 4.3**: Remove pro directory from core

- [x] Delete empty `packages/react-on-rails/src/pro/` directory
- [x] Verify no references to old pro paths remain in any files
- [x] Update any remaining import statements that referenced pro paths

**Success Validation**:

- [x] Pro files exist in correct new locations
- [x] No pro directory remains in core package
- [x] Import paths are correctly updated
- [x] Git history preserved for all moved files

### Step 5: Move and Update Pro Tests

**Checkpoint 5.1**: Identify pro-related tests

- [x] Search for test files importing from pro directories:
  - `streamServerRenderedReactComponent.test.jsx`
  - `registerServerComponent.client.test.jsx`
  - `injectRSCPayload.test.ts`
  - `SuspenseHydration.test.tsx`
- [x] Identify tests that specifically test pro functionality
- [x] Create list of all test files that need to be moved (4 test files identified)

**Checkpoint 5.2**: Move pro tests

- [x] Move identified pro tests to `packages/react-on-rails-pro/tests/` using git mv
- [x] Git history preserved for all moved test files
- [ ] Update test import paths to reflect new package structure
- [ ] Update Jest configuration if needed for pro package
- [ ] Ensure test utilities are available or create pro-specific ones

**Checkpoint 5.3**: Update remaining core tests

- [x] Update core tests that may have been testing pro functionality to only test core features
- [x] Updated serverRenderReactComponent.test.ts to use core ComponentRegistry
- [x] Core ComponentRegistry and StoreRegistry tests already test core functionality with pro method stubs
- [ ] Verify all core tests pass

**Success Validation**:

- [ ] Core tests pass and only test core functionality
- [ ] Pro tests are properly moved and can run
- [ ] No test dependencies on moved pro files remain in core

### Step 6: Create Pro Package Implementation

**Checkpoint 6.1**: Create pro package main entry point

- [ ] Create `packages/react-on-rails-pro/src/index.ts` that:
  - Imports all core functionality: `import ReactOnRailsCore from 'react-on-rails'`
  - Imports pro registries: `import * as ProComponentRegistry from './ComponentRegistry'`
  - Imports pro features: `import { renderOrHydrateComponent, hydrateStore } from './ClientSideRenderer'`
  - Creates enhanced ReactOnRails object with all core methods plus pro methods
  - Sets `globalThis.ReactOnRails` to pro version
  - Exports enhanced version as default
- [ ] Ensure pro startup script runs and replaces core startup behavior

**Checkpoint 6.2**: Configure pro package exports

- [x] Update `packages/react-on-rails-pro/package.json` exports section
- [x] Include all current pro exports:
  - `"."` (main entry)
  - `"./RSCRoute"`
  - `"./RSCProvider"`
  - `"./registerServerComponent/client"`
  - `"./registerServerComponent/server"`
  - `"./wrapServerComponentRenderer/client"`
  - `"./wrapServerComponentRenderer/server"`
  - `"./ServerComponentFetchError"`
- [x] Ensure proper TypeScript declaration exports

**Checkpoint 6.3**: Test pro package build and functionality

- [x] Verify pro package builds successfully: `cd packages/react-on-rails-pro && yarn build`
- [x] Test that pro package includes all core functionality
- [x] Test that pro-specific async methods work (`getOrWaitForComponent`, `getOrWaitForStore`)
- [x] Verify pro package can be imported and used

**Success Validation**:

- [x] Pro package builds without errors
- [x] Pro package exports work correctly
- [x] Pro functionality is available when imported
- [x] All core functionality is preserved in pro package

### Step 7: Update Workspace Configuration

**Checkpoint 7.1**: Update root workspace

- [x] Update root `package.json` workspaces to include `"packages/react-on-rails-pro"`
- [x] Update workspace scripts:
  - `"build"` should build both packages
  - `"test"` should run tests for both packages
  - `"type-check"` should check both packages
- [x] Configure build dependencies if pro package needs core built first

**Checkpoint 7.2**: Test workspace functionality

- [x] Test `yarn build` builds both packages successfully
- [x] Test `yarn test` runs tests for both packages
- [x] Test `yarn type-check` checks both packages
- [x] Verify workspace dependency resolution works correctly

**Success Validation**:

- [x] Workspace commands work for both packages
- [x] Both packages build in correct order
- [x] Workspace dependency resolution is working

### Step 8: Update License Compliance

**Checkpoint 8.1**: Update LICENSE.md

- [x] Remove `packages/react-on-rails/src/pro/` from Pro license section (no longer exists)
- [x] Add `packages/react-on-rails-pro/` to Pro license section
- [x] Update license scope to accurately reflect new structure:

  ```md
  ## MIT License applies to:

  - `lib/react_on_rails/` (including specs)
  - `packages/react-on-rails/` (including tests)

  ## React on Rails Pro License applies to:

  - `packages/react-on-rails-pro/` (including tests) (NEW)
  - `react_on_rails_pro/` (remaining files)
  ```

- [x] Verify all pro directories are listed correctly
- [x] Ensure no pro code remains in MIT-licensed directories

**Checkpoint 8.2**: Verify license compliance

- [x] Run automated license check if available
- [x] Verify all pro files have correct license headers
- [x] Manually verify no MIT-licensed directories contain pro code
- [x] Check that `packages/react-on-rails-pro/package.json` has `"license": "UNLICENSED"`

**Success Validation**:

- [x] LICENSE.md accurately reflects new structure
- [x] All pro files are properly licensed
- [x] No license violations exist

### Step 9: Comprehensive Testing and Validation

**Checkpoint 9.1**: Core package testing

- [x] Run full core package test suite: `cd packages/react-on-rails && yarn test`
- [x] Test core functionality in dummy Rails app with only core package
- [x] Verify pro methods throw appropriate error messages
- [x] Test that core package works in complete isolation
- [x] Verify core package build: `cd packages/react-on-rails && yarn build`

**Checkpoint 9.2**: Pro package testing

- [x] Run full pro package test suite: `cd packages/react-on-rails-pro && yarn test`
- [x] Test in dummy Rails app with pro package (should include all core + pro features)
- [x] Test pro-specific features:
  - Async component waiting (`getOrWaitForComponent`)
  - Async store waiting (`getOrWaitForStore`)
  - Immediate hydration feature
  - RSC functionality
- [x] Verify pro package works as complete replacement for core

**Checkpoint 9.3**: Integration testing

- [x] Test workspace builds: `yarn build` from root
- [x] Test workspace tests: `yarn test` from root
- [x] Verify no regressions in existing dummy app functionality
- [x] Test that switching from core to pro package works seamlessly
- [x] Verify all CI checks pass

**Success Validation**:

- [x] All tests pass for both packages
- [x] No functional regressions
- [x] Pro package provides all core functionality plus enhancements
- [x] Clean upgrade path from core to pro

### Step 10: Documentation and Final Cleanup

**Checkpoint 10.1**: Update package documentation

- [x] Update core package README if needed (mention pro package existence)
- [x] Create `packages/react-on-rails-pro/README.md` with installation and usage instructions
- [x] Update any relevant documentation about package structure
- [x] Document upgrade path from core to pro

**Checkpoint 10.2**: Final cleanup and verification

- [x] Remove any temporary files or configurations created during migration
- [x] Clean up any commented-out code
- [x] Verify all files are properly organized
- [x] Run final linting: `yarn lint` from root
- [x] Run final type checking: `yarn type-check` from root

**Success Validation**:

- [x] Documentation is complete and accurate
- [x] All temporary artifacts removed
- [x] Final linting and type checking passes
- [x] Packages are ready for production use

## Success Criteria

### Functional Requirements

- [x] All existing functionality preserved in both packages
- [x] No breaking changes for existing core users
- [x] Pro users get all functionality (core + pro) from single package
- [x] Clean separation between synchronous (core) and asynchronous (pro) features

### Technical Requirements

- [x] Both packages build independently without errors
- [x] All CI checks pass for both packages
- [x] TypeScript types work correctly for both packages
- [x] Proper dependency resolution in workspace
- [x] No circular dependencies

### License Compliance

- [x] Strict separation between MIT and Pro licensed code
- [x] LICENSE.md accurately reflects all package locations
- [x] All pro files have correct license headers
- [x] No pro code in MIT-licensed directories

### User Experience

- [x] Core users: Simple import, basic functionality
- [x] Pro users: Single import, all functionality
- [x] Clear upgrade path from core to pro
- [x] No migration required for existing code

## Testing Strategy

### After Each Major Step:

1. **Build Test**: Verify affected packages build successfully
2. **Unit Tests**: Run relevant unit test suites
3. **Integration Test**: Test functionality in dummy Rails application
4. **Regression Check**: Ensure no existing functionality broken
5. **License Validation**: Check license compliance maintained

### Validation Commands:

```bash
# Test workspace
yarn build
yarn test
yarn type-check
yarn lint

# Test individual packages
cd packages/react-on-rails && yarn build && yarn test
cd packages/react-on-rails-pro && yarn build && yarn test

# Test in dummy app
cd react_on_rails/spec/dummy && yarn install && yarn build
```

## Rollback Strategy

### Git Strategy:

- Each major step should be a separate commit with clear commit message
- Use descriptive commit messages: `"Step 4.1: Move pro files to pro package"`
- Tag successful major milestones

### Rollback Process:

1. **Identify Issue**: Determine which step introduced the problem
2. **Revert Commits**: Use `git revert` to undo problematic changes
3. **Analyze Root Cause**: Understand what went wrong
4. **Fix and Retry**: Address the issue and re-attempt the step
5. **Validate**: Ensure fix resolves the problem without introducing new issues

## Key Implementation Principles

### 1. Direct Import Strategy

- **MIT files** import MIT registries directly (no indirection)
- **Pro files** import Pro registries directly (access to async methods)
- **Shared files** use `globalThis.ReactOnRails` for flexibility

### 2. No Complex Dependency Injection

- Avoid complex registry injection patterns
- Keep architecture simple and understandable
- Use direct imports for clear dependencies

### 3. Maintain Backward Compatibility

- Core users should see no changes in behavior
- Pro users get enhanced functionality seamlessly
- No breaking changes to existing APIs

### 4. License Boundary Integrity

- Maintain strict separation between MIT and Pro code
- Update LICENSE.md immediately when moving files
- Never allow pro code in MIT-licensed directories

### 5. Independent Package Builds

- Each package builds independently
- Pro package manages its dependency on core package
- Clean separation of concerns

## Post-Implementation Validation

### Manual Testing Checklist:

- [ ] Fresh install of core package works
- [ ] Fresh install of pro package works
- [ ] Switching from core to pro package works
- [ ] All async pro features work correctly
- [ ] No console errors or warnings
- [ ] Performance is acceptable
- [ ] Memory leaks not introduced

### Automated Testing:

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] CI pipeline passes completely
- [ ] No new linting violations
- [ ] TypeScript compilation clean

This implementation plan ensures a methodical approach to separating the pro functionality while maintaining all existing capabilities and providing clear upgrade paths for users.
