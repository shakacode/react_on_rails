# Information Architecture Redesign Plan (Section 1)

**Date:** September 30, 2025
**Scope:** Addresses Problems 1.1, 1.2, 1.3, 1.4 from `01-problem-analysis.md`
**Goal:** Create clear, logical navigation that guides users from beginner to advanced

---

## Executive Summary

This plan tackles ALL four Information Architecture problems identified in Section 1:

- **1.1** Unclear Category Hierarchy (11 confusing categories)
- **1.2** Multiple Conflicting Entry Points (4 different starting points)
- **1.3** Internal Docs Visible (contributor/planning docs in user navigation)
- **1.4** "Outdated" Category Visible (deprecated docs exposed)

**Core Strategy:** Redesign from user needs, not implementation details. Group by user journey stage (getting started → learning → building → troubleshooting → reference).

---

## Problem Deep Dive

### Current State: What's Broken

**11 Categories with No Clear Logic:**

```
1. [Root]              ← Misc files at root
2. Guides              ← 21 files, everything from installation to advanced SSR
3. Rails               ← 5 files, Rails-specific topics
4. Javascript          ← 17 files, webpack/bundling/tools
5. Additional details  ← 7 files, catch-all
6. Deployment          ← 2 files, production setup
7. React on rails pro  ← 2 files, Pro features
8. Api                 ← 3 files, reference docs
9. Misc                ← 5 files, another catch-all
10. Contributor info   ← 6 files, internal docs (WRONG AUDIENCE)
11. Testimonials       ← 3 files, marketing (WRONG CONTEXT)
12. Outdated           ← 5 files, deprecated (WRONG TO SHOW)
```

**Total: 93 markdown files** across these categories.

**User Pain Points:**

1. ❌ Can't find what they need (too many places to look)
2. ❌ Don't know where to start (4 entry points)
3. ❌ See irrelevant content (internal docs, testimonials, outdated)
4. ❌ No progression (beginner and advanced mixed)
5. ❌ Catch-all categories lack meaning ("Additional details", "Misc")

---

## Success Criteria

**How do we know this redesign worked?**

### Measurable Outcomes

1. **Navigation clarity:**
   - ✅ User can find installation docs in < 10 seconds
   - ✅ Clear difference between beginner and advanced topics
   - ✅ One obvious starting point (not four)

2. **Content organization:**
   - ✅ Every doc has clear category home
   - ✅ No "catch-all" categories
   - ✅ Internal docs hidden from main nav

3. **Professional appearance:**
   - ✅ No "Outdated" category visible
   - ✅ No testimonials in technical docs
   - ✅ No planning documents in user nav

4. **User feedback:**
   - ✅ New users report easier onboarding
   - ✅ Fewer "where do I find X?" questions
   - ✅ Lower bounce rate on docs

### Qualitative Goals

- Navigation tells a story: "Start here → Learn this → Build that → Get help"
- Categories have clear, single purposes
- User can predict where to find specific information

---

## Proposed Solution

### New Category Structure (8 Categories)

**Based on user journey stages:**

```
1. 🚀 Getting Started        [Onboarding, first component]
2. 📚 Core Concepts          [SSR, bundling, how it works]
3. 🔧 Building Features      [Common patterns, real-world examples]
4. 📖 API Reference          [View helpers, config, JS API]
5. 🚢 Deployment             [Production, performance, troubleshooting]
6. 📈 Upgrading              [Version upgrades, release notes]
7. 🔄 Migrating              [From other tools: react-rails, angular]
8. 💎 React on Rails Pro     [Pro features]
```

**Removed from user navigation:**

- ❌ Contributor info → Move to `/contributing/` or CONTRIBUTING.md
- ❌ Testimonials → Move to marketing website
- ❌ Outdated → Hide completely (keep in repo for reference)
- ❌ Planning docs → Filter out (not user-facing)
- ❌ Internal docs (MONOREPO_MERGER_PLAN, etc.) → Filter out

---

### Detailed Category Mapping

#### 1. 🚀 Getting Started (6-8 docs)

**Purpose:** Get users from zero to first working component ASAP.

**Contents:**

- **Introduction** (NEW - see Section 1.2 solution)
  - Why React on Rails?
  - Comparison with alternatives
  - When to use / when not to use

- **Quick Start** (`quick-start/README.md`)
  - 15-minute setup
  - First component

- **Installation** (`guides/installation-into-an-existing-rails-app.md`)
  - Detailed installation for existing apps

- **Tutorial** (`guides/tutorial.md`)
  - Comprehensive walkthrough

- **Project Structure** (`additional-details/recommended-project-structure.md`)
  - Where files go
  - Naming conventions

**Current location → New location:**

```
docs/quick-start/README.md                               → getting-started/quick-start.md
docs/guides/installation-into-an-existing-rails-app.md   → getting-started/installation-into-an-existing-rails-app.md
docs/guides/tutorial.md                                  → getting-started/tutorial.md
docs/additional-details/recommended-project-structure.md → getting-started/project-structure.md
NEW: docs/introduction.md                                → docs/introduction.md (HOMEPAGE)
```

---

#### 2. 📚 Core Concepts (8-10 docs)

