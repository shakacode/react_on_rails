# Agent Coordination Backend

Concurrent agent batches can use the private `shakacode/agent-coordination`
repository for shared claim, heartbeat, and batch dependency state.

Keep schema definitions and examples in the private backend repository. This
React on Rails repository should only carry this pointer and the public workflow
rules in [AGENTS.md](../../AGENTS.md), [.agents/skills/pr-batch/SKILL.md](../../.agents/skills/pr-batch/SKILL.md),
and [.agents/workflows/pr-processing.md](../../.agents/workflows/pr-processing.md).

This pointer was validated against private backend commit `ed339f2`. Until the
private repo has tagged releases, pull the private repo and rerun the smoke
checks below after backend CLI or schema changes. Update this hash in the same
PR whenever the private CLI interface, schema, or smoke-check procedure changes.

## Setup

```bash
gh auth status
gh repo clone shakacode/agent-coordination
cd agent-coordination
ruby -Itest test/agent_coord_test.rb
bin/agent-coord --help
mkdir -p "$HOME/.local/bin"
ln -sf "$PWD/bin/agent-coord" "$HOME/.local/bin/agent-coord"
agent-coord --help
```

The workflow docs assume `agent-coord` is available on `PATH`. Add
`$HOME/.local/bin` to the shell `PATH` if needed, or run the command by its full
path inside the private clone.

Treat the backend as available when `agent-coord status` exits 0. If the command
is missing, auth fails, the private repo cannot be read, or `status` exits
non-zero, report private state as `UNKNOWN` and use structured public claim
comments as an advisory fallback. A successful status check followed by a
refused `agent-coord claim` is not unavailability; it is a hard stop.

Use a temporary local state directory for smoke checks that should not write to
GitHub:

```bash
STATE_ROOT=$(mktemp -d)
AGENT_COORD_STATE_ROOT="$STATE_ROOT" bin/agent-coord heartbeat \
  --agent-id worker-3969 \
  --repo shakacode/react_on_rails \
  --target 3969
AGENT_COORD_STATE_ROOT="$STATE_ROOT" bin/agent-coord status
```

## Heartbeats

Workers refresh heartbeats at every phase transition:

- item start
- branch or PR update
- review pass
- blocked state
- done state

Use stable agent ids that identify machine, tool, and lane, for example
`m5-codex-batch2` or `m1-claude-fable-lane1`.

```bash
bin/agent-coord heartbeat \
  --agent-id m5-codex-batch2 \
  --repo shakacode/react_on_rails \
  --target 3970 \
  --batch-id "agent-coord-$(date +%Y-%m-%d)" \
  --branch jg-codex/3970-agent-heartbeats
bin/agent-coord status
```

Heartbeat liveness is derived from timestamps: `live` before the TTL expires,
`stale` until 4x TTL, and `dead` after that. The default heartbeat TTL is 15
minutes, so the default dead threshold is 60 minutes after the heartbeat update.
The default claim lease TTL is 4 hours, used only as a fallback when heartbeat
liveness is missing or invalid. Use the private repo's launchd template for
desktop sessions that need out-of-band renewal while an agent is between tool
calls.

For `batches/<batch-id>.json`, the dependency-complete heartbeat statuses at
private backend commit `ed339f2` are `complete`, `completed`, `done`, `merged`,
and `ready`. A released claim is audit state and does not unblock dependent
lanes by itself.

Do not store secrets, `.env` files, credentials, patches, customer data, or Pro
source code in the coordination backend. It is only for minimal JSON state files.
