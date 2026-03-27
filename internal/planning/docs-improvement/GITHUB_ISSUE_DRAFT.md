# GitHub Issue Draft: Documentation IA Redesign

**Copy/paste this into a new GitHub issue**

---

## Title

[RFC] Documentation Information Architecture Redesign

---

## Labels

- `documentation`
- `enhancement`
- `discussion`

---

## Issue Body

---

## Problem

React on Rails documentation has **unclear navigation structure** that makes it difficult for users to find information and understand the learning path.

### Current Issues

**1. 11 Confusing Categories**

Our documentation is organized into 11 categories with unclear purposes:

- "Guides" (21 files) - everything from installation to advanced SSR
- "Additional details" - catch-all with unrelated content
- "Misc" - another catch-all
- "Javascript" - build tools mixed with React patterns
- "Rails" - integration topics
- "Contributor info" - **internal docs in user navigation** ❌
- "Testimonials" - **marketing content in technical docs** ❌
- "Outdated" - **deprecated docs visible to users** ❌

**User impact:** Can't find information quickly, no clear beginner→advanced progression.

**2. Homepage File Conflict**

Two files in the repo map to the same docs homepage URL:

- `docs/home.md` → `/react-on-rails/docs/`
- `docs/README.md` → `/react-on-rails/docs/`

Only one can render (non-deterministic which "wins"). This creates confusion about which file is the actual homepage.

**Note:** _Website build appears outdated (last deployed Sept 21, PR #1813 merged Sept 23). We should verify the actual user experience after the website rebuilds with latest docs from master branch. The entry points problem may need reassessment once the site is updated._

**3. No Clear User Journey**

Documentation is organized by **implementation details** (Javascript, Rails, API) rather than **user needs** (Getting Started, Building Features, Troubleshooting).

Beginners see advanced topics (streaming SSR, conditional rendering) mixed with basics (installation, first component).

---

## Proposed Solution

### New Category Structure (7 Categories)

Reorganize around **user journey stages**:

```
1. 🚀 Getting Started     → Onboarding, first component (6-8 docs)
2. 📚 Core Concepts       → SSR, bundling, how it works (8-10 docs)
3. 🔧 Building Features   → Common patterns, integrations (10-12 docs)
4. 📖 API Reference       → View helpers, config, JS API (5-7 docs)
5. 🚢 Deployment          → Production, troubleshooting (8-10 docs)
6. 🔄 Migration           → Upgrading, migrating from others (5-7 docs)
7. 💎 React on Rails Pro  → Pro features (2-3 docs)
```

**Removed from user navigation:**

- Contributor docs → moved to `CONTRIBUTING.md`
- Testimonials → moved to marketing website
- Outdated docs → hidden from navigation
- Internal docs → filtered from build

### Single Entry Point

Create **one clear homepage**: `docs/introduction.md`

**Contains:**

- What is React on Rails? (value proposition)
- Why React on Rails vs. alternatives? (comparison)
- When to use / when not to use (decision guide)
- **Three clear paths:**
  - 🚀 Quick Start (15 minutes)
  - 📦 Installation Guide (existing app)
  - 📚 Full Tutorial (comprehensive)

**Resolve homepage conflict:**

- Decide whether `home.md` or `README.md` should be homepage, or replace both with `introduction.md`
- Update gatsby-node.js to map one file to `/docs/`
- Delete or repurpose the redundant file

---

## Implementation Overview

### Phase 1: Website Configuration (`sc-website` repo)

Update `gatsby-node.js`:

- Change category order from 11 to 7 categories
- Add filter to exclude internal docs
- Set `introduction.md` as homepage

**Estimated:** 2-3 hours

### Phase 2: Content Reorganization (`react_on_rails` repo)

Create new folder structure:

```
docs/
├── introduction.md           # NEW HOMEPAGE
├── getting-started/
│   ├── quick-start.md
│   ├── installation.md
│   └── tutorial.md
├── core-concepts/
├── building/
├── api-reference/
├── deployment/
├── migration/
└── pro/
```

Move ~80 files to new locations with `git mv` (preserves history).

**Estimated:** 4-5 hours

### Phase 3: Content Updates

- Create `introduction.md` homepage
- Split `getting-started.md` into appropriate sections
- Update all internal links
- Delete redundant files

**Estimated:** 6-8 hours

### Phases 4-6: Cleanup

- Move contributor docs to `CONTRIBUTING.md`
- Coordinate testimonial move to marketing site
- Hide outdated content

**Estimated:** 5-6 hours

**Total estimated time:** 22-28 hours (~3-4 days)

---

## Benefits

### For Users

✅ **Find information in <10 seconds** - Clear category names
✅ **Understand learning path** - Beginner→Advanced progression
✅ **One obvious starting point** - No more confusion
✅ **Professional appearance** - No internal docs, no "Outdated" category

### For Maintainers

✅ **Easier to add new content** - Clear category homes
✅ **Better organization** - No more catch-all categories
✅ **Reduced support burden** - Users find answers faster

---

## Questions for Review

1. **Website rebuild**: Should we trigger a website rebuild first to see current state with PR #1813 changes before planning further?

2. **Category structure**: Do these 7 categories make sense for user journeys?

3. **Entry point strategy**: Is one `introduction.md` homepage the right approach?

4. **Contributor docs**: Should they go in `CONTRIBUTING.md` or separate `/contributing/` site?

5. **Testimonials**: Best place on marketing site?

6. **Implementation order**: Should we do website config first (Phase 1) to test, or all at once?

7. **Rollback plan**: Satisfied with git revert strategy if issues arise?

---

## Next Steps

Once approved:

1. Create tracking checklist issue or project board
2. Start with Phase 1 (website config) as proof-of-concept
3. Get early feedback on category rendering
4. Proceed with content reorganization
5. Iterate based on team and user feedback

---

**Note:** This addresses **Section 1 (Information Architecture)** problems. After completion, we can tackle **Section 2 (Beginner Onboarding)** issues like missing conceptual guides.