**Purpose:** Explain fundamental concepts users need to understand.

**Contents:**

- **How React on Rails Works** (`guides/how-react-on-rails-works.md`)
- **Overview** (`guides/react-on-rails-overview.md`)
- **Client vs Server Rendering** (`guides/client-vs-server-rendering.md`)
- **Server-Side Rendering** (`guides/react-server-rendering.md`)
- **Component Registration** (`guides/render-functions-and-railscontext.md`)
- **Auto-Bundling** (`guides/auto-bundling-file-system-based-automated-bundle-generation.md`)
- **Webpack Integration** (`guides/webpack-configuration.md`)

**NEW docs needed (from Problem 2.1):**

- Understanding SSR (deep dive)
- How Bundling Works
- Props and RailsContext explained

**Current location → New location:**

```
docs/guides/how-react-on-rails-works.md                                        → core-concepts/how-it-works.md
docs/guides/react-on-rails-overview.md                                         → core-concepts/overview.md
docs/guides/client-vs-server-rendering.md                                      → core-concepts/client-vs-server-rendering.md
docs/guides/react-server-rendering.md                                          → core-concepts/server-rendering.md
docs/guides/render-functions-and-railscontext.md                               → core-concepts/render-functions-and-railscontext.md
docs/guides/auto-bundling-file-system-based-automated-bundle-generation.md    → core-concepts/auto-bundling.md
docs/guides/webpack-configuration.md                                           → core-concepts/webpack-configuration.md
```

---

#### 3. 🔧 Building Features (10-12 docs)

**Purpose:** Practical guides for building real features.

**Contents:**

**Common Patterns:**

- **Hot Module Replacement** (`guides/hmr-and-hot-reloading-with-the-webpack-dev-server.md`)
- **Internationalization** (`guides/i18n.md`)
- **Testing Setup - RSpec** (`guides/rspec-configuration.md`)
- **Testing Setup - Minitest** (`guides/minitest-configuration.md`)

**Advanced Techniques:**

- **Streaming SSR** (`guides/streaming-server-rendering.md`) - ADVANCED
- **Conditional Rendering** (`guides/how-to-conditionally-server-render-based-on-device-type.md`)
- **Different Client/Server Files** (`guides/how-to-use-different-files-for-client-and-server-rendering.md`)

**Integration Guides:**

- **React Router** (`javascript/react-router.md`)
- **Redux** (`javascript/react-and-redux.md`)
- **React Helmet** (`javascript/react-helmet.md`)
- **Rails Integration Options** (`guides/rails-webpacker-react-integration-options.md`)

**Tools & Workflow:**

- **Code Splitting** (`javascript/code-splitting.md`)
- **Images** (`javascript/images.md`)
- **Foreman** (`javascript/foreman-issues.md`)

**Current location → New location:**

```
docs/guides/hmr-and-hot-reloading-with-the-webpack-dev-server.md           → Building/HMR
docs/guides/i18n.md                                                         → Building/Internationalization
docs/guides/rspec-configuration.md                                          → Building/Testing (RSpec)
docs/guides/minitest-configuration.md                                       → Building/Testing (Minitest)
docs/guides/streaming-server-rendering.md                                   → Building/Advanced SSR
docs/guides/how-to-conditionally-server-render-based-on-device-type.md     → Building/Conditional Rendering
docs/guides/how-to-use-different-files-for-client-and-server-rendering.md  → Building/Client/Server Files
docs/javascript/react-router.md                                             → Building/React Router
docs/javascript/react-and-redux.md                                          → Building/Redux
docs/javascript/react-helmet.md                                             → Building/React Helmet
docs/javascript/code-splitting.md                                           → Building/Code Splitting
docs/javascript/images.md                                                   → Building/Images
```

---

#### 4. 📖 API Reference (5-7 docs)

**Purpose:** Quick lookup for syntax, options, parameters.

**Contents:**

- **View Helpers** (`api/view-helpers-api.md`)
  - react_component
  - react_component_hash
  - Options and parameters

- **JavaScript API** (`api/javascript-api.md`)
  - ReactOnRails.register
  - ReactOnRails.getStore
  - etc.

- **Redux Store API** (`api/redux-store-api.md`)

- **Configuration API** (`guides/configuration.md`)
  - All config options reference
  - ReactOnRails.configure do |config| options

- **Generator Options** (`additional-details/generator-details.md`)
  - react_on_rails:install flags
  - What generator creates

**Current location → New location:**

```
docs/api/view-helpers-api.md                     → api-reference/view-helpers-api.md
docs/api/javascript-api.md                       → api-reference/javascript-api.md
docs/api/redux-store-api.md                      → api-reference/redux-store-api.md
docs/guides/configuration.md                     → api-reference/configuration.md
docs/additional-details/generator-details.md     → api-reference/generator-details.md
```

---

#### 5. 🚢 Deployment (8-10 docs)

**Purpose:** Production deployment, troubleshooting, performance.

**Contents:**

**Production Setup:**

- **Deployment Guide** (`guides/deployment.md`)
- **Heroku Deployment** (`deployment/heroku-deployment.md`)
- **Elastic Beanstalk** (`deployment/elastic-beanstalk.md`)
- **Capistrano** (`javascript/capistrano-deployment.md`)

