# Recorded Rspack vs Vite DX control result

Generated from [results/recorded.json](results/recorded.json) by `scripts/report.mjs`. Do not edit this table by hand.

| Metric                   | Rspack median (min–max) | Vite median (min–max) | Vite relative to Rspack |
| ------------------------ | ----------------------: | --------------------: | ----------------------- |
| Cold start to HTTP ready |  242.3 ms (235.2–258.8) |  244 ms (242.8–250.2) | **wash**                |
| Browser-observed HMR     |     77.4 ms (76.2–79.6) |  72.6 ms (24.3–181.4) | **ambiguous**           |

Each timing has 5 samples. The conservative noise band is the larger observed min-to-max spread for that metric. This machine-local result is not a universal product ranking.

| Surface check         | Rspack     | Vite         |
| --------------------- | ---------- | ------------ |
| Compile-error overlay | observed   | not observed |
| Click-to-editor       | not tested | not tested   |
| Explicit config lines | 12         | 2            |

## Environment

- Recorded: 2026-07-12T13:08:39.771Z
- Harness commit: `2730785d7531b6bec09f5f9245ab8f6e654b55b1`
- Harness worktree clean at start: true
- OS: Darwin 25.5.0 arm64
- CPU: Apple M5 Max (18 logical CPUs)
- Node: v22.12.0; pnpm: 10.33.4
- Rspack: rspack/2.1.3 darwin-arm64 node-v22.12.0; Vite: vite/8.1.4 darwin-arm64 node-v22.12.0

## Interpretation boundary

This run compares matched, minimal JavaScript controls and isolates dev-server startup, module replacement reaching a real browser, compile-error overlay attachment, and explicit bundler configuration. It does **not** compare generated Rails applications, `vite_ruby`, Inertia, Rails startup, React transforms or Fast Refresh, runtime-error overlays, or click-to-editor integration. Accordingly, it is reproducible control evidence, not sufficient evidence for a supported “Rspack matches Vite” onboarding claim.
