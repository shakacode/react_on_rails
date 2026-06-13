# Agent Coordination Backend

Concurrent agent batches can use the private `shakacode/agent-coordination`
repository for shared claim, heartbeat, and batch dependency state.

Keep schema definitions and examples in the private backend repository. This
React on Rails repository should only carry this pointer and the public workflow
rules in [AGENTS.md](../../AGENTS.md), [.agents/skills/pr-batch/SKILL.md](../../.agents/skills/pr-batch/SKILL.md),
and [.agents/workflows/pr-processing.md](../../.agents/workflows/pr-processing.md).

Until the private repo has tagged releases, pull the private repo and rerun the
smoke checks below after backend CLI or schema changes. The command examples in
this page were verified at the initial backend rollout; the private README and
`bin/agent-coord --help` output are authoritative if they differ from this
public pointer.

## Setup

```bash
gh auth status
gh repo clone shakacode/agent-coordination
cd agent-coordination
ruby -Itest test/agent_coord_test.rb
bin/agent-coord --help
mkdir -p "$HOME/.local/bin"
ln -sf "$PWD/bin/agent-coord" "$HOME/.local/bin/agent-coord"
"$HOME/.local/bin/agent-coord" --help
```

The workflow docs assume `agent-coord` is available on `PATH`. Add
`$HOME/.local/bin` to the shell `PATH` if needed, or run the command by its full
path inside the private clone.

Treat the backend as available when `agent-coord status` exits 0. If the command
is missing, auth fails, the private repo cannot be read, or `status` exits
non-zero, report private state as `UNKNOWN` and use structured public claim
comments as an advisory fallback. A successful status check followed by a
refused `agent-coord claim` is not unavailability; it is a hard stop.
`agent-coord status` is a preflight view; `agent-coord claim` is the backend's
compare-and-swap gate for concurrent claim races.

Do not use an unverified private clone for hard-stop gates. If the local private
CLI or README no longer matches this public pointer and the operator cannot
validate the current private backend version, report private state as `UNKNOWN`
and stay in advisory fallback mode until a coordinator validates the backend.

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
AGENT_COORD_STATE_ROOT="$STATE_ROOT" bin/agent-coord heartbeat \
  --agent-id smoke-test-0 \
  --repo shakacode/react_on_rails \
  --target 9999
AGENT_COORD_STATE_ROOT="$STATE_ROOT" bin/agent-coord status
rm -rf "$STATE_ROOT"
```

## Heartbeats

Workers refresh heartbeats at every phase transition:

- item start
- branch or PR update
- review pass
- blocked state
- resumed state
- done state

Use stable agent ids that identify machine role, tool, and lane, for example
`mobile-codex-batch2` or `desktop-claude-fable-lane1`.

```bash
BATCH_ID="agent-coord-$(date +%Y%m%d-%H%M%S)-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -c1-8)-coord-layer"
BATCH_ID_FILE="${TMPDIR:-/tmp}/agent-coord-batch-id.coord-layer"
# Set once at kickoff, include a short batch slug plus a unique suffix, and reuse for this batch.
printf '%s\n' "$BATCH_ID" > "$BATCH_ID_FILE"
# In a fresh shell, restore with: BATCH_ID=$(cat "$BATCH_ID_FILE")
# At batch closeout, remove the temporary pointer: rm -f "$BATCH_ID_FILE"

bin/agent-coord heartbeat \
  --agent-id mobile-codex-batch2 \
  --repo shakacode/react_on_rails \
  --target 3970 \
  --batch-id "$BATCH_ID" \
  --branch jg-codex/3970-agent-heartbeats
bin/agent-coord status
```

Heartbeat liveness is derived from timestamps: `live` before the TTL expires,
`stale` until 4x TTL, and `dead` after that. See the private backend README and
CLI help for current default TTL values and the dead-threshold calculation.
Dependent lanes blocked on a dead-heartbeat takeover should wait until current
backend liveness marks the holder `dead` before takeover is safe. The default
claim lease TTL is only a fallback when heartbeat liveness is missing or invalid.
Use the private repo's launchd template for desktop sessions that need
out-of-band renewal while an agent is between tool calls.

For dependency-sensitive lanes, coordinators create or update
`batches/<batch-id>.json` in the private backend before dispatching dependent
workers. Batch files are edited as JSON in the private repo in v1. Use the
private backend README and schema files for that JSON layout; this public pointer
intentionally omits the batch-state schema. The private backend README and CLI
are authoritative for the terminal heartbeat statuses that unblock `depends_on`
refs, currently `complete`, `completed`, `done`, `merged`, and `ready`. A
released claim is audit state and does not unblock dependent lanes by itself.

If a worker lane declares `depends_on` but `agent-coord status` shows no matching
batch file or lane state, the worker must treat dependency state as `UNKNOWN` and
stop to report the missing private batch state instead of proceeding as
independent.

Do not store secrets, `.env` files, credentials, patches, customer data, or Pro
source code in the coordination backend. It is only for minimal JSON state files.