**Troubleshooting:**

- **Troubleshooting Guide** (`troubleshooting/README.md`) - ✅ Already good from PR #1813
- **Build Errors** (`javascript/troubleshooting-build-errors.md`)
- **Shakapacker Issues** (`javascript/troubleshooting-when-using-shakapacker.md`)
- **Webpacker Issues** (`javascript/troubleshooting-when-using-webpacker.md`)

**Maintenance:**

- **Updating Dependencies** (`additional-details/updating-dependencies.md`)
- **Performance Tips** (`misc/tips.md` - rename/move)

**Rails-Specific:**

- **Turbolinks** (`rails/turbolinks.md`)
- **Rails Engine Integration** (`rails/rails-engine-integration.md`)
- **Convert API-Only App** (`rails/convert-rails-5-api-only-app.md`)

**Current location → New location:**

```
docs/guides/deployment.md                                  → Deployment/Production Setup
docs/deployment/heroku-deployment.md                       → Deployment/Heroku
docs/deployment/elastic-beanstalk.md                       → Deployment/AWS
docs/troubleshooting/README.md                             → Deployment/Troubleshooting
docs/javascript/troubleshooting-build-errors.md            → Deployment/Build Errors
docs/additional-details/updating-dependencies.md           → Deployment/Maintenance
docs/rails/turbolinks.md                                   → Deployment/Turbolinks
docs/rails/rails-engine-integration.md                     → Deployment/Rails Engines
```

---

#### 6. 📈 Upgrading (5-7 docs)

**Purpose:** Help users upgrade between React on Rails versions.

**Contents:**

- **Upgrading React on Rails** (`guides/upgrading-react-on-rails.md`)
- **Release Notes** (link to `release-notes/` folder)
- **Breaking Changes** (extract from CHANGELOG)
- **Upgrade Guides by Version:**
  - v16.0.0 (`release-notes/16.0.0.md`)
  - v15.0.0 (`release-notes/15.0.0.md`)
- **Pro Performance Upgrade Guide** (`react-on-rails-pro/major-performance-breakthroughs-upgrade-guide.md`)

**Current location → New location:**

```
docs/guides/upgrading-react-on-rails.md                                       → upgrading/upgrading-react-on-rails.md
docs/react-on-rails-pro/major-performance-breakthroughs-upgrade-guide.md      → upgrading/pro-performance-upgrade.md
docs/release-notes/                                                           → upgrading/release-notes/
```

---

#### 7. 🔄 Migrating (2-3 docs)

**Purpose:** Help users migrate TO React on Rails from other tools.

**Contents:**

- **Migrating from react-rails** (`additional-details/migrating-from-react-rails.md`)
- **Migrating from AngularJS** (`javascript/angular-js-integration-migration.md`)

**Could add (if valuable):**

- Migrating from plain Rails views
- Migrating from Hotwire/Turbo
- Migrating from separate React SPA

**Current location → New location:**

```
docs/additional-details/migrating-from-react-rails.md  → migrating/from-react-rails.md
docs/javascript/angular-js-integration-migration.md    → migrating/from-angular.md
```

---

#### 8. 💎 React on Rails Pro (2-3 docs)

**Purpose:** Showcase Pro features, link to Pro docs.

**Contents:**

- **React on Rails Pro Overview** (`react-on-rails-pro/react-on-rails-pro.md`)
- **Major Performance Breakthroughs** (`react-on-rails-pro/major-performance-breakthroughs-upgrade-guide.md`)
- **Link to Pro Documentation** (external)

**Current location → New location:**

```
docs/react-on-rails-pro/react-on-rails-pro.md                                → pro/react-on-rails-pro.md
docs/react-on-rails-pro/major-performance-breakthroughs-upgrade-guide.md     → pro/major-performance-breakthroughs-upgrade-guide.md
```

---

### Removed/Hidden Categories

**Contributor Info → Not in User Docs**

```
docs/contributor-info/linters.md                → CONTRIBUTING.md or separate /contributing site
docs/contributor-info/coding-agents-guide.md    → CONTRIBUTING.md
docs/contributor-info/errors-with-hooks.md      → CONTRIBUTING.md
docs/contributor-info/generator-testing.md      → CONTRIBUTING.md
docs/contributor-info/releasing.md              → CONTRIBUTING.md
docs/contributor-info/pull-requests.md          → CONTRIBUTING.md
```

**Testimonials → Marketing Website**

```
docs/testimonials/testimonials.md               → shakacode.com/testimonials
docs/testimonials/hvmn.md                       → shakacode.com/case-studies/hvmn
docs/testimonials/resortpass.md                 → shakacode.com/case-studies/resortpass
```

**Outdated → Hidden (Keep in Repo)**

```
docs/outdated/*                                 → Excluded from build, kept for historical reference
```

**Planning/Internal → Excluded from Build**

```
docs/planning/*                                 → Excluded via gatsby-node.js filter
docs/MONOREPO_MERGER_PLAN.md                    → Excluded via gatsby-node.js filter
docs/DIRECTORY_LICENSING.md                     → Excluded via gatsby-node.js filter
docs/LICENSING_FAQ.md                           → Maybe move to root? Or exclude?
```

