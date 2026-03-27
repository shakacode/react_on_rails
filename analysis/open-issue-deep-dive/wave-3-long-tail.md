# Wave 3 Long-Tail Issues (No Open PR at Snapshot)

Generated from open-issue triage snapshot dated 2026-03-22.

Field note: `Posted question` is the exact question posted to each issue during the 2026-03-22 triage pass.

## Domain Breakdown (19 Issues)

| Domain              | Count |
| ------------------- | ----- |
| core/runtime        | 9     |
| ci/tooling          | 4     |
| documentation       | 4     |
| discussion/rfc      | 1     |
| pro/rsc integration | 1     |

## Resolved After Snapshot, Before Execution

- #1887 Investigate the ability to make RSC Payload smaller by removing props and stack objects from it — closed as duplicate of #2522 on 2026-03-23 (canonical issue tracked in Wave 1).
- #1754 Add open telemetry support for react_on_rails — closed as duplicate of #2156 on 2026-03-23 (canonical issue tracked in Wave 2).

## #2527 RSC migration docs: Minor unverified references

- Domain: documentation
- Labels: documentation, docs-cleanup
- Created: 2026-03-04
- Context excerpt: ## Summary Several tool names, import paths, and references in the RSC migration docs should be verified. ## Issues ### E1. `WithAsyncProps` type import path unverified `rsc-data-fetching.md` shows `import type { WithAsy ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2524 RSC migration docs: Missing React on Rails Pro helper references

- Domain: documentation
- Labels: documentation, docs-cleanup
- Created: 2026-03-04
- Context excerpt: ## Summary The RSC migration docs are missing references to key React on Rails Pro helpers that users need during migration. ## Issues ### B4. Missing guidance on `stream_react_component_with_async_props` `rsc-preparing- ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #1999 CI: Fix workflow matrix exclusion logic with empty strings

- Domain: ci/tooling
- Labels: enhancement, P3
- Created: 2025-11-12
- Context excerpt: ## Problem The exclude logic in our GitHub Actions workflows has a potential issue where conditional expressions can produce empty strings that won't match any matrix values: ```yaml exclude: - ruby-version: ${{ github.e ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #1985 Add RSC Migration Success Stories to Documentation

- Domain: documentation
- Labels: documentation, P3
- Created: 2025-11-12
- Context excerpt: ## Overview Add compelling React Server Components (RSC) migration success stories to our documentation to give readers incentive to migrate. ## Success Stories to Feature ### 1. **Mux: 50,000 Lines Migrated** - \*\*Articl ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #1959 CI/Build improvements: prepack scripts and yalc workflow fixes

- Domain: ci/tooling
- Labels: enhancement, P3
- Created: 2025-11-09
- Context excerpt: ## Summary Improve CI workflows and build scripts for better reliability and consistency. ## Background PR #1896 contained several CI and build improvements. This issue tracks extracting those that are still relevant for ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #1958 Improve generator robustness and error handling

- Domain: core/runtime
- Labels: enhancement, P3
- Created: 2025-11-09
- Context excerpt: ## Summary Improve the React on Rails install generator to be more robust with better error handling, validation, and package manager detection. ## Background PR #1896 contained several generator improvements that should ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #1949 Roadmap: Incremental Improvements to Match and Exceed Inertia Rails and Vite Ruby

- Domain: discussion/rfc
- Labels: enhancement, discussion, P3
- Created: 2025-11-09
- Context excerpt: # React on Rails Incremental Improvements Roadmap ## Practical Baby Steps to Match and Exceed Inertia Rails and Vite Ruby ## Executive Summary With Rspack integration coming for better build performance and enhanced Reac ...
- Posted question: Is this still active for implementation, or should it remain a discussion-only backlog item?

## #1929 Add RBS Type Signatures to Improve Developer Experience

- Domain: core/runtime
- Labels: enhancement, P3
- Created: 2025-11-05
- Context excerpt: # Add RBS Type Signatures to Improve Developer Experience ## Problem Currently, both `shakapacker` and `react_on_rails` lack static type information for their Ruby APIs. This means: - IDEs cannot provide accurate autocom ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #1862 Add rake task to generate and export reference webpack/rspack configurations

