# Phase 6: Restructure Ruby Gems to Final Layout - Detailed Checklist

**Goal:** Make react_on_rails_pro a sibling structure instead of nested subdirectory

**Branch:** `restructure-ruby-gems`

**Estimated Time:** 3-4 days

**⚠️ CRITICAL:** This phase significantly changes directory structure. Test thoroughly at each step.

---

## Pre-Phase Verification

- [ ] Verify Phase 5 is complete (all 3 NPM packages in workspace)
- [ ] Verify current structure:

  ```bash
  # Should exist:
  ls -la react_on_rails_pro/lib/react_on_rails_pro/
  ls -la react_on_rails_pro/react_on_rails_pro.gemspec

  # Should NOT exist yet:
  ls -la lib/react_on_rails_pro/         # Should fail
  ls -la react_on_rails_pro.gemspec      # Should fail (at root)
  ```

- [ ] Create feature branch:

  ```bash
  git checkout -b restructure-ruby-gems
  ```

- [ ] Create backup tag (safety):
  ```bash
  git tag pre-phase-6-restructure
  ```

---

## Step 1: Move Pro Ruby Gem Code

### 1.1: Prepare Target Directory

- [ ] Ensure target doesn't exist:
  ```bash
  [ ! -d lib/react_on_rails_pro ] && echo "✅ Ready to proceed"
  ```

### 1.2: Move Pro Lib Files

- [ ] Count files being moved:

  ```bash
  find react_on_rails_pro/lib/react_on_rails_pro -type f | wc -l
  ```

- [ ] Move pro lib directory with git mv (preserves history):

  ```bash
  git mv react_on_rails_pro/lib/react_on_rails_pro lib/
  ```

- [ ] Verify files moved:

  ```bash
  ls -la lib/react_on_rails_pro/
  git status
  ```

- [ ] Check that both gems are now siblings:
  ```bash
  ls -la lib/
  # Should show:
  # - react_on_rails/
  # - react_on_rails_pro/
  ```

---

## Step 2: Move Pro Specs

**Decision Point:** Where should Pro specs live?

- **Option A:** `lib/react_on_rails_pro/spec/` (with gem code)
- **Option B:** `spec/pro/` (separate from gem code)
- **Option C:** Keep at current location for now

**Recommended:** Option B (`spec/pro/`) for consistency with current structure

### 2.1: Create Spec Directory (Option B)

- [ ] Create spec/pro directory:
  ```bash
  mkdir -p spec/pro
  ```

### 2.2: Move Pro Specs

- [ ] Count spec files:

  ```bash
  find react_on_rails_pro/spec -name "*_spec.rb" | wc -l
  ```

- [ ] Move spec files:

  ```bash
  git mv react_on_rails_pro/spec/* spec/pro/
  ```

- [ ] Verify specs moved:
  ```bash
  ls -la spec/pro/
  ```

### 2.3: Update RSpec Configuration

- [ ] Check if `.rspec` or `spec/spec_helper.rb` needs updates
- [ ] Update any paths that assume pro specs are in `react_on_rails_pro/spec/`
- [ ] Test specs can be found:
  ```bash
  bundle exec rspec --dry-run spec/pro/
  ```

---

## Step 3: Move Pro Gemspec to Root

### 3.1: Move Gemspec File

- [ ] Move gemspec to root:

  ```bash
  git mv react_on_rails_pro/react_on_rails_pro.gemspec ./
  ```

- [ ] Verify both gemspecs at root:
  ```bash
  ls -la *.gemspec
  # Should show:
  # - react_on_rails.gemspec
  # - react_on_rails_pro.gemspec
  ```

### 3.2: Update Gemspec Paths

- [ ] Open `react_on_rails_pro.gemspec`

- [ ] Update `lib` path (used to be at `react_on_rails_pro/`, now at root):

  ```ruby
  # OLD:
  lib = File.expand_path("lib", __dir__)
  # This was pointing to react_on_rails_pro/lib/

  # NEW (should stay same, but verify):
  lib = File.expand_path("lib", __dir__)
  # Now points to root lib/, which contains lib/react_on_rails_pro/
  ```