**Misc Category → Dissolved**

```
docs/misc/tips.md                               → Deployment/Performance Tips
docs/misc/doctrine.md                           → Introduction (philosophy section)
docs/misc/articles.md                           → External Resources (in introduction or footer)
docs/misc/style.md                              → CONTRIBUTING.md
docs/misc/code_of_conduct.md                    → Root CODE_OF_CONDUCT.md
```

**Javascript Category → Dissolved**
Integrated into Building Features and Deployment categories (see above)

**Rails Category → Dissolved**
Integrated into Deployment category (see above)

**Additional Details Category → Dissolved**
Integrated into various categories (see above)

---

## Solution: Entry Point Consolidation (Problem 1.2)

### Current Situation: 4+ Entry Points

**Problem:** Users land on different pages with no clear "start here":

1. `docs/README.md` (173 lines) - Navigation hub
2. `docs/home.md` (29 lines) - Minimal landing
3. `docs/getting-started.md` (254 lines) - Installation + concepts + reference (too much)
4. `docs/quick-start/README.md` (212 lines) - 15-minute path
5. Root `README.md` - Project README (not docs landing page)

### Proposed Solution: One Clear Entry Point

**Create ONE landing page:** `docs/introduction.md`

**This becomes the homepage** when users visit `/react-on-rails/docs/`

**Structure:**

```markdown
# React on Rails

> Integrate React seamlessly into your Rails application with server-side rendering, hot reloading, and more.

## What is React on Rails?

[2-3 paragraphs explaining what it is, what problems it solves]

## Why React on Rails?

[Comparison with alternatives: plain Rails, separate SPA, Hotwire, Inertia.js]
[When to use React on Rails vs. alternatives]

## Quick Decision Guide

**Choose React on Rails if:**

- ✅ You have an existing Rails app
- ✅ You want React's component model
- ✅ You need server-side rendering for SEO/performance
- ✅ You want to leverage Rails conventions

**Consider alternatives if:**

- ❌ You're building a separate API + SPA
- ❌ You want minimal JavaScript (try Hotwire)
- ❌ You need cutting-edge React features only (React Server Components in standalone Next.js)

## Getting Started

Choose your path:

### 🚀 New to React on Rails?

**[15-Minute Quick Start →](./quick-start/README.md)**
Get your first component running in minutes.

### 📦 Adding to Existing Rails App?

**[Installation Guide →](./getting-started/installation.md)**
Detailed integration instructions.

### 📚 Want Comprehensive Tutorial?

**[Complete Tutorial →](./getting-started/tutorial.md)**
Step-by-step with Redux, routing, and testing.

## Core Concepts

Before diving deep, understand these fundamentals:

- [How React on Rails Works](./core-concepts/how-it-works.md)
- [Client vs. Server Rendering](./core-concepts/rendering.md)
- [Component Registration](./core-concepts/components.md)
- [Webpack Integration](./core-concepts/webpack.md)

## Popular Use Cases

[Table linking to specific guides for common scenarios]

## Philosophy & Principles

[Extract from docs/misc/doctrine.md]
React on Rails values transparency over magic, flexibility over convention...

## Community & Support

- GitHub Discussions
- Slack
- Professional Support

## External Resources

[Link to articles, videos, case studies on marketing site]
```

**What happens to other files:**

1. **`docs/home.md`** → DELETE (redundant)
2. **`docs/README.md`** → DELETE or simplify to just TOC (not landing page)
3. **`docs/getting-started.md`** → SPLIT:
   - Installation content → `docs/getting-started/installation.md`
   - Concepts → Move to Core Concepts category
   - API examples → Move to API Reference
4. **`docs/quick-start/README.md`** → KEEP (but clearly positioned as one of three paths)
5. **Root `README.md`** → KEEP (project README, not docs entry)

**Result:**

- ✅ ONE landing page: `introduction.md`
- ✅ THREE clear paths from there: Quick Start, Installation, Tutorial
- ✅ No circular references
- ✅ No confusion about "where do I start?"

---

## Implementation Plan

### Phase 1: Website Configuration (sc-website repo)

**File:** `/home/ihab/ihab/work/shakacode/sc-website/gatsby-node.js`

**Changes needed:**

**1. Update category order (lines 31-44):**

```javascript
// OLD:
const reactOnRailsDocsFoldersOrder = [
  firstCategory,
  'Guides',
  'Rails',
  'Javascript',
  'Additional details',
  'Deployment',
  'React on rails pro',
  'Api',
  'Misc',
  'Contributor info',
  'Testimonials',
  'Outdated',
];

// NEW:
const reactOnRailsDocsFoldersOrder = [
  firstCategory, // For introduction.md at root
  'Getting Started',
  'Core Concepts',
  'Building Features',
  'API Reference',
  'Deployment',
  'Migration & Upgrading',
  'React on Rails Pro',
];
```

**2. Add filter to exclude internal docs (around line 151):**

