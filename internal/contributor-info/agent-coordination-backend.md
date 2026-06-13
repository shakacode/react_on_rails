# Agent Coordination Backend

Concurrent agent batches can use the private `shakacode/agent-coordination`
repository for shared claim, heartbeat, and batch dependency state.

Keep schema definitions and examples in the private backend repository. This
React on Rails repository should only carry this pointer and the public workflow
rules in [AGENTS.md](../../AGENTS.md), [.agents/skills/pr-batch/SKILL.md](../../.agents/skills/pr-batch/SKILL.md),
and [.agents/workflows/pr-processing.md](../../.agents/workflows/pr-processing.md).

## Setup

```bash
gh auth status
gh repo clone shakacode/agent-coordination
cd agent-coordination
ruby -Itest test/agent_coord_test.rb
bin/agent-coord --help
```

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

Do not store secrets, `.env` files, credentials, patches, customer data, or Pro
source code in the coordination backend. It is only for minimal JSON state files.
