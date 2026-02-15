# PR #1813 Comparison: What Was Fixed vs. What Remains

**Date:** September 30, 2025
**PR Reference:** [#1813 - Comprehensive documentation improvements](https://github.com/shakacode/react_on_rails/pull/1813)
**Merged:** September 23, 2025 by Justin Gordon

---

## Executive Summary

PR #1813 made **significant progress** on documentation improvements, addressing many surface-level issues. However, the **fundamental information architecture problems** remain unresolved. This document compares what was fixed against the problems identified in `01-problem-analysis.md`.

---

## ✅ What PR #1813 Successfully Fixed

### 1. Quick Start Guide Created ✅

**Problem Addressed:** Section 2.1 - Missing fast onboarding path

**What Was Done:**

- Created `docs/quick-start/README.md` (212 lines)
- 15-minute quick start with clear steps
- Modern auto-bundling patterns emphasized
- Step-by-step with time estimates

**Impact:**

- ✅ Users now have a fast path to first success
- ✅ Clear progression through installation → running → editing
- ✅ Modern best practices (auto-bundling) featured

**Remaining Gaps:**

- Quick start still buried in subdirectory (not in main navigation prominently)
- Still referenced as "one option" rather than THE starting point

---

### 2. Troubleshooting Guide Created ✅

**Problem Addressed:** Section 5.3 - Scattered troubleshooting

**What Was Done:**

- Created `docs/troubleshooting/README.md` (304 lines)
- Organized by problem type (Installation, Build, Runtime, SSR, Performance)
- Quick diagnosis table at top
- Common error messages with solutions

**Impact:**

- ✅ Centralized troubleshooting resource
- ✅ Clear decision tree for diagnosis
- ✅ Specific error messages documented

**Quality:**
Strong execution. This addresses the troubleshooting fragmentation well.

---

### 3. Documentation Hub Created ✅

**Problem Addressed:** Section 1.2 - Multiple conflicting entry points

**What Was Done:**

- Created `docs/README.md` (172 lines)
- Learning paths section
- Popular use cases table
- Complete table of contents

**Impact:**

- ✅ Single navigation hub exists
- ✅ Multiple user journeys acknowledged
- ✅ Better organization than before

**Remaining Issues:**

- Doesn't solve the fundamental problem of 4 entry points
- Now we have: `README.md`, `docs/README.md`, `docs/home.md`, `docs/getting-started.md`, `docs/quick-start/README.md`
- More coordination between these, but still confusing which is THE starting point

---

### 4. Broken Links Fixed ✅

**Problem Addressed:** Section 4.1 - Link management risk

**What Was Done:**

- Fixed 27+ broken internal links
- Updated image paths
- Corrected anchor links
- Added automated link checking CI (PR #1800)

**Impact:**

- ✅ Users won't hit 404s
- ✅ CI prevents future link rot
- ✅ Navigation more reliable

**Quality:**
Excellent technical improvement with future-proofing.

---

### 5. Version Requirements Standardized ✅

**Problem Addressed:** Section 2.3 - Inconsistent prerequisites

**What Was Done:**

- Reconciled version specs across all docs
- Consistent messaging: Shakapacker 6+ (7+ recommended), Ruby 3.0+, Rails 5.2+, Node 18+
- Removed conflicting "Ruby 2.7+ supported" references
- Prominent version warnings with 🚨 emoji

**Impact:**

- ✅ Clear system requirements
- ✅ No more conflicting info
- ✅ Users know what they need upfront

---

### 6. Visual Improvements ✅

**Problem Addressed:** Section 3.4 - Inconsistent formatting

**What Was Done:**

- Consistent emoji usage (🚀, 🎯, ✅, 💡, etc.)
- Tables for comparison and navigation
- Callout boxes with > quotes
- Better heading hierarchy
- Code blocks with language tags

**Impact:**

- ✅ More scannable documents
- ✅ Visual hierarchy clearer
- ✅ Professional appearance

**Quality:**
Good improvement, though not comprehensive across all docs.

---

### 7. AI Agent Instructions ✅

**Problem Addressed:** (Not in our analysis - bonus improvement)

**What Was Done:**

- Created `AI_AGENT_INSTRUCTIONS.md`
- Proper installation order for coding agents
- Common pitfalls documented

**Impact:**

- ✅ Better AI-assisted development experience
- ✅ Reduces errors from incorrect agent assumptions

---

### 8. Content Modernization ✅

**Problem Addressed:** Section 2.1 - Outdated patterns

**What Was Done:**

- Emphasized auto-bundling over manual registration throughout
- Updated examples to use current best practices
- Added security note about automatic props sanitization
- Removed references to deprecated patterns

**Impact:**

- ✅ Users learn modern patterns first
- ✅ Less confusion about "old way" vs "new way"

---

## ⚠️ What Remains Unresolved

### 1. Information Architecture Still Problematic ❌

**Original Problem:** Section 1.1 - Unclear category hierarchy

**Current State:**
The 11-category structure in `gatsby-node.js:31-44` **was not changed**:

```javascript
const reactOnRailsDocsFoldersOrder = [
  firstCategory,
  'Guides', // Still 18+ diverse topics
  'Rails',
  'Javascript',
  'Additional details', // Still a catch-all
  'Deployment',
  'React on rails pro',
  'Api',
  'Misc', // Still a catch-all
  'Contributor info', // Still in main nav
  'Testimonials', // Still in main nav
  'Outdated', // Still visible!
];
```

**Why This Wasn't Fixed:**
PR #1813 focused on **content improvements within existing structure**, not restructuring the categories themselves. This is understandable as restructuring requires website code changes in `sc-website` repo.

**Impact:**

- ❌ Users still face 11 categories with unclear hierarchy
- ❌ "Outdated" still visible in navigation
- ❌ Contributor docs still mixed with user docs
- ❌ Testimonials still in technical docs

**Evidence:**
From `01-problem-analysis.md` Section 1.1, all issues remain:

- "Additional details" is still a vague bucket
- "Misc" still unclear
- "Guides" still too broad (18+ files)
- No beginner → intermediate → advanced progression

---

### 2. Multiple Entry Points Still Confusing ❌

**Original Problem:** Section 1.2 - Four conflicting starting points

**Current State After PR #1813:**

1. **Root `README.md`** - Main project README (now better, but still project-level)
2. **`docs/README.md`** - New documentation hub (172 lines, comprehensive navigation)
3. **`docs/home.md`** - Still exists (29 lines, just links) - **Why?**
4. **`docs/getting-started.md`** - Enhanced (254 lines) but still tries to be everything
5. **`docs/quick-start/README.md`** - NEW (212 lines) - Great, but another entry point

**Current User Experience:**

A new user might land on:

- GitHub repo → sees root `README.md` → links to `docs/`
- Docs site → lands on... `docs/home.md`? `docs/README.md`? `getting-started.md`?
- Quick start → `docs/quick-start/README.md`

**Cross-References Create Circular Navigation:**

From `docs/README.md:9-11`:

```markdown
**→ [15-Minute Quick Start Guide](./quick-start/README.md)**

Already have Rails + Shakapacker? **→ [Add to existing app guide](./guides/installation-into-an-existing-rails-app.md)**
```

From `docs/getting-started.md:3`:

```markdown
> **💡 Looking for the fastest way to get started?** Try our **[15-Minute Quick Start Guide](./quick-start/README.md)** instead.
```

**Questions:**

- If quick start is the fastest way, why show `getting-started.md` first?
- What is `docs/home.md` for? (Still unexplained)
- Should there be ONE canonical starting point?

**Why This Wasn't Fully Fixed:**
PR #1813 improved coordination between entry points but didn't consolidate them. Each doc now cross-references others better, but the fundamental question remains: "Where do I actually start?"

**Impact:**

- ⚠️ Improved but not solved
- ✅ Better cross-referencing helps
- ❌ Still confusing for newcomers
- ❌ No single, clear "start here" page

---

### 3. Concepts Still Not Explained Before Usage ❌

**Original Problem:** Section 2.1 - Missing conceptual foundations

**Current State:**

**Example: Server-Side Rendering**

From updated `docs/getting-started.md:93-97` (still in PR #1813):

````erb
- **Server-Side Rendering**: Your React component is first rendered into HTML on the server. Use the **prerender** option:

  ```erb
  <%= react_component("HelloWorld", props: @some_props, prerender: true) %>
````

```

**Still Missing:**
- ❌ What is SSR conceptually?
- ❌ Why does it matter? (SEO, performance, UX)
- ❌ What's the tradeoff? (complexity vs. benefits)
- ❌ When should I use it vs. not?

**Pattern Persists:**
Documentation still follows "here's the feature → here's the syntax" rather than "here's the problem → here's how this solves it → here's how to use it."

**Why This Wasn't Fixed:**
Foundational concept explanations require new content, not just reorganization. PR #1813 focused on improving existing content flow, not adding conceptual deep-dives.

**Impact:**
- ❌ Beginners still need to understand webpack, bundling, SSR, render functions without explicit teaching
- ❌ Copy-paste without understanding continues
- ❌ Debugging harder for users who don't grasp concepts

**What Would Fix This:**
New conceptual guides in a "Core Concepts" section:
- "Understanding Server-Side Rendering"
- "How Bundling Works in React on Rails"
- "Component Registration Explained"
- "Props and RailsContext Deep Dive"

---

### 4. Installation Still Scattered ⚠️
**Original Problem:** Section 2.2 - Installation across multiple docs

**Current State After PR #1813:**

**Improved:**
- ✅ Quick start now provides fast installation path
- ✅ `getting-started.md` enhanced with clearer steps
- ✅ Version requirements consistent

**Still Scattered:**

1. **`docs/quick-start/README.md`** - Fast 15-minute path
2. **`docs/getting-started.md:38-76`** - "Basic Installation" section
3. **`docs/guides/installation-into-an-existing-rails-app.md`** - Detailed existing app guide
4. **`docs/guides/tutorial.md`** - Tutorial-based installation
5. **Root `README.md`** - Quick install commands

**Questions for Users:**
- Which installation guide do I follow?
- Are they all saying the same thing?
- When do I use quick-start vs. installation-into-existing-app?

**Why This Wasn't Fully Fixed:**
Different user journeys legitimately need different installation instructions:
- Blank slate → Quick start
- Existing app → Detailed integration guide
- Learning journey → Tutorial

The issue is these aren't clearly **differentiated and signposted**.

**Impact:**
- ⚠️ Better coordination but still multiple sources
- ✅ Each guide improved individually
- ❌ User still has to decide which path to follow
- ❌ Risk of conflicting instructions

**What Would Fix This:**
Clear decision tree on main docs page:
```

Are you...
├─ Starting a brand new Rails app? → Quick Start
├─ Adding React to existing Rails app? → Integration Guide
└─ Learning React on Rails deeply? → Tutorial

````

Then ensure all three paths are **internally consistent** in their steps.

---

### 5. No "Why React on Rails?" Introduction ❌
**Original Problem:** Section 5.1 - Missing value proposition

**Current State:**
Still no clear "Why React on Rails?" page.

**What Exists:**
- `docs/guides/react-on-rails-overview.md` - Technical overview, not value proposition
- `docs/guides/how-react-on-rails-works.md` - Architecture explanation

**Still Missing:**

1. **Problem Statement:**
   - Why integrate React with Rails?
   - What pain points does this solve?

2. **Comparison with Alternatives:**
   - vs. plain Rails views + Hotwire
   - vs. separate React SPA
   - vs. react-rails gem
   - vs. Inertia.js

3. **When to Use / When Not to Use:**
   - Best fit use cases
   - When to choose something else

4. **Decision Framework:**
   - Help teams evaluate if React on Rails is right for them

**Why This Wasn't Fixed:**
PR #1813 focused on improving **how-to** documentation for users who've already decided to use React on Rails. The "why" content is a different type of writing (persuasive/educational vs. instructional).

**Impact:**
- ❌ Developers can't make informed architectural decisions
- ❌ No clear pitch for managers/stakeholders
- ❌ Evaluation takes longer (have to read through implementation docs to infer value)
- ❌ Harder to advocate internally for adoption

**What Would Fix This:**
New page: `docs/introduction.md` or `docs/why-react-on-rails.md`:
- Problem: Building interactive UIs in Rails
- Solutions overview (spectrum from Hotwire to SPA)
- Where React on Rails fits
- Key benefits (SSR, component reuse, Rails integration, developer experience)
- Tradeoffs (complexity, learning curve)
- Who should use it / who shouldn't

---

### 6. No Progressive Disclosure ❌
**Original Problem:** Section 3.1 - Flat structure, no difficulty levels

**Current State:**

**Small Improvement in `docs/README.md`:**
```markdown
### 🔰 **Beginner Path**
1. Quick Start
2. Core Concepts
3. Tutorial

### ⚡ **Experienced Developer Path**
- Installation Guide
- API Reference
- Advanced Features
````

**Better, but still limited:**

- Only shows 2 paths (beginner vs. experienced)
- No indication of time investment per section
- No prerequisites shown between docs
- All guides in category system still flat (no beginner/intermediate/advanced tags)

**In Sidebar Navigation (not changed by PR #1813):**
The Gatsby sidebar still shows all 11 categories with all docs visible at once:

```
Guides (18+ files, all visible)
├─ Tutorial
├─ Installation
├─ Configuration
├─ Streaming SSR (advanced!)
├─ How to conditionally render (advanced!)
└─ ...all mixed together
```

**Why This Wasn't Fixed:**
Progressive disclosure requires restructuring the category system and potentially duplicating docs into "Basic" and "Advanced" sections. PR #1813 worked within existing structure.

**Impact:**

- ⚠️ `docs/README.md` helps with signposting
- ❌ Actual navigation still flat
- ❌ Beginners can still accidentally read advanced topics first
- ❌ No way to "filter" to just beginner content

**What Would Fix This:**
Restructure categories in `gatsby-node.js`:

```javascript
const reactOnRailsDocsFoldersOrder = [
  'Getting Started', // Quick start, installation, first component
  'Core Concepts', // SSR, bundling, registration, props
  'Building Features', // Common patterns, real-world examples
  'Advanced', // Streaming SSR, device-specific rendering, custom configs
  'API Reference', // View helpers, JS API, configuration
  'Deployment', // Production setup
  'Troubleshooting', // (already good)
];
```

---

### 7. API Reference Still Mixed with Guides ⚠️

**Original Problem:** Section 3.2 - Reference vs. learning content not separated

**Current State:**

**Slight Improvement:**

- `docs/api/` folder exists with 3 files
- `docs/README.md` has "API Reference" section

**Still Mixed:**
From `docs/getting-started.md`:

- Lines 86-120: API examples (how to use `react_component`)
- Lines 206-222: Documents `react_component_hash` (API reference)

From `docs/guides/configuration.md` (316 lines):

- Entire file is essentially API reference for config options
- But lives in "Guides" category

**Pattern:**
Learning guides still contain API reference information inline, rather than linking to centralized API docs.

**Why This Wasn't Fully Fixed:**
Separating API reference from guides requires:

1. Moving content out of guides
2. Ensuring API docs are complete
3. Adding cross-references from guides to API
4. Risk of breaking user workflows

PR #1813 improved existing docs but didn't reorganize this structure.

**Impact:**

- ⚠️ Better than before (API folder exists)
- ❌ Duplication still present
- ❌ No single source of truth for API
- ❌ Hard to maintain consistency

**What Would Fix This:**

**In Guides (learning):**

```markdown
## Using react_component

The `react_component` helper renders React components in Rails views.

**Basic usage:**
<%= react_component("MyComponent", props: { name: "World" }) %>

For all options and parameters, see [react_component API Reference](/api/view-helpers-api#react_component).
```

**In API Reference (complete listing):**

```markdown
# react_component API

## Syntax

<%= react_component(component_name, options) %>

## Parameters

| Parameter | Type | Default | Description |
| component_name | String | required | ... |
| props | Hash | {} | ... |
| prerender | Boolean | false | Enable SSR |
| trace | Boolean | false | ... |
[Complete table with ALL options]
```

---

### 8. Internal Docs Still in Navigation ❌

**Original Problem:** Section 1.3 - Contributor docs mixed with user docs

**Current State:**
**Completely unchanged.** All these still in main navigation:

1. **`contributor-info/` folder** - 5 files:
   - `linters.md`
   - `coding-agents-guide.md` (newly created in PR #1813)
   - `errors-with-hooks.md`
   - `generator-testing.md`
   - `releasing.md`
   - `pull-requests.md`

2. **Planning documents:**
   - `docs/planning/DOCUMENTATION_IMPROVEMENT_PLAN.md` (created in PR #1813)
   - `docs/planning/DOCS_PR_SUMMARY.md` (created in PR #1813)

3. **Root-level internal docs:**
   - `docs/MONOREPO_MERGER_PLAN.md`
   - `docs/DIRECTORY_LICENSING.md`

**Why This Wasn't Fixed:**
PR #1813 was content-focused, not navigation-focused. Hiding these requires changes to website build (`gatsby-node.js`) to exclude certain paths.

**Impact:**

- ❌ Navigation still cluttered
- ❌ Unprofessional appearance (internal docs visible)
- ❌ Users might read contributor docs and get confused

**What Would Fix This:**
In `sc-website/gatsby-node.js`, filter out internal directories:

```javascript
docs: allFile(
  filter: {
    dir: { regex: "/^.*/gatsby-source-git/.*$/" }
    extension: { in: ["md", "mdx"] }
    // Add this:
    relativePath: {
      regex: "/^(?!.*\/(contributor-info|planning|MONOREPO|DIRECTORY).*$).*/"
    }
  }
)
```

Then create separate `/contributing/` section for contributor docs.

---

### 9. Testimonials Still in Technical Docs ❌

**Original Problem:** Section 3.3 - Marketing content in docs

**Current State:**
**Completely unchanged.**

From `gatsby-node.js:41-42`:

```javascript
"Testimonials",
"Outdated",
```

Still the last two categories in technical documentation navigation.

**Why This Wasn't Fixed:**
Same as #8 - navigation restructuring not in scope of PR #1813.

**Impact:**

- ❌ Unprofessional appearance
- ❌ Navigation clutter
- ❌ Inconsistent with industry standards

**What Would Fix This:**

1. Remove "Testimonials" category from `reactOnRailsDocsFoldersOrder`
2. Move testimonial content to shakacode.com marketing site
3. Add single link in introduction: "See who uses React on Rails →"

---

### 10. "Outdated" Category Still Visible ❌

**Original Problem:** Section 1.4 - Deprecated docs in main nav

**Current State:**
**Completely unchanged.**

From `gatsby-node.js:43`:

```javascript
"Outdated",  // ← Still last category!
```

Still visible as the final category in navigation.

**Why This Wasn't Fixed:**
Navigation restructuring not in scope.

**Impact:**

- ❌ Confusing for users
- ❌ Undermines trust in documentation
- ❌ May rank in search results

**What Would Fix This:**

1. Remove "Outdated" from `reactOnRailsDocsFoldersOrder`
2. Add regex filter to exclude outdated directory from build
3. Keep outdated docs in repo for reference but don't publish them
4. OR: Move to separate versioned docs (like `v15.shakacode.com/docs`)

---

## 📊 Summary Score Card

| Problem Area                             | Severity (Before) | Status After PR #1813 | Priority |
| ---------------------------------------- | ----------------- | --------------------- | -------- |
| **1. Quick start missing**               | 🔴 Critical       | ✅ **FIXED**          | -        |
| **2. Troubleshooting scattered**         | 🟡 Medium         | ✅ **FIXED**          | -        |
| **3. Broken links**                      | 🟡 Medium         | ✅ **FIXED**          | -        |
| **4. Version requirements inconsistent** | 🟡 Medium         | ✅ **FIXED**          | -        |
| **5. Visual formatting poor**            | 🟡 Medium         | ✅ **IMPROVED**       | -        |
| **6. Content outdated**                  | 🟡 Medium         | ✅ **FIXED**          | -        |
|                                          |                   |                       |          |
| **7. Information architecture unclear**  | 🔴 Critical       | ❌ **UNRESOLVED**     | 🔥 High  |
| **8. Multiple entry points**             | 🔴 Critical       | ⚠️ **PARTIAL**        | 🔥 High  |
| **9. Concepts not explained**            | 🔴 Critical       | ❌ **UNRESOLVED**     | 🔥 High  |
| **10. No "Why" introduction**            | 🔴 Critical       | ❌ **UNRESOLVED**     | 🔥 High  |
| **11. Installation scattered**           | 🟡 Medium         | ⚠️ **IMPROVED**       | Medium   |
| **12. No progressive disclosure**        | 🟡 Medium         | ⚠️ **PARTIAL**        | Medium   |
| **13. API mixed with guides**            | 🟡 Medium         | ⚠️ **PARTIAL**        | Medium   |
| **14. Internal docs visible**            | 🟠 Low            | ❌ **UNRESOLVED**     | Low      |
| **15. Testimonials in docs**             | 🟠 Low            | ❌ **UNRESOLVED**     | Low      |
| **16. "Outdated" visible**               | 🟠 Low            | ❌ **UNRESOLVED**     | Low      |

**Legend:**

- ✅ **FIXED** - Problem fully resolved
- ⚠️ **IMPROVED/PARTIAL** - Problem partially addressed, work remains
- ❌ **UNRESOLVED** - Problem not addressed

---

## 🎯 What PR #1813 Accomplished

**Strengths:**

1. ✅ **Tactical wins** - Fixed many immediate pain points
2. ✅ **Quality execution** - New content (quick start, troubleshooting) is well-written
3. ✅ **Technical debt** - Link checking, version consistency, formatting
4. ✅ **Modern patterns** - Auto-bundling emphasized, deprecated patterns removed
5. ✅ **User-focused** - Clear attention to user experience in new content

**Type of Improvements:**

- Content quality ✅
- Consistency ✅
- Accuracy ✅
- Accessibility ⚠️

**What It Didn't Do:**

- Structural changes ❌
- Navigation redesign ❌
- Information architecture ❌
- New conceptual content ❌

---

## 🚀 What Comes Next

### Phase 1: Structural Foundations (High Priority)

These require changes to **both** `react_on_rails` repo **and** `sc-website` repo:

1. **Information Architecture Redesign**
   - Restructure 11 categories → 6-7 logical groups
   - Hide internal docs from main navigation
   - Remove "Outdated" and "Testimonials" categories
   - **Files to change:** `sc-website/gatsby-node.js:31-44`

2. **Entry Point Consolidation**
   - Establish ONE canonical starting point
   - Clarify purpose of each remaining entry doc
   - Decision tree for "which guide to follow"
   - **Files to change:** `docs/home.md`, `docs/README.md`, `docs/getting-started.md`

3. **Progressive Disclosure System**
   - Tag docs with difficulty level
   - Restructure categories: Getting Started → Core → Advanced
   - Filter navigation by user level
   - **Files to change:** `gatsby-node.js` category order, frontmatter in docs

### Phase 2: Content Additions (High Priority)

These only require changes to `react_on_rails` repo:

4. **Conceptual Guides**
   - "Understanding Server-Side Rendering"
   - "How Bundling Works"
   - "Component Registration Explained"
   - "Props and RailsContext Deep Dive"
   - **New files:** `docs/concepts/*.md`

5. **Value Proposition Introduction**
   - "Why React on Rails?"
   - Comparison with alternatives
   - When to use / when not to use
   - **New file:** `docs/introduction.md`

6. **API Reference Consolidation**
   - Complete, authoritative API docs
   - Separate from learning guides
   - Guides link to API reference
   - **Refactor:** `docs/api/*.md` + remove duplication from guides

### Phase 3: Polish and Enhance (Medium Priority)

7. **Installation Decision Tree**
   - Clear signposting for different user journeys
   - Consistent steps across all installation paths

8. **Search and Metadata**
   - Add frontmatter to all docs
   - Improve SEO
   - Better internal search

---

## 💡 Recommendations

### For Immediate Action:

**Week 1-2: Information Architecture Redesign**

- Highest impact for user experience
- Requires coordination between repos
- Foundation for all other improvements

**Reasoning:**
Even if we add more great content (like PR #1813 did), users still can't find it easily due to poor IA. Fix the structure first, then add content.

### For Near-Term:

**Week 3-4: Conceptual Guides**

- Addresses critical "concepts not explained" problem
- Can be done independently of IA changes
- High value for beginners

### For Medium-Term:

**Month 2: Polish and Consistency**

- Installation decision tree
- API reference consolidation
- Progressive disclosure tags

---

## 📝 Conclusion

**PR #1813 was excellent tactical work** that fixed many immediate issues and created valuable new resources (quick start, troubleshooting). The new content is well-written and user-focused.

**However, the fundamental strategic problems remain:** unclear information architecture, confusing entry points, missing conceptual foundations, and no clear value proposition.

**Next steps should focus on structural changes** (IA redesign, entry point consolidation) **before adding more content**. Otherwise, we risk creating more great content that users still can't navigate effectively.

**Analogy:**
PR #1813 renovated the rooms in the house (new furniture, fresh paint, better lighting). But users still can't find the rooms because the floor plan is confusing and there are too many front doors.

**We need to:**

1. Fix the floor plan (IA redesign) ← Phase 1
2. Mark one clear front door (entry point consolidation) ← Phase 1
3. Add room signage (progressive disclosure) ← Phase 1
4. Then furnish the empty rooms (conceptual guides) ← Phase 2