```javascript
// OLD:
docs: allFile(
  filter: {
    dir: { regex: "/^.*/gatsby-source-git/.*$/" }
    extension: { in: ["md", "mdx"] }
  }
)

// NEW:
docs: allFile(
  filter: {
    dir: { regex: "/^.*/gatsby-source-git/.*$/" }
    extension: { in: ["md", "mdx"] }
    # Exclude internal docs
    relativePath: {
      nin: [
        "/contributor-info/",
        "/testimonials/",
        "/outdated/",
        "/planning/",
        "/MONOREPO_MERGER_PLAN.md",
        "/MONOREPO_MERGER_PLAN_REF.md",
        "/DIRECTORY_LICENSING.md",
      ]
    }
  }
)
```

**Note:** Syntax needs to be checked - GraphQL filter syntax in Gatsby. May need different approach:

- Option A: Filter in JavaScript after query
- Option B: Use regex to exclude paths
- Option C: Use `nin` (not in) operator

**3. Update index page handling (around line 196):**

```javascript
// Ensure introduction.md becomes homepage
const indexPages = ['introduction'];
```

**Testing checklist:**

- [ ] Run `gatsby develop` locally in sc-website
- [ ] Verify new categories appear
- [ ] Verify internal docs hidden
- [ ] Verify introduction.md becomes homepage
- [ ] Check all links work
- [ ] Test mobile navigation

---

### Phase 2: Content Reorganization (react_on_rails repo)

**Strategy:** Move files to match new category structure

**Approach options:**

**Option A: Create new folders matching categories**

```bash
docs/
├── introduction.md           # NEW HOMEPAGE
├── getting-started/
│   ├── quick-start.md
│   ├── installation.md
│   ├── tutorial.md
│   └── project-structure.md
├── core-concepts/
│   ├── how-it-works.md
│   ├── overview.md
│   ├── rendering.md
│   └── ...
├── building/
│   ├── hmr.md
│   ├── i18n.md
│   └── ...
├── api-reference/
├── deployment/
├── migration/
└── pro/
```

**Option B: Keep current folders, rely on categories**

- Keep current file locations
- Categories map to folders via label transformation
- Requires folder renames to match categories

**Recommendation: Option A** (new folders)

- Clearer structure
- Easier to understand
- Better for future maintenance
- Git history preserved with `git mv`

**File moves needed:**

Create script: `scripts/reorganize-docs.sh`

```bash
#!/bin/bash
# Reorganize docs to match new IA

# Create new directories
mkdir -p docs/getting-started
mkdir -p docs/core-concepts
mkdir -p docs/building
mkdir -p docs/api-reference
mkdir -p docs/deployment
mkdir -p docs/migration
mkdir -p docs/pro

# Move files (using git mv to preserve history)

# Getting Started
git mv docs/quick-start/README.md docs/getting-started/quick-start.md
git mv docs/guides/installation-into-an-existing-rails-app.md docs/getting-started/installation.md
git mv docs/guides/tutorial.md docs/getting-started/tutorial.md
git mv docs/additional-details/recommended-project-structure.md docs/getting-started/project-structure.md

# Core Concepts
git mv docs/guides/how-react-on-rails-works.md docs/core-concepts/how-it-works.md
git mv docs/guides/react-on-rails-overview.md docs/core-concepts/overview.md
git mv docs/guides/client-vs-server-rendering.md docs/core-concepts/rendering.md
git mv docs/guides/react-server-rendering.md docs/core-concepts/server-rendering.md
git mv docs/guides/render-functions-and-railscontext.md docs/core-concepts/components.md
git mv docs/guides/auto-bundling-file-system-based-automated-bundle-generation.md docs/core-concepts/auto-bundling.md
git mv docs/guides/webpack-configuration.md docs/core-concepts/webpack.md
git mv docs/guides/configuration.md docs/core-concepts/configuration.md

# Building Features
git mv docs/guides/hmr-and-hot-reloading-with-the-webpack-dev-server.md docs/building/hmr.md
git mv docs/guides/i18n.md docs/building/i18n.md
git mv docs/guides/rspec-configuration.md docs/building/testing-rspec.md
git mv docs/guides/minitest-configuration.md docs/building/testing-minitest.md
git mv docs/guides/streaming-server-rendering.md docs/building/streaming-ssr.md
git mv docs/guides/how-to-conditionally-server-render-based-on-device-type.md docs/building/conditional-rendering.md
git mv docs/javascript/react-router.md docs/building/react-router.md
git mv docs/javascript/react-and-redux.md docs/building/redux.md

# API Reference
git mv docs/api docs/api-reference

# Deployment
git mv docs/guides/deployment.md docs/deployment/production.md
git mv docs/troubleshooting/README.md docs/deployment/troubleshooting.md
# ... etc

# Migration
git mv docs/guides/upgrading-react-on-rails.md docs/migration/upgrading.md
git mv docs/additional-details/migrating-from-react-rails.md docs/migration/from-react-rails.md

# Pro
git mv docs/react-on-rails-pro docs/pro

# Remove old empty directories
rmdir docs/guides
rmdir docs/javascript
rmdir docs/rails
rmdir docs/additional-details
rmdir docs/misc
rmdir docs/quick-start

echo "✅ Files reorganized. Review changes before committing."
```

**Testing checklist:**

