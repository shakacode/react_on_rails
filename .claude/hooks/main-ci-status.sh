#!/usr/bin/env bash
# Prints a compact CI-status block for origin/main's current HEAD commit.
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
CACHE_DIR="${REPO_ROOT}/.claude"
CACHE_PREFIX=".main-ci-status.cache"
CACHE_TTL_SECONDS=300

# Helper: print an "unavailable" message and exit 0 without writing the cache.
fail_open() {
  echo "Main CI status unavailable: $1"
  exit 0
}

read_fresh_cache() {
  local cache_file="$1"
  local cache_mtime
  local now
  local age

  [ -f "${cache_file}" ] || return 1

  if [ "$(uname)" = "Darwin" ]; then
    cache_mtime=$(stat -f %m "${cache_file}" 2>/dev/null || echo 0)
  else
    cache_mtime=$(stat -c %Y "${cache_file}" 2>/dev/null || echo 0)
  fi

  now=$(date +%s)
  age=$((now - cache_mtime))
  if [ "${age}" -lt "${CACHE_TTL_SECONDS}" ]; then
    cat "${cache_file}"
    exit 0
  fi

  return 1
}

github_slug_from_origin() {
  local origin_url
  local slug

  origin_url=$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null) || return 1
  case "${origin_url}" in
    https://github.com/*)
      slug=${origin_url#https://github.com/}
      ;;
    git@github.com:*)
      slug=${origin_url#git@github.com:}
      ;;
    ssh://git@github.com/*)
      slug=${origin_url#ssh://git@github.com/}
      ;;
    *)
      return 1
      ;;
  esac

  slug=${slug%.git}
  [ -n "${slug}" ] || return 1
  printf '%s\n' "${slug}"
}

# Fast path: if the local remote-tracking ref has a warm SHA-keyed cache,
# print it without making a live network call. On cache miss we still ask the
# remote for the authoritative current SHA before querying GitHub checks.
local_head_sha=$(git -C "${REPO_ROOT}" rev-parse --verify origin/main 2>/dev/null || echo "")
if [ -n "${local_head_sha}" ]; then
  CACHE_FILE="${CACHE_DIR}/${CACHE_PREFIX}.${local_head_sha:0:12}"
  read_fresh_cache "${CACHE_FILE}"
fi

# Resolve `origin/main` HEAD SHA from the remote before querying checks. We use
# `git ls-remote` (not `gh run list`) so the SHA reflects the current ref tip,
# not the latest push-workflow run — which can lag right after a push (or never
# appear at all for docs-only pushes when paths-ignore filters every workflow).
# Matching the release gate's origin/main semantics keeps session-time and
# release-time observations consistent.
head_sha=$(git -C "${REPO_ROOT}" ls-remote origin refs/heads/main 2>/dev/null | awk 'NR==1 {print $1}')

if [ -n "${head_sha}" ]; then
  CACHE_FILE="${CACHE_DIR}/${CACHE_PREFIX}.${head_sha:0:12}"
else
  # Network or git failure — fall back to the legacy un-keyed cache so a
  # stale read is still possible, but a single failed `ls-remote` call
  # doesn't force a full live re-fetch on every session start.
  CACHE_FILE="${CACHE_DIR}/${CACHE_PREFIX}"
fi

# If the cache for THIS SHA is fresh, print it and exit.
read_fresh_cache "${CACHE_FILE}"

# Helper: atomically replace the cache file with the contents of $1, then
# print $1 to stdout. A direct `tee` would leave a partial file readable
# by a concurrent session-start if the script were interrupted mid-write.
# We print from the parameter rather than re-reading the file, so a
# concurrent delete between the `mv` and the print cannot trigger a
# misleading "cache write failed" fail_open.
#
# After a successful swap, prune older SHA-keyed cache files so we don't
# accumulate one per main commit ever seen. The `-mmin +1` guard avoids
# racing a concurrent session that may have just written its own
# different-SHA cache.
write_cache_atomic() {
  local tmp
  tmp=$(mktemp "${CACHE_FILE}.XXXXXX") || return 1
  # Trailing newline keeps the next shell prompt on its own line. The
  # surrounding `output=$(...)` substitution strips trailing newlines, so
  # without explicitly re-adding one here both the cached file and the
  # stdout print would end mid-line.
  printf '%s\n' "$1" >"${tmp}" || { rm -f "${tmp}"; return 1; }
  mv -f "${tmp}" "${CACHE_FILE}" || { rm -f "${tmp}"; return 1; }
  find "${CACHE_DIR}" -maxdepth 1 \
    -name "${CACHE_PREFIX}*" \
    -not -name "$(basename "${CACHE_FILE}")" \
    -type f -mmin +1 \
    -delete 2>/dev/null || true
  printf '%s\n' "$1"
}

