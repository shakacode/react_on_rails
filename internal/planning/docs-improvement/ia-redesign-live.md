# IA Redesign - Live Implementation Tracker

**Purpose:** Track actual implementation progress for the documentation IA redesign. This file tracks what we're _actually doing_ and may diverge from the original plan as we learn and adapt.

**Reference Plan:** See `04-ia-redesign-plan.md` for the detailed original plan.

**Branch:** `feature/docs-ia-redesign`

**Started:** October 2, 2025

---

## Implementation Approach

We're breaking Phase 2 (File Reorganization) into 8 reviewable steps, pausing between each for review before proceeding.

### Why Step-by-Step?

- This is critical infrastructure - can't rush it
- Each step is reviewable and reversible
- Learn from each step before proceeding
- Catch issues early before they compound

---

## Step-by-Step Plan

### ✅ Step 0: Setup & Baseline

- [x] Create feature branch `feature/docs-ia-redesign`
- [x] Commit all planning docs (clean baseline for diffs)
- [x] Create this live tracker
- [ ] Create empty folder structure
- [ ] Review structure before moving files

**Status:** In Progress
**Started:** October 2, 2025

---

### ⏸️ Step 1: Move Getting Started Files (~6-8 files)

- [ ] Move files using `git mv`
- [ ] Verify git history preserved
- [ ] Check for any immediate issues
- [ ] Wait for review before next step

**Rationale:** Small, clear category to validate our approach.

**Status:** Pending
**Files to move:** TBD (from plan mapping)

---

### ⏸️ Step 2: Move Core Concepts Files (~8-10 files)

- [ ] Move files using `git mv`
- [ ] Check for link breakage patterns
- [ ] Wait for review

**Status:** Pending

---

### ⏸️ Step 3: Move Building Features Files (~10-12 files)

- [ ] Move files using `git mv`
- [ ] Larger category - good stress test
- [ ] Wait for review

**Status:** Pending

---

### ⏸️ Step 4: Move API Reference Files (~5-7 files)

- [ ] Move files using `git mv`
- [ ] Straightforward technical docs
- [ ] Wait for review

**Status:** Pending

---

### ⏸️ Step 5: Move Deployment Files (~8-10 files)

- [ ] Move files using `git mv`
- [ ] Includes troubleshooting content
- [ ] Wait for review

**Status:** Pending

---

### ⏸️ Step 6: Move Migration & Upgrading Files (~5-7 files)

- [ ] Move files using `git mv`
- [ ] Version-specific content
- [ ] Wait for review

**Status:** Pending

---

### ⏸️ Step 7: Move Pro Files (~2-3 files)

- [ ] Move files using `git mv`
- [ ] Small, contained category
- [ ] Wait for review

**Status:** Pending

---

### ⏸️ Step 8: Handle Special Files

- [ ] Create new `introduction.md` homepage
- [ ] Delete/archive `home.md` and `README.md`
- [ ] Final review before moving to Phase 1

**Status:** Pending

---

## Decisions & Adaptations

This section tracks any deviations from the original plan and why we made them.

### Decision Log

#### Decision 1: Split Migration & Upgrading into Two Categories (Oct 2, 2025)

**Original plan:** Category 6 called "Migration & Upgrading" in one folder `migration/`

**Decision:** Split into TWO separate categories:

- Category 6: 📈 **Upgrading** (`upgrading/`) - Version upgrades, release notes
- Category 7: 🔄 **Migrating** (`migrating/`) - From other tools (react-rails, angular, etc.)

**Rationale:**

- Research showed popular frameworks use separate "Upgrading" and "Migrating" sections
- Clear distinction: upgrading = staying with RoR between versions; migrating = coming FROM other tools
- Both are important enough to warrant separate categories
- Users have different intents: "I need to upgrade" vs "I'm switching from react-rails"
- Only adds 1 category (8 total vs original 7) - still way better than current 11

**New category structure:**

```
1. 🚀 Getting Started
2. 📚 Core Concepts
3. 🔧 Building Features
4. 📖 API Reference
5. 🚢 Deployment
6. 📈 Upgrading          ← NEW (split from Migration & Upgrading)
7. 🔄 Migrating          ← NEW (split from Migration & Upgrading)
8. 💎 Pro
```