- [ ] Run reorganization script
- [ ] Verify all files moved correctly
- [ ] Check for broken internal links
- [ ] Update any absolute paths in docs
- [ ] Test locally that categories work
- [ ] Git commit with clear message

---

### Phase 3: Content Updates (react_on_rails repo)

**STATUS:** ✅ COMPLETED (with adaptations) - See ia-redesign-live.md for details

**Create new files:**

**1. `docs/introduction.md`** ✅ DONE

- Homepage for docs
- Explains what React on Rails is
- Why use it vs alternatives
- Links to three paths (Quick Start, Installation, Tutorial)
- Philosophy section

**2. Split `docs/getting-started.md`:** ✅ DONE (but transformed, not split)

- **PLANNED:** Move installation → `docs/getting-started/installation.md`
- **ACTUAL:** Transformed to `docs/getting-started/using-react-on-rails.md` (conceptual guide)
- **REASON:** installation.md already existed, needed conceptual guide instead
- DELETE original after content extracted ✅ DONE

**3. Update `docs/README.md`:** ✅ DONE (kept simplified)

- **DECIDED:** Option B (kept as simple TOC)
- Reduced from 173 → 65 lines
- Serves GitHub users browsing repo

**4. Delete `docs/home.md`:** ✅ DONE

- Redundant with introduction.md

**ADDITIONS (discovered during implementation):**

**5. Tutorial improvements** ✅ DONE

- Extracted Heroku deployment (139 lines) to dedicated guide
- Fixed outdated versions (Ruby 3.0+, Rails 7+, RoR v16)
- Clarified Redux vs Hooks usage
- Merged duplicate HMR sections
- Reorganized "Other features" → "Going Further"

**6. Delete `manual-installation-overview.md`** ✅ DONE

- Outdated since 2018
- Confused purpose
- No clear use case (generator IS manual installation)

**7. Update cross-references:** ✅ DONE (manually)

- Updated links to renamed/moved files as they were discovered
- Key changes:
  - overview.md → introduction.md (2 links)
  - understanding-react-on-rails.md → using-react-on-rails.md (1 link)
  - manual-installation-overview.md link removed (1 link)
- **NOTE:** Did not use automated script - manual updates were more appropriate given incremental changes

**Testing checklist:**

- [x] All new files created
- [x] Old files deleted or transformed
- [x] All internal links updated (manually as encountered)
- [ ] Run markdown link checker (TODO: before final merge)
- [x] Manual spot-checks of navigation
- [ ] Test on local gatsby build (deferred to Phase 1 - website config)

---

### Phase 4: Contributor Docs (react_on_rails repo)

**Move contributor content:**

**Update `CONTRIBUTING.md` to include:**

- Content from `docs/contributor-info/linters.md`
- Content from `docs/contributor-info/coding-agents-guide.md`
- Content from `docs/contributor-info/generator-testing.md`
- Content from `docs/contributor-info/releasing.md`
- Content from `docs/contributor-info/pull-requests.md`
- Content from `docs/misc/style.md`

**OR create `/contributing/` documentation site** (separate from user docs)

**Delete after moving:**

```bash
rm -rf docs/contributor-info
rm docs/misc/style.md
```

**Move to root:**

```bash
git mv docs/misc/code_of_conduct.md CODE_OF_CONDUCT.md
```

**Testing checklist:**

- [ ] CONTRIBUTING.md comprehensive
- [ ] Contributor info not in user docs
- [ ] CODE_OF_CONDUCT.md at root
- [ ] Links to CONTRIBUTING.md work

---

### Phase 5: Testimonials & Marketing (both repos)

**In react_on_rails repo:**

```bash
# Remove testimonials from docs
rm -rf docs/testimonials
```

**In sc-website repo:**

- Create `/testimonials/` or `/case-studies/` page
- Import testimonial content
- Add links from introduction.md: "See who uses React on Rails →"

**Testing checklist:**

- [ ] Testimonials not in docs navigation
- [ ] Testimonials page exists on marketing site
- [ ] Link from docs to testimonials works

---

### Phase 6: Outdated Content (react_on_rails repo)

**Options:**

**Option A: Hide from build, keep in repo**

```bash
# Keep files but exclude from gatsby build
# Already done in Phase 1 (gatsby-node.js filter)
```

**Option B: Move to separate branch**

```bash
git checkout -b archive/outdated-docs
git mv docs/outdated /
git commit -m "Archive outdated docs"
git checkout master
rm -rf docs/outdated
```

**Option C: Delete entirely**

```bash
rm -rf docs/outdated
```

**Recommendation: Option A** (keep in repo, exclude from build)

- Preserves history
- Still accessible if needed
- Not visible to users

**Testing checklist:**

- [ ] Outdated category not in navigation
- [ ] Files still in repo (if Option A)
- [ ] No broken links to outdated docs

---

## Files to Modify Summary

### In `sc-website` repo:

1. **`gatsby-node.js`**
   - Update `reactOnRailsDocsFoldersOrder` (lines 31-44)
   - Add filter to exclude internal docs (around line 151)
   - Update index page handling (around line 196)

2. **Test locally:**
   - Run gatsby develop
   - Verify navigation
   - Check links

### In `react_on_rails` repo:

**New files:**

