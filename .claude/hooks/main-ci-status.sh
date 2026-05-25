#!/usr/bin/env bash
# Prints a compact CI-status block for origin/main's latest push commit.
#
# Designed to be wired into Claude Code's SessionStart and PreToolUse hooks
# (see .claude/settings.json) so the agent always sees whether main is green
# before opening a PR or pushing.
#
# Fail-open by design: any tooling failure (gh missing, unauthenticated, no
# network) prints a one-line "unavailable" message and exits 0. We never
# block a session because the status check failed.
#
# Caches output for 5 minutes in .claude/.main-ci-status.cache to avoid
# pounding the GitHub API across rapid session starts.

set -u  # No `set -e` — we want to handle errors ourselves to stay fail-open.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE_FILE="${REPO_ROOT}/.claude/.main-ci-status.cache"
CACHE_TTL_SECONDS=300

# If the cache is fresh, print it and exit. Per-platform stat invocation differs.
if [ -f "${CACHE_FILE}" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    cache_mtime=$(stat -f %m "${CACHE_FILE}" 2>/dev/null || echo 0)
  else
    cache_mtime=$(stat -c %Y "${CACHE_FILE}" 2>/dev/null || echo 0)
  fi
  now=$(date +%s)
  age=$((now - cache_mtime))
  if [ "${age}" -lt "${CACHE_TTL_SECONDS}" ]; then
    cat "${CACHE_FILE}"
    exit 0
  fi
fi

# Helper: print an "unavailable" message and exit 0 without writing the cache.
fail_open() {
  echo "Main CI status unavailable: $1"
  exit 0
}

command -v gh >/dev/null 2>&1 || fail_open "gh CLI not installed"
gh auth status >/dev/null 2>&1 || fail_open "gh CLI not authenticated (run \`gh auth login\`)"

# Pull the latest push run's status check rollup. `--limit 1 --event push`
# isolates main pushes from PR/comment-triggered runs that we don't care about.
runs_json=$(gh run list \
  --branch main \
  --limit 1 \
  --event push \
  --json conclusion,headSha,workflowName,url,status,createdAt \
  2>/dev/null) || fail_open "gh run list failed"

[ -n "${runs_json}" ] || fail_open "no main push runs visible"

# Resolve the head SHA from the most recent push run, then pull every check
# run on that commit. We use the Checks API (not `gh run list`) because a
# single push commit triggers multiple workflows and we want them aggregated.
head_sha=$(echo "${runs_json}" | jq -r '.[0].headSha // empty' 2>/dev/null) || fail_open "jq parse failed"
[ -n "${head_sha}" ] || fail_open "no headSha on most recent push run"

repo_slug=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) || fail_open "gh repo view failed"

# Use `--paginate` with `--jq '.check_runs[]'` to emit JSONL (one check_run per
# line). A separate `jq -s` then slurps the JSONL back into a single array.
# This avoids the gotcha where `gh --paginate` with `--jq '[...]'` produces one
# array per page (concatenated), breaking single-array aggregation.
checks_jsonl=$(gh api \
  --paginate \
  "repos/${repo_slug}/commits/${head_sha}/check-runs" \
  --jq '.check_runs[]' \
  2>/dev/null) || fail_open "gh api check-runs failed"

checks_json=$(echo "${checks_jsonl}" | jq -s '[.[] | {name, status, conclusion, html_url}]' 2>/dev/null) \
  || fail_open "jq slurp failed"

# Aggregate counts with jq. `success`, `skipped`, `neutral` are all "passing".
# Anything completed with another conclusion is a failure. Anything not yet
# completed is in_progress.
summary=$(echo "${checks_json}" | jq -r '
  . as $all
  | {
      total: length,
      passed: [.[] | select(.status == "completed" and (.conclusion | IN("success", "skipped", "neutral")))] | length,
      failed: [.[] | select(.status == "completed" and (.conclusion | IN("success", "skipped", "neutral") | not))],
      in_progress: [.[] | select(.status != "completed")]
    }
  | "TOTAL=\(.total)",
    "PASSED=\(.passed)",
    "FAILED_COUNT=\(.failed | length)",
    "IN_PROGRESS_COUNT=\(.in_progress | length)",
    (.failed[] | "FAILED_LINE=" + .name + " — " + (.conclusion // "incomplete") + " — " + (.html_url // "")),
    (.in_progress[] | "INPROGRESS_LINE=" + .name + " — " + (.status // "in_progress") + " — " + (.html_url // ""))
') || fail_open "jq summary failed"

# Pull short SHA + workflow run URL for the header. Both fields come from runs_json.
short_sha="${head_sha:0:8}"
created_at=$(echo "${runs_json}" | jq -r '.[0].createdAt // ""')

# Build the output as a single string, then write it to cache + stdout.
{
  printf 'Main CI status (origin/main %s, pushed at %s):\n' "${short_sha}" "${created_at}"
  total=$(echo "${summary}" | grep "^TOTAL=" | cut -d= -f2)
  passed=$(echo "${summary}" | grep "^PASSED=" | cut -d= -f2)
  failed_count=$(echo "${summary}" | grep "^FAILED_COUNT=" | cut -d= -f2)
  in_progress_count=$(echo "${summary}" | grep "^IN_PROGRESS_COUNT=" | cut -d= -f2)

  printf '  Total: %s | Passed: %s | Failed: %s | In progress: %s\n' \
    "${total}" "${passed}" "${failed_count}" "${in_progress_count}"

  if [ "${failed_count}" -gt 0 ] 2>/dev/null; then
    echo "  Failures:"
    echo "${summary}" | grep "^FAILED_LINE=" | sed 's/^FAILED_LINE=/    - /'
  fi

  if [ "${in_progress_count}" -gt 0 ] 2>/dev/null; then
    echo "  In progress:"
    echo "${summary}" | grep "^INPROGRESS_LINE=" | sed 's/^INPROGRESS_LINE=/    - /'
  fi

  if [ "${failed_count}" -gt 0 ] 2>/dev/null || [ "${in_progress_count}" -gt 0 ] 2>/dev/null; then
    echo "  See: https://github.com/${repo_slug}/commit/${head_sha}/checks"
  fi
} | tee "${CACHE_FILE}"

exit 0