**Files affected:**

- `upgrading/`: upgrading-react-on-rails.md, release notes, version-specific guides
- `migrating/`: from-react-rails.md, from-angular.md

---

#### Decision 2: Keep Descriptive Long Filenames (Oct 2, 2025)

**Question:** Should we rename `installation-into-an-existing-rails-app.md` to just `installation.md`?

**Decision:** Keep the original long descriptive filename.

**Rationale:**

- The distinction between "existing Rails app" vs "new Rails app" is meaningful
- `tutorial.md` covers installation for NEW apps (with `rails new`)
- `installation-into-an-existing-rails-app.md` covers EXISTING apps (already have code)
- Shortening to `installation.md` creates ambiguity - users won't know which scenario it covers
- Descriptive filenames help users find the right doc for their situation

**Pattern:** Prefer descriptive filenames over short ones when there's meaningful distinction.

---

#### Decision 3: Move configuration.md to API Reference (Oct 2, 2025)

**Question:** Should `configuration.md` go in Core Concepts or API Reference?

**Decision:** Move to API Reference.

**Rationale:**

- `configuration.md` is a 391-line reference list of ALL config options
- Same format as `view-helpers-api.md` and `javascript-api.md` (method/parameter lists)
- Users look it up when they need a specific setting (reference usage pattern)
- Not teaching a concept - documenting an interface
- Core Concepts = understanding how things work; API Reference = lookup tables for methods/configs

**Pattern:** Reference lists of options/methods/parameters belong in API Reference, not Core Concepts.

---

#### Decision 4: Rethink Deployment Category - Remove Non-Deployment Files (Oct 3, 2025)

**Context:** After completing Step 5 (moving Deployment files), we reviewed what actually ended up in `deployment/` and found several files that don't belong.

**Problem:** The plan placed these files in Deployment, but upon review they're not deployment-specific.

**Decision:** Move these 5 files OUT of Deployment to proper categories (keeping original filenames per Decision 2):

1. `updating-dependencies.md` → **misc/updating-dependencies.md** (temporary holding)
2. `turbolinks.md` → **building-features/turbolinks.md** (feature integration)
3. `rails-engine-integration.md` → **advanced-topics/rails-engine-integration.md** (temporary holding)
4. `convert-rails-5-api-only-app.md` → **migrating/convert-rails-5-api-only-app.md** (prerequisite migration)
5. `rails_view_rendering_from_inline_javascript.md` → **api-reference/rails_view_rendering_from_inline_javascript.md** (API reference)

**New temporary categories created:**

- `misc/` - For files that don't fit elsewhere (review at end)
- `advanced-topics/` - For advanced setup scenarios (review at end)

**Deployment category now contains (7 files):**

- Production deployment guides (4 files: deployment.md, capistrano, heroku, elastic-beanstalk)
- Troubleshooting production/CI issues (3 files)

**Rationale:**

- Don't force-fit files to match the plan if they don't belong
- Follow industry standards: categorize by user intent, not by technology
- Protect important categories from bloat
- Gather orphaned files in temporary categories for later review
- Deployment should be about getting to production and operating in production

**Pattern:** Categorize by WHEN and WHY users need the info, not by what technology it involves.

---

#### Decision 5: No "Rails" Category Needed (Oct 3, 2025)

**Question:** Should we create a "Rails" category for Rails-specific files?

**Decision:** NO - do not create a "Rails" category.

**Rationale:**

- React on Rails IS a Rails integration - everything is Rails-related
- A "Rails" category would become a dumping ground like the old "Additional details"
- Better to categorize by user intent (what are they trying to do?) not by technology
- Industry pattern: Stimulus, Turbo, Inertia.js don't have "Rails" categories
- Files from old `rails/` folder distributed to appropriate categories by intent

**Pattern:** Intent-based categorization (user journey) beats technology-based categorization.

---

## Issues & Blockers

### Issue 1: Content Overlap in Getting Started (Oct 2, 2025)

**Problem:** Three files overlap significantly in covering installation:

1. **quick-start.md** (212 lines)
   - 15-minute setup
   - Assumes existing Rails app (or just run `rails new`)
   - Steps: install gem → run generator → hello world