1. `docs/introduction.md` (homepage)
2. `scripts/reorganize-docs.sh` (file moving script)
3. `scripts/update-links.sh` (link updating script)

**Modified files:**

1. Update `CONTRIBUTING.md` (add contributor content)
2. Update internal link references (all .md files)

**Deleted files:**

1. `docs/home.md`
2. `docs/README.md` (or drastically simplified)
3. `docs/getting-started.md` (content extracted)
4. `docs/contributor-info/*` (moved to CONTRIBUTING.md)
5. `docs/testimonials/*` (moved to marketing site)
6. `docs/misc/style.md` (moved to CONTRIBUTING.md)

**Moved files:**

- ~80 files moved to new structure (see Phase 2 script)

---

## Timeline Estimate

**Conservative estimate with testing:**

| Phase                            | Tasks                                            | Estimated Time              |
| -------------------------------- | ------------------------------------------------ | --------------------------- |
| **Phase 1: Website Config**      | Update gatsby-node.js, test locally              | 2-3 hours                   |
| **Phase 2: File Reorganization** | Create script, move files, test                  | 4-5 hours                   |
| **Phase 3: Content Updates**     | Create introduction.md, split docs, update links | 6-8 hours                   |
| **Phase 4: Contributor Docs**    | Move to CONTRIBUTING.md                          | 2-3 hours                   |
| **Phase 5: Testimonials**        | Move to marketing site                           | 2-3 hours                   |
| **Phase 6: Outdated Content**    | Hide from build                                  | 1 hour                      |
| **Testing & Refinement**         | End-to-end testing, fix issues                   | 4-5 hours                   |
| **Documentation**                | Update README about changes                      | 1 hour                      |
| **Total**                        |                                                  | **22-28 hours** (~3-4 days) |

**Aggressive estimate (if everything goes smoothly):** 15-18 hours (~2 days)

---

## Rollback Plan

**If something goes wrong:**

### Quick Rollback (Website Config)

**In `sc-website` repo:**

```bash
git revert <commit-hash>
npm run build
npm run deploy
```

**Result:** Old category structure restored immediately.

### Full Rollback (Content Reorganization)

**In `react_on_rails` repo:**

```bash
# Revert file moves
git revert <commit-hash-range>

# Or if not committed yet:
git reset --hard HEAD
```

**Result:** Files back in original locations.

### Partial Rollback

If only some categories are problematic:

1. Keep working categories
2. Revert problematic ones
3. Fix issues
4. Re-deploy

**Risk mitigation:**

- ✅ Test on staging first
- ✅ Deploy website changes separately from content changes
- ✅ Keep PRs focused (one phase per PR)
- ✅ Document each change clearly

---

## Testing Strategy

### Pre-Deployment Testing

**1. Local Gatsby Build (sc-website):**

```bash
cd sc-website
npm install
gatsby develop
# Visit http://localhost:8000/react-on-rails/docs/
```

**Check:**

- [ ] New categories appear correctly
- [ ] Internal docs hidden
- [ ] introduction.md is homepage
- [ ] All links work
- [ ] Mobile navigation works
- [ ] Search works (if applicable)

**2. Local React on Rails Testing:**

```bash
cd react_on_rails
# Check file structure
ls -la docs/

# Run link checker
npm run check-links  # if exists, or:
find docs -name "*.md" -exec markdown-link-check {} \;
```

**Check:**

- [ ] All files in correct locations
- [ ] No broken internal links
- [ ] No 404s on moved files

**3. User Journey Testing:**

**Test Scenario 1: New User**

- Land on docs homepage
- Can find Quick Start in < 10 seconds
- Complete Quick Start without confusion
- Can navigate to Core Concepts

**Test Scenario 2: Experienced User Looking for API**

- Land on docs homepage
- Can find API Reference in < 5 seconds
- Can look up react_component options
- Can return to previous page

**Test Scenario 3: User with Problem**

- Land on docs homepage
- Can find Troubleshooting in < 10 seconds
- Can diagnose issue type
- Can find solution

**4. Cross-Browser Testing:**

- [ ] Chrome
- [ ] Firefox
- [ ] Safari
- [ ] Mobile Safari
- [ ] Mobile Chrome

---

### Post-Deployment Verification

**1. Production Checks:**

```bash
# Visit actual site
open https://www.shakacode.com/react-on-rails/docs/

# Check Google Search Console (after a few days)
# - Are old URLs redirecting?
# - Are new URLs indexed?
```

**2. Monitor Issues:**

- [ ] Watch GitHub issues for "can't find X" questions
- [ ] Monitor Slack for navigation confusion
- [ ] Track analytics (bounce rate, time on page)

**3. Gather Feedback:**

- [ ] Ask beta users to test
- [ ] Post in community: "We reorganized docs, feedback?"
- [ ] Monitor social media mentions

---

## Success Metrics (After 2-4 Weeks)

**Quantitative:**

1. **Bounce rate** on docs pages decreases by 10-20%
2. **Time to find specific info** (via user testing) decreases by 30%
3. **"Where is X?" questions** in issues/Slack decrease by 40%
4. **Page views** on key pages (Quick Start, Installation) increase by 20%

