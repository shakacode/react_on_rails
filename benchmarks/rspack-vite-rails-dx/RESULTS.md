# Recorded Rails-tier Rspack vs Vite DX result

Generated from [results/recorded.json](results/recorded.json) by `scripts/report.mjs`. Do not edit the tables by hand.

| Metric                                           | React on Rails + Rspack median (min–max) | Inertia Rails + Vite median (min–max) | Vite relative to Rspack |
| ------------------------------------------------ | ---------------------------------------: | ------------------------------------: | ----------------------- |
| Generated dev environment to browser-ready React |                  5008.8 ms (4852.7–5339) |             3001.5 ms (2952.4–3234.4) | **improvement**         |
| Browser-observed React Fast Refresh              |                     77.6 ms (74.5–179.2) |                  77.4 ms (75.2–176.2) | **ambiguous**           |

Each timing has 5 samples. The conservative noise band is the larger observed min-to-max spread for that metric. A result is ambiguous when either spread exceeds 50% of its median.

| Generated configuration audit                            | React on Rails + Rspack | Inertia Rails + Vite |
| -------------------------------------------------------- | ----------------------: | -------------------: |
| Files in the declared config surface                     |                       7 |                    3 |
| Nonblank, non-comment lines                              |                     197 |                   30 |
| Fast Refresh preserved typed React state in every sample |                     yes |                  yes |

Configuration counts describe generated files only. They are not a usability score.

## Environment

- Recorded: 2026-09-04T02:25:25.259Z
- Harness commit: `107cef846b8cc284ac5021947fa57683aa930b34`
- Worktree clean at start: true
- OS: Darwin 25.6.0 arm64
- CPU: Apple M5 Max (18 logical CPUs)
- Memory: 128 GiB
- Node: v22.12.0; pnpm: 10.33.4; Ruby: ruby 4.0.5 (2026-05-20 revision 64336ffd0e) +PRISM [arm64-darwin23]
- Rails: Rspack starter Rails 8.1.3; Vite starter Rails 8.1.3
- Rspack stack: react_on_rails 17.0.1; shakapacker 10.3.0; rspack/2.2.2 darwin-arm64 node-v22.12.0
- Vite stack: inertia_rails 3.22.0; vite_rails 3.11.1; vite/8.2.2 darwin-arm64 node-v22.12.0

## Interpretation boundary

This is a same-machine development benchmark of two pinned generated Rails starters. It measures each generator's normal `bin/dev` path through a real browser, including Rails boot, asset startup, React rendering, and state-preserving Fast Refresh. It does not isolate bundler cost, score onboarding comprehension, measure production builds, test runtime-error overlay quality, or verify click-to-editor. Results can vary with hardware, filesystem caches, background load, and dependency versions.

Use this package with the bare-JavaScript control from [issue #4612](https://github.com/shakacode/react_on_rails/pull/4612) to inform [the broader DX positioning issue #4600](https://github.com/shakacode/react_on_rails/issues/4600). Do not turn one machine-local run into a universal “parity,” “faster,” or “near-instant” claim.
