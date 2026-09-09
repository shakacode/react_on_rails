# Rails-tier Rspack vs Vite developer-experience benchmark

This package supplies the Rails-level evidence requested by issue #4695 and the broader positioning work in issue #4600. It compares two pinned Rails 8.1.3 starters generated from current stable releases:

- React on Rails 17.0.1 + Shakapacker 10.3.0 + Rspack 2.2.2
- Inertia Rails 3.22.0 + Vite Rails 3.11.1 + Vite 8.2.2

Both starters use React 19.0.4 and the same minimal stateful component. Their committed Ruby and pnpm lockfiles make the package replayable. [PROVENANCE.md](PROVENANCE.md) records the generation commands and the small alignment edits made after generation.

## What it measures

The harness records at least five samples per stack for:

- cold startup from the normal generated `bin/dev` process spawn until the matched React marker is visible in Chromium;
- source edit to browser-observed React Fast Refresh, while verifying a typed input value survives every edit.

Cold samples alternate stack order. Each cold sample uses a fresh ignored copy of the starter and clears app/tool caches without reinstalling locked dependencies. A unique compiled marker and preflighted ports prevent stale-process false positives. The raw result records the machine, runtime versions, exact harness commit, sample arrays, configuration-file inventory, and noise-aware summary.

## Replay

Prerequisites: Ruby 4.0.5, Bundler 4.0.10+, Node 22.12+, pnpm 10, Overmind or Foreman, and a Playwright-compatible Chromium installation.

```bash
cd benchmarks/rspack-vite-rails-dx
bundle install --gemfile starters/rspack/Gemfile
bundle install --gemfile starters/vite/Gemfile
pnpm install --ignore-workspace --frozen-lockfile
pnpm run prepare:starters
pnpm run check
pnpm run benchmark -- --samples 5 --output results/local.json
pnpm exec node scripts/report.mjs --raw results/local.json --output RESULTS.local.md
```

Run on an otherwise quiet machine and compare both stacks within the same run. Do not compare an isolated new run with the committed result as though it were a controlled baseline.

## Result interpretation

The report uses medians and min-to-max spread. It labels a metric `ambiguous` when either spread exceeds 50% of its median. Otherwise, a difference inside the larger observed spread is a `wash`; only a difference outside that local noise band is called an improvement or regression for Vite relative to Rspack.

The generated-configuration audit is descriptive. File and line counts do not measure how difficult the concepts are to learn. This package also does not test production performance, runtime-error overlay quality, or click-to-editor behavior; issue #4696 owns the overlay follow-up.