2. **installation-into-an-existing-rails-app.md** (67 lines)
   - Detailed installation for existing apps
   - Very similar steps to quick-start
3. **tutorial.md** (389 lines)
   - Comprehensive walkthrough with `rails new`
   - Includes installation + features + deployment

**Issue:** Users may be confused about which guide to follow. Content is redundant.

**Status:** Flagged for Section 2 (Content Improvements) - NOT fixing during IA reorg

**Next steps:** After completing IA restructuring, evaluate whether to:

- Merge quick-start and installation docs
- Delete one and improve the other
- Clarify when to use each with better headers/descriptions

_This is a content problem, not a structure problem. Keep moving files for now._

---

## Testing Notes

### Local Testing Strategy

- Use `gatsby develop` in sc-website repo pointing to this branch
- Verify categories render correctly
- Check navigation flow
- Test internal links

_Test results will be logged here as we go_

---

## Completion Summary

**✅ ALL STEPS COMPLETE (Steps 1-8):**

- Step 1: Getting Started (4 files)
- Step 2: Core Concepts (7 files) + API Reference (1 file)
- Step 3: Building Features (14 files)
- Step 4: API Reference (4 files)
- Step 5: Deployment (9 files, then corrected to 7)
- Step 6: Upgrading (4 files, then moved 1 to pro)
- Step 7: Migrating (2 files)
- Step 8: Pro (1 file)

**✅ ORPHANED FILES REORGANIZED (12 files):**
After Steps 1-8, found 12 files not in original plan. Investigated and reorganized:

- 7 moved to existing categories
- 4 moved to outdated/
- 1 merged and deleted

**Total files moved:** ~50+ files across all steps

---

## Phase 3: Entry Point Consolidation (Oct 7, 2025)

