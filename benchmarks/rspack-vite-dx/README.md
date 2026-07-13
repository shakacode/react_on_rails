# Rspack vs Vite developer-experience controls

This benchmark provides a replayable, machine-readable control comparison for issue #4600. It intentionally separates measurements from positioning claims.

## What it measures

Two matched minimal JavaScript applications differ only in their bundler/dev server and the small HMR adapter required by each tool. Neither control uses a framework transform or refresh plugin. The harness records:

- cold dev-server start from process spawn to the first successful HTTP response;
- source-file write to a DOM marker update observed by a real Chromium browser;
- whether a compile-error overlay attaches in the browser;
- nonblank, non-comment lines in each explicit bundler config.

Cold-start samples alternate order to reduce systematic thermal/order bias. Tool caches are deleted before every cold start. There are at least five samples per tool and metric. The result table uses medians and includes min/max spread. A run is `ambiguous` when either spread exceeds 50% of its median. Otherwise, a difference smaller than the larger observed spread is a `wash`; beyond that conservative local noise band, the direction is `improvement` or `regression` for Vite relative to Rspack.

Every server starts on a preflighted ephemeral port and compiles a unique nonce into its initial marker. The harness rejects HTML that does not contain exactly one expected application entry, terminates the spawned process group, awaits process exit, and confirms the port closes before continuing. It refuses to run unless the harness commit is clean; the raw result records that commit and clean state.

## Replay

Prerequisites: Node 22.12+, pnpm 10, and a Playwright-compatible Chromium installation.

```bash
cd benchmarks/rspack-vite-dx
pnpm install --ignore-workspace --frozen-lockfile
pnpm run check
pnpm run benchmark -- --samples 5 --output results/local.json
pnpm exec node scripts/report.mjs --raw results/local.json --output RESULTS.local.md
```

The path-scoped `Rspack/Vite DX benchmark replay` workflow runs the same frozen install and check whenever this harness changes.

Close unrelated CPU-heavy applications before measuring. Keep both controls on the same machine and power mode. Do not compare a new local run to the committed result as though it were a controlled baseline; compare both tools within one run.

The committed [recorded result](RESULTS.md) is generated from [raw JSON](results/recorded.json). Run `pnpm run check` to verify the checked-in report still matches the raw artifact. The replay also fails closed if the raw artifact contains an unredacted benchmark root or a common macOS, Linux, or Windows local-user path.

## Matched-control inventory

| Dimension               | Rspack                                           | Vite                |
| ----------------------- | ------------------------------------------------ | ------------------- |
| Framework transforms    | none                                             | none                |
| Entry behavior          | render exported marker; accept its module update | same                |
| Browser                 | same Playwright Chromium process                 | same                |
| Host                    | `127.0.0.1`, preflighted ephemeral port          | same                |
| Source maps             | development default plus `eval-source-map`       | development default |
| Cache before cold start | tool cache removed                               | tool cache removed  |

The lockfile pins all benchmark dependencies. Environment and exact CLI version output are captured in each raw run.

## Comparability and claim limits

This is an isolation benchmark, not the final Rails onboarding comparison requested by issue #4600. Vite is not currently a directly supported React on Rails bundler control, and this subtree does not add that support. In particular, these controls do not include React, `vite_ruby`, Inertia, Rails boot, generated Shakapacker configuration, framework transforms or Fast Refresh, runtime-error overlays, or editor-protocol registration.

Overlay attachment is a useful smoke check, not an overlay-quality score. Click-to-editor remains explicitly unverified because it depends on local editor protocol setup. Configuration line counts are descriptive and should not be treated as equal to concepts a new user must understand without a separate user study or generated-app audit.

Therefore, use this artifact to refine a future full Rails-vs-Rails benchmark and to catch large local regressions. Do not use it alone to publish “parity,” “faster,” “near-instant,” “sub-second,” or onboarding-superiority claims.