- [ ] Update require path for version (if needed):

  ```ruby
  # OLD:
  require "react_on_rails_pro/version"

  # NEW (should be same):
  require "react_on_rails_pro/version"
  # Path should still work since lib/react_on_rails_pro/ is in load path
  ```

- [ ] Update core version dependency path:

  ```ruby
  # OLD:
  require_relative "../lib/react_on_rails/version"

  # NEW:
  require_relative "lib/react_on_rails/version"
  ```

- [ ] Update file patterns if they reference old structure:
  ```ruby
  s.files = `git ls-files -z`.split("\x0").reject do |f|
    # Make sure this doesn't exclude lib/react_on_rails_pro/
    # Update patterns as needed
  end
  ```

### 3.3: Test Gemspec Validity

- [ ] Test gemspec loads:

  ```bash
  gem build react_on_rails_pro.gemspec
  ```

- [ ] Verify gem contents:

  ```bash
  gem spec react_on_rails_pro-*.gem --ruby | grep files
  ```

- [ ] Clean up test gem:
  ```bash
  rm react_on_rails_pro-*.gem
  ```

---

## Step 4: Update Root Gemfile

### 4.1: Update Gemfile Configuration

- [ ] Open root `Gemfile`

- [ ] Update to include both gemspecs:

  ```ruby
  # OLD (likely just had one gemspec):
  gemspec

  # NEW:
  gemspec name: "react_on_rails"
  gemspec name: "react_on_rails_pro"

  # Development dependencies
  # ... rest of Gemfile
  ```

### 4.2: Update Bundle Configuration

- [ ] Run bundle install:

  ```bash
  bundle install
  ```

- [ ] Verify both gems are in bundle:

  ```bash
  bundle list | grep react_on_rails
  # Should show:
  # - react_on_rails
  # - react_on_rails_pro
  ```

- [ ] Test gem can be required:
  ```bash
  bundle exec ruby -e "require 'react_on_rails_pro'; puts 'OK'"
  ```

---

## Step 5: Update Ruby Require Paths

### 5.1: Find Files with Require Statements

- [ ] Find all Ruby files that require pro code:

  ```bash
  grep -r "require.*react_on_rails_pro" --include="*.rb" .
  ```

- [ ] Check for require_relative statements:
  ```bash
  grep -r "require_relative.*react_on_rails_pro" --include="*.rb" .
  ```

### 5.2: Update Require Paths

Most should still work, but verify paths like:

- [ ] In `lib/react_on_rails_pro/version.rb` - check module structure
- [ ] In `lib/react_on_rails_pro.rb` (if exists) - main entry point
- [ ] In `spec/pro/` files - update paths to lib files
- [ ] In rake tasks - update any hardcoded paths

### 5.3: Test Requires Work

- [ ] Test in IRB:
  ```bash
  bundle exec irb
  > require 'react_on_rails_pro'
  > ReactOnRailsPro::VERSION
  ```

---

## Step 6: Update LICENSE.md

### 6.1: Update License File

- [ ] Open `LICENSE.md`

- [ ] Remove old `react_on_rails_pro/` directory reference

- [ ] Update to final structure:

  ```md
  ## MIT License applies to:

  - lib/react_on_rails/ (including all subdirectories)
  - packages/react-on-rails/ (including tests)
  - All other files not explicitly listed as Pro-licensed below

  ## React on Rails Pro License applies to:

  - lib/react_on_rails_pro/ (including all subdirectories)
  - spec/pro/ (Pro test files)
  - packages/react-on-rails-pro/ (including tests)
  - packages/react-on-rails-pro-node-renderer/ (including tests)
  - react_on_rails_pro.gemspec
  ```

### 6.2: Verify License Compliance

- [ ] No pro files in MIT directories:

  ```bash
  # This should find nothing:
  find lib/react_on_rails packages/react-on-rails -type f -name "*pro*"
  ```

- [ ] All pro files have headers:
  ```bash
  find lib/react_on_rails_pro -name "*.rb" | while read f; do
    if ! head -20 "$f" | grep -q "Pro License\|UNLICENSED"; then
      echo "Missing header: $f"
    fi
  done
  ```

---

## Step 7: Remove Empty react_on_rails_pro Directory

### 7.1: Verify Directory is Empty

