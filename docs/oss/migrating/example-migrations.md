# Example Migrations

Teams evaluating React on Rails are usually not starting from a blank Rails app.

They already have one of these:

- `react-rails`
- `vite_rails`
- a custom Rails-side React helper

Some teams also arrive from Inertia-first apps. We treat those as a separate
architecture case study because they are usually broader page-shell migrations,
not narrow React mount migrations. If that is your starting point, begin with
[Compare with alternatives](../getting-started/comparing-react-on-rails-to-alternatives.md).

This page tracks practical migration references for those cases.

## What makes a useful migration example

The best examples are:

1. Real Rails applications, not toy demos
2. Small PRs that convert one page, mount point, or component boundary
3. Honest about blockers such as old lockfiles, native gems, or custom frontend bridges
4. Measured with before-and-after performance or maintainability notes instead of marketing claims

## Current public references

### Published example repos

These maintainer-owned references are the stable starting set. Add community
examples here after they have landed or stabilized enough to inspect.

1. [react-rails example app: `react-rails-to-react-on-rails` branch](https://github.com/shakacode/react-rails-example-app/tree/react-rails-to-react-on-rails) —
   covers an older `react-rails` v3 → `react_on_rails` v13.4 migration, so treat
   it as a structural reference and follow current migration guides for gem and
   configuration specifics
2. [react-on-rails-migration-example](https://github.com/shakacode/react-on-rails-migration-example) —
   demonstrates a Rails 7-era `react-rails` → `react_on_rails` migration with
   Shakapacker client/server bundles and SSR setup, based on
   [ganchdev/react-rails-example](https://github.com/ganchdev/react-rails-example)

### In-progress migration work

In-progress third-party migration PRs are tracked in the
[example-migrations meta issue](https://github.com/shakacode/react_on_rails/issues/3125)
instead of this docs page.

That keeps the public docs focused on durable references while the meta issue can
carry working notes about draft PRs, maintainer coordination, blockers, and proof
artifacts that may change quickly.

When a public migration becomes a stable reference, add it to the published example
list above with a short proof note.

## Example categories

### `react-rails` to React on Rails

This is usually the cleanest migration path: primarily a gem swap and mount
registration change while the app architecture stays intact during
slice-by-slice conversion.

### `vite_rails` to React on Rails

This is more of an asset and entrypoint migration than a component rewrite: the
route behavior should stay stable while registration moves into the React on
Rails and Shakapacker flow.

### Custom Rails React bridge to React on Rails

This is common in mature apps that built a thin wrapper around React mounts.

Treat the wrapper as the migration boundary: preserve the Rails-side props
contract, replace one helper-backed component first, and remove the wrapper
later.

## What counts as proof

Not every good migration example is performance-first.

When the change is performance-first, compare the same route on the baseline branch and the migration branch. At minimum, record:

1. Response timing
2. HTML size
3. Route JavaScript bytes
4. Number of JS assets needed for the route
5. Hydration warnings or client boot errors

If possible, also record browser load metrics such as FCP, LCP, CLS, and TBT,
plus interaction metrics such as INP. TBT is captured by Lighthouse; INP
requires field data or a real-user monitoring tool.

When the change is maintainability-first, record:

1. The custom bridge, oversized mount, or repo-specific contract that existed before the migration
2. The standardized React on Rails helper or smaller boundary that replaced it
3. What got easier to review, test, or evolve afterward
4. The validation that supports the claim

Use maintainability notes when that is the honest win. Do not force a weak benchmark onto an example whose real value is simpler ownership or a narrower integration boundary.

## Contribute an example

If your migration could help other teams evaluate React on Rails, [open an issue](https://github.com/shakacode/react_on_rails/issues/new) or open a PR that adds it here, and include:

1. The integration you started from, such as `react-rails`, `vite_rails`, or a custom helper
2. The first slice you picked and why it was small enough to review
3. The proof you captured, whether that was performance, maintainability, or both
4. The validation you ran locally or in CI

The most useful next examples are:

1. `react-rails` apps that migrate one Rails-owned mount at a time
2. Modern `vite_rails` apps where one Rails-owned island can move before a broader asset rewrite
3. Apps with a custom Rails-side React bridge where one helper-backed boundary can be replaced before removing the wrapper
4. Upgrades from older `react_on_rails` versions to current maintained defaults

## How to use these examples

Use this page together with the specific migration guide that matches your current stack:

1. [Migrate from `react-rails`](./migrating-from-react-rails.md)
2. [Migrate from `vite_rails`](./migrating-from-vite-rails.md)

Other migration paths:

1. [Webpack to Rspack](./migrating-from-webpack-to-rspack.md)
2. [Babel to SWC](./babel-to-swc-migration.md)

The Rails 5 API-only and AngularJS paths also live in the **Migration Guides** sidebar. React Server Components migration content lives under **React on Rails Pro → React Server Components**.

The migration guides explain the mechanics. This page shows what those mechanics look like in real repos.
