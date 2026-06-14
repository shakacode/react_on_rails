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
agent-coord doctor
```

The workflow docs assume `agent-coord` is available on `PATH`.
`bin/agent-coord bootstrap` installs both `agent-coord` and the compatibility
alias `agent_coord` into `$HOME/.local/bin` by default. Add that directory to the
active shell `PATH` if the shell has not reloaded its profile yet.

Treat the backend as available when `agent-coord doctor` and `agent-coord status`
exit 0. If the command is missing, auth fails, the private repo cannot be read,
or either command exits non-zero, report private state as `UNKNOWN` and use
structured public claim comments as an advisory fallback where dependency rules
allow it. A successful status check followed by a refused `agent-coord claim`
with exit code 3 / `CLAIM_REFUSED` is not unavailability; it is a hard stop.
`agent-coord status` is a preflight view; `agent-coord claim` is the backend's
compare-and-swap gate for concurrent claim races.

Do not use an unverified private clone for hard-stop gates. If the local private
CLI or README no longer matches this public pointer and the operator cannot
validate the current private backend version/config output, report private state
as `UNKNOWN` and stay in advisory fallback mode until a coordinator validates the
backend.

Machine agents must not override a refused private claim on their own. A human
coordinator may authorize a one-off manual override only after running
`agent-coord status`, recording why the private state is wrong or degraded in
the batch handoff as the authoritative incident note, and repairing the private
state so later machine agents can observe the override through `agent-coord
status`. Mirror the same note to the issue or PR when that is the active lane
discussion, but do not use a public claim comment as the machine-readable
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
file such as `.agent-coord.local.json`. The repository ignores that path so
capacity values can change without source edits. If the backend exposes a
registration command, use it as the source of truth; otherwise use the private
backend README and schema files. The installed `agent-coord` 0.1.0 public
contract exposes claim, heartbeat, status, version, config, doctor, and
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
   bounded by enabled inboxes and current live or blocked claims.
3. Let `N` be the resulting available lane-slot count.
4. Split work into up to `N` non-empty groups, or stop phase 2 with a blocker
   when `N` cannot be verified. When actionable work has fewer items than
   available slots, report the remaining idle slots instead of creating empty
   groups or prompts.

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

Do not store secrets, `.env` files, credentials, patches, customer data, or Pro
source code in the coordination backend. It is only for minimal JSON state files.
