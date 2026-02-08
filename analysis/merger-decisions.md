# Merger Decisions Log

Last updated: 2026-02-08

## Purpose

Record final decisions once, then reference this file to avoid repeating debates.

## Decision Format

- `Date:` YYYY-MM-DD
- `Decision:` short statement
- `Why:` one to three points
- `Impacts:` repos/files/teams affected
- `References:` issue/PR/doc links

## Decisions

### D-001

- Date: 2026-02-06
- Decision: Use a unified root changelog for OSS and Pro entries.
- Why:
  - Removes split-source ambiguity.
  - Keeps release communication in one place.
- Impacts:
  - `CHANGELOG.md`
  - `react_on_rails_pro/CHANGELOG.md` (pointer only)
- References:
  - https://github.com/shakacode/react_on_rails/pull/2359

### D-002

- Date: 2026-02-01
- Decision: React on Rails Pro is license-optional for evaluation/dev/test/CI; paid license required for production.
- Why:
  - Lowers adoption friction.
  - Supports virality goal while preserving production licensing.
- Impacts:
  - License validation behavior in Ruby and Node renderer.
  - Messaging across README/docs/site.
- References:
  - https://github.com/shakacode/react_on_rails/pull/2324
  - https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md

### D-003

- Date: 2026-02-08
- Decision: Complete merger with fixed merge order: CI first, runtime/generator second, docs third, examples/site fourth.
- Why:
  - Reduces rebase churn and contradictory docs.
  - Keeps blockers visible and bounded.
- Impacts:
  - All merger-related PR sequencing.
- References:
  - `analysis/MERGER_COMMAND_CENTER.md`

### D-004

- Date: 2026-02-08
- Decision: Treat the following open issues as resolved/superseded and close after verification in default branch.
- Why:
  - They are already addressed by merged work.
  - Keeping them open distorts priority.
- Impacts:
  - Issue hygiene in `shakacode/react_on_rails`.
- References:
  - #2115 resolved by https://github.com/shakacode/react_on_rails/pull/2116
  - #2323 resolved by https://github.com/shakacode/react_on_rails/pull/2324
  - #2192 resolved by https://github.com/shakacode/react_on_rails/pull/2359

## Open Decision Slots

### D-005 (pending)

- Topic: Final strategy for `yalc` removal and CI/workspace coupling.
- Options:
  - Complete `workspace:*` migration.
  - Keep yalc only for selected CI flows.
- Drivers:
  - Stability of dummy app/test pipelines.
  - Complexity vs reproducibility.
- Related:
  - #2089
  - PR #2338

### D-006 (pending)

- Topic: Pro docs IA target structure in repo before website migration.
- Options:
  - Keep root files and add website-only grouping.
  - Move Pro docs into category folders in repo.
- Drivers:
  - `sc-website` sidebar generation model.
  - Redirect maintenance cost.
- Related:
  - #2300
  - #2362
  - https://github.com/shakacode/sc-website/issues/454