- [ ] Check what's left in react_on_rails_pro/:

  ```bash
  ls -la react_on_rails_pro/
  ```

- [ ] Should only see leftover config/docs:
  - `.rubocop.yml` (can be removed or kept for reference)
  - `README.md` (should be moved or merged)
  - `.gitignore` (can be removed)
  - Documentation files (move to `docs/pro/` if valuable)
  - CI config files (should already be removed)

### 7.2: Handle Remaining Files

- [ ] **CHANGELOG.md**: Move to root as CHANGELOG_PRO.md:

  ```bash
  # Move Pro changelog to root as sibling
  git mv react_on_rails_pro/CHANGELOG.md CHANGELOG_PRO.md
  ```

- [ ] **README.md**: Move valuable content to root README or docs/:

  ```bash
  # If valuable, preserve content:
  cat react_on_rails_pro/README.md >> docs/pro/README.md
  ```

- [ ] **Config files**: Remove or move to root if needed:

  ```bash
  # If has unique rubocop rules, merge into root .rubocop.yml
  # Otherwise delete
  ```

- [ ] **Documentation**: Move to docs/pro/:
  ```bash
  mv react_on_rails_pro/docs/* docs/pro/ 2>/dev/null || true
  ```

### 7.3: Remove Directory

- [ ] Verify again it's safe to delete:

  ```bash
  ls -la react_on_rails_pro/
  ```

- [ ] Remove the directory:

  ```bash
  git rm -rf react_on_rails_pro/
  ```

- [ ] Verify git status:
  ```bash
  git status
  # Should show react_on_rails_pro/ as deleted
  ```

---

## Step 8: Update File Paths in Scripts and CI

### 8.1: Update Rake Tasks

- [ ] Find rake tasks referencing old path:

  ```bash
  grep -r "react_on_rails_pro/" rakelib/
  ```

- [ ] Update to new paths:
  - `lib/react_on_rails_pro/` for Ruby gem code
  - `spec/pro/` for pro specs
  - `packages/react-on-rails-pro*` for NPM packages

### 8.2: Update GitHub Actions Workflows

- [ ] Find workflows with old paths:

  ```bash
  grep -r "react_on_rails_pro/" .github/workflows/
  ```

- [ ] Update all references to use new paths

### 8.3: Update Shell Scripts

- [ ] Check bin/ scripts:

  ```bash
  grep -r "react_on_rails_pro/" bin/
  ```

- [ ] Update script/ directory:
  ```bash
  grep -r "react_on_rails_pro/" script/
  ```

### 8.4: Update Documentation

- [ ] Update all markdown files:

  ```bash
  grep -r "react_on_rails_pro/" docs/ --include="*.md"
  ```

- [ ] Update CLAUDE.md:
  - Update changelog section to reference `/CHANGELOG_PRO.md`
  - Update any paths referencing old structure
- [ ] Update CONTRIBUTING.md
- [ ] Update any README files

---

## Step 9: Update RuboCop Configuration

### 9.1: Update Exclusions

- [ ] Open `.rubocop.yml`

- [ ] Update exclusions to use new paths:

  ```yaml
  AllCops:
    Exclude:
      # Remove this if it exists:
      # - 'react_on_rails_pro/**/*'

      # These should stay:
      - 'lib/react_on_rails_pro/**/*' # Still excluded (different config)
      - 'spec/pro/**/*' # Pro specs
      - 'packages/**/*' # NPM packages
  ```

### 9.2: Test RuboCop

- [ ] Run RuboCop on all Ruby files:

  ```bash
  bundle exec rubocop
  ```

- [ ] Fix any violations:
  ```bash
  bundle exec rubocop -A
  ```

---

## Step 10: Update CI Configuration

### 10.1: Update Test Paths

- [ ] Update GitHub Actions workflows for new spec paths:

  ```yaml
  # OLD:
  - run: bundle exec rspec react_on_rails_pro/spec

  # NEW:
  - run: bundle exec rspec spec/pro
  ```

### 10.2: Update Build Paths

- [ ] Verify CI builds both gems from root
- [ ] Update any caching paths that reference old structure

### 10.3: Update Pro Dummy App Paths (if in CI)

- [ ] Check if CI references pro dummy app:

  ```bash
  grep -r "react_on_rails_pro/spec/dummy" .github/
  ```

