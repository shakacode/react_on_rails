# RC Testing Plan — Design Spec

**Status:** Draft, pending user review
**Date:** 2026-05-21
**Author:** Justin Gordon (via Claude Code brainstorming)

## Context

We ship release candidates (RCs) of `react_on_rails` and `shakapacker` ahead of each final release. Today, RC testing is informal and inconsistent across the ecosystem of demo repos under `shakacode/`. Regressions slip through to final releases because:

- No canonical list of which repos should validate an RC.
- No uniform checklist for what "RC tested" means.
- Demo-specific behaviors (RSC streaming, HMR + SSR coexistence, bundle splitting) are not exercised by automated tests in most demos.
- After the final ships, demos sometimes stay pinned to the RC version.

This spec defines a repeatable RC testing process: a known set of demo repos, a uniform automated + manual checklist applied to each, per-repo appendices that exercise the headline feature of each demo, a tiered gating policy, and a mandatory post-release follow-up to bump every demo to the final version.

## Decisions

Locked through brainstorming dialog 2026-05-21:

| #   | Decision                     | Choice                                                                                                                                      |
| --- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Q1  | Repo scope                   | **A** — Active demos only (~10 repos). Adjacent infrastructure called out as future scope.                                                  |
| Q2  | How RCs land in demos        | **C** — PR per RC into `main` of each demo. Plus a scheduled follow-up PR to bump RC → final after the gem ships.                           |
| Q3  | Test plan structure          | **B** — Uniform common checklist + short per-repo appendix targeting the headline feature.                                                  |
| Q4  | Manual vs automated boundary | **B** — Use existing CI; manual fills the gap. One-time investment: add a Playwright smoke per demo for the headline feature where missing. |
| Q5a | Gating policy                | **B** — Tiered. Critical demos hard-block the final; tutorial/examples soft-track.                                                          |
| Q5b | Plan file location           | **C** — Canonical in `.claude/docs/rc-testing-plan.md`; stub link in `docs/contributing/rc-testing-plan.md`.                                |

## Repo Inventory

### Tier 1 — Hard gate (7 repos)

A failed RC PR in any of these blocks the final release.

| Repo                                                       | Headline feature                                                           |
| ---------------------------------------------------------- | -------------------------------------------------------------------------- |
| `shakacode/react-on-rails-rsc-demo`                        | Minimal RSC starter — client component hydrating inside a server component |
| `shakacode/react-on-rails-demo-hacker-news-rsc`            | RSC streaming with comment trees                                           |
| `shakacode/react-on-rails-demo-marketplace-rsc`            | RSC product grid + filter interactions                                     |
| `shakacode/react-on-rails-demo-gumroad-rsc`                | RSC dashboards + performance benchmark                                     |
| `shakacode/react_on_rails-demo-octochangelog-on-rails-pro` | RSC + server-rendered markdown                                             |
| `shakacode/react-on-rails-demo-ssr-hmr`                    | SSR + HMR coexistence                                                      |
| `shakacode/react-on-rails-demo-v16-bundle-splitting`       | On-demand bundle loading                                                   |

### Tier 2 — Soft track (3 repos)

Tested for each RC; failures filed as issues but do not block the final release.

| Repo                                            | Headline feature                         |
| ----------------------------------------------- | ---------------------------------------- |
| `shakacode/react-on-rails-example-open-flights` | Larger migrated app (search + map)       |
| `shakacode/react-on-rails-example-migration`    | `react-rails` → React on Rails migration |
| `shakacode/react-webpack-rails-tutorial`        | Legacy tutorial reference app            |

### Follow-up scope (not v1)

Documented in the plan as candidates for future inclusion:

- `shakacode/cypress-playwright-on-rails`
- `shakacode/package_json`
- `shakacode/react-on-django`
- `shakacode/shakapacker.com` (docs site)
- `shakacode/reactonrails.com` (docs site)
- `shakacode/shakaperf`

