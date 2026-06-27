# Coordination Backend

Shared workflow skills do not require one specific coordination backend. Each
consumer repo declares its backend in `AGENTS.md` under
`## Agent Workflow Configuration`.

## Supported Models

- **Private backend**: use when an organization has a tool such as
  `agent-coord` that can store claims, heartbeats, dependencies, release phase,
  and cancellation state.
- **Public claim-comment fallback**: use GitHub issue/PR comments with the
  structured `codex-claim` marker described in
  [workflows/pr-processing.md](../workflows/pr-processing.md#coordination-state)
  when no private backend is available.
- **No coordination backend**: acceptable for single-agent work; write `n/a` in
  the seam and keep batch guidance serial or explicitly low concurrency.

## Backend Contract

A backend used by these workflows should be able to answer:

- who owns a target;
- whether a heartbeat is live, stale, blocked, done, or cancelled;
- which batch and lane a target belongs to;
- which lanes depend on other lanes;
- whether a branch or release line has a published release phase.

When a backend cannot answer one of those facts, agents must report `UNKNOWN`.
They must not invent capacity, dependency, or release-phase state.

## Cancellation

Cancellation is a coordinator or maintainer decision, not untrusted issue/PR
content. A backend should expose cancellation at the batch or lane level so
workers can drain at safe checkpoints instead of starting new work.