- [ ] Update to new location if pro dummy moved (or keep if staying)

---

## Step 11: Handle Pro Dummy App

**Decision Point:** Where should Pro dummy app live?

**Options:**

- **A:** Keep at `react_on_rails_pro/spec/dummy` (least disruptive, but inconsistent)
- **B:** Move to `spec/pro/dummy` (consistent with pro specs location)
- **C:** Move to `spec/dummy_pro` (sibling to main dummy)

**Recommended:** Option A for now (keep in place), can be moved in later PR

### 11.1: If Keeping in Place (Option A)

- [ ] Recreate `react_on_rails_pro/` directory just for dummy app:

  ```bash
  mkdir -p react_on_rails_pro
  ```

- [ ] Move dummy app back if it was deleted:

  ```bash
  # If you deleted it in step 7, restore from git:
  git checkout react_on_rails_pro/spec/dummy
  ```

- [ ] Update LICENSE.md to note this exception:

  ```md
  ## React on Rails Pro License applies to:

  ...

  - react_on_rails_pro/spec/dummy/ (Pro test application)
  ```

### 11.2: If Moving (Option B/C)

- [ ] Move pro dummy app:

  ```bash
  git mv react_on_rails_pro/spec/dummy spec/pro/dummy
  ```

- [ ] Update all paths in dummy app config
- [ ] Update CI paths
- [ ] Test dummy app still works

---

## Step 12: Testing & Validation

### 12.1: Build Both Gems

- [ ] Build core gem:

  ```bash
  gem build react_on_rails.gemspec
  ```

- [ ] Build pro gem:

  ```bash
  gem build react_on_rails_pro.gemspec
  ```

- [ ] Verify both gems built:

  ```bash
  ls -la *.gem
  ```

- [ ] Clean up:
  ```bash
  rm *.gem
  ```

### 12.2: Run Ruby Tests

- [ ] Run core specs:

  ```bash
  bundle exec rspec spec/react_on_rails/
  # Or whatever path core specs are at
  ```

- [ ] Run pro specs:

  ```bash
  bundle exec rspec spec/pro/
  ```

- [ ] Run all specs:
  ```bash
  bundle exec rake run_rspec:gem
  ```

### 12.3: Test Dummy Apps

- [ ] Test core dummy app:

  ```bash
  cd react_on_rails/spec/dummy
  bundle install
  yarn install
  yarn build
  ```

- [ ] Test pro dummy app (if separate):
  ```bash
  cd react_on_rails_pro/spec/dummy  # Or new location
  bundle install
  yarn install
  yarn build
  ```

### 12.4: Integration Testing

- [ ] Test full build:

  ```bash
  bundle && yarn
  yarn build
  bundle exec rake
  ```

- [ ] Verify no broken requires
- [ ] Check for any load path issues

---

## Step 13: Update Documentation

### 13.1: Update MONOREPO_MERGER_PLAN.md

- [ ] Mark Phase 6 as complete
- [ ] Update current state section

### 13.2: Update MONOREPO_MIGRATION_STATUS.md

- [ ] Mark restructuring complete
- [ ] Update directory structure diagrams

### 13.3: Update Architecture Docs

- [ ] Update any architecture diagrams
- [ ] Update developer setup instructions
- [ ] Update contribution guidelines

---

## Step 14: Final Verification

### 14.1: Visual Verification

- [ ] Verify final structure matches target:
  ```bash
  tree -L 3 -I 'node_modules|coverage|tmp'
  # Should show:
  # lib/
  #   react_on_rails/
  #   react_on_rails_pro/
  # packages/
  #   react-on-rails/
  #   react-on-rails-pro/
  #   react-on-rails-pro-node-renderer/
  # spec/
  #   pro/
  # *.gemspec (both at root)
  ```

### 14.2: License Compliance

- [ ] Run license compliance check (if automated)
- [ ] Manually verify LICENSE.md is accurate
- [ ] Check no pro code in MIT directories

### 14.3: Pre-Commit Checks

- [ ] Run linters:

  ```bash
  bundle exec rubocop
  yarn lint
  ```

- [ ] Run tests:

  ```bash
  bundle exec rake
  yarn test
  ```

