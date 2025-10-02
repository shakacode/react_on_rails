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

_None yet - will update as we go_

---

## Issues & Blockers

_None yet_

---

## Testing Notes

### Local Testing Strategy

- Use `gatsby develop` in sc-website repo pointing to this branch
- Verify categories render correctly
- Check navigation flow
- Test internal links

_Test results will be logged here as we go_

---

## Next Actions

**Current:** Complete Step 0 - create folder structure and commit baseline

**After Step 0 approval:** Move to Step 1 (Getting Started files)

---

## Reference: New Folder Structure

```
docs/
├── introduction.md              # NEW HOMEPAGE (to be created)
├── getting-started/
│   ├── quick-start.md
│   ├── installation.md
│   └── tutorial.md
├── core-concepts/
│   ├── server-side-rendering.md
│   ├── client-vs-server-rendering.md
│   └── ...
├── building-features/
│   ├── using-redux.md
│   ├── react-router.md
│   └── ...
├── api-reference/
│   ├── view-helpers-api.md
│   ├── configuration.md
│   └── ...
├── deployment/
│   ├── production-deployment.md
│   ├── troubleshooting.md
│   └── ...
├── migration/
│   ├── upgrading-react-on-rails.md
│   ├── migrating-from-react-rails.md
│   └── ...
└── pro/
    ├── react-on-rails-pro.md
    └── ...
```

See `04-ia-redesign-plan.md` for detailed file mapping.
