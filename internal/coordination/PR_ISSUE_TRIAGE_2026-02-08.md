# PR and Issue Triage Matrix

Date: 2026-02-08
Repo: `shakacode/react_on_rails`

## Scope and Method

- Source snapshot: 19 open PRs, 75 open issues.
- Objective: reduce merger/docs confusion and shrink active queue.
- Action vocabulary: `merge`, `rework`, `close`, `defer`.

## Open PR Actions

### Merge now

- #2235 `Fix conductor-setup.sh: Use pnpm and bundle in all directories`
- #2346 `Add auto-registration for Redux stores`
- #2349 `Add extensible bin/dev precompile pattern (#2347)`
- #2364 `Add .docs-config.yml manifests with CI validation`
- #2366 `Optimize CLAUDE.md for Opus 4.6 context handling`

### Rebase and merge (near-ready)

- #2288 `Fix generator inheriting BUNDLE_GEMFILE from parent process`
- #2348 `Add component_extensions config for ReScript and transpiled languages`
- #2285 `Dependabot: shakapacker 9.3.0 -> 9.5.0`
- #2286 `Dependabot: npm-security group update`

### Rework before merge

- #2338 `Remove yalc, use pnpm workspaces for dummy apps` (core merger blocker)
- #2340 `Add database setup check to bin/dev`
- #2336 `Fix FOUC in Pro spec/dummy app by inlining critical CSS`
- #2354 `Add suppressWarnings option to silence console warnings`
- #2284 `Add --pro and --rsc flags to install generator`
- #2282 `Fix precompile hook detection to match generator template`

### Close or replace

- #2365 `Restructure CLAUDE.md ...` (superseded by #2366)
- #2254 `automatic license renewal` (re-scope after new licensing model)
- #2265 `Async Props docs with animated SVG diagrams` (re-open as focused docs IA PR)
- #2203 `jws vulnerability` (stale/outpaced by current lock/dependency state; re-open only if active alert remains)

## Open Issue Actions

### Close now (already resolved by merged PR)

- #2115 resolved by PR #2116
- #2323 resolved by PR #2324
- #2192 resolved by PR #2359

### Keep open and tie to active PR

- #2089 <- PR #2338
- #2099 <- PR #2340
- #2100 <- PR #2336
- #2117 <- PR #2354
- #2277 <- PR #2284
- #2279 <- PR #2282
- #2287 <- PR #2288
- #2343 <- PR #2348
- #2344 <- PR #2346

### Convert to one canonical merger tracker

Consolidate into one new issue and close as superseded after linking:

- #2105
- #2106
- #2128
- #2214 (if fully covered by canonical tracker + CI PR)

### Short-term docs cleanup queue

- #2300 `Outdated React on Rails Pro documentation references GitHub Packages`
- #2362 `Remove or redirect deprecated code-splitting docs page`
- `sc-website#454` `Organize React on Rails Pro docs sidebar categories`

### Defer (post-merger growth roadmap)

- #1590 `Add support for Vite`
- #1828 `Rspack support for RSC`
- #1949 `Roadmap: match/exceed Inertia Rails and Vite Ruby`

## Other Repos: Current Actionable Work

### `shakacode/sc-website`

- Issue: #454 (docs sidebar categories) -> execute with Pro docs folder restructure.
- PR: #427 (license API) -> verify if still needed in current licensing direction.

### `shakacode/react_on_rails-demos`

- PR #108 (version bump) and PR #104 (TanStack demo) are current and should be integrated with docs refresh.

### `shakacode/react-webpack-rails-tutorial`

- Keep as reference app. Triage stale PRs/issues separately from merger-critical track.

## Execution Order

1. Merge immediate low-risk PRs.
2. Close resolved issues.
3. Finish blocker rework PRs.
4. Land docs cleanup in core + Pro docs.
5. Update `sc-website` sidebar/redirect behavior.
