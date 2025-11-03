# Shakapacker 9.3.0 Upgrade - PR Breakdown Strategy

## Current Status

- **Master branch**: Shakapacker 8.2.0 (per Gemfile.lock)
- **Feature branch**: Shakapacker 9.3.0
- **Total changes**: 90 commits, 402 files modified

## Key Architectural Notes

- **Babel**: Used for non-React Server Components
- **SWC**: Used for React Server Components
- **React version**: React 19 with conditional exports ('react-server' vs 'default')

---

## Recommended PR Sequence

### PR #1: Preparatory Refactoring (Low Risk)

**Goal**: Extract changes that improve code quality without changing behavior

**Commits to cherry-pick**:

- `517f1579` - Fix unsafe system calls to use array form in pack_generator.rb
- `5186da7a` - Fix bin/dev pack generation in Bundler context
- `1c37907f` - Skip generate_packs when shakapacker precompile hook configured
- `e33826f8` - Fix generator robustness issues

**Files changed**:

- `lib/react_on_rails/dev/pack_generator.rb`
- `lib/react_on_rails/engine.rb`
- `lib/generators/react_on_rails/base_generator.rb`

**Why first**: These are bug fixes and safety improvements that work with 8.2.0

**Risk**: Low - No dependency changes

---

### PR #2: Version Validation Improvements (Low Risk)

**Goal**: Improve version checking to handle Shakapacker upgrade scenarios

**Commits to cherry-pick**:

- `45821a25` - Add lockfile version resolution for exact version checking
- `777bee2e` - Skip version validation when package.json doesn't exist during setup
- `2def04b0` - Fix CI failure by skipping version validation during generator runtime
- `ae5425bd` - Fix generator validation by using environment variable
- `8b7fb6a1` - Skip version validation when react-on-rails package not installed
- `0d87ea75` - Unify release scripts and add strict version validation

**Files changed**:

- `lib/react_on_rails/version_checker.rb`
- `lib/react_on_rails/packer_utils.rb`
- `lib/generators/react_on_rails/base_generator.rb`
- Test files for version checking

**Why second**: Sets up better version checking before we start upgrading

**Risk**: Low - Only affects validation, not runtime behavior

---

### PR #3: Babel Configuration Updates (Medium Risk)

**Goal**: Update Babel config detection for Shakapacker 9.x path changes

**Commits to cherry-pick**:

- `6b76f956` - Fix using_swc? to properly parse YAML and default to babel
- `f454ea0d` - Update using_swc? to return true by default for Shakapacker 9.3.0

**Files changed**:

- `lib/react_on_rails/packer_utils.rb`
- Test specs

**Why third**: Shakapacker 9.x changed babel preset paths from `shakapacker/package/babel/preset.js` to different locations

**Risk**: Medium - Changes transpilation detection logic

**Testing needed**:

- Verify non-RSC components still use Babel
- Verify RSC components can use SWC

---

### PR #4: CSS Modules Compatibility Fix (Medium Risk)

**Goal**: Fix CSS Modules namedExport issue with Shakapacker 9.x

**Commits to cherry-pick**:

- `364b730b` - Fix CSS Modules compatibility with Shakapacker 9.0.0

**Files changed**:

- `spec/dummy/config/webpack/commonWebpackConfig.js`
- `react_on_rails_pro/spec/dummy/config/webpack/commonWebpackConfig.js`

**Background**:
Shakapacker 9.0+ defaults CSS Modules to `namedExport: true`, breaking existing code that uses `import styles from './file.module.css'`. Need to override with `namedExport: false`.

**Why fourth**: CSS issues will break builds

**Risk**: Medium - Changes webpack configuration

**Testing needed**: Verify CSS Modules work in dummy apps

---

### PR #5: SWC Loader Support (Medium Risk)

**Goal**: Add SWC loader configuration for RSC bundles

**Commits to cherry-pick**:

- `c86f217e` - Add swc-loader support for Shakapacker 9.3.0
- `ef315c91` - Add swc-loader to React on Rails generator dependencies
- `e7f23659` - Move swc-loader and @swc/core to devDependencies

**Files changed**:

- `lib/generators/react_on_rails/install_generator.rb`
- `packages/react-on-rails-pro/package.json`
- Generator templates

**Why fifth**: Sets up SWC before the Shakapacker upgrade

**Risk**: Medium - Adds new dependency but doesn't require it yet

**Testing needed**: Verify RSC bundles can use SWC

---

### PR #6: Core Shakapacker Upgrade 8.2.0 → 9.3.0 (HIGH RISK)

**Goal**: Update Shakapacker gem and npm package versions

**Commits to cherry-pick**:

- `0b21a528` - Update shakapacker dependency to version 9.3.0
- `c895c45b` - Update shakapacker gem version to 9.3.0 in Pro Gemfiles
- `8a6bb6e2` - Update Pro dummy app yarn.lock for Shakapacker 9.3.0
- `eea877e4` - Update execjs-compatible-dummy yarn.lock for Shakapacker 9.3.0

**Files changed**:

