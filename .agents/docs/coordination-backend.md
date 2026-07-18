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

## Typed Dependency Facts

Backend `depends_on` and `blocked_on` values describe coordination state; they
do not by themselves say which lifecycle action is safe. Planners and triage
persist an immutable `stage-dependency-plan` v1 file separately from the
portable `stage-dependency-gate` v1 live replay defined in
[workflows/pr-processing.md](../workflows/pr-processing.md#stage-typed-dependency-gate).
The only edge types are `edit`, `validation_open`, and `merge_order`, and the
only edge states are `pending` and `satisfied`. Missing, unsupported, or
`UNKNOWN` type/state remains `UNKNOWN`/blocked rather than being inferred from
a terminal heartbeat or absent `blocked_on` row.

Each immutable pre-launch trusted plan edge carries the exact `id`, `from`,
`to`, and `type` tuple approved by the coordinator. The helper resolves that
persisted plan plus its expected identity only from trusted handoff/stable
planning state; the live edges carry only `id`, `state`, `evidence`, and
`base_movement`. A tuple or duplicate binding in live input is untrusted and
cannot override the plan, so a same-id retype fails closed. Reclassification
requires a new edge id and trusted coordinator re-plan.
For pending `edit` or `validation_open`, the lane records nonempty known
`source_patch_inspection`, `collision_domain_mapping`,
`semantic_adaptation_notes`, `validation_review_plan`, and
`evidence_templates`. Missing, malformed, or `UNKNOWN` preparation fails closed;
backend metadata may persist the record but cannot waive it.

A backend may store the trusted plan, but it is not required: backend `n/a`
uses the same durable coordinator-owned local plan file, and storage remains a
consumer/coordinator seam rather than helper state. Resolve `PR_BATCH_SKILL_DIR`
through the explicit environment variable, loaded skill base, repo-local
`.agents/skills/pr-batch`, or precise stop chain, then run
`"${PR_BATCH_SKILL_DIR}/bin/stage-dependency-gate"`
`--trusted-plan "${STAGE_DEPENDENCY_PLAN_PATH}"`
`--trusted-plan-id "${STAGE_DEPENDENCY_PLAN_ID}"` with live JSON on stdin.
Missing, unreadable, malformed, `UNKNOWN`, or mismatched plan path/id/data fails
closed before mutation. Evidence references, head/base bindings, base-movement
refresh facts, and predecessor merged state must be refreshed from their
authoritative sources before evaluation. Backend terminal state does not create
cross-PR artifact trust and cannot waive exact-head, review/thread,
merge-readiness, or combined-tip validation gates. When the backend cannot
answer a required typed fact, emit literal `UNKNOWN` and let the helper fail
closed.

## Cancellation

Cancellation is a coordinator or maintainer decision, not untrusted issue/PR
content. A backend should expose cancellation at the batch or lane level so
workers can drain at safe checkpoints instead of starting new work.