**Qualitative:**

1. ✅ Positive feedback from community
2. ✅ Fewer confused new users
3. ✅ More self-service, less support needed
4. ✅ Better reviews/mentions of docs quality

---

## Dependencies & Coordination

### Team Coordination Needed

**1. Justin (Maintainer):**

- Review IA redesign plan
- Approve category structure
- Review content changes
- Deploy website changes

**2. Bob (Mentor):**

- Review technical approach
- Test navigation changes
- Provide feedback on content

**3. Ihab (You):**

- Execute reorganization
- Write introduction.md
- Update links
- Test thoroughly

### External Dependencies

**1. Gatsby Build System:**

- Must understand how gatsby-node.js creates pages
- Need access to sc-website repo
- Need ability to test locally

**2. Git History:**

- Use `git mv` to preserve history
- Commit in logical chunks
- Write clear commit messages

**3. CI/CD Pipeline:**

- Ensure link checker still works
- RuboCop/Prettier formatting maintained
- No breaking changes to build

---

## Risk Assessment

| Risk                                 | Likelihood | Impact   | Mitigation                             |
| ------------------------------------ | ---------- | -------- | -------------------------------------- |
| **Broken links after move**          | High       | High     | Automated link checker, manual testing |
| **Category not rendering**           | Medium     | High     | Test locally first, staging deploy     |
| **User confusion during transition** | Medium     | Medium   | Announcement, redirect old URLs        |
| **Search broken**                    | Low        | Medium   | Test search on staging                 |
| **Mobile nav issues**                | Low        | High     | Cross-device testing                   |
| **Build failures**                   | Low        | Critical | Test locally, rollback plan ready      |
| **Team disagreement on structure**   | Medium     | Low      | Get buy-in before starting             |

---

## Open Questions

**To discuss with team:**

1. **Should we keep `docs/README.md` or delete it?**
   - Option A: Delete (introduction.md is new homepage)
   - Option B: Keep as simple TOC
   - **Recommendation:** Delete (simplify entry points)

2. **What to do with `docs/misc/doctrine.md`?**
   - Option A: Integrate into introduction.md (philosophy section)
   - Option B: Separate "Philosophy" page
   - **Recommendation:** Integrate (fewer top-level pages)

3. **Should contributor docs be in CONTRIBUTING.md or separate site?**
   - Option A: All in CONTRIBUTING.md (simple)
   - Option B: Separate `/contributing/` docs site (more discoverable)
   - **Recommendation:** CONTRIBUTING.md for now (simpler)

4. **How to handle testimonials on marketing site?**
   - Option A: New /testimonials page
   - Option B: Integrate into /case-studies
   - Option C: Scatter across site (homepage, about, etc.)
   - **Recommendation:** Get marketing team input

5. **Should we add version switcher?**
   - For v15 vs v16 docs
   - Similar to Next.js version switcher
   - **Recommendation:** Defer to later phase (nice-to-have)

6. **Redirect old URLs to new ones?**
   - Set up 301 redirects for moved pages
   - Or let 404s naturally resolve over time
   - **Recommendation:** Yes, set up redirects (better UX)

---

## Next Steps

**Before starting implementation:**

1. **Review this plan with Justin and Bob**
   - Get feedback on category structure
   - Confirm approach is sound
   - Resolve open questions

2. **Prioritize phases**
   - Must-do: Phases 1-3 (core IA changes)
   - Nice-to-have: Phases 4-6 (cleanup)

3. **Set up staging environment**
   - Fork sc-website repo
   - Test locally
   - Deploy to staging if available

4. **Create tracking issue**
   - GitHub issue linking to this plan
   - Checklist of phases
   - Track progress

**After plan approved:**

1. **Start with Phase 1** (website config)
   - Small, testable change
   - See if approach works
   - Learn the system

2. **Get feedback early**
   - Show category structure working
   - Adjust if needed
   - Build confidence

3. **Move to Phase 2** (file moves)
   - Bigger change but mechanical
   - Run script, test, commit

4. **Complete remaining phases**
   - One phase per PR
   - Test thoroughly
   - Iterate based on feedback

---

## Conclusion

This plan addresses ALL four Information Architecture problems:

✅ **1.1 Unclear Category Hierarchy** → 7 clear categories based on user journey
✅ **1.2 Multiple Entry Points** → 1 homepage (introduction.md), 3 clear paths
✅ **1.3 Internal Docs Visible** → Filtered out, moved to CONTRIBUTING.md
✅ **1.4 Outdated Content Visible** → Hidden from navigation

**Expected outcomes:**

- Users can find what they need quickly
- Clear progression from beginner to advanced
- Professional appearance (no clutter)
- One obvious starting point
- Better first impression

**This is foundational work** that makes all future documentation improvements easier. Once the structure is right, we can:

- Add conceptual guides (Problem 2.1)
- Improve installation flow (Problem 2.2)
- Add progressive disclosure (Problem 3.1)
- Consolidate API reference (Problem 3.2)

**Estimated effort:** 22-28 hours (~3-4 days)
**Risk:** Medium (testing and rollback plan mitigate)
**Impact:** 🔥🔥🔥 Critical - fixes foundation for all other improvements
