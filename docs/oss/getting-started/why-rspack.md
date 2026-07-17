---
sidebar_label: 'Why Rspack (not Vite)'
description: The recorded architecture decision behind React on Rails shipping on Shakapacker with Rspack instead of Vite — the RSC plugin contract, the measured evidence so far, honest tradeoffs, and the triggers that would reopen the decision.
---

# Why Rspack (and not Vite)?

Teams evaluating React on Rails against the popular `inertia_rails` + `vite_ruby` stack ask this question constantly, and it deserves a direct answer rather than a dodge. Choosing Rspack over Vite is a deliberate, recorded architecture decision — [ADR-0001: Rspack answers Vite](https://github.com/shakacode/react_on_rails/blob/main/internal/adr/0001-rspack-answers-vite.md) — not an accident of history. This page lays out the reasoning, the evidence we have published so far, what that evidence does and does not show, and the concrete conditions under which we would revisit the decision.

## The Short Answer

React on Rails Pro's React Server Components (RSC) pipeline is built on the webpack/rspack plugin contract. That pipeline is production-proven on Webpack today. The Rspack implementation of the same contract is currently **experimental** — its end-to-end production gate is scheduled on the [roadmap](https://github.com/shakacode/react_on_rails/blob/main/ROADMAP.md) for 17.2 ([#3488](https://github.com/shakacode/react_on_rails/issues/3488)). Vite has no implementation of this pipeline at all. That asymmetry is the decision: finishing the Rspack RSC path is incremental work inside a plugin contract the pipeline already targets, while adopting Vite as the runtime bundler would mean rebuilding the pipeline on a different plugin architecture — at a time when RSC-on-Vite is still stabilizing across the wider ecosystem.

Rather than split the bundler story, the decision recorded in the ADR is to invest in Rspack developer-experience parity, measure the gaps honestly, and answer the Vite question in the open. This is a position we expect to keep re-testing, not a permanent verdict — see [What Would Change Our Minds](#what-would-change-our-minds) below.

## The RSC Pipeline Is a Bundler Plugin Contract

React on Rails Pro's RSC implementation uses a three-bundle architecture: a client bundle, a server (SSR) bundle, and an RSC bundle. Coordinating those bundles is the job of the [`react-on-rails-rsc`](https://www.npmjs.com/package/react-on-rails-rsc) npm package, and every piece of it speaks the webpack/rspack plugin contract:

- **Manifest plugins.** `react-on-rails-rsc/WebpackPlugin` and the rspack-native `react-on-rails-rsc/RspackPlugin` (`RSCRspackPlugin`) hook the bundler's compilation to emit the client and server component manifests — the JSON files that map `'use client'` component modules to the chunks that contain them. Both plugins emit the same manifest schema, so the RSC runtime resolves client references identically under either bundler.
- **The `'use client'` loader.** `react-on-rails-rsc/WebpackLoader` transforms client component files into client reference proxies inside the RSC bundle. It is written against the webpack loader interface, which rspack also implements.
- **Flight chunk handling.** The RSC payload (React's Flight format) streams client reference metadata to the browser, and the runtime uses the manifests to load the matching client chunks. The chunk naming and manifest lookup are products of the webpack/rspack compilation model.

Because every layer targets the webpack/rspack contract, moving the RSC pipeline from webpack to Rspack is an incremental swap rather than a rewrite: the same loader runs under both bundlers, and the native `RSCRspackPlugin` uses only standard rspack public APIs. To be precise about where that swap stands today: the Webpack RSC pipeline is the production-proven path, while the Rspack RSC path is **experimental** — the generator scaffolds it, but the end-to-end CI gate is not yet wired, and the production path is scheduled for 17.2 (see [Rspack Compatibility with React Server Components](../../pro/react-server-components/rspack-compatibility.md) and [issue #3488](https://github.com/shakacode/react_on_rails/issues/3488) for current status). Supporting Vite would not be a swap at all: Vite does not run plugins written against the webpack/rspack compilation contract, so the manifest plugins, the loader integration, and the flight chunk handling would all need a from-scratch Vite implementation — precisely the ground the wider RSC-on-Vite ecosystem is still stabilizing.

The ADR also records why the halfway options were rejected: supporting Vite only for the non-RSC tier would permanently split the bundler story and double the support and CI matrix for the tier that differentiates React on Rails least, and saying nothing at all would leave a constant evaluator question unanswered.

For how the RSC pipeline works in detail, see [How React Server Components Work](../../pro/react-server-components/how-react-server-components-work.md).

## What We Have Measured So Far

We publish our comparison evidence rather than asserting it. As of July 2026, the published evidence is a **bare-JavaScript control-tier benchmark** — matched, minimal Rspack and Vite dev setups with no Rails, no React transforms, and no framework integration — recorded on a single Apple M5 Max run with 5 samples per metric. Full harness, raw samples, and methodology: [`benchmarks/rspack-vite-dx`](https://github.com/shakacode/react_on_rails/tree/main/benchmarks/rspack-vite-dx) ([RESULTS.md](https://github.com/shakacode/react_on_rails/blob/main/benchmarks/rspack-vite-dx/RESULTS.md), merged in [PR #4612](https://github.com/shakacode/react_on_rails/pull/4612)).

| Metric                   | Rspack median (min–max) | Vite median (min–max) | Verdict   |
| ------------------------ | ----------------------: | --------------------: | --------- |
| Cold start to HTTP ready |  242.3 ms (235.2–258.8) |  244 ms (242.8–250.2) | wash      |
| Browser-observed HMR     |     77.4 ms (76.2–79.6) |  72.6 ms (24.3–181.4) | ambiguous |

| Surface check         | Rspack     | Vite         |
| --------------------- | ---------- | ------------ |
| Compile-error overlay | observed   | not observed |
| Click-to-editor       | not tested | not tested   |
| Explicit config lines | 12         | 2            |

Read the verdicts as recorded: cold start was a **wash**, and the HMR comparison is **ambiguous** because the Vite samples had a much wider spread (24.3–181.4 ms) than the Rspack samples. The compile-error overlay row means Rspack's overlay was observed in that run and Vite's was not — it is a single-run observation, not an overlay-parity conclusion. Vite clearly won the explicit-config-lines count, 2 to 12.

**What these numbers do not show.** The control tier deliberately isolates the bundlers from everything else, so it says nothing about:

- generated Rails applications (React on Rails + Shakapacker/Rspack vs `inertia_rails` + `vite_ruby`)
- Rails startup, `vite_ruby`, or Inertia integration behavior
- React transforms or Fast Refresh
- runtime-error overlays or click-to-editor integration
- onboarding or setup effort

This page therefore makes **no claims about Rails-tier performance or developer-experience parity**. Those claims wait for Rails-tier evidence.

:::info Rails-tier measurements are in progress

The Rails-tier comparison — pinned, matched generated Rails starter pairs with raw samples — is tracked by [#4600 (Rspack DX parity bar vs Vite)](https://github.com/shakacode/react_on_rails/issues/4600) and its child issues: [#4695 (Rails-tier benchmark package)](https://github.com/shakacode/react_on_rails/issues/4695), [#4696 (error-overlay parity + click-to-editor verification)](https://github.com/shakacode/react_on_rails/issues/4696), and [#4697 (zero-config surface reduction)](https://github.com/shakacode/react_on_rails/issues/4697). As results land there, this page will be updated to cite them.

:::

## What Vite Does Genuinely Well

An honest positioning page has to say this part out loud:

- **The dev-server model.** Vite's native-ESM dev server with on-demand transforms is a genuinely elegant architecture, and it is a large part of why Vite's dev loop has the reputation it does.
- **Ecosystem and defaults.** A large share of the frontend ecosystem — templates, component libraries, meta-frameworks, tutorials — assumes Vite first. Being the default has real compounding value: more examples, more Stack Overflow answers, more plugins built against Vite's plugin API.
- **Config minimalism.** In our own control benchmark, the Vite setup needed 2 explicit config lines to Rspack's 12. That six-fold difference is measured, ours, and worth copying — [#4697](https://github.com/shakacode/react_on_rails/issues/4697) tracks driving the generated Rspack config surface down.

## What Would Change Our Minds

The ADR records explicit revisit triggers, so the decision cannot silently ossify:

- **Evaluator evidence** that bundler choice is a primary reason teams bounce off React on Rails.
- **RSC-on-Vite reaching production maturity upstream.** The ADR's watch items (2026-07 snapshot): `@vitejs/plugin-rsc`, official under the vitejs org and already the base for React Router's RSC framework mode, but pre-1.0; and Rspack 2.x's built-in experimental RSC support, whose evolution informs our own native-plugin work in [#3488](https://github.com/shakacode/react_on_rails/issues/3488). We track state, not promises — neither project's future pace is something this page predicts.

Meanwhile, [#2552 (bundler-neutral config file naming)](https://github.com/shakacode/react_on_rails/issues/2552), planned for the 18.0 cycle, renames `*WebpackConfig.js`-style files to bundler-neutral names so that a future bundler addition — Vite or anything else — does not require another breaking rename cycle. The door stays open by design.

The ADR closes with a self-enforcing clause worth repeating here: if Rspack DX parity claims stop being true, this page and the decision behind it both come up for review.

## Common Objections

### "Vite's HMR is faster"

Our control-tier measurement could not confirm a winner: browser-observed HMR medians were 77.4 ms (Rspack) vs 72.6 ms (Vite), with the Vite spread wide enough (24.3–181.4 ms) that the recorded verdict is _ambiguous_. React Fast Refresh timing in generated Rails apps has not been measured yet — that is [#4695](https://github.com/shakacode/react_on_rails/issues/4695). Until that evidence exists, we make no HMR speed claim in either direction, and you should be skeptical of anyone who does without publishing samples.

### "Vite's plugin ecosystem is bigger"

For app-level tooling, both ecosystems are large. Rspack targets compatibility with the webpack plugin and loader API, which is the API the Rails/Shakapacker world has built against for years — so the relevant comparison for a React on Rails app is less "Vite plugins vs Rspack plugins" than "does the webpack-contract tooling you already use carry over" (check the [Rspack compatibility documentation](https://rspack.dev/guide/compatibility/plugin) for specific plugins). The plugin that decides our architecture is the RSC manifest/loader tooling described above, and that exists for webpack and rspack only.

### "Everyone uses Vite — you're swimming upstream"

Defaults matter, and we take this seriously — it is why the ADR, the measurement program, and this page exist at all. But adopting a bundler with no implementation of the RSC pipeline would trade an evaluation-stage objection for a from-scratch rewrite of the tier that most differentiates React on Rails. The costs of not being the default are real and mostly social (fewer copy-paste examples); we spend that cost deliberately and work to shrink it with measured DX parity ([#4600](https://github.com/shakacode/react_on_rails/issues/4600)) and lower switching friction ([#2552](https://github.com/shakacode/react_on_rails/issues/2552)).

### "Why not support both bundlers?"

The ADR considered exactly this and rejected it for the 17.x cycle: Vite for the standard (non-RSC) tier only would permanently fork the bundler story, double the support and CI matrix, and spend that effort on the tier where React on Rails is least differentiated. One well-supported bundler contract, measured against the alternative in the open, is the better trade while the RSC-on-Vite ground is still moving.

## Related Pages

- [Comparing React on Rails to Alternatives](./comparing-react-on-rails-to-alternatives.md) — the broader decision guide, including Inertia and Next.js
- [Migrate from `vite_rails`](../migrating/migrating-from-vite-rails.md) — the mechanics, if you decide to move
- [Migrating from Webpack to Rspack](../migrating/migrating-from-webpack-to-rspack.md)
- [Webpack Configuration](../core-concepts/webpack-configuration.md)
- [Rspack Compatibility with React Server Components](../../pro/react-server-components/rspack-compatibility.md)
