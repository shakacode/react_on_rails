# Monorepo Merger Command Center

Last updated: 2026-02-08 (US)

## Purpose

This is the single coordination point for completing the React on Rails + Pro monorepo merger without team confusion.

Rules:

1. Every merger-related PR and issue links back to this file.
2. Every PR has one primary workstream owner.
3. Merge order is fixed (infra and CI first, docs and examples later).
4. Superseded issues are closed immediately after merge.

## Canonical Trackers

- Primary repo: https://github.com/shakacode/react_on_rails
- Monorepo plan (legacy): `docs/MONOREPO_MERGER_PLAN.md`
- Issue triage matrix: `internal/coordination/PR_ISSUE_TRIAGE_2026-02-08.md`
- Label conventions: `internal/coordination/triage-label-conventions.md`
- Decision log: `internal/coordination/merger-decisions.md`

## Workstreams

| Workstream | Scope | Owner | Backup | Active Items |
| --- | --- | --- | --- | --- |
| `ci-unification` | GitHub Actions, Dependabot, lint convergence | TBD | TBD | #2171, #2214, #2338 |
| `generator-bin-dev` | install flags, precompile hook, startup UX | TBD | TBD | #2277, #2287, #2340 |
| `docs-oss` | /docs cleanup, deprecations, redirects | TBD | TBD | #2362, #2105, #2128 |
| `docs-pro` | /react_on_rails_pro/docs IA and stale content | TBD | TBD | #2300, sc-website#454 |
| `examples-demos` | tutorial and demos alignment with current install model | TBD | TBD | demos#104, demos#108, tutorial#673 |
| `licensing-messaging` | consistency across README/docs/changelog/site | TBD | TBD | #2323 (close), #2192 (close) |

## Merge Order

1. CI and dependency flow stabilization.
2. Generator and `bin/dev` correctness fixes.
3. Docs config and docs cleanup.
4. Demos/tutorial updates.
5. Website/sidebar migration.

No PR from a later phase merges if it depends on an earlier phase item still open.

## Definition of Ready (PR)

- Single topic.
- Explicit "in scope" and "out of scope".
- Linked issue(s).
- Linked dependency PRs.
- Tests listed and run status reported.

## Definition of Done (Issue)

- Merged PR in default branch.
- Changelog impact assessed.
- Superseded/duplicate issues closed.
- Command Center active item list updated.

## Daily Sync Template

Post in one thread each day:

- `Done:`
- `Next:`
- `Blockers:`
- `Needs review:`

## Immediate Focus Queue

1. Merge low-risk ready PRs: #2235, #2346, #2349, #2364, #2366.
2. Rebase and finish: #2338, #2340, #2336, #2354, #2288.
3. Close resolved/superseded issues: #2115, #2323, #2192.
4. Start docs short-term cleanup: #2300, #2362, sc-website#454.

## Freeze Policy

Temporary freeze on high-churn files while related PRs are open:

- `.github/workflows/**`
- `docs/**`
- `react_on_rails_pro/docs/**`
- generator templates in `react_on_rails/lib/generators/**`

Only the designated workstream owner edits frozen paths during active review.
