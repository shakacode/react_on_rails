# Recorded Rspack vs Vite DX control result

Generated from [results/recorded.json](results/recorded.json) by `scripts/report.mjs`. Do not edit this table by hand.

| Metric                   | Rspack median (min–max) | Vite median (min–max) | Vite relative to Rspack |
| ------------------------ | ----------------------: | --------------------: | ----------------------- |
| Cold start to HTTP ready |  276.1 ms (268.8–321.1) |  288.8 ms (260–307.2) | **wash**                |
| Browser-observed HMR     |     76.5 ms (23.2–78.3) |  76.4 ms (23.9–179.6) | **ambiguous**           |

Each timing has 5 samples. The conservative noise band is the larger observed min-to-max spread for that metric. This machine-local result is not a universal product ranking.

| Surface check         | Rspack       | Vite       |
| --------------------- | ------------ | ---------- |
| Compile-error overlay | not observed | observed   |
| Click-to-editor       | not tested   | not tested |
| Explicit config lines | 12           | 5          |

## Environment

- Recorded: 2026-07-12T11:45:35.234Z
- Git baseline: `dec0a06b2a17bf54cd317b797dabd6c2b9e391bb`
- OS: Darwin 25.5.0 arm64
- CPU: Apple M5 Max (18 logical CPUs)
- Node: v22.12.0; pnpm: 10.33.4
- Rspack: rspack/2.1.3 darwin-arm64 node-v22.12.0; Vite: vite/8.1.4 darwin-arm64 node-v22.12.0

## Interpretation boundary

This run compares matched, minimal React controls and isolates dev-server startup, module replacement reaching a real browser, compile-error overlay attachment, and explicit bundler configuration. It does **not** compare generated Rails applications, `vite_ruby`, Inertia, Rails startup, React Fast Refresh state preservation, runtime-error overlays, or click-to-editor integration. Accordingly, it is reproducible control evidence, not sufficient evidence for a supported “Rspack matches Vite” onboarding claim.