These are out of scope for v1 because they either don't consume the gems directly (docs sites) or have a different release cadence (utility/companion gems).

## Workflow

### Per-RC PR cycle

For each new RC of `react_on_rails` or `shakapacker` (or both together):

1. **Release manager creates a tracking issue** in `shakacode/react_on_rails`:
   - Title: `RC test tracking: react_on_rails X.Y.Z-rc.N [+ shakapacker A.B.C-rc.M]`
   - Body generated from `.github/ISSUE_TEMPLATE/rc-release-tracking.md` — pre-populated with all Tier 1 and Tier 2 demos, grouped by tier, with checkbox per demo and a slot for the PR link.

2. **For each demo**, open a PR to `main` of that demo:
   - Title: `chore: bump react_on_rails to X.Y.Z-rc.N` (or `bump shakapacker to A.B.C-rc.M`, or both)
   - Body: paste the **RC Test Report template** from `.claude/docs/rc-testing-plan.md` and fill it out as testing progresses
   - Bumps `Gemfile` (and `Gemfile.lock`) and any `package.json` reference to the new RC

3. **CI runs automatically** on the PR. The PR description tracks manual sign-off via checkboxes.

4. **Link the PR back** to the tracking issue. The issue's checkbox is ticked when the PR's CI is green AND all manual items are checked off.

5. **Gating evaluation** (before final release):
   - All 7 Tier-1 PRs must have CI green + manual fully signed off.
   - Tier-2 PRs that fail get a follow-up issue filed in the affected demo and a comment in the tracking issue; they do not block.

### Post-release follow-up (mandatory)

When the gem ships final:

1. Release manager updates each demo's RC PR by pushing a new commit that bumps from the RC to the final version (do **not** force-push; the existing RC commit stays in the PR history). If preferred, close the RC PR and open a fresh PR for the final.
2. CI re-runs.
3. Merge the PRs into `main` of each demo.
4. Close the tracking issue with a summary comment.

This step is mandatory — demos must not stay pinned to an RC after the final ships. The tracking issue stays open until all Tier-1 demos are bumped to final.

## Common Checklist

The plan's canonical checklist applied to **every** demo PR.

### Automated (CI on the PR)

"How to check": look at the PR's GitHub status checks. All must be green.

| Check                              | What it verifies                       | How to check locally                                       |
| ---------------------------------- | -------------------------------------- | ---------------------------------------------------------- |
| `bundle install`                   | Ruby deps resolve including the new RC | `bundle install` in the demo's working directory           |
| JS install                         | Node deps resolve                      | `pnpm install` / `yarn install` / `npm install` (per repo) |
| RuboCop / lint                     | Style + structural lint                | per repo's lint task                                       |
| ESLint (where present)             | JS lint                                | per repo's npm script                                      |
| Asset compilation                  | Build pipeline succeeds                | `bin/shakapacker` or `bin/webpacker`                       |
| RSpec (where present)              | Server-side unit + integration         | `bundle exec rspec`                                        |
| Jest (where present)               | Client-side unit                       | per repo's test script                                     |
| Playwright/Cypress (where present) | End-to-end                             | per repo's e2e script                                      |

If a demo lacks a category (e.g., no Jest), that line is N/A and called out in the per-repo appendix.

### Manual (signed off in PR description)

Each item must have a "how to check" line so the tester knows exactly what to look for. The plan spells these out verbatim.

