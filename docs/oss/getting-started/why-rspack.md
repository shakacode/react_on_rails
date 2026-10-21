---
sidebar_label: 'Why Rspack (not Vite)'
description: Why React on Rails ships on Shakapacker with Rspack instead of Vite, what Vite does well, and what would reopen the decision.
---

# Why Rspack (and not Vite)?

Teams comparing React on Rails with the `inertia_rails` + `vite_ruby` stack often ask why React on Rails uses Rspack. It is a deliberate, recorded decision: [ADR-0001: Rspack answers Vite](https://github.com/shakacode/react_on_rails/blob/main/internal/adr/0001-rspack-answers-vite.md). This page is the short version.

## The Short Answer

React on Rails Pro's React Server Components (RSC) pipeline is built on the webpack/Rspack plugin contract. Rspack implements that contract, and since React on Rails 17.0.0 it has been the default bundler for fresh installs. The `react-on-rails-rsc` package that powers RSC ships Rspack and webpack versions of its plugins and loaders; it has no Vite version. Choosing Rspack keeps one bundler story for every tier, from client-rendered components to streaming SSR and RSC.

## Why the Bundler Matters for RSC

RSC in React on Rails Pro builds three bundles: client, server (SSR), and RSC. The [`react-on-rails-rsc`](https://www.npmjs.com/package/react-on-rails-rsc) package connects them, and each piece runs inside the bundler's compilation:

- **Manifest plugins** record which `'use client'` modules live in which chunks. On Rspack this is the native `RSCRspackPlugin`.
- **A `'use client'` loader** replaces client components with references inside the RSC bundle.
- **The RSC payload** streams those references to the browser, which loads the matching chunks.

The generator scaffolds this setup for RSC apps, and a CI job builds all three bundles with Rspack and checks that RSC routes render and hydrate. See [Rspack Compatibility with React Server Components](../../pro/react-server-components/rspack-compatibility.md) for status and [How React Server Components Work](../../pro/react-server-components/how-react-server-components-work.md) for the architecture.

Moving this pipeline to Vite would mean rebuilding the plugins, the loader integration, and the chunk handling for a different plugin system.

## What Rspack Gives You

- **One bundler for every tier.** The same Shakapacker setup covers client rendering, SSR, streaming, and RSC.
- **The webpack ecosystem, faster.** Rspack describes itself as a [fast, Rust-based bundler with a modernized webpack API](https://rspack.rs/). Webpack loaders carry over, and so do many webpack plugins; check Rspack's [plugin compatibility list](https://rspack.rs/plugins/community-plugin-compatibility) for specific ones. To move an existing app, see [Migrating from Webpack to Rspack](../migrating/migrating-from-webpack-to-rspack.md).

## What Vite Does Well

Vite is a strong tool, and it deserves a fair account:

- Its native-ESM dev server with on-demand transforms is an elegant design.
- Much of the frontend ecosystem, from templates to tutorials, assumes Vite first.
- Its defaults need little configuration. Shrinking the generated Rspack config is tracked in [#4697](https://github.com/shakacode/react_on_rails/issues/4697).

## Why Not Support Both?

The ADR considered Vite for the non-RSC tier only and rejected it. That would split the bundler story and double the support and CI matrix for the tier where React on Rails is least differentiated.

## What Would Change Our Minds

The ADR names the triggers for revisiting this decision:

- Evidence that bundler choice is a primary reason teams bounce off React on Rails.
- RSC on Vite reaching production maturity upstream, for example through [`@vitejs/plugin-rsc`](https://www.npmjs.com/package/@vitejs/plugin-rsc).

Meanwhile, [#2552](https://github.com/shakacode/react_on_rails/issues/2552) plans bundler-neutral config file names for 18.0, so adding another bundler later would not need another breaking rename.

## Related Pages

- [Comparing React on Rails to Alternatives](./comparing-react-on-rails-to-alternatives.md)
- [Migrate from `vite_rails`](../migrating/migrating-from-vite-rails.md)
- [Migrating from Webpack to Rspack](../migrating/migrating-from-webpack-to-rspack.md)
- [Webpack Configuration](../core-concepts/webpack-configuration.md)
- [Rspack Compatibility with React Server Components](../../pro/react-server-components/rspack-compatibility.md)
