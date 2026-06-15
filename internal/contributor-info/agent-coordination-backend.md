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
if ! INSTALLED_AGENT_COORD_BIN=$(command -v agent-coord 2>/dev/null); then
  echo "agent-coord not found; recheck PATH or rerun bin/agent-coord bootstrap" >&2
  return 1 2>/dev/null || exit 1
fi
"$INSTALLED_AGENT_COORD_BIN" --help # Loose smoke-check; use CLI Contract Preflight for strict validation.
if ! command -v agent_coord >/dev/null 2>&1; then
  echo "agent_coord alias not found; bootstrap may not have installed it" >&2
  return 1 2>/dev/null || exit 1
fi
agent_coord --help # Verify the compatibility alias (underscore form) is also on PATH.
"$INSTALLED_AGENT_COORD_BIN" version --json
if ! "$INSTALLED_AGENT_COORD_BIN" config show --json >/dev/null 2>&1; then
  echo "agent-coord config show --json failed; rerun directly in a private terminal for diagnostics" >&2
fi
"$INSTALLED_AGENT_COORD_BIN" doctor
"$INSTALLED_AGENT_COORD_BIN" status
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

The setup block uses `INSTALLED_AGENT_COORD_BIN` only as an install smoke-check;
the later operational snippets require `AGENT_COORD_BIN`, which is exported only
after the CLI contract preflight validates the selected private checkout.

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

Run this block in `bash`; it relies on `pipefail`, functions, and `local`.
If the strict preflight exits at the private `config show` step, rerun
`"$AGENT_COORD_REPO/bin/agent-coord" config show --json` directly in a private
terminal without output suppression to read the backend diagnostic.

