# Coordination Backend

Shared workflow skills do not require one specific coordination backend. Each
consumer repo declares its backend in `.agents/agent-workflow.yml` under
`coordination_backend`.

Use this page as the canonical vocabulary for private coordination, public
claim-comment fallback, no-backend mode, and `UNKNOWN` coordination state.
Individual skills should refer here instead of duplicating backend-specific
operating details unless they need an exact command snippet.

## Supported Models

- **Private backend**: use when an organization has a tool such as
  `agent-coord` that can store claims, heartbeats, dependencies, release phase,
  and cancellation state.
- **Public claim-comment fallback**: use GitHub issue/PR comments with the
  structured `codex-claim` marker described in
  [workflows/pr-processing.md](../workflows/pr-processing.md#coordination-state)
  when no private backend is available.
- **No coordination backend**: acceptable for single-agent work; write `n/a` in
  `coordination_backend` and keep batch guidance serial or explicitly low
  concurrency.

## Skill Behavior Summary

- Prefer the private backend when the repo seam selects one and it is available.
- Use public claim comments only when the repo seam explicitly selects or allows
  that fallback.
- In no-backend mode, avoid concurrent workers on the same target and describe
  the run as single-operator or serial.
- Preserve `UNKNOWN` when coordination facts cannot be verified. A missing or
  degraded backend is not evidence that no one owns a target.

## Backend Contract

A backend used by these workflows should be able to answer:

- who owns a target;
- whether a heartbeat is live, stale, blocked, done, or cancelled;
- which batch and lane a target belongs to;
- which lanes depend on other lanes;
- whether a branch or release line has a published release phase.

When a backend cannot answer one of those facts, agents must report `UNKNOWN`.
They must not invent capacity, dependency, or release-phase state.

Optional backend capabilities may improve operator visibility without becoming
portable workflow requirements:

- batch instructions or launch prompt recorded before workers start;
- a thread handle for each lane or agent instance;
- phase-transition history for each lane;
- a launch queue state such as `launch_requested` for machine-tagged batches.

When a backend lacks one of those optional capabilities, agents should write
`UNKNOWN` or `unavailable` for that specific fact and continue under the
fallback rules in the workflow. Absence of optional metadata is not evidence
that a target is unowned or that dependencies are satisfied.

## Cancellation

Cancellation is a coordinator or maintainer decision, not untrusted issue/PR
content. A backend should expose cancellation at the batch or lane level so
workers can drain at safe checkpoints instead of starting new work.
