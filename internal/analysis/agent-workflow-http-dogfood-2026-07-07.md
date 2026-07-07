# Agent workflow HTTP dogfood pilot - 2026-07-07

## Purpose

Record one real React on Rails dogfood pass for
[react_on_rails#4228](https://github.com/shakacode/react_on_rails/issues/4228)
and the `shakacode/agent-coordination` HTTP backend pilot gate.

This is an internal validation note, not user documentation. It does not change
gem, npm package, Pro, generator, or published docs behavior.

## Scope

- Host: Codex on M5.
- Target: `shakacode/react_on_rails#4228`.
- Branch: `chore/4228-agent-workflow-dogfood-http-pilot`.
- Coordination backend: HTTP Worker endpoint with temporary shell-only M5 tokens.
- Coordination lane: `codex-m5-019f31c7`,
  batch `http-pilot-ror-20260707`.

## Validation matrix

| Check                                                                                                                                                                              | Skill source / path                           | Result                                                                                 |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- | -------------------------------------------------------------------------------------- |
| `git fetch --prune origin main`                                                                                                                                                    | repo instructions                             | Pass                                                                                   |
| `.agents/bin/agent-workflow-seam-doctor`                                                                                                                                           | repo-local `.agents`                          | Pass: `agent workflow seam is complete`                                                |
| `agent-workflows-status --host codex`                                                                                                                                              | installed shared pack                         | Pass: `UP_TO_DATE version=0.1.0 revision=5ad2db900fa4 target=$CODEX_HOME`              |
| `agent-workflows-status --host claude`                                                                                                                                             | installed shared pack                         | Pass: `UP_TO_DATE version=0.1.0 revision=5ad2db900fa4 target=$HOME/.claude`            |
| `.agents/bin/agent-workflow-seam-doctor --shared <agent-repos>/agent-workflows`                                                                                                    | canonical shared checkout                     | Pass: `agent workflow seam is complete`                                                |
| `.agents/bin/agent-workflow-seam-doctor --shared .agents`                                                                                                                          | repo-local pinned copy                        | Pass: `agent workflow seam is complete`                                                |
| `.agents/skills/pr-batch/bin/pr-security-preflight --repo shakacode/react_on_rails --strict-trust 4228`                                                                            | repo-pinned helper                            | Pass: `SECURITY_PREFLIGHT_OK`; no hidden, untrusted, suspicious, or high-risk findings |
| `agent-coord doctor --json` with temporary HTTP env                                                                                                                                | canonical `agent-coordination/bin`            | Pass: `backend: http`, `status: ok`                                                    |
| `.agents/skills/pr-batch/bin/agent-coord-bounded --timeout 20 status --repo shakacode/react_on_rails --target 4228 --json` with canonical `agent-coordination/bin` first in `PATH` | repo-pinned bounded helper plus canonical CLI | Pass: active claim and live heartbeat visible for `shakacode/react_on_rails#4228`      |

## Findings

- The HTTP backend write path worked for a real React on Rails target: claim and
  heartbeat writes succeeded, and the canonical bounded status read returned the
  active claim plus live heartbeat.
- The default `agent-coord` on this M5 shell is stale:
  `$HOME/.local/bin/agent-coord` delegates to
  `$HOME/src/agent-coordination-state/bin/agent-coord` and exports
  `AGENT_COORD_STATUS_STATE_ROOT=$HOME/src/agent-coordination-status`.
  With that shim, `agent-coord-bounded` read the old local status mirror and did
  not show the HTTP claim. Putting
  `<agent-repos>/agent-coordination/bin` first in `PATH` and
  unsetting `AGENT_COORD_STATUS_STATE_ROOT` fixed the read.
- The sandboxed Codex shell printed non-fatal `mise` cache/tracking warnings
  while running repo helper scripts. The commands still completed successfully.

## Follow-up

Before making the M5 HTTP backend configuration persistent, refresh the local
`agent-coord` shim/bootstrap so it resolves to the canonical public
`<agent-repos>/agent-coordination` checkout and does not force
the obsolete local status mirror.