command -v gh >/dev/null 2>&1 || fail_open "gh CLI not installed"
gh auth status >/dev/null 2>&1 || fail_open "gh CLI not authenticated (run \`gh auth login\`)"

repo_slug=$(github_slug_from_origin) || fail_open "unable to determine GitHub repo from origin"

[ -n "${head_sha}" ] || fail_open "git ls-remote origin main failed"

# Pull every check run on the commit. We use the Checks API because a single
# push commit triggers multiple workflows and we want them aggregated.
#
# `--paginate` with `--jq '.check_runs[]'` emits JSONL (one check_run per line).
# A separate `jq -s` slurps the JSONL back into a single array. This avoids
# the gotcha where `gh --paginate` with `--jq '[...]'` produces one array per
# page (concatenated), breaking single-array aggregation.
checks_jsonl=$(gh api \
  --paginate \
  "repos/${repo_slug}/commits/${head_sha}/check-runs" \
  --jq '.check_runs[]' \
  2>/dev/null) || fail_open "gh api check-runs failed"

# Collapse multiple runs per (check_suite_id, name) to the most recent
# attempt (highest check_run id). The key intentionally includes the
# suite id so we only collapse true reruns and not unrelated workflows
# that happen to share a job name (e.g. this repo has multiple workflows
# that each define a `detect-changes` job). Mirrors the Ruby dedup in
# `validate_main_ci_status!` (rakelib/release.rake). Keep the two in sync.
checks_json=$(echo "${checks_jsonl}" | jq -s '
  [.[] | {id, name, status, conclusion, html_url, suite_id: (.check_suite.id // .id), app_id: (.app.id // null)}]
  | group_by([.suite_id, .name, .app_id])
  | map(max_by(.id))
' 2>/dev/null) || fail_open "jq slurp failed"

required_json=$(gh api \
  "repos/${repo_slug}/branches/main/protection/required_status_checks" \
  --jq '{contexts: (.contexts // []), checks: (.checks // [] | map({context, app_id}))}' \
  2>/dev/null || echo "null")
case "${required_json}" in
  \{*\}) ;;
  *) required_json="null" ;;
esac

# Aggregate counts with jq. `success`, `skipped`, `neutral` are all "passing".
# Anything completed with another conclusion is a failure. Anything not yet
# completed is in_progress.
summary=$(echo "${checks_json}" | jq -r --argjson required_names "${required_json}" '
  def app_wildcard($app_id): $app_id == null or $app_id == -1;
  def check_matches($required):
    .name == $required.context and (app_wildcard($required.app_id) or .app_id == $required.app_id);
  def required_check_label:
    if app_wildcard(.app_id) then .context else "\(.context) (app_id: \(.app_id))" end;

  . as $all
  | {
      total: length,
      passed: [.[] | select(.status == "completed" and (.conclusion | IN("success", "skipped", "neutral")))] | length,
      failed: [.[] | select(.status == "completed" and (.conclusion | IN("success", "skipped", "neutral") | not))],
      in_progress: [.[] | select(.status != "completed")],
      missing_required: (
        if $required_names == null then []
        else
          # NOTE: legacy contexts are intentionally app-agnostic here. Commit
          # statuses are not fetched here; this hook is a fail-open display
          # tool. The Ruby release gate owns app-pinned legacy enforcement.
          (($required_names.contexts // [])
            | map(select(. as $context | ($all | any(.name == $context) | not))))
          +
          (($required_names.checks // [])
            | map(select(. as $required | ($all | any(check_matches($required)) | not)))
            | map(required_check_label))
        end
      )
    }
  | "TOTAL=\(.total)",
    "PASSED=\(.passed)",
    "FAILED_COUNT=\(.failed | length)",
    "IN_PROGRESS_COUNT=\(.in_progress | length)",
    "MISSING_REQUIRED_COUNT=\(.missing_required | length)",
    (.failed[] | "FAILED_LINE=" + .name + " — " + (.conclusion // "incomplete") + " — " + (.html_url // "")),
    (.in_progress[] | "INPROGRESS_LINE=" + .name + " — " + (.status // "in_progress") + " — " + (.html_url // "")),
    (.missing_required[] | "MISSING_REQUIRED_LINE=" + .)
') || fail_open "jq summary failed"

short_sha="${head_sha:0:8}"
total=$(echo "${summary}" | grep "^TOTAL=" | cut -d= -f2)
passed=$(echo "${summary}" | grep "^PASSED=" | cut -d= -f2)
failed_count=$(echo "${summary}" | grep "^FAILED_COUNT=" | cut -d= -f2)
in_progress_count=$(echo "${summary}" | grep "^IN_PROGRESS_COUNT=" | cut -d= -f2)
missing_required_count=$(echo "${summary}" | grep "^MISSING_REQUIRED_COUNT=" | cut -d= -f2)
# Default to 0 when the parse step produced no line (partial-output edge case).
# The `total=0` branch below already covers the all-empty case, but a defensive
# default here keeps `[ "${failed_count}" -gt 0 ]` from silently failing.
: "${failed_count:=0}" "${in_progress_count:=0}" "${missing_required_count:=0}"

# Build the output as a single string, then atomically swap it into the cache
# so a concurrent reader never sees a half-written file.
if [ "${total:-0}" = "0" ]; then
  # No check runs visible for this commit. The Checks API may simply not have
  # registered any workflows yet (right after a push), or all workflows were
  # filtered out by paths-ignore. Either way, the agent should NOT read this
  # as "all green" — say so explicitly. The release gate treats the same case
  # as a blocking violation; aligning the wording here keeps the two signals
  # honest.
  output=$(printf 'Main CI status (origin/main %s): no check runs visible yet.\n  CI may not have started for this commit, or the Checks API is unavailable.\n  See: https://github.com/%s/commit/%s/checks\n' \
    "${short_sha}" "${repo_slug}" "${head_sha}")
else
  output=$(
    printf 'Main CI status (origin/main %s):\n' "${short_sha}"
    printf '  Total: %s | Passed: %s | Failed: %s | In progress: %s | Required missing: %s\n' \
      "${total}" "${passed}" "${failed_count}" "${in_progress_count}" "${missing_required_count}"

    if [ "${failed_count}" -gt 0 ]; then
      echo "  Failures:"
      echo "${summary}" | grep "^FAILED_LINE=" | sed 's/^FAILED_LINE=/    - /'
    fi

    if [ "${in_progress_count}" -gt 0 ]; then
      echo "  In progress:"
      echo "${summary}" | grep "^INPROGRESS_LINE=" | sed 's/^INPROGRESS_LINE=/    - /'
    fi

    if [ "${missing_required_count}" -gt 0 ]; then
      echo "  Missing required checks:"
      echo "${summary}" | grep "^MISSING_REQUIRED_LINE=" | sed 's/^MISSING_REQUIRED_LINE=/    - /'
    fi

    if [ "${failed_count}" -gt 0 ] || [ "${in_progress_count}" -gt 0 ] || [ "${missing_required_count}" -gt 0 ]; then
      echo "  See: https://github.com/${repo_slug}/commit/${head_sha}/checks"
    fi
  )
fi

# If the cache write itself fails (filesystem full, .claude/ read-only,
# interrupted mv), still emit the computed status — we already spent a
# full API round-trip on it and discarding the result just because the
# cache was unwritable is worse than not caching. The `\n` here matches
# write_cache_atomic's normal output path so the printed status block
# never glues onto the next shell prompt.
write_cache_atomic "${output}" || { printf '%s\n' "${output}"; exit 0; }

exit 0
