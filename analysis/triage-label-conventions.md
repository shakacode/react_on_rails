# Triage and Label Conventions

Last updated: 2026-02-08

## Goals

- Keep the backlog queryable.
- Make ownership obvious.
- Prevent duplicate and stale work.

## Required Labels

Apply at least one from each group.

### Group A: Work Type

- `merger-blocker`: blocks merger completion.
- `docs-cleanup`: docs cleanup or migration.
- `runtime-fix`: user-facing behavior fix.
- `ci-tooling`: workflows, checks, scripts.
- `dependency`: dependency/security updates.

### Group B: Priority

- `P0`: merge this week.
- `P1`: this sprint.
- `P2`: backlog.
- `P3`: parked.

### Group C: Status

- `ready-to-merge`: approved and green or only rebase needed.
- `needs-review`: no final review yet.
- `needs-rebase`: conflicts/out-of-date base.
- `changes-requested`: blocking review comments unresolved.
- `blocked`: waiting on dependency.
- `superseded`: replaced by another issue/PR.

### Group D: Ownership

- `owner:<github-handle>` (one primary owner).
- `backup:<github-handle>` (optional).

## PR Naming Convention

Use a stable prefix:

- `merge/` for merger structural work.
- `docs/` for docs reorganization/redirects.
- `ci/` for workflow and tooling updates.
- `fix/` for runtime or generator behavior.

Examples:

- `merge/remove-yalc-workspace-flow`
- `docs/pro-sidebar-restructure`
- `ci/unify-core-pro-lint`

## Issue Lifecycle

1. New issue created.
2. Add labels from all groups.
3. Link to command center and any dependent item.
4. Move to `ready-to-merge` or `blocked` within 48h.
5. Close immediately after merge with PR reference.

## Superseded and Duplicate Handling

If duplicate/superseded:

1. Add label `superseded`.
2. Comment with replacement issue or PR URL.
3. Close issue in same session.

## Definition of Escalation

Escalate in daily sync if either is true:

- PR is blocked for more than 2 business days.
- CI fails more than 2 consecutive runs for unknown reasons.

## Recommended GitHub Saved Searches

- `is:open is:pr label:merger-blocker -label:ready-to-merge`
- `is:open is:issue label:superseded`
- `is:open is:pr label:needs-rebase`
- `is:open is:issue label:P0`