- `Gemfile.lock`
- `spec/dummy/Gemfile.lock`
- `spec/dummy/yarn.lock`
- `react_on_rails_pro/Gemfile*`
- Various `yarn.lock` files

**Why sixth**: This is the actual version bump

**Risk**: HIGH - Version upgrade can break everything

**Testing needed**:

- Run full test suite
- Test all dummy apps
- Test generators
- Manual testing of example apps

---

### PR #7: React 19 Import Compatibility Fix (HIGH RISK)

**Goal**: Fix React import issues with TypeScript + React 19 conditional exports

**Commits to cherry-pick**:

- `1129f940` - Fix React 19 server bundle errors by using named imports (YOUR LATEST FIX)
- `a229abc0` - Fix React 18.0.0 compatibility by using React namespace imports

**Files changed**:

- `packages/react-on-rails-pro/src/RSCProvider.tsx`
- `packages/react-on-rails-pro/src/RSCRoute.tsx`

**Background**:
React 19 has conditional exports (`react-server` vs `default`). TypeScript with `esModuleInterop: false` was generating invalid imports like `import ReactClient from 'react/index.js'`. Fixed by using named imports: `import { createContext, useContext } from 'react'`.

**Why seventh**: Fixes breaking changes introduced by React 19 + Shakapacker 9.3.0

**Risk**: HIGH - Core RSC functionality

**Testing needed**:

- Build server bundles
- Test RSC components render correctly
- Verify no import errors

---

### PR #8: Generator Template Updates (Medium Risk)

**Goal**: Update generator templates for Shakapacker 9.3.0

**Commits to cherry-pick**:

- `6e55fe0f` - Remove Shakapacker config changes from generator templates
- Related generator fixes

**Files changed**:

- `lib/generators/react_on_rails/templates/**`
- Generator specs

**Why eighth**: Templates need to generate 9.3.0-compatible configs

**Risk**: Medium - Affects new installations only

---

### PR #9: Cleanup and Documentation (Low Risk)

**Goal**: Clean up temporary fixes and update docs

**Commits to include**:

- Any reverts from previous attempts
- Documentation updates about Babel vs SWC
- Changelog entries

**Files changed**:

- `CHANGELOG.md`
- `docs/**`
- `CLAUDE.md` updates

**Why last**: Clean up after everything works

**Risk**: Low - Documentation only

---

## Alternative Strategy: Three Focused PRs

If 9 PRs seems too granular:

### **Fast Track Option - 3 PRs**

#### **PR A: Infrastructure Prep (Steps 1-2)**

- Bug fixes + version validation improvements
- ~10 commits, low risk
- Can merge independently

#### **PR B: Shakapacker 9.3.0 Core Upgrade (Steps 3-6)**

- Babel/SWC detection + CSS Modules + SWC support + version bump
- ~15-20 commits, HIGH risk
- Thorough testing required

#### **PR C: React 19 Compatibility + Polish (Steps 7-9)**

- React import fixes + generator updates + docs
- ~15 commits, medium-high risk
- Depends on PR B

---

## Testing Checklist (For Each PR)

- [ ] `bundle exec rubocop` passes with zero offenses
- [ ] `bundle exec rake lint` passes
- [ ] `bundle exec rake all_but_examples` passes
- [ ] Dummy app builds successfully
- [ ] Pro dummy app builds successfully
- [ ] Generator produces working apps
- [ ] Manual smoke test of key features
- [ ] CI passes on all workflows

---

## Key Decisions Needed

1. **How many PRs do you want?**

   - 9 small PRs: Maximum safety, easier review, slower progress
   - 3 medium PRs: Good balance of safety and speed
   - 1-2 large PRs: Fastest but highest risk per review

2. **What's the timeline?**

   - Aggressive (1 week): Go with 2-3 large PRs
   - Moderate (2-3 weeks): Go with 3 medium PRs
   - Conservative (4+ weeks): Go with 9 small PRs

3. **Are there active users/production systems?**

   - Yes → More smaller PRs for safety
   - No/Internal only → Larger PRs acceptable

4. **What's your testing capacity?**
   - Limited → Smaller PRs with focused testing
   - Full QA team → Larger PRs with comprehensive testing

---

## Recommended Approach

Based on the fact that you mentioned 9.2.0 (though git shows 8.2.0), I recommend:

### **3 Medium PRs (Fast Track)**

This balances:

- ✅ Manageable review size
- ✅ Clear separation of concerns
- ✅ Reasonable risk per PR
- ✅ Can complete in 2-3 weeks
- ✅ Each PR provides value independently

**Timeline**:

- Week 1: PR A (prep) - merge after 1-2 days
- Week 2: PR B (core upgrade) - thorough testing, merge after 4-5 days
- Week 3: PR C (React 19 + polish) - merge after 3-4 days

---

## Next Steps

1. **Confirm your preference**: 3, 6, or 9 PRs?
2. **I'll create a new branch for PR #1** with the appropriate commits cherry-picked
3. **Test locally** before pushing
4. **Create PR** with clear description of changes and testing done
5. **Repeat** for subsequent PRs

Would you like me to start with PR A (Infrastructure Prep)?
