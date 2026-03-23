# Wave 1 Active Issues (No Open PR at Snapshot)

Generated from open-issue triage snapshot dated 2026-03-22.

## #2806 update-changelog.md: Version Stamping header should mention explicit version support

- Domain: documentation
- Labels: (none)
- Created: 2026-03-22
- Context excerpt: ## Context In `.claude/commands/update-changelog.md`, the Version Stamping section header (line 153) reads: > When this command is invoked with `release`, `rc`, or `beta`, **use the rake task to stamp the version header* ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2805 Improve /address-review with merge-ready quick actions and follow-up issue workflow

- Domain: ci/tooling
- Labels: (none)
- Created: 2026-03-22
- Context excerpt: ## Summary The current `/address-review` workflow leads to endless review cycles where fixes generate more review suggestions. We need the command to support a "fix what matters, merge, follow-up the rest" pattern with q ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2804 Audit ExecJS documentation accuracy across new docs pages

- Domain: documentation
- Labels: (none)
- Created: 2026-03-22
- Context excerpt: ## Summary PR #2785 added several new docs pages covering ExecJS limitations, performance benchmarks, debugging, and client-vs-server rendering. Bot reviewers raised several valid concerns about ExecJS technical accuracy ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2796 Track E: improve first-run and scaffold CI consistency for RSC flows

- Domain: ci/tooling
- Labels: (none)
- Created: 2026-03-21
- Context excerpt: Parent: #2496 ## Scope Implement Track E from #2496: first-run/scaffold consistency for RSC + Node renderer flows. ## Checklist - [ ] Ensure generated docs include precompile/build ordering instructions. - [ ] Ensure gen ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2795 Track D: enforce secure renderer password defaults for production-like envs

- Domain: pro/rsc integration
- Labels: (none)
- Created: 2026-03-21
- Context excerpt: Parent: #2496 ## Scope Implement Track D from #2496: secure renderer defaults and production guardrails. ## Checklist - [ ] Require explicit `RENDERER_PASSWORD` in production/staging-like environments. - [ ] Keep local d ...
- Posted question: Can we proceed with OSS-side prep now and defer Pro package changes until explicit approval?

## #2793 Track A: add --rsc-pro generator mode with matched Pro/RSC defaults

- Domain: pro/rsc integration
- Labels: (none)
- Created: 2026-03-21
- Context excerpt: Parent: #2496 ## Scope Implement Track A from #2496: first-class `--rsc-pro` generator mode. ## Checklist - [ ] Add generator flag and templates for Pro RSC defaults. - [ ] Pin matching gem + npm versions in generated fi ...
- Posted question: Can we proceed with OSS-side prep now and defer Pro package changes until explicit approval?

## #2777 Add language hints to bare fenced code blocks in docs (deployment, api-reference, misc)

- Domain: documentation
- Labels: (none)
- Created: 2026-03-20
- Context excerpt: ## Summary Several remaining docs pages have fenced code blocks without language identifiers, preventing syntax highlighting. ## Affected files | File | Bare blocks | Languages needed | |------|-------------|------------ ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2776 Add language hints to bare fenced code blocks in docs (migrating & RSC)

- Domain: documentation
- Labels: (none)
- Created: 2026-03-20
- Context excerpt: ## Summary Several docs pages under `migrating/` and `pro/react-server-components/` have fenced code blocks without language identifiers, preventing syntax highlighting. ## Affected files | File | Bare blocks | Languages ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2775 Add language hints to bare fenced code blocks in docs (building-features)

- Domain: documentation
- Labels: (none)
- Created: 2026-03-20
- Context excerpt: ## Summary Several docs pages under `building-features/` have fenced code blocks without language identifiers, preventing syntax highlighting. ## Affected files | File | Bare blocks | Languages needed | |------|--------- ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2774 Add language hints to bare fenced code blocks in docs (upgrading)

- Domain: documentation
- Labels: (none)
- Created: 2026-03-20
- Context excerpt: ## Summary Several docs pages have fenced code blocks without language identifiers (e.g., bare ``` instead of ```ruby or ```bash). This prevents syntax highlighting on reactonrails.com and anywhere else the docs are rend ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2771 Doctor: migrate from regex config parsing to runtime config queries

- Domain: core/runtime
- Labels: enhancement
- Created: 2026-03-19
- Context excerpt: ## Problem The doctor validates app configuration by regex-parsing initializer files as strings. This approach is fragile and can produce wrong results when configs use conditional logic, ERB, dynamic values, or patterns ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #2769 Investigate common client RSC migration mistakes and update migration guide

- Domain: documentation
- Labels: (none)
- Created: 2026-03-19
- Context excerpt: ## Summary Gather real-world feedback on mistakes and pain points clients encounter while migrating to React Server Components, then fold that knowledge back into the existing migration guide series. ## Motivation We hav ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2763 Add REACT_ON_RAILS_PRERENDER_OVERRIDE env var to globally disable prerendering

