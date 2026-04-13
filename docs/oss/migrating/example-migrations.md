## Example Migrations

Teams evaluating React on Rails are usually not starting from a blank Rails app.

They already have one of these:

- `react-rails`
- `vite_rails`
- a custom Rails-side React helper
- a legacy asset-pipeline React mount

This page tracks practical migration references for those cases.

## What makes a useful migration example

The best examples are:

1. Real Rails applications, not toy demos
2. Small PRs that convert one page, mount point, or component boundary
3. Honest about blockers such as old lockfiles, native gems, or custom frontend bridges
4. Measured with before-and-after performance or maintainability notes instead of marketing claims

## Current public references

### Published example repos

These are stable references you can inspect today:

1. [react-rails example app: `react-rails-to-react-on-rails` branch](https://github.com/shakacode/react-rails-example-app/tree/react-rails-to-react-on-rails)
2. [react-on-rails-migration-example](https://github.com/shakacode/react-on-rails-migration-example)

### Public migration PRs in progress

These show how narrow, app-by-app migration slices look in real repositories:

Last verified on April 12, 2026. Draft PR states may change after that date.

| Repo                                                                                                                | Current Integration                | First Slice                            | Status                                                                                         | Evidence so far                                                                                                               |
| ------------------------------------------------------------------------------------------------------------------- | ---------------------------------- | -------------------------------------- | ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [`EFForg/action-center-platform`](https://github.com/EFForg/action-center-platform)                                 | `react-rails`                      | Admin topics page                      | [Draft PR #975](https://github.com/EFForg/action-center-platform/pull/975)                     | Local benchmark note: warm request median `6.11ms -> 5.04ms`; estimated total JS bytes `2,179,067 -> 1,636,265` for the slice |
| [`thewca/worldcubeassociation.org`](https://github.com/thewca/worldcubeassociation.org)                             | `react-rails`                      | Disclaimer page mount                  | [Draft PR #14010](https://github.com/thewca/worldcubeassociation.org/pull/14010)               | Maintainability note: one legacy Rails page now has a React on Rails path that stays separate from `next-frontend/`           |
| [`demarche-numerique/demarche.numerique.gouv.fr`](https://github.com/demarche-numerique/demarche.numerique.gouv.fr) | `vite_rails` + custom React bridge | `SelectProcedureDropDownListComponent` | [Draft PR #12954](https://github.com/demarche-numerique/demarche.numerique.gouv.fr/pull/12954) | Maintainability note: replaced a custom `coldwired/react` mount contract with a documented React on Rails helper path         |
| [`GSA/search-gov`](https://github.com/GSA/search-gov)                                                               | `react-rails` + Shakapacker        | Search results shell split             | [Draft PR #2010](https://github.com/GSA/search-gov/pull/2010)                                  | Maintainability note: split SERP chrome into smaller mounts; public PR is green on `jest`, `rspec`, and `cucumber`            |

These PRs are still in progress. The useful part is the scope and the evidence, not whether they are already merged.

## Example categories

### `react-rails` to React on Rails

This is usually the cleanest migration path. The main changes are:

1. Replace `react_ujs` mounting with explicit React on Rails registration
2. Update `react_component` helper calls to the React on Rails options style
3. Keep the old app architecture in place while converting one mount at a time

### `vite_rails` to React on Rails

This is more of an asset and entrypoint migration than a component rewrite.

The primary changes are:

1. Replace Vite layout tags and entrypoints
2. Move component registration into the React on Rails / Shakapacker flow
3. Preserve route behavior before removing Vite

### Custom Rails React bridge to React on Rails

This is common in mature apps that built a thin wrapper around React mounts.

The safest approach is:

1. Preserve the Rails-side props contract
2. Replace one helper-backed component boundary first
3. Treat the wrapper removal as a later step

## What counts as proof

Not every good migration example is performance-first.

When the change is performance-first, compare the same route on the baseline branch and the migration branch. At minimum, record:

1. Response timing
2. HTML size
3. Route JavaScript bytes
4. Number of JS assets needed for the route
5. Hydration warnings or client boot errors

If possible, also record browser metrics such as FCP, LCP, CLS, and TBT or INP.

When the change is maintainability-first, record:

1. The custom bridge, oversized mount, or repo-specific contract that existed before the migration
2. The standardized React on Rails helper or smaller boundary that replaced it
3. What got easier to review, test, or evolve afterward
4. The validation that supports the claim

Use maintainability notes when that is the honest win. Do not force a weak benchmark onto an example whose real value is simpler ownership or a narrower integration boundary.

## Later targets worth watching

The current PR wave is intentionally narrow. After that, the next high-signal targets are:

1. [`mastodon/mastodon`](https://github.com/mastodon/mastodon) and [`gitlabhq/gitlabhq`](https://github.com/gitlabhq/gitlabhq) as whale targets
2. [`thecartercenter/nemo`](https://github.com/thecartercenter/nemo) as a smaller institutionally credible `react-rails` target
3. [`Codeminer42/cm42-central`](https://github.com/Codeminer42/cm42-central) and [`broadinstitute/single_cell_portal_core`](https://github.com/broadinstitute/single_cell_portal_core) as modern `vite_rails` examples

## How to use these examples

Use this page together with the specific migration guide that matches your current stack:

1. [Migrate from `react-rails`](./migrating-from-react-rails.md)
2. [Migrate from `vite_rails`](./migrating-from-vite-rails.md)

The migration guides explain the mechanics. This page shows what those mechanics look like in real repos.