| Item                             | How to check                                                                                                                                           |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `bin/dev` (or equivalent) starts | Run `bin/dev`. All Procfile.dev processes show `started` and do not exit within 60 seconds.                                                            |
| App responds                     | `curl -I http://localhost:3000` returns a 2xx or 3xx status.                                                                                           |
| SSR view-source check            | Browse to the primary route. View page source. Grep for `data-react-class` (or `data-rsc` for RSC demos). Expect ≥1 hit.                               |
| Console clean                    | Open browser DevTools. After page load + one interaction, the Console tab shows no red errors. (Warnings acceptable; note any new warnings in the PR.) |
| Hot reload                       | Edit a leaf component file. Save. Verify the browser updates without manual refresh and that component state (e.g., counter, input value) persists.    |
| Clean shutdown                   | `Ctrl+C` stops every process. Run `bin/dev` again — it starts cleanly with no port-in-use errors.                                                      |
| Headline feature                 | See the per-repo appendix in the plan.                                                                                                                 |

The plan presents this as a copy-pasteable Markdown checklist for the PR body.

## Per-Repo Appendices

Each demo gets a 3–5 item appendix in the canonical plan. Items marked `*` require verification by reading the repo's README/docs during plan authoring — the spec captures the intent, the plan captures the exact assertions.

### `react-on-rails-rsc-demo`

- A client component (with `'use client'`) hydrates inside a server-rendered component tree.
- Streaming suspense fallback is visible during initial load.
- View-source shows server-rendered markup for the server component (not an empty container).

### `react-on-rails-demo-hacker-news-rsc`

- Story list streams in over RSC (`*` confirm transport — RSC payload vs streaming HTML).
- Clicking a story navigates without a full page reload (no white flash).
- Comment tree renders server-side; first comment appears in view-source.

### `react-on-rails-demo-marketplace-rsc`

- Product grid renders server-side and streams.
- Applying a filter updates the result set without a full page reload.
- Image lazy-load fires below the fold (`*` confirm — Network tab shows images loading on scroll).

### `react-on-rails-demo-gumroad-rsc`

- Dashboard charts render with data fetched server-side (no client-side data waterfall visible in Network).
- Benchmark page (`/benchmark` or equivalent — `*` confirm path) loads under the documented `action_total` target.
- RSC payload visible in the network response for the dashboard route.

### `react_on_rails-demo-octochangelog-on-rails-pro`

- Changelog entries render with server-rendered Markdown.
- Pagination loads the next page without a full reload.
- View-source shows rendered Markdown HTML (not raw Markdown).

### `react-on-rails-demo-ssr-hmr`

- SSR and HMR are both active simultaneously (view-source shows SSR output; component edit triggers HMR).
- Editing a component preserves component state through the HMR update.
- After HMR, view-source on a hard reload still shows SSR output (HMR did not break the server bundle).

### `react-on-rails-demo-v16-bundle-splitting`

- Navigating to a code-split route triggers a new chunk download visible in the Network tab.
- Initial bundle size is below the documented threshold (`*` confirm threshold from repo).
- The on-demand chunk loads and executes without a JS error.

### `react-on-rails-example-open-flights`

- Search returns results.
- Map renders without console errors.
- SSR view-source clean.

### `react-on-rails-example-migration`

- App boots after migration.
- A pre-migration and a post-migration component example both render correctly.
- No console errors.

### `react-webpack-rails-tutorial`

- The tutorial's primary flow (`*` confirm — likely the Hello World / Redux example) works end-to-end.
- Both client-side and SSR examples render.
- No console errors on the primary routes.

## Automation Roadmap

For each demo, the plan records its **current** automated coverage and lists missing Playwright smoke tests for the headline appendix item. Adding the smoke is a separate per-repo PR, not blocking on v1 of this plan.

The plan includes a table like:

| Demo                      | Current CI | Missing Playwright | Priority      |
| ------------------------- | ---------- | ------------------ | ------------- |
| `react-on-rails-rsc-demo` | TBD        | TBD                | High (Tier 1) |
| ...                       | ...        | ...                | ...           |

The TBDs are filled in during plan authoring by inspecting each demo's `.github/workflows/` and `package.json` / `Gemfile`.

Priority: Tier 1 demos first, Tier 2 demos as backlog.

## Gating Policy

### Tier 1 (hard gate)

All 7 Tier-1 PRs must satisfy both:

