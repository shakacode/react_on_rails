# Agent Coordination Backend

Concurrent agent batches can use the private `shakacode/agent-coordination`
repository for shared claim, heartbeat, and batch dependency state.

Keep authoritative JSON schema definitions and examples in the private backend
repository. This React on Rails repository carries the operator-facing contract
and public workflow rules in [AGENTS.md](../../AGENTS.md),
[.agents/skills/pr-batch/SKILL.md](../../.agents/skills/pr-batch/SKILL.md),
[.agents/skills/triage/SKILL.md](../../.agents/skills/triage/SKILL.md), and
[.agents/workflows/pr-processing.md](../../.agents/workflows/pr-processing.md).

Until the private repo has tagged releases, use `agent-coord version --json` and
`agent-coord config show --json` as the CLI contract. The private README,
`agent-coord --help`, and `agent-coord config show --json` output are
authoritative if they differ from this public pointer.

## Setup

For a fresh machine joining an active multi-machine batch, start with
[Multi-Batch Operations](multi-batch-operations.md#fresh-machine-quick-start)
and then run the backend setup below.

```bash
gh auth status
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
preflights through `.agents/skills/pr-batch/bin/agent-coord-bounded` with the
same targeted status subcommand so a slow private read becomes explicit degraded
state instead of an indefinite wait:

```bash
.agents/skills/pr-batch/bin/agent-coord-bounded --timeout 20 doctor --json
.agents/skills/pr-batch/bin/agent-coord-bounded --timeout 20 status --repo OWNER/REPO --target TARGET --json
.agents/skills/pr-batch/bin/agent-coord-bounded --timeout 20 status --batch-id BATCH_ID --json
```

Use broad `agent-coord status` only for audit-mode triage sweeps and post-merge
batch discovery; treat those reads as advisory/discovery-only, not authoritative
lane state. If the command is missing, auth fails, the private repo cannot be
read, a bounded probe times out, or targeted status exits non-zero (exit 1/2
means degraded/UNKNOWN; exit 3 is a hard stop, see below), report private state
as `UNKNOWN` / degraded. Use structured public claim comments as an advisory
fallback only where dependency rules allow it. A successful status check followed by a refused
`agent-coord claim` with exit code 3 / `CLAIM_REFUSED` is not unavailability; it is a hard stop. Targeted
`agent-coord status` is a preflight view; `agent-coord claim` is the backend's
compare-and-swap gate for concurrent claim races.

For exact independent lanes with no `depends_on` refs, a coordinator may attempt
a bounded direct `agent-coord claim` when doctor/status is degraded. A successful
claim can proceed as `private_state: claim-only`, with normal heartbeats and
handoff evidence that status was degraded. If the claim is refused, hard-stop.
If the claim times out, stop with `private_state: UNKNOWN (claim outcome)` and
reconcile private state before fallback or branching because the mutating claim
may already have landed. Use the advisory public claim fallback only when the
private claim cannot be started or fails with a definitive non-timeout
setup/auth error, and only after checking for existing unexpired `codex-claim`
comments on the same target. Dependency-sensitive lanes do not use claim-only or
public fallback when status is unavailable; they stop with dependency state
`UNKNOWN`.

Do not use an unverified private clone for hard-stop gates. If the local private
CLI or README no longer matches this public pointer and the operator cannot
validate the current private backend version/config output, report private state
as `UNKNOWN` and stay in advisory fallback mode until a coordinator validates the
backend.

Machine agents must not override a refused private claim on their own. A human
coordinator may authorize a one-off manual override only after running
targeted `agent-coord status`, recording why the private state is wrong or
degraded in the batch handoff as the authoritative incident note, and repairing
the private state so later machine agents can observe the override through
targeted status. Mirror the same note to the issue or PR when that is the active
lane discussion, but do not use a public claim comment as the machine-readable
override channel or to bypass a live or stale holder that can be contacted.

Use a temporary local state directory for smoke checks that should not write to
GitHub. `AGENT_COORD_STATE_ROOT` sets the directory where `agent-coord` reads
and writes JSON state; override it here so dry runs stay local instead of using
the default state root documented in the private repo README.

```bash
STATE_ROOT=$(mktemp -d)
AGENT_COORD_STATE_ROOT="$STATE_ROOT" agent-coord heartbeat \
  --agent-id smoke-test-0 \
  --repo shakacode/react_on_rails \
  --target 9999
AGENT_COORD_STATE_ROOT="$STATE_ROOT" agent-coord status
rm -rf "$STATE_ROOT"
```

## Capacity Profiles And Inbox Queues

Capacity profiles and per-inbox assignment queues are backend-owned runtime
state. Do not commit operator hardware values, machine names, inbox identities,
model or tool names, or active group counts to this public repository.

The public contract for a capacity profile is:

- `profile_id`: stable runtime id chosen by the operator or backend.
- `ram_gb`: positive integer reported by runtime registration or a gitignored
  local config file.
- `max_concurrent_batches`: positive integer capacity for simultaneous batch
  lane ownership from that profile.
- `inboxes`: operator-configured inbox ids that can receive assigned-but-not-
  started work for that profile.
- optional routing metadata, such as capability tags, read from runtime config
  rather than hardcoded model or tool names.

Profiles must be registered at runtime or loaded from a machine-local ignored
file such as `.agent-coord.local.json` or a per-profile file like
`.agent-coord.local.<profile>.json`. The repository ignores those paths so
capacity values can change without source edits. If the backend exposes a
registration command, use it as the source of truth; otherwise use the private
backend README and schema files. The installed `agent-coord` 0.1.0 public
contract exposes claim, release, heartbeat, status, version, config, doctor, and
bootstrap commands, but does not yet expose a public capacity-profile or queue
subcommand.

The per-inbox queue is an assignment view, not a lock. A queued item means "this
inbox should pick this up next"; the worker must still acquire an
`agent-coord claim` before editing. Queue entries should reference the target
repo, issue or PR number, batch id, lane name, planned agent id, and assignment
status. The inbox "next up" view should hide completed items, show in-flight
items from live claims and heartbeats, and flag lost-heartbeat items as needing a
takeover or resume decision instead of silently reassigning them.

> **Planned (not yet in `agent-coord` 0.1.0):** `agent-coord status` or a
> future `batch-status` subcommand should expose this per-inbox "next up" view
> once queue state is implemented in the backend.

Capacity-aware triage derives group count from registered state:

1. Read current capacity profiles and enabled inbox config.
2. Convert profiles into available lane slots from `max_concurrent_batches`,
   bounded by enabled inboxes.
3. Build a unique occupied/reserved lane-ref set from live in-progress lanes,
   live blocked lanes, blocked lanes without a live heartbeat, and reserved
   lanes, then subtract that set size from the bounded total. If lane refs,
   heartbeat liveness, blocked state, reserved state, profiles, or inbox config
   cannot be verified, stop phase 2 with a precise blocker instead of deriving
   `N`.
4. If the subtraction result is negative, report "occupied/reserved lanes exceed
   registered capacity" with the bounded slot count and occupied lane refs, then
   stop phase 2 instead of clamping or inventing groups.
5. Let `N` be the resulting non-negative available lane-slot count.
6. If `N` is 0 while actionable work remains, report "all lanes currently
   occupied" and stop phase 2 instead of inventing groups.
7. Split the current wave into up to `N` non-empty groups, capped by the
   `$pr-batch` per-batch limits: 8 items when files or risk overlap, or 10 fully
   independent items. Stop phase 2 with a blocker when `N` cannot be verified.
   When actionable work exceeds the capped current wave, report the remaining
   backlog/next wave; when actionable work has fewer items than available slots,
   report the remaining idle slots instead of creating empty groups or prompts.

Do not multiply per-batch item caps by an assumed number of machines. The
registered profiles and inbox config are the only source for capacity-aware
group count.

## Heartbeats

Workers refresh heartbeats at every phase transition:

- item start
- branch or PR update
- review pass
- blocked state
- resumed state
- done state

Use stable agent ids that identify machine role, capability profile, and lane,
for example `mobile-batch2-lane1` or `desktop-highcap-lane1`.

**Migration note:** Existing `<machine>-<tool>-<batch>` ids remain valid while
their old claim or heartbeat is live. A restarted worker must continue using the
old id until that claim is released or expired; re-key to
`<machine-or-profile>-<batch>-<lane>` only for new lanes or after the old claim
is gone.

```bash
BATCH_ID="agent-coord-$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 4)-coord-layer"
BATCH_ID_FILE=$(mktemp "${TMPDIR:-/tmp}/agent-coord-batch-id.coord-layer.XXXXXX")
# Set once at kickoff, include a short batch slug plus a unique suffix, and reuse for this batch.
printf '%s\n' "$BATCH_ID" > "$BATCH_ID_FILE"
# Record the printed file path in the batch handoff.
printf 'Batch id file: %s\n' "$BATCH_ID_FILE"
# In a fresh shell, set BATCH_ID_FILE to the recorded path, then restore:
# BATCH_ID_FILE=/tmp/agent-coord-batch-id.coord-layer.abc123
# BATCH_ID=$(cat "$BATCH_ID_FILE")
# At batch closeout, remove the temporary pointer: rm -f "$BATCH_ID_FILE"

agent-coord heartbeat \
  --agent-id mobile-batch2-lane1 \
  --repo shakacode/react_on_rails \
  --target 3970 \
  --batch-id "$BATCH_ID" \
  --branch jg-codex/3970-agent-heartbeats
agent-coord status
```

Heartbeat liveness is derived from timestamps: `live` before the TTL expires,
`stale` until the backend dead threshold, and `dead` after that. Use
`agent-coord config show --json`, the private backend README, and CLI help for
current default TTL values, terminal heartbeat statuses, and dead-threshold
calculation.
Dependent lanes blocked on a dead-heartbeat takeover should wait until current
backend liveness marks the holder `dead` before takeover is safe. The default
claim lease TTL is only a fallback when heartbeat liveness is missing or invalid.
Use the private repo's scheduler templates, such as macOS `launchd` or Linux
`systemd --user`, for sessions that need out-of-band renewal while an agent is
between tool calls.

For dependency-sensitive lanes, coordinators create or update
`batches/<batch-id>.json` in the private backend before dispatching dependent
workers. Batch files are edited as JSON in the private repo in v1. Use the
private backend README and schema files for that JSON layout; this public pointer
intentionally omits the batch-state schema and terminal-status list. The private
backend README, schema files, and `agent-coord config show --json` output are
authoritative for the terminal heartbeat statuses that unblock `depends_on`
refs; re-check them after backend updates. A released claim is audit state and
does not unblock dependent lanes by itself.

If a worker lane declares `depends_on` but `agent-coord status` shows no matching
batch file or lane state, the worker must treat dependency state as `UNKNOWN` and
stop to report the missing private batch state instead of proceeding as
independent.

## Cancellation

A coordinator or maintainer can stop an in-flight batch — for example to relaunch
it with updated skills, workflow rules, or targets — instead of waiting out claim
leases. Cancellation is coordinator-published batch state, like `depends_on` and
the release phase: it is not a worker self-service action and never a request that
untrusted issue, PR, or comment content can make.

Keep the exact JSON field, terminal cancel statuses, and any subcommand surface in
the private backend repo. This public pointer carries only the contract:

- Cancellation is recorded in the private backend `batches/<batch-id>.json`,
  edited directly as JSON in the current `agent-coord` 0.1.x workflow, at batch
  scope or for specific lanes. Cancellation is additive: a worker drains when
  either its lane or the whole batch is cancelled, and clearing one scope does
  not resume a lane while the other scope remains cancelled. To relaunch safely,
  clear every relevant batch- and lane-scope cancellation field, and cancel or
  reassign downstream lanes that still `depends_on` a cancelled lane. Workers
  read cancellation through targeted
  `agent-coord status --batch-id <batch-id> --json` at every phase-transition
  heartbeat, the same cadence they already use for `depends_on` / `blocked_on`.
  The private backend README and `agent-coord config show --json` are
  authoritative for the exact field name and cancel status values if they differ
  from this pointer.
- Treat cancellation state as available only when `agent-coord doctor --json`
  and targeted status exit 0, exactly as for claim, heartbeat, and phase state.
  Otherwise report it as `UNKNOWN`. If cancellation was already recorded before
  the outage, a coordinator can continue the process-level escape hatch; if not,
  stop worker processes and wait to reconcile claims and cancellation state in
  the private backend before relaunch. A coordinator or maintainer may post an
  advisory GitHub comment as a human-facing incident note, but workers do not
  treat comments as a drain signal. Arbitrary public comments cannot initiate
  this fallback.
- A cancelled worker drains at its next safe checkpoint and then runs
  `agent-coord release` for the lane. See
  [.agents/workflows/pr-processing.md](../../.agents/workflows/pr-processing.md)
  → **Cancelling Or Stopping A Batch** for the worker drain rule, the hard
  process-level escape hatch for wedged workers, and the rule that restarting with
  updated skills requires fresh worker processes from an updated checkout.
- Only a coordinator or maintainer publishes or clears a batch's cancellation,
  exactly as for the release phase. Record the cancellation, and any hard
  process-level stop, in the batch handoff as the authoritative incident note.
- Once every old worker has drained, released its claim, or been stopped and
  cleaned up, record the relaunch intent in the handoff or private state. Then
  clear every relevant batch- and lane-scope cancellation field in
  `batches/<batch-id>.json` immediately before launching fresh workers so new
  claims are not refused by stale cancellation state.

> **Planned (not yet in `agent-coord` 0.1.0):** a first-class `agent-coord cancel`
> verb and a `status` field that surfaces batch/lane cancellation directly, so
> coordinators do not hand-edit `batches/<batch-id>.json` and workers get an
> explicit cancel signal. Until then, cancellation rides the existing batch-state
> JSON and `status` read path.

## Release Phase

The backend also publishes the current **release phase** for each release line so
agents pick the right merge gate from the PR's target branch without parsing the
release tracker on every PR. The phase model, the phase→gate table, and the full
branching runbook live in
[release-train-runbook.md](release-train-runbook.md); `AGENTS.md` ->
**Release-Train Branching And Phase Gating** is the canonical short policy.

Keep the schema and exact subcommand surface in the private backend repo. This
public pointer carries only the contract:

- The backend exposes a phase value (`beta` | `rc` | `final`) keyed by release
  line / target branch. For PR/issue lanes, read it from targeted
  `agent-coord status --repo shakacode/react_on_rails --target <issue-or-pr> --json`.
  There is no separate `none` value; a missing
  entry (no published phase for that line) means "no explicit override is
  published", so derive the phase from the target branch exactly as in the
  backend-UNKNOWN fallback below (`main` -> `beta`; `release/*` -> `rc`, or
  `final` in `final-release` mode). A missing entry must never down-gate a
  `release/*` target to `beta`. The private backend README, `agent-coord --help`,
  and `agent-coord config show --json` are authoritative for the exact field and
  subcommand if they differ from this pointer.
- Treat the published phase as available only when `agent-coord doctor --json`
  and targeted status exit 0, exactly as for claim and heartbeat state.
  Otherwise report the phase as `UNKNOWN` and use the `AGENTS.md` fallback:
  derive it from the target branch (`main` -> `beta`; `release/*` -> `rc`, or
  `final` when the applicable tracker is in `final-release` mode — the only
  machine-readable signal in the fallback path).
- The release tracker remains the human source of truth for mode and go/no-go.
  The published phase is the fast machine path. If the published phase and the
  tracker disagree, treat it as a `release-mode-conflict` per `AGENTS.md`, report
  it, and do not auto-merge until reconciled.
- Phase is read-mostly coordination state, not a claim. Only a maintainer (or the
  release coordinator they designate) publishes or changes a release line's
  phase, at the transitions in the runbook: `beta` -> `rc` at RC cut, `rc` ->
  `final` at the promotion freeze, and cleared at release close-out (the entry is
  removed when the release branch is deleted; absence falls back to `beta`).

Do not store secrets, `.env` files, credentials, patches, customer data, or Pro
source code in the coordination backend. It is only for minimal JSON state files.
