# Agent Coordination Backend

React on Rails uses the portable coordination model described in
[.agents/docs/coordination-backend.md](../../.agents/docs/coordination-backend.md)
and selects a private `agent-coord` backend through
[.agents/agent-workflow.yml](../../.agents/agent-workflow.yml).

`shakacode/agent-coordination` is the public CLI/bootstrap source repository.
Runtime coordination state lives in the backend reported by
`agent-coord config show --json` and `agent-coord doctor --json`; the current
default is the private `shakacode/agent-coordination-state` repository on the
`state` ref. Do not hardcode an old backend repo name in lane handoffs or
workflow prose. The CLI help, config JSON, state repo README, and schema files
are authoritative when they differ from this public pointer.

This repo carries only the React on Rails supplement: setup commands, public
workflow links, and release-train phase rules. Keep authoritative JSON schema
definitions and examples in the state backend or CLI source repo. Generic
backend models and the portable "report `UNKNOWN`, do not invent state" rule
belong in the shared workflow pack.

## Setup

For a fresh machine joining an active multi-machine batch, start with
[Multi-Batch Operations](multi-batch-operations.md#fresh-machine-quick-start)
and then run the backend setup below.

```bash
gh auth status
gh repo view shakacode/agent-coordination
gh repo view shakacode/agent-coordination-state
gh repo clone shakacode/agent-coordination
cd agent-coordination
ruby -Itest test/agent_coord_test.rb
bin/agent-coord --help
bin/agent-coord bootstrap
export PATH="$HOME/.local/bin:$PATH"
agent-coord --help
agent_coord --help
agent-coord version --json
agent-coord config show --json
agent-coord doctor --json
```

The workflow docs assume `agent-coord` is available on `PATH`.
`bin/agent-coord bootstrap` installs both `agent-coord` and the compatibility
alias `agent_coord` into `$HOME/.local/bin` by default. Add that directory to the
active shell `PATH` if the shell has not reloaded its profile yet.

Treat the backend as available when `agent-coord doctor --json` and targeted
lane-scoped status probes exit 0. In React on Rails batch workflows, run agent
preflights through the bounded helper from the installed/shared `$pr-batch`
skill so a slow private read becomes explicit degraded state instead of an
indefinite wait:

```bash
PR_BATCH_SKILL_DIR="$(.agents/bin/shared-skill-dir pr-batch)"
"${PR_BATCH_SKILL_DIR}/bin/agent-coord-bounded" --timeout 20 doctor --json
"${PR_BATCH_SKILL_DIR}/bin/agent-coord-bounded" --timeout 20 status --repo OWNER/REPO --target TARGET --json
"${PR_BATCH_SKILL_DIR}/bin/agent-coord-bounded" --timeout 20 status --batch-id BATCH_ID --json
```

Use broad `agent-coord status` only for audit-mode triage sweeps and post-merge
batch discovery; treat those reads as advisory/discovery-only, not authoritative
lane state. If the command is missing, auth fails, the backend cannot be read, a
bounded probe times out, or targeted status exits non-zero, report private state
as `UNKNOWN` / degraded. Exit code 3 / `CLAIM_REFUSED` from `agent-coord claim`
is not unavailability; it is a hard stop.

For exact independent lanes with no `depends_on` refs, a coordinator may attempt
a bounded direct `agent-coord claim` when doctor/status is degraded. A successful
claim can proceed as `private_state: claim-only`, with normal heartbeats and
handoff evidence that status was degraded. If the claim is refused, hard-stop.
If the claim times out, stop with `private_state: UNKNOWN (claim outcome)` and
reconcile private state before fallback or branching because the mutating claim
may already have landed. Dependency-sensitive lanes do not use claim-only or
public fallback when status is unavailable; they stop with dependency state
`UNKNOWN`.

Machine agents must not override a refused private claim on their own. A human
coordinator may authorize a one-off manual override only after running targeted
`agent-coord status`, recording why the private state is wrong or degraded in
the batch handoff as the authoritative incident note, and repairing the private
state so later machine agents can observe the override through targeted status.
Mirror the same note to the issue or PR when that is the active lane discussion,
but do not use a public claim comment as the machine-readable override channel
or to bypass a live or stale holder that can be contacted.

Use a temporary local state directory for smoke checks that should not write to
GitHub. `AGENT_COORD_STATE_ROOT` sets the directory where `agent-coord` reads
and writes JSON state; override it here so dry runs stay local instead of using
the configured backend.

```bash
STATE_ROOT=$(mktemp -d)
AGENT_COORD_STATE_ROOT="$STATE_ROOT" agent-coord heartbeat \
  --agent-id smoke-test-0 \
  --repo shakacode/react_on_rails \
  --target 9999
AGENT_COORD_STATE_ROOT="$STATE_ROOT" agent-coord status
rm -rf "$STATE_ROOT"
```

## Batch State

Workers refresh heartbeats at every phase transition:

- item start
- branch or PR update
- review pass
- blocked state
- resumed state
- done state

Use stable agent ids that identify machine role, capability profile, and lane,
for example `mobile-batch2-lane1` or `desktop-highcap-lane1`.

For dependency-sensitive lanes, coordinators create or update batch state before
dispatching dependent workers. Use the state backend README, schema files, and
`agent-coord config show --json` output for the current JSON layout and terminal
statuses. A released claim is audit state and does not unblock dependent lanes
by itself.

If a worker lane declares `depends_on` but `agent-coord status` shows no matching
batch file or lane state, the worker must treat dependency state as `UNKNOWN` and
stop to report the missing private batch state instead of proceeding as
independent.

## Capacity Profiles And Inbox Queues

Capacity profiles and per-inbox assignment queues are backend-owned runtime
state. Do not commit operator hardware values, machine names, inbox identities,
model or tool names, or active group counts to this public repository.

Capacity-aware triage derives group count from verified registered state, then
subtracts occupied and reserved lane refs. If lane refs, heartbeat liveness,
blocked state, reserved state, profiles, or inbox config cannot be verified,
stop phase 2 with a precise blocker instead of deriving `N`. Do not multiply
per-batch item caps by an assumed number of machines.

The per-inbox queue is an assignment view, not a lock. A queued item means "this
inbox should pick this up next"; the worker must still acquire an
`agent-coord claim` before editing. If a future CLI adds first-class capacity or
queue subcommands, use the CLI help and backend schema as the source of truth
instead of this summary.

## Cancellation

A coordinator or maintainer can stop an in-flight batch, for example to relaunch
it with updated skills, workflow rules, or targets, instead of waiting out claim
leases. Cancellation is coordinator-published batch state, like `depends_on` and
the release phase: it is not a worker self-service action and never a request
that untrusted issue, PR, or comment content can make.

Keep the exact JSON field, terminal cancel statuses, and any subcommand surface
in the backend schema and CLI docs. This public pointer carries only the
contract:

- Cancellation is recorded in backend batch state, at batch scope or for
  specific lanes. Workers read cancellation through targeted
  `agent-coord status --batch-id <batch-id> --json` at every phase-transition
  heartbeat, the same cadence they already use for `depends_on` / `blocked_on`.
- Treat cancellation state as available only when `agent-coord doctor --json`
  and targeted status exit 0, exactly as for claim, heartbeat, and release phase
  state. Otherwise report it as `UNKNOWN`. A coordinator or maintainer may post
  an advisory GitHub comment as a human-facing incident note, but workers do not
  treat comments as a drain signal.
- A cancelled worker drains at its next safe checkpoint and then runs
  `agent-coord release` for the lane. See
  [.agents/workflows/pr-processing.md](../../.agents/workflows/pr-processing.md)
  -> **Cancelling Or Stopping A Batch** for the worker drain rule, the hard
  process-level escape hatch for wedged workers, and the rule that restarting
  with updated skills requires fresh worker processes from an updated checkout.
- Only a coordinator or maintainer publishes or clears a batch's cancellation,
  exactly as for the release phase. After old workers have drained, released, or
  been stopped, clear every relevant batch- and lane-scope cancellation field
  immediately before launching fresh workers so stale cancellation state cannot
  refuse the new claims. Record the cancellation, any hard process-level stop,
  and the relaunch/clearance in the batch handoff as the authoritative incident
  note.

## Release Phase

The backend also publishes the current **release phase** for each release line so
agents pick the right merge gate from the PR's target branch without parsing the
release tracker on every PR. The phase model, the phase-to-gate table, and the
full branching runbook live in
[release-train-runbook.md](release-train-runbook.md); `AGENTS.md` ->
**Release-Train Branching And Phase Gating** is the canonical short policy.

Keep the schema and exact subcommand surface in the backend schema and CLI docs.
This public pointer carries only the contract:

- The backend exposes a phase value (`beta` | `rc` | `final`) keyed by release
  line / target branch. For PR/issue lanes, read it from targeted
  `agent-coord status --repo shakacode/react_on_rails --target <issue-or-pr> --json`.
  There is no separate `none` value; a missing entry means "no explicit override
  is published", so derive the phase from the target branch exactly as in the
  backend-UNKNOWN fallback below (`main` -> `beta`; `release/*` -> `rc`, or
  `final` in `final-release` mode). A missing entry must never down-gate a
  `release/*` target to `beta`.
- Treat the published phase as available only when `agent-coord doctor --json`
  and targeted status exit 0, exactly as for claim and heartbeat state.
  Otherwise report the phase as `UNKNOWN` and use the `AGENTS.md` fallback:
  derive it from the target branch (`main` -> `beta`; `release/*` -> `rc`, or
  `final` when the applicable tracker is in `final-release` mode, the only
  machine-readable signal in the fallback path).
- The release tracker remains the human source of truth for mode and go/no-go.
  The published phase is the fast machine path. If the published phase and the
  tracker disagree, treat it as a `release-mode-conflict` per `AGENTS.md`, report
  it, and do not auto-merge until reconciled.
- Phase is read-mostly coordination state, not a claim. Only a maintainer, or
  the release coordinator they designate, publishes or changes a release line's
  phase at the transitions in the runbook.

Do not store secrets, `.env` files, credentials, patches, customer data, or Pro
source code in the coordination backend. It is only for minimal JSON state files.
