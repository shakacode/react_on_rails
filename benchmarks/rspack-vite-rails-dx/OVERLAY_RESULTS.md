# Recorded Rails-tier overlay evidence

Generated from `results/overlay-recorded.json`. Do not edit the matrix by hand.

| Stack                   | Compile overlay | Runtime overlay with original source frame | Compile-error click-to-editor | Source restoration |
| ----------------------- | --------------- | ------------------------------------------ | ----------------------------- | ------------------ |
| React on Rails + Rspack | PASS            | FAIL                                       | FAIL                          | PASS               |
| Inertia Rails + Vite    | PASS            | FAIL                                       | FAIL                          | PASS               |

Each overlay result requires the deterministic marker and the original TSX file and line. Click-to-editor uses a temporary `LAUNCH_EDITOR` recorder and requires the copied workspace's exact source path, line, and column. The harness restores each mutation, waits for the overlay to clear, and removes its process group, workspace, and ports.

## Environment

- Recorded: 2026-09-12T00:52:09.890Z
- Harness commit: `aff9a6a2a83fa85bebce13e91b7d3882b500404c`
- Worktree clean at start: true
- OS: Darwin 25.6.0 arm64
- CPU: Apple M5 Max (18 logical CPUs)
- Node: v22.12.0; pnpm: 10.33.4; Ruby: ruby 4.0.5 (2026-05-20 revision 64336ffd0e) +PRISM [arm64-darwin23]
- Rspack stack: react_on_rails 17.0.1; shakapacker 10.3.0; rspack/2.2.2 darwin-arm64 node-v22.12.0
- Vite stack: inertia_rails 3.22.0; vite_rails 3.11.1; vite/8.2.2 darwin-arm64 node-v22.12.0

## Interpretation boundary

This is a same-machine browser verification of the two pinned generated Rails starters. A FAIL records observed behavior; it is not by itself a product defect. Product fixes require separate issue evaluation. See [issue #4696](https://github.com/shakacode/react_on_rails/issues/4696).