**Branch:** `feature/docs-ia-redesign-1845-continue` (continuing from merged PR #1845)

### Actions Completed:

1. **✅ Deleted orphaned `docs/guides/advanced/README.md`**
   - Navigation index left behind after reorganization
   - Linked to files now in core-concepts/
   - Redundant, deleted

2. **✅ Created `docs/introduction.md`** - New unified homepage
   - Explains what React on Rails is and why use it
   - When to use / when not to use decision guide
   - Three clear paths: Quick Start, Installation, Tutorial
   - Popular use cases quick reference table
   - Core concepts links
   - Philosophy section linking to doctrine
   - Help and support section
   - Added community stat (thousands of production sites)
   - Added all 3 example repos (spec/dummy, demo SSR/HMR, reactrails.com)
   - System requirements from actual docs
   - Built from: overview.md, doctrine.md, README.md structure

3. **✅ Deleted `docs/core-concepts/react-on-rails-overview.md`**
   - Content consolidated into introduction.md
   - Outdated prerequisites (Rails >=5 vs current Rails 7+)
   - Created confusion with two similar entry points
   - Updated 2 links: home.md and doctrine.md

4. **✅ Simplified `docs/README.md`** for GitHub users
   - Reduced from 173 lines to 65 lines
   - Directs to website first
   - Kept valuable learning paths from PR #1813
   - Kept popular use cases table
   - Added documentation categories overview
   - Removed duplicate content (now in introduction.md)
   - Purpose: Serves GitHub users browsing repo, not website visitors

5. **✅ Deleted `docs/home.md`**
   - Was the current website homepage (29 lines of links)
   - Replaced by introduction.md
   - All valuable content already in introduction.md or README.md
   - No unique content lost

6. **✅ Transformed `docs/getting-started.md` → `docs/getting-started/using-react-on-rails.md`**
   - Reduced from 253 to 238 lines (still comprehensive but focused)
   - Removed: Choose Starting Point (redundant), System Requirements (duplicate), More Reading (navigation)
   - Transformed installation section to conceptual overview with links

7. **✅ Deleted `docs/advanced-topics/manual-installation-overview.md`**
   - Outdated since 2018 (had "TODO: Review this file" for 7 years)
   - Confused purpose: title said "Manual Installation" but subtitle said "summarizes what generator does"
   - Outdated content: referenced `/client`, `webpacker`, missing auto-bundling
   - No clear use case: generator IS the manual installation (not external CLI)
   - Content better covered in: how-react-on-rails-works.md, using-react-on-rails.md
   - Removed link from installation-into-an-existing-rails-app.md
   - Decision discussed with team in Slack
   - Deleted original `docs/getting-started.md`

**Remaining Entry Point Tasks:**

- Update website config (sc-website gatsby-node.js) to use introduction.md as homepage

**Next Actions:** Update website config when ready (keeping for last as user requested)

---

## Reference: Final Folder Structure

```
docs/
├── introduction.md              # ✅ Created - new unified homepage
├── README.md                    # ✅ Simplified for GitHub users
├── getting-started/ (5 files)
│   ├── using-react-on-rails.md  # ✅ NEW - Transformed from getting-started.md
│   ├── quick-start.md
│   ├── installation-into-an-existing-rails-app.md
│   ├── tutorial.md
│   └── project-structure.md
├── core-concepts/ (7 files)
│   ├── how-react-on-rails-works.md
│   ├── client-vs-server-rendering.md
│   ├── react-server-rendering.md
│   ├── render-functions-and-railscontext.md
│   ├── render-functions.md                    # Orphaned: detailed render-functions guide
│   ├── auto-bundling-file-system-based-automated-bundle-generation.md
│   └── webpack-configuration.md
├── building-features/ (15 files)
│   ├── hmr-and-hot-reloading-with-the-webpack-dev-server.md
│   ├── i18n.md
│   ├── rspec-configuration.md
│   ├── minitest-configuration.md
│   ├── streaming-server-rendering.md
│   ├── how-to-conditionally-server-render-based-on-device-type.md
│   ├── how-to-use-different-files-for-client-and-server-rendering.md
│   ├── react-router.md
│   ├── react-and-redux.md
│   ├── react-helmet.md
│   ├── rails-webpacker-react-integration-options.md
│   ├── code-splitting.md                      # Moved to outdated/ (marked outdated)
│   ├── images.md
│   ├── foreman-issues.md
│   └── turbolinks.md                          # Step 5 correction: from deployment
├── api-reference/ (7 files)
│   ├── README.md                              # Orphaned: index page
│   ├── view-helpers-api.md
│   ├── javascript-api.md
│   ├── redux-store-api.md
│   ├── configuration.md
│   ├── generator-details.md
│   └── rails_view_rendering_from_inline_javascript.md  # Step 5 correction: from rails/
├── deployment/ (10 files)
│   ├── deployment.md
│   ├── capistrano-deployment.md
│   ├── heroku-deployment.md
│   ├── elastic-beanstalk.md
│   ├── troubleshooting-build-errors.md
│   ├── troubleshooting-when-using-shakapacker.md
│   ├── troubleshooting-when-using-webpacker.md
│   ├── server-rendering-tips.md               # Orphaned: SSR debugging
│   ├── troubleshooting.md                     # Orphaned: comprehensive troubleshooting
│   └── (removed 4 files in Step 5 corrections)
├── upgrading/ (3 files)
│   ├── upgrading-react-on-rails.md
│   └── release-notes/
│       ├── 15.0.0.md
│       └── 16.0.0.md
├── migrating/ (3 files)
│   ├── migrating-from-react-rails.md
│   ├── angular-js-integration-migration.md
│   └── convert-rails-5-api-only-app.md        # Step 5 correction: from deployment
├── pro/ (2 files)
│   ├── react-on-rails-pro.md
│   └── major-performance-breakthroughs-upgrade-guide.md
├── misc/ (7 files - KEEPING as category)
│   ├── updating-dependencies.md               # Step 5 correction + merged node-deps
│   ├── credits.md                             # Orphaned: acknowledgments
│   ├── asset-pipeline.md                      # Orphaned: warning guide
│   ├── articles.md
│   ├── code_of_conduct.md
│   ├── doctrine.md
│   ├── style.md
│   └── tips.md
└── advanced-topics/ (1 file - KEEPING as category)
    └── rails-engine-integration.md            # Step 5 correction: from deployment
```

**Final Decisions:**

- `misc/` and `advanced-topics/` are now PERMANENT categories (not temporary)
- All orphaned files found homes
- Old folders (guides/, javascript/, additional-details/, etc.) are now EMPTY

See `04-ia-redesign-plan.md` for original plan (NOTE: this live doc is source of truth after Steps 1-8 + orphaned files).