- Domain: core/runtime
- Labels: P3
- Created: 2025-10-11
- Context excerpt: ## Summary Create a contributor rake task that generates fresh webpack AND rspack configuration exports for documentation purposes. These exported configs can serve as canonical reference examples for users and AI analys ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #1828 Rspack support for RSC

- Domain: pro/rsc integration
- Labels: discussion, P3
- Created: 2025-09-26
- Context excerpt: @AbanoubGhadban we will need to research if rspack can work with RORP RSC. This PR might be relevant: https://github.com/web-infra-dev/rspack/pull/5824 ...
- Posted question: Do you want this prioritized for the next RSC stability wave?

## #1746 Use Error causes

- Domain: core/runtime
- Labels: P3
- Created: 2025-07-09
- Context excerpt: We can slightly simplify code and improve shown errors by using the `cause` option of `Error` constructor. Original blocker #1745 is now merged, so this is unblocked. ...
- Triage note: Previously blocked by #1745; that PR merged on 2025-07-14, so this issue is now unblocked and schedulable.
- Posted question: Now that the blocker is resolved, should this be scheduled in the next implementation wave?

## #1692 Fix Coveralls setup

- Domain: ci/tooling
- Labels: P3
- Created: 2025-01-24
- Context excerpt: Currently the badge in our README for https://coveralls.io/github/shakacode/react_on_rails?branch=master is tied to Travis, which we don't use, and has very old data. Fix this. See https://docs.coveralls.io/. Include our ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #1658 Create load tests and add them to CI

- Domain: ci/tooling
- Labels: P3
- Created: 2024-11-21
- Context excerpt: Probably using K6 for consistency with the new React on Rails Pro load tests. For reference: https://github.com/shakacode/react_on_rails_pro/pull/453, https://github.com/shakacode/react_on_rails_pro/issues/458, https://g ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #1627 Add lock file for creating packs

- Domain: core/runtime
- Labels: P3
- Created: 2024-06-08
- Context excerpt: `ruby ReactOnRails::PacksGenerator.instance.generate_packs_if_stale ` Have this call create a lock file so it can't run concurrently. The lock file should expire within a short time. Here is how to do this: https://w ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #1590 Add support for Vite

- Domain: core/runtime
- Labels: enhancement, P3
- Created: 2023-12-08
- Context excerpt: Stealing the idea from https://github.com/reactjs/react-rails/issues/1134 ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?
- Triage note: Still under consideration; may be deprioritized until Rspack stabilization.

## #1583 Convert spec/dummy/client to Typescript

- Domain: core/runtime
- Labels: contributions: up for grabs!, P3
- Created: 2023-11-15
- Context excerpt: This will enable us to detect type conflicts similar to the ones resolved by https://github.com/shakacode/react_on_rails/pull/1582 ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #1468 Add tests for Turbo/Turbolinks

- Domain: core/runtime
- Labels: enhancement, P3
- Created: 2022-07-07
- Context excerpt: We need to cover use with Turbo in integration or unit tests, because some code paths are currently not tested. Make sure Strict Mode is used. Turbolinks 5 should ideally also be covered, but probably lower priority. ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #1465 Enable StrictMode everywhere in spec/dummy

- Domain: core/runtime
- Labels: enhancement, P3
- Created: 2022-06-27
- Context excerpt: See https://react.dev/reference/react/StrictMode. This should help detect more bugs in RoR. ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #1196 Debugging Server Rendering with the Node VM Rendering Server

- Domain: documentation
- Labels: documentation, P3
- Created: 2019-02-20
- Context excerpt: # Motivation Because server rendering often uses `react_component_hash` to get the meta tags for SEO, we can't just flip a switch and turn off server rendering to debug the code in the browser. Here are the steps to debu ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?
- Triage note: Pending verification before scheduling; confirm whether this legacy Node VM doc is still needed or superseded by newer Node Renderer guidance.
- Action: Verify against current Node Renderer docs and decide keep/update/archive by 2026-03-30 before scheduling.