- **Automated**: every CI check on the PR is green.
- **Manual**: every checkbox in the PR's Manual section is ticked, with a tester name and date in the PR description.

The final release of `react_on_rails` or `shakapacker` is blocked until all 7 Tier-1 PRs pass. The release manager confirms this by reviewing the tracking issue.

**Pre-existing failures**: if a Tier-1 demo fails for a reason unrelated to the RC (verified by reproducing on `main` of the demo without the RC bump), the failure does not block. The release manager documents the unrelated failure in the tracking issue with a link to the reproducing run on `main`, files an issue in the demo repo, and marks the demo as "tested, blocked by pre-existing issue." This carve-out exists so a stale demo bug cannot indefinitely block a release.

### Tier 2 (soft track)

Tier-2 PRs are opened, tested, and tracked. A Tier-2 failure:

- Files an issue in the affected demo repo.
- Adds a note in the tracking issue.
- Does NOT block the final release.

If a Tier-2 demo fails three RC cycles in a row without being fixed, the next release manager raises it for triage (escalate to Tier 1 or formally deprecate).

### Recording results

The tracking issue is the single source of truth for "did we test this RC?" Every checkbox links to its PR. The issue stays open until:

- All Tier-1 demos are bumped to final.
- All Tier-2 failures have either been fixed or filed as tracked issues.

## Deliverables

Three files land in `shakacode/react_on_rails`:

### 1. `.claude/docs/rc-testing-plan.md` (canonical plan)

Comprehensive plan with all sections:

- Context + scope
- Repo inventory (Tier 1, Tier 2, follow-up)
- Workflow (per-RC PR cycle + post-release follow-up)
- Common checklist (automated + manual, with "how to check" specifics)
- Per-repo appendices (10 sections)
- Automation roadmap table
- Gating policy
- **RC Test Report template** (copy-pasteable for demo PR bodies)
- **Tracking issue template** (mirrored in `.github/ISSUE_TEMPLATE/`)

### 2. `docs/contributing/rc-testing-plan.md` (stub for the published docs site)

Short page (~150 words) explaining what the plan is and linking to the canonical `.claude/docs/rc-testing-plan.md`. Surfaces the plan to humans reading the public docs.

### 3. `.github/ISSUE_TEMPLATE/rc-release-tracking.md`

GitHub issue template that pre-populates the tracking issue body with:

- Tier 1 and Tier 2 demos as checkboxes
- Slots for PR links
- Manual sign-off slots for the release manager

No changes are committed to the demo repos as part of v1 of this plan. Demo repos consume the template ad-hoc per RC by copy-pasting from the canonical plan.

## Out of Scope (v1)

- Adding Playwright tests to demos — captured as an automation roadmap backlog inside the plan, not implemented here.
- RC testing of adjacent infrastructure (`cypress-playwright-on-rails`, `package_json`, `react-on-django`, docs sites, `shakaperf`) — listed as future scope in the plan.
- Per-RC clone repos (the `react_on_rails-demo-16-4-0-rc5` pattern) — superseded by the PR-per-RC workflow.
- Automated RC PR creation (e.g., a bot that opens the bump PRs in all 10 demos) — manual for v1; can be added later as a meta-script.
- Cross-repo CI orchestration (e.g., dispatching a workflow in `react_on_rails` that triggers builds in every demo) — out of scope; the tracking issue is the orchestration surface.

## Open Verification Items

Items marked `*` in per-repo appendices require reading each demo's README/source to confirm exact assertions (route paths, performance thresholds, network markers). The implementation plan (next step) will include a verification pass over each Tier-1 demo before the plan ships.

## Next Steps

1. User reviews this spec.
2. On approval, invoke `superpowers:writing-plans` to produce the implementation plan (file-level work breakdown for the three deliverables in this repo).
3. Implement the deliverables.
4. Open the first tracking issue against the next RC of either gem to validate the workflow end-to-end.