```bash
if test -z "${AGENT_COORD_REPO:-}"; then
  echo "Set AGENT_COORD_REPO to the shakacode/agent-coordination clone path" >&2
  return 1 2>/dev/null || exit 1
elif ! AGENT_COORD_REPO_ABS="$(cd "$AGENT_COORD_REPO" && pwd -P)"; then
  echo "AGENT_COORD_REPO must point at a readable shakacode/agent-coordination clone" >&2
  return 1 2>/dev/null || exit 1
elif test ! -x "$AGENT_COORD_REPO_ABS/bin/agent-coord"; then
  echo "bin/agent-coord is missing or not executable in '$AGENT_COORD_REPO_ABS'; did bootstrap complete?" >&2
  return 1 2>/dev/null || exit 1
fi

# Intentionally update the caller's variable before the subshell.
# Later snippets inherit the canonical path.
AGENT_COORD_REPO="$AGENT_COORD_REPO_ABS"

if (
  set -eu -o pipefail

  command -v jq >/dev/null 2>&1 || { echo "jq is required for this preflight" >&2; exit 1; }

  require_json_output() {
    local label="$1"
    local output="$2"

    if ! printf '%s\n' "$output" | grep -q '[^[:space:]]'; then
      echo "$label produced no output" >&2
      return 1
    fi

    # Require a JSON object, not an array or scalar. If the private CLI changes
    # shape, update this check and the CLI Contract prose together.
    if ! printf '%s\n' "$output" | jq -e 'type == "object"' >/dev/null; then
      echo "$label did not produce a JSON object" >&2
      return 1
    fi
  }

  load_agent_coord_config_json() {
    "$AGENT_COORD_BIN" config show --json 2>/dev/null || {
      echo 'agent-coord config show --json failed; rerun it directly for private diagnostics' >&2
      return 1
    }
  }

  require_clean_agent_coord_checkout() {
    # Non-zero means the index was stale; the diff checks below are the real cleanliness gate.
    git -C "$AGENT_COORD_REPO" update-index -q --refresh || true
    local untracked_files # Keep separate so set -e sees git ls-files failures below, not local's exit code.

    if ! git -C "$AGENT_COORD_REPO" diff --quiet --ignore-submodules -- ||
       ! git -C "$AGENT_COORD_REPO" diff --cached --quiet --ignore-submodules --; then
      echo "agent-coordination checkout has local modifications; commit, stash, or record dirty evidence" >&2
      return 1
    fi

    untracked_files="$(git -C "$AGENT_COORD_REPO" ls-files --others --exclude-standard)" || {
      echo "git ls-files failed in '$AGENT_COORD_REPO'" >&2
      return 1
    }

    if [ -n "$untracked_files" ]; then
      echo "agent-coordination checkout has untracked files; commit, clean, or record dirty evidence" >&2
      return 1
    fi
  }

  require_published_agent_coord_head() {
    local head_sha remote_tag_refs
    head_sha="$(git -C "$AGENT_COORD_REPO" rev-parse HEAD)" || {
      echo "could not read agent-coordination HEAD" >&2
      return 1
    }

    # This mutates the private clone's remote-tracking refs and local tag namespace.
    # Run it only against the private checkout selected by AGENT_COORD_REPO.
    git -C "$AGENT_COORD_REPO" fetch --quiet --prune --tags origin || {
      echo "could not fetch private agent-coordination origin; backend SHA reachability is UNKNOWN" >&2
      return 1
    }

    remote_tag_refs="$(git -C "$AGENT_COORD_REPO" ls-remote --tags --refs origin)" || {
      echo "could not list private agent-coordination origin tags; backend SHA reachability is UNKNOWN" >&2
      return 1
    }

    remote_tag_contains_head() {
      local tag_ref

      while IFS= read -r tag_ref; do
        test -n "$tag_ref" || continue
        git -C "$AGENT_COORD_REPO" merge-base --is-ancestor "$head_sha" "$tag_ref" && return 0
      done < <(printf '%s\n' "$remote_tag_refs" | awk '{print $2}')

      return 1
    }

    origin_branch_contains_head() {
      local origin_ref

      origin_ref="$(git -C "$AGENT_COORD_REPO" for-each-ref --count=1 --contains "$head_sha" \
        --format='%(refname)' refs/remotes/origin)" || return 1
      test -n "$origin_ref"
    }

    if ! origin_branch_contains_head &&
       ! remote_tag_contains_head; then
      echo "agent-coordination HEAD $head_sha is not reachable from a fetched remote branch or tag" >&2
      return 1
    fi

    # Print the SHA so public PR evidence can record the private backend commit.
    printf '%s\n' "$head_sha"
  }

  AGENT_COORD_BIN="$AGENT_COORD_REPO/bin/agent-coord" # Subshell-local; parent re-exports after probes pass.
  # set -eu above handles abort-on-error; && keeps each evidence/probe step explicit.
  require_clean_agent_coord_checkout &&
    # --dirty annotates race-condition dirtiness; the clean-check above is the hard gate.
    git -C "$AGENT_COORD_REPO" describe --tags --always --dirty &&
    require_published_agent_coord_head &&
    "$AGENT_COORD_BIN" --help >/dev/null &&
    AGENT_COORD_VERSION_JSON="$("$AGENT_COORD_BIN" version --json)" &&
    require_json_output "agent-coord version --json" "$AGENT_COORD_VERSION_JSON" &&
    # Suppress stderr: diagnostics may expose private config paths or error details.
    # Non-zero exits still stop the preflight after printing the sanitized hint above.
    # Blank stdout after a zero exit is caught by require_json_output.
    # For private diagnostics, run "$AGENT_COORD_REPO/bin/agent-coord config show --json" directly.
    AGENT_COORD_CONFIG_JSON="$(load_agent_coord_config_json)" &&
    require_json_output "agent-coord config show --json" "$AGENT_COORD_CONFIG_JSON" &&
    "$AGENT_COORD_BIN" doctor &&
    "$AGENT_COORD_BIN" status &&
    "$AGENT_COORD_BIN" claim --help >/dev/null &&
    "$AGENT_COORD_BIN" heartbeat --help >/dev/null &&
    "$AGENT_COORD_BIN" release --help >/dev/null
); then
  AGENT_COORD_BIN="$AGENT_COORD_REPO/bin/agent-coord"
  export AGENT_COORD_BIN
  printf 'AGENT_COORD_BIN=%s\n' "$AGENT_COORD_BIN"
else
  unset AGENT_COORD_BIN
  return 1 2>/dev/null || exit 1
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
(
  set -eu
  STATE_ROOT=$(mktemp -d) || {
    echo "mktemp failed" >&2
    exit 1
  }
  trap 'rm -rf "$STATE_ROOT"' EXIT INT TERM
  AGENT_COORD_STATE_ROOT="$STATE_ROOT" "$AGENT_COORD_BIN" heartbeat \
    --agent-id smoke-test-0 \
    --repo shakacode/react_on_rails \
    --target 9999 # sentinel/fake PR number for local smoke tests only
  AGENT_COORD_STATE_ROOT="$STATE_ROOT" "$AGENT_COORD_BIN" status
)
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
BATCH_ID_FILE=$(mktemp "${TMPDIR:-/tmp}/agent-coord-batch-id.coord-layer.XXXXXX") || {
  echo "mktemp failed" >&2
  return 1 2>/dev/null || exit 1
}
# Set once at kickoff, include a short batch slug plus a unique suffix, and reuse for this batch.
# Do not install an interrupt trap here: the pointer may be needed by a fresh shell after interruption.
printf '%s\n' "$BATCH_ID" > "$BATCH_ID_FILE"
# Record the printed file path in the batch handoff.
printf 'Batch id file: %s\n' "$BATCH_ID_FILE"
# In a fresh shell, set BATCH_ID_FILE to the recorded path, then restore:
# BATCH_ID_FILE=/tmp/agent-coord-batch-id.coord-layer.abc123
# BATCH_ID=$(cat "$BATCH_ID_FILE")
# During normal batch closeout, remove the temporary pointer: rm -f "$BATCH_ID_FILE"
# If the coordinator shell is interrupted before closeout, the recorded file may remain in /tmp;
# use the handoff path to remove it once no workers need to restore this batch id.

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