- Domain: core/runtime
- Labels: (none)
- Created: 2026-03-19
- Context excerpt: ## Problem There is no way to globally force prerendering off when views explicitly set `prerender: true` on individual components. **Use case:** In CI/test environments (e.g., CircleCI), there is no SSR server available ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #2678 Meta: Documentation Overhaul — Consolidation, Cleanup, and Modernization

- Domain: documentation
- Labels: documentation, P2
- Created: 2026-03-18
- Context excerpt: ## Purpose Meta issue tracking the documentation overhaul for React on Rails. The goal: make docs modern, navigable, and present Pro features as an integrated tier rather than a separate product. ### Problems being solve ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2677 RSC template hello_server links to unpublished docs page

- Domain: documentation
- Labels: (none)
- Created: 2026-03-18
- Context excerpt: ## Problem The RSC generator template at `react_on_rails/lib/generators/react_on_rails/templates/rsc/base/app/views/hello_server/index.html.erb` links to `https://reactonrails.com/docs/pro/react-server-components/`, but ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2673 Remove broad Pro URL exclusions from lychee link checker config

- Domain: pro/rsc integration
- Labels: (none)
- Created: 2026-03-18
- Context excerpt: ## Problem PR #2668 added broad exclusions to `.lychee.toml` that disable link checking for the exact hosts that were rewired in the Pro URL migration. Specifically, these exclusions mask broken links to the new `/docs/. ...
- Posted question: Can we proceed with OSS-side prep now and defer Pro package changes until explicit approval?

## #2647 TanStack Router follow-up: remove dependency on internal router.ssr flag

- Domain: core/runtime
- Labels: (none)
- Created: 2026-03-16
- Context excerpt: ## Summary TanStack Router SSR support merged in [PR #2516](https://github.com/shakacode/react_on_rails/pull/2516) and now correctly uses the public async `router.load()` API. However, the current server-side helper stil ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #2646 Docs version policy: normalize sub-16.4.0 references in active guides

- Domain: documentation
- Labels: (none)
- Created: 2026-03-16
- Context excerpt: ## Context Current docs still contain many references to versions below the current baseline floor (16.4.0), including obvious placeholders and mixed historical references. Source report: https://github.com/shakacode/rea ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2633 Follow-up: tighten Doctor/SystemChecker webpack config diagnostics during Rspack migration

- Domain: core/runtime
- Labels: (none)
- Created: 2026-03-16
- Context excerpt: ## Context In PR #2612 we deferred a couple of non-blocking review items that are related to webpack config path discovery. These are low priority while we continue the Rspack migration, but we should track them explicit ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #2626 Pro generator should automate gem/package swap during upgrade

- Domain: pro/rsc integration
- Labels: (none)
- Created: 2026-03-16
- Context excerpt: ## Summary The `react_on_rails:pro` generator should handle the full upgrade automatically — swap the gem in the Gemfile, run `bundle install`, swap the npm package, and update imports — so users can upgrade with a singl ...
- Posted question: Can we proceed with OSS-side prep now and defer Pro package changes until explicit approval?

## #2582 Follow-up: CSP nonce sanitization consolidation and validation policy

- Domain: core/runtime
- Labels: enhancement, P2
- Created: 2026-03-10
- Context excerpt: ## Context PR #2418 contains two non-blocking review topics that we are deferring so the PR can merge while @abanoub is away. ## Follow-up items 1. Consolidate duplicate nonce sanitization logic - Current duplicate imple ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #2563 Migrate from deprecated Async::Variable to Async::Promise

- Domain: pro/rsc integration
- Labels: enhancement, P2
- Created: 2026-03-08
- Context excerpt: ## Summary `Async::Variable` was deprecated in Async gem v2.29.0 in favor of `Async::Promise`. The codebase currently uses `Async::Variable` in the streaming helper for synchronizing the first chunk between producer task ...
- Posted question: Can we proceed with OSS-side prep now and defer Pro package changes until explicit approval?

## #2560 Release 16.4.0 Triage: PRs, Issues, and Prioritization

- Domain: discussion/rfc
- Labels: discussion, P1
- Created: 2026-03-08
- Context excerpt: > **Last updated:** 2026-03-11 morning (Update 5) ## Summary | Category | Count | |---|---| | Open PRs | 21 | | Open Issues | 85 | | Must-have PRs (approved, ready) | 1 | | Must-have PRs (need work) | 2 | | Must-have iss ...
- Posted question: Is this still active for implementation, or should it remain a discussion-only backlog item?
- Triage note: Meta release tracker; use for coordination and split implementation into focused child issues.

## #2538 Fix chunk contamination docs in RSC migration guide (PR #2460)