- [ ] Check git status:
  ```bash
  git status
  ```

---

## Commit & Push

- [ ] Stage all changes:

  ```bash
  git add -A
  ```

- [ ] Review diff one more time:

  ```bash
  git diff --staged --stat
  ```

- [ ] Commit with detailed message:

  ```bash
  git commit -m "Phase 6: Restructure Ruby Gems to Final Layout

  Major directory restructure to make react_on_rails_pro a sibling instead of subdirectory.

  Changes:
  - Move lib/react_on_rails_pro/ to root lib/ (sibling to react_on_rails)
  - Move spec/pro/ to root spec/
  - Move react_on_rails_pro.gemspec to root
  - Remove empty react_on_rails_pro/ directory
  - Update all require paths and imports
  - Update Gemfile to include both gemspecs
  - Update LICENSE.md with final structure
  - Update all CI workflows for new paths
  - Update all documentation

  Directory structure now matches monorepo plan target architecture.
  Both gems are now equal siblings in the monorepo.

  Breaking Changes: None for users (gem names/APIs unchanged)
  Internal Changes: Significant path changes for contributors

  Closes Phase 6 of monorepo migration plan."
  ```

- [ ] Push branch:
  ```bash
  git push -u origin restructure-ruby-gems
  ```

---

## Create Pull Request

- [ ] Create PR:

  ```bash
  gh pr create --title "Phase 6: Restructure Ruby Gems to Final Layout" \
               --body "$(cat <<'EOF'
  ## Summary

  Completes Phase 6 of the monorepo migration by restructuring the directory layout so react_on_rails_pro is a sibling structure instead of a nested subdirectory.

  ### Major Changes

  #### Directory Moves:
  - `react_on_rails_pro/lib/react_on_rails_pro/` → `lib/react_on_rails_pro/`
  - `react_on_rails_pro/spec/` → `spec/pro/`
  - `react_on_rails_pro/react_on_rails_pro.gemspec` → `react_on_rails_pro.gemspec` (root)
  - Removed `react_on_rails_pro/` directory (except dummy app)

  #### Configuration Updates:
  - Updated `Gemfile` to include both gemspecs
  - Updated all require paths
  - Updated LICENSE.md with final structure
  - Updated all CI workflows
  - Updated RuboCop exclusions

  ### Benefits

  - ✅ Clearer directory structure (equal siblings, not parent/child)
  - ✅ Both gems buildable from root
  - ✅ Licensing boundaries more obvious
  - ✅ Matches monorepo plan target architecture

  ### Test Plan

  - [x] Both gems build from root
  - [x] All Ruby tests pass
  - [x] All NPM tests pass
  - [x] Dummy apps still work
  - [x] No broken requires or imports
  - [x] LICENSE.md is accurate
  - [x] CI passes

  ### Migration Impact

  **Users:** No impact (gem names and APIs unchanged)
  **Contributors:** Must update local clones, paths changed

  ### Related

  - Completes Phase 6 of monorepo migration
  - Resolves directory structure confusion
  - Prepares for final documentation phase

  EOF
  )"
  ```

---

## Success Criteria ✅

Before merging, verify:

- [ ] Both gems build successfully from root
- [ ] All tests pass (Ruby + JS)
- [ ] No `react_on_rails_pro/` directory exists (except maybe dummy)
- [ ] LICENSE.md accurately reflects new structure
- [ ] All CI checks pass
- [ ] No broken requires or imports
- [ ] Documentation updated
- [ ] Code review approved

---

## Rollback Plan

If critical issues arise:

```bash
# Revert to pre-phase-6 tag
git reset --hard pre-phase-6-restructure

# Or revert the merge commit if already merged
git revert -m 1 <merge-commit-sha>
```

---

## Post-Merge Verification

After merging to master:

- [ ] Delete old tag:

  ```bash
  git tag -d pre-phase-6-restructure
  ```

- [ ] Create new stable tag:

  ```bash
  git tag monorepo-phase-6-complete
  git push --tags
  ```

- [ ] Update team on structure change
- [ ] Monitor CI on master for any issues

---

**Next Phase:** Phase 7 - Final CI/CD polish
**Then:** Phase 8 - Documentation & examples
