# Agent Coordination Backend

Concurrent agent batches can use the private `shakacode/agent-coordination`
repository for shared claim, heartbeat, and batch dependency state.

Keep schema definitions and examples in the private backend repository. This
React on Rails repository should only carry this pointer and the public workflow
rules in [AGENTS.md](../../AGENTS.md), [.agents/skills/pr-batch/SKILL.md](../../.agents/skills/pr-batch/SKILL.md),
and [.agents/workflows/pr-processing.md](../../.agents/workflows/pr-processing.md).

The private backend owns the CLI contract, schema details, liveness thresholds,
terminal heartbeat statuses, and default values. Use a tagged private release
when one exists. Until then, use `agent-coord version --json` and
`agent-coord config show --json` as the CLI contract and record the exact
private backend commit validated by the coordinator. The private README,
`agent-coord --help`, and `agent-coord config show --json` output are
authoritative if they differ from this public pointer. This public page records
the workflow contract and verification path, not a copy of the private backend's
operational defaults.

## Setup

For a fresh machine joining an active multi-machine batch, start with
[Multi-Batch Operations](multi-batch-operations.md#fresh-machine-quick-start)
and then run the backend setup below.

```bash
gh auth status
gh repo clone shakacode/agent-coordination
cd agent-coordination
git rev-parse HEAD # Record this private backend commit SHA in PR evidence.
ruby -Itest test/agent_coord_test.rb
bin/agent-coord --help
bin/agent-coord bootstrap
export PATH="$HOME/.local/bin:$PATH"
AGENT_COORD_BIN=$(command -v agent-coord)
"$AGENT_COORD_BIN" --help
agent_coord --help
"$AGENT_COORD_BIN" version --json
"$AGENT_COORD_BIN" config show --json
"$AGENT_COORD_BIN" doctor
"$AGENT_COORD_BIN" status
```

The workflow docs assume the `agent-coord` CLI from the private
`shakacode/agent-coordination` backend is available on `PATH`.
`bin/agent-coord bootstrap` installs both `agent-coord` and the compatibility
alias `agent_coord` into `$HOME/.local/bin` by default. Add that directory to the
active shell `PATH` if the shell has not reloaded its profile yet, or run the
command by its full path inside the private clone. A successful
`gh repo view shakacode/agent-coordination` is not enough to treat the backend
as available; the worker or coordinator must run `agent-coord doctor` and
`agent-coord status` through the same binary validated from `PATH` or from a
verified private clone.

Fresh conductor, Codex, Claude, and Linux hosts must install or locate
`agent-coord` before coordination-aware finishing. If out-of-band heartbeat
renewal is needed, use the scheduler guidance and templates from the private
backend for that platform instead of adapting private scheduler snippets in this
public repo.

## CLI Contract Preflight

Before relying on a newly cloned or updated backend, capture the private
contract marker and prove the commands this public workflow depends on:

Set `AGENT_COORD_REPO` to the private `shakacode/agent-coordination` clone path
before running this block. Update that private clone intentionally before this
preflight if the latest upstream state matters; the block below only records and
probes the checkout already selected. Public PR evidence should record the
private backend tag/commit marker, the command names, exit codes, and whether
the JSON commands parsed successfully. Do not paste raw `agent-coord config
show --json` output, private defaults, liveness thresholds, or terminal-status
details into public PRs.

The preflight exports `AGENT_COORD_BIN` in the calling shell only after the
private checkout and command contract probes pass. Keep that exported value for
the operational snippets below so the probed private checkout and later
heartbeat/claim commands use the same binary.

```bash
if test -z "${AGENT_COORD_REPO:-}"; then
  echo "Set AGENT_COORD_REPO to the shakacode/agent-coordination clone path" >&2
  exit 1
elif test ! -x "$AGENT_COORD_REPO/bin/agent-coord"; then
  echo "AGENT_COORD_REPO must point at a shakacode/agent-coordination clone" >&2
  exit 1
fi

if (
  set -eu -o pipefail

  command -v jq >/dev/null 2>&1 || { echo "jq is required for this preflight" >&2; exit 1; }

  require_json_output() {
    local label="$1"
    local output="$2"

    if ! printf '%s' "$output" | grep -q '[^[:space:]]'; then
      echo "$label produced no JSON output" >&2
      return 1
    fi

    if ! printf '%s\n' "$output" | jq -e 'type == "object"' >/dev/null; then
      echo "$label did not produce a JSON object" >&2
      return 1
    fi
  }

  AGENT_COORD_BIN="$AGENT_COORD_REPO/bin/agent-coord"
  git -C "$AGENT_COORD_REPO" describe --tags --always --dirty &&
    git -C "$AGENT_COORD_REPO" rev-parse HEAD &&
    "$AGENT_COORD_BIN" --help &&
    AGENT_COORD_VERSION_JSON="$("$AGENT_COORD_BIN" version --json)" &&
    require_json_output "agent-coord version --json" "$AGENT_COORD_VERSION_JSON" &&
    # Suppress stderr intentionally: private config details must not appear in public PRs.
    # Non-zero exits still stop the preflight; blank stdout is caught only after a zero exit.
    # For private diagnostics, rerun without 2>/dev/null in a private terminal.
    AGENT_COORD_CONFIG_JSON="$("$AGENT_COORD_BIN" config show --json 2>/dev/null)" &&
    require_json_output "agent-coord config show --json" "$AGENT_COORD_CONFIG_JSON" &&
    "$AGENT_COORD_BIN" doctor &&
    "$AGENT_COORD_BIN" status &&
    "$AGENT_COORD_BIN" claim --help &&
    "$AGENT_COORD_BIN" heartbeat --help &&
    "$AGENT_COORD_BIN" release --help
); then
  AGENT_COORD_BIN="$AGENT_COORD_REPO/bin/agent-coord"
  export AGENT_COORD_BIN
  printf 'AGENT_COORD_BIN=%s\n' "$AGENT_COORD_BIN"
else
  exit 1
fi
```

Do not paste private schemas, default TTLs, dead-threshold formulas,
terminal-status lists, or full help output into this public repo. Public PR
evidence should record the private tag or commit, the commands run, and whether
each command exited 0. When tag state is uncertain, treat the commit SHA from
`git rev-parse HEAD` as the authoritative evidence.

For operational snippets below, set `AGENT_COORD_BIN` to the same validated
binary; if relying on `PATH`, record `command -v agent-coord` and
`agent-coord version --json` as part of the public-safe evidence.

Treat the backend as available when `agent-coord doctor` and `agent-coord status`
exit 0. If the command is missing, auth fails, the private repo cannot be read,
or either command exits non-zero, report private state as `UNKNOWN` and use
structured public claim comments as an advisory fallback where dependency rules
allow it. A successful status check followed by a refused `agent-coord claim`
with exit code 3 / `CLAIM_REFUSED` is not unavailability; it is a hard stop.
`agent-coord status` is a preflight view; `agent-coord claim` is the backend's
compare-and-swap gate for concurrent claim races.

Use this outcome matrix when classifying failures:

| Observation                                                                                               | Classification                  | Worker action                                                                                  |
| --------------------------------------------------------------------------------------------------------- | ------------------------------- | ---------------------------------------------------------------------------------------------- |
| `agent-coord doctor` and `agent-coord status` both exit 0                                                 | backend available               | continue to claim or dependency checks                                                         |
| `agent-coord doctor` or `agent-coord status` cannot run or exits non-zero                                 | operational failure / `UNKNOWN` | use advisory public claim comments only for independent lanes; stop dependency-sensitive lanes |
| `agent-coord claim` exits 0 after status exited 0                                                         | claim acquired or renewed       | proceed and heartbeat at phase transitions                                                     |
| `agent-coord claim` exits 3 / `CLAIM_REFUSED` because another holder owns a live or lease-protected claim | refused claim                   | hard-stop the lane and report holder, liveness, and target                                     |
| `agent-coord claim` exits non-zero for an unclear reason                                                  | operational failure / `UNKNOWN` | do not create a competing branch; ask the coordinator or retry after the backend is validated  |

Do not use an unverified private clone for hard-stop gates. If the local private
CLI or README no longer matches this public pointer and the operator cannot
validate the current private backend contract, report private state as `UNKNOWN`
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

### Local State Smoke Check

```bash
: "${AGENT_COORD_BIN:?set AGENT_COORD_BIN to the validated agent-coord binary}"
STATE_ROOT=$(mktemp -d)
AGENT_COORD_STATE_ROOT="$STATE_ROOT" "$AGENT_COORD_BIN" heartbeat \
  --agent-id smoke-test-0 \
  --repo shakacode/react_on_rails \
  --target 9999
AGENT_COORD_STATE_ROOT="$STATE_ROOT" "$AGENT_COORD_BIN" status
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
: "${AGENT_COORD_BIN:?set AGENT_COORD_BIN to the validated agent-coord binary}"
: "${AGENT_ID:?set AGENT_ID, e.g. desktop-codex-lane1}"
: "${TARGET_PR_NUMBER:?set TARGET_PR_NUMBER for the lane}"
: "${BRANCH_NAME:?set BRANCH_NAME for the lane}"

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

"$AGENT_COORD_BIN" heartbeat \
  --agent-id "$AGENT_ID" \
  --repo shakacode/react_on_rails \
  --target "$TARGET_PR_NUMBER" \
  --batch-id "$BATCH_ID" \
  --branch "$BRANCH_NAME"
"$AGENT_COORD_BIN" status
```

Heartbeat liveness is derived from timestamps: `live` before the TTL expires,
`stale` until the backend dead threshold, and `dead` after that. Use
`agent-coord config show --json`, the private backend README, and CLI help for
current default TTL values, terminal heartbeat statuses, and dead-threshold
calculation.
Dependent lanes blocked on a dead-heartbeat takeover should wait until current
backend liveness marks the holder `dead` before takeover is safe. Before a
replacement claim proceeds, check the current branch and PR state so the
takeover does not overwrite live work, and record the takeover action in the
private coordination state plus the batch handoff or active PR/issue discussion.
The default claim lease TTL is only a fallback when heartbeat liveness is
missing or invalid. Use the private backend's scheduler templates, such as macOS
`launchd` or Linux `systemd --user`, for sessions that need out-of-band renewal
while an agent is between tool calls.

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

## Public Drift Guard

Use this checklist whenever the private backend CLI, private README, or public
workflow examples change:

1. Fetch the private backend and record the validated tag or commit.
2. Run the private backend tests and the `CLI Contract Preflight` commands above.
3. Run the `AGENT_COORD_STATE_ROOT` smoke-check block in the
   [Local State Smoke Check](#local-state-smoke-check) section so examples do not
   write private coordination records while testing command wiring.
4. Confirm this public page still documents only command names, verification
   steps, and outcome rules. Keep schemas, private defaults, terminal heartbeat
   statuses, and scheduler snippets in the private backend.
5. If private help or README output differs from this page, update this pointer
   or report private state as `UNKNOWN`; do not silently rely on stale public
   examples.
6. In PR evidence, list the private backend tag or commit, command results,
   public files changed, and any intentionally omitted private details.

Do not store secrets, `.env` files, credentials, patches, customer data, or Pro
source code in the coordination backend. It is only for minimal JSON state files.