- Domain: documentation
- Labels: documentation, docs-cleanup, P2
- Created: 2026-03-05
- Context excerpt: ## Summary The chunk contamination section in the RSC migration guide (PR #2460) has two issues that should be fixed before merging: 1. **Incorrect root cause explanation** — the guide says chunks are overwritten ("last ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2528 Add RSC migration guide article: Flight payload optimization and when server components hurt performance

- Domain: documentation
- Labels: enhancement, documentation, P2
- Created: 2026-03-04
- Context excerpt: ## Context PR #2460 adds a 6-part RSC migration guide series. The guides currently treat the server-vs-client component decision purely as a **technical capability** question: "Does the component use state/hooks/events? ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2522 Reduce RSC payload overhead: double JSON.stringify adds ~38KB (24%) unnecessary bloat

- Domain: rsc/runtime
- Labels: enhancement, P2
- Created: 2026-03-04
- Context excerpt: ## Summary The current RSC payload embedding pipeline applies `JSON.stringify` **twice** to Flight data before injecting it into the HTML stream. This double serialization causes every `"` character in the Flight payload ...
- Posted question: Do you want this prioritized for the next RSC stability wave?

## #2514 Align generated Procfile.dev HMR messaging with default hmr setting

- Domain: pro/rsc integration
- Labels: enhancement, P2, codex
- Created: 2026-03-04
- Context excerpt: ## Summary The generated `Procfile.dev` is documented as an HMR profile, but the default Shakapacker dev server config uses `hmr: false`. This creates confusing DX because users expect Fast Refresh/HMR from the launcher ...
- Posted question: Can we proceed with OSS-side prep now and defer Pro package changes until explicit approval?

## #2437 create-react-on-rails-app CLI missing --rsc and --pro flags

- Domain: pro/rsc integration
- Labels: enhancement, P1, release:16.4.0-must-have
- Created: 2026-02-16
- Context excerpt: ## Feature Request The `create-react-on-rails-app` CLI tool (v16.4.0-rc.2) doesn't support the `--rsc` or `--pro` flags, even though the underlying Rails generator (`react_on_rails:install`) now supports both. ## Current ...
- Posted question: Can we proceed with OSS-side prep now and defer Pro package changes until explicit approval?

## #2426 RSC docs: add troubleshooting matrix for common setup/runtime failures

- Domain: documentation
- Labels: enhancement, documentation, P2
- Created: 2026-02-16
- Context excerpt: ## Problem Current RSC docs describe happy-path setup, but they do not have a consolidated troubleshooting section for the most common setup/runtime failures. As RSC adoption grows, users need fast diagnosis guidance wit ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2425 RSC docs: add standalone upgrade guide for existing Pro apps

- Domain: documentation
- Labels: enhancement, documentation, P2
- Created: 2026-02-16
- Context excerpt: ## Problem After #2284 (and follow-up compatibility work in #2424), there are now two real-world webpack export shapes in existing Pro apps: - legacy: `module.exports = configureServer` - current: `module.exports = { def ...
- Posted question: Should this be batched with related docs issues in a single docs PR, or handled separately?

## #2367 Merger Command Center (2026-02): Canonical execution tracker

- Domain: core/runtime
- Labels: P2
- Created: 2026-02-08
- Context excerpt: ## Summary This issue is the canonical tracker for completing the monorepo merger and docs cleanup. Use this instead of tracking execution in multiple stale planning issues. **Labels are live on GitHub** — use the conven ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?

## #2248 Lefthook pre-push hook is too slow

- Domain: ci/tooling
- Labels: P2
- Created: 2025-12-25
- Context excerpt: Here's an example for PR https://github.com/shakacode/react_on_rails/pull/2247 2 files changed and: - summary: (done in 33.17 seconds) - ✔️ branch-lint (1.71 seconds) ``` gpf 1 ↵ ╭─────────────────────────────────────╮ │ ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2171 Fix CI failures for Dependabot PRs due to missing REACT_ON_RAILS_PRO_LICENSE secret

- Domain: ci/tooling
- Labels: dependencies, P2
- Created: 2025-12-05
- Context excerpt: # Fix CI Failures for Dependabot PRs ## Summary Dependabot PRs consistently fail CI because they don't have access to the `REACT_ON_RAILS_PRO_LICENSE` secret. This blocks automated dependency updates from being merged. # ...
- Posted question: Should this run in the CI/tooling maintenance wave, or be deferred behind release-critical runtime work?

## #2142 Remove `immediate_hydration` feature from everywhere at the codebase

- Domain: core/runtime
- Labels: P2
- Created: 2025-11-28
- Context excerpt: Issue body is template boilerplate with no concrete reproduction/context; triage should require a concrete deprecation-removal plan before implementation scheduling. ...
- Posted question: Do you want this scheduled in the next implementation wave, or parked until after active release work?
