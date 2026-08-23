#!/usr/bin/env bash
# Test harness for script/ci-required-diff-base.
#
# Run: bash script/ci-required-diff-base-test.bash
# CI invokes it from the "Run CI gate tests" step of the same workflow.
#
# The real script is executed against a synthetic repository, so the logic under
# test is exactly the logic that ships.
#
# script/ci-changes-detector is stubbed here. Its own behavior is covered by
# script/ci-changes-detector-test.bash; what this harness pins down is which base
# ref the step hands it, and that the step survives a large changed-file list.
#
# Cases are run under `bash --noprofile --norc -eo pipefail`, the exact shell
# GitHub Actions uses for run: steps. The pipefail part is load-bearing: it is
# what turned a truncating pipe into a hard failure of this required gate.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIFF_BASE_SCRIPT="$REPO_ROOT/script/ci-required-diff-base"
WORKFLOW="$REPO_ROOT/.github/workflows/ci-required.yml"

TESTS_RUN=0
TESTS_FAILED=0
FAILURES=()

LAST_OUTPUT=""
LAST_RC=0

fail() {
  local message="$1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES+=("$message")
  echo "  FAIL: $message" >&2
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"

  case "$haystack" in
    *"$needle"*) ;;
    *) fail "$label: expected '$needle' in: $haystack" ;;
  esac
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"

  case "$haystack" in
    *"$needle"*) fail "$label: did not expect '$needle' in: $haystack" ;;
    *) ;;
  esac
}

assert_rc() {
  local expected="$1"
  local label="$2"

  if [ "$LAST_RC" -ne "$expected" ]; then
    fail "$label: expected exit $expected, got $LAST_RC. Output: $LAST_OUTPUT"
  fi
}

WORKDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

REPO="$WORKDIR/repo"

if [ ! -x "$DIFF_BASE_SCRIPT" ]; then
  echo "FAIL: executable diff-base script not found at $DIFF_BASE_SCRIPT" >&2
  exit 1
fi

test_workflow_wiring() {
  local wiring_output

  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> workflow delegates changed-file detection to the helper"

  if ! wiring_output="$(ruby -ryaml - "$WORKFLOW" 2>&1 <<'RUBY'
workflow = YAML.safe_load_file(ARGV.fetch(0), permitted_classes: [], aliases: false)
steps = workflow.fetch("jobs").fetch("required-pr-gate").fetch("steps")
matching_steps = steps.select { |step| step["name"] == "Run changed-files detector" }

abort "expected exactly one Run changed-files detector step, found #{matching_steps.length}" unless matching_steps.length == 1

step = matching_steps.fetch(0)
expected_env = {
  "PULL_REQUEST_BASE_SHA" => %q(${{ github.event.inputs.pull_request_base_sha || '' }}),
  "PULL_REQUEST_HEAD_SHA" => %q(${{ github.event.pull_request.head.sha || '' }}),
  "EVENT_BASE_REF" => %q(${{ github.event.pull_request.base.sha || github.event.merge_group.base_sha || github.event.before || 'origin/main' }}),
}

abort "expected id=changes, got #{step['id'].inspect}" unless step["id"] == "changes"
abort "expected run=script/ci-required-diff-base, got #{step['run'].inspect}" unless step["run"] == "script/ci-required-diff-base"
abort "helper env bindings changed: #{step['env'].inspect}" unless step["env"] == expected_env
RUBY
  )"; then
    fail "workflow wiring: $wiring_output"
  fi
}

test_workflow_wiring

git init -q "$REPO"
mkdir -p "$REPO/script"

cat > "$REPO/script/ci-changes-detector" <<'STUB'
#!/usr/bin/env bash
# Stub standing in for the real detector: record the base ref it was handed.
echo "DETECTOR_BASE=$1"
STUB
chmod +x "$REPO/script/ci-changes-detector"

git_commit() {
  git -C "$REPO" -c user.name=ci-test -c user.email=ci-test@example.com \
    commit -q --no-verify "$@"
}

git -C "$REPO" checkout -q -b main
git -C "$REPO" add script/ci-changes-detector
git_commit -m "Add detector stub"

echo "old" > "$REPO/older.txt"
git -C "$REPO" add older.txt
git_commit -m "Older main commit"
OLD_MAIN="$(git -C "$REPO" rev-parse HEAD)"

echo "new" > "$REPO/newer.txt"
git -C "$REPO" add newer.txt
git_commit -m "Newer main commit"
MAIN_TIP="$(git -C "$REPO" rev-parse HEAD)"

# A docs-only PR branch, cut from the OLDER main commit. OLD_MAIN stands in for a
# pull_request.base.sha that has gone stale while main moved on.
git -C "$REPO" checkout -q -b docs "$OLD_MAIN"
echo "docs" > "$REPO/docs.md"
git -C "$REPO" add docs.md
git_commit -m "Docs-only change"
PR_HEAD="$(git -C "$REPO" rev-parse HEAD)"

# Stand-in for refs/pull/<n>/merge: first parent is the base side, second is the
# PR head. This is the shape actions/checkout puts in HEAD for pull_request.
git -C "$REPO" checkout -q main
git -C "$REPO" -c user.name=ci-test -c user.email=ci-test@example.com \
  merge -q --no-ff -m "Merge docs into main" "$PR_HEAD"
MERGE_REF="$(git -C "$REPO" rev-parse HEAD)"

# A newer PR head that landed after the merge ref was computed. Nothing merges it,
# so MERGE_REF's tree cannot contain its file. This is the stale-merge-ref race:
# the event reports this head while the checkout still holds the older merge.
git -C "$REPO" checkout -q docs
echo "added later" > "$REPO/added-after-merge-ref.txt"
git -C "$REPO" add added-after-merge-ref.txt
git_commit -m "Change present only in the newer PR head"
NEW_PR_HEAD="$(git -C "$REPO" rev-parse HEAD)"
git -C "$REPO" checkout -q main

# A second merge ref carrying a large changed-file list, for the truncation case.
# The names are long on purpose: the whole list has to exceed the 64KB pipe buffer
# for an early-closing reader to be able to break the step.
git -C "$REPO" checkout -q -b big "$MERGE_REF"
mkdir -p "$REPO/bigdir"
long_name="a-deliberately-long-path-segment-to-exceed-the-pipe-buffer-quickly"
seq 1 3000 | while read -r index; do
  printf '%s/bigdir/%s-%05d.txt\n' "$REPO" "$long_name" "$index"
done | xargs touch
git -C "$REPO" add -A
git_commit -m "Large changed-file list"
BIG_HEAD="$(git -C "$REPO" rev-parse HEAD)"

git -C "$REPO" checkout -q main
git -C "$REPO" -c user.name=ci-test -c user.email=ci-test@example.com \
  merge -q --no-ff -m "Merge big into main" "$BIG_HEAD"
BIG_MERGE_REF="$(git -C "$REPO" rev-parse HEAD)"

run_case() {
  local name="$1"
  local head="$2"
  local event_name="$3"
  local dispatch_base_sha="$4"
  local pr_head_sha="$5"
  local event_base_ref="$6"

  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> $name"

  git -C "$REPO" checkout -q --detach "$head"

  LAST_OUTPUT="$(
    cd "$REPO" || exit 1
    CI=1 \
      GITHUB_EVENT_NAME="$event_name" \
      GITHUB_OUTPUT="$WORKDIR/github-output.txt" \
      PULL_REQUEST_BASE_SHA="$dispatch_base_sha" \
      PULL_REQUEST_HEAD_SHA="$pr_head_sha" \
      EVENT_BASE_REF="$event_base_ref" \
      bash --noprofile --norc -eo pipefail "$DIFF_BASE_SCRIPT" 2>&1
  )"
  LAST_RC=$?
}

run_case "current merge ref uses the first parent" \
  "$MERGE_REF" pull_request "" "$PR_HEAD" "$OLD_MAIN"
assert_rc 0 "current merge ref"
assert_contains "$LAST_OUTPUT" "Diff base: $MAIN_TIP (source: PR merge commit first parent)" "current merge ref"
assert_contains "$LAST_OUTPUT" "DETECTOR_BASE=$MAIN_TIP" "current merge ref"
assert_contains "$LAST_OUTPUT" "docs.md" "current merge ref"
# The whole point of the fix: main's own drift must not enter the diff.
assert_not_contains "$LAST_OUTPUT" "newer.txt" "current merge ref"

# Regression guard for the under-selection hazard, which is the sharpest edge in
# this step. When the merge ref is stale, HEAD's tree does not contain the current
# head's changes, so NO choice of base can classify them: every base is diffed
# against a tree that is already missing them. Widening the base does not help.
# The step must refuse to classify rather than emit a confident, incomplete answer
# that could let a generator change through this required gate.
#
# NEW_PR_HEAD below is deliberately not reachable from MERGE_REF, which is exactly
# the shape of the race this guards against.
run_case "stale merge ref fails closed" \
  "$MERGE_REF" pull_request "" "$NEW_PR_HEAD" "$OLD_MAIN"
assert_rc 1 "stale merge ref"
assert_contains "$LAST_OUTPUT" "::error::" "stale merge ref"
assert_contains "$LAST_OUTPUT" "GitHub's merge ref is stale" "stale merge ref"
assert_contains "$LAST_OUTPUT" "Re-run this job" "stale merge ref"
# It must not hand any base to the detector once it knows the tree is wrong.
assert_not_contains "$LAST_OUTPUT" "DETECTOR_BASE=" "stale merge ref"

# Demonstrates WHY widening the base is not a fix: the file added in the current
# head simply is not in HEAD's tree, so it cannot appear in any diff taken here.
missing_from_stale_head="$(git -C "$REPO" diff --name-only "$OLD_MAIN" "$MERGE_REF" | grep -c 'added-after-merge-ref.txt')"
if [ "$missing_from_stale_head" -ne 0 ]; then
  fail "stale merge ref: expected the newer head's file to be absent from the widest diff against the stale HEAD"
fi

# A single-parent HEAD must never take HEAD^1: there it is the PR's own previous
# commit rather than the base branch. Unlike the stale-merge-ref case there is no
# better base available, so warn and continue.
run_case "single-parent HEAD keeps the event base" \
  "$PR_HEAD" pull_request "" "$PR_HEAD" "$OLD_MAIN"
assert_rc 0 "single-parent HEAD"
assert_contains "$LAST_OUTPUT" "Diff base: $OLD_MAIN (source: event payload)" "single-parent HEAD"
assert_contains "$LAST_OUTPUT" "not the expected two-parent PR merge commit" "single-parent HEAD"

run_case "workflow_dispatch input wins" \
  "$MERGE_REF" workflow_dispatch "$OLD_MAIN" "$PR_HEAD" "$MAIN_TIP"
assert_rc 0 "workflow_dispatch input"
assert_contains "$LAST_OUTPUT" "Diff base: $OLD_MAIN (source: workflow_dispatch input)" "workflow_dispatch input"

# merge_group must keep diffing from the merge queue base SHA it is handed. This
# mirrors the contract asserted in
# react_on_rails/spec/react_on_rails/ruby_version_support_spec.rb.
run_case "merge_group keeps the event base" \
  "$MERGE_REF" merge_group "" "" "$OLD_MAIN"
assert_rc 0 "merge_group"
assert_contains "$LAST_OUTPUT" "Diff base: $OLD_MAIN (source: event payload)" "merge_group"
assert_not_contains "$LAST_OUTPUT" "source: PR merge commit first parent" "merge_group"

# Exercise the helper's guarded changed-file listing directly. The shim delegates
# every other git invocation, including merge-base, to the captured real binary.
REAL_GIT="$(command -v git)"
GIT_SHIM_DIR="$WORKDIR/git-shim"
mkdir -p "$GIT_SHIM_DIR"
cat > "$GIT_SHIM_DIR/git" <<'SHIM'
#!/usr/bin/env bash
if [ "${1:-}" = "diff" ] && [ "${2:-}" = "--name-only" ]; then
  exit 1
fi
exec "${REAL_GIT:?}" "$@"
SHIM
chmod +x "$GIT_SHIM_DIR/git"

BASH_ENV=/dev/null \
  PATH="$GIT_SHIM_DIR:$PATH" \
  REAL_GIT="$REAL_GIT" \
  run_case "changed-file listing failure names the diff refs" \
  "$MERGE_REF" merge_group "" "" "$OLD_MAIN"
assert_rc 1 "changed-file listing failure"
assert_contains "$LAST_OUTPUT" \
  "::error::git diff failed for $OLD_MAIN..HEAD while listing changed files." \
  "changed-file listing failure"

# Regression guard for the truncation pipe. Under pipefail an early-closing reader
# makes git exit 141 and takes the whole required gate down with it.
run_case "large changed-file list does not abort the step" \
  "$BIG_MERGE_REF" pull_request "" "$BIG_HEAD" "$OLD_MAIN"
assert_rc 0 "large changed-file list"
assert_contains "$LAST_OUTPUT" "3000 total, showing up to 50" "large changed-file list"

printed_files="$(printf '%s\n' "$LAST_OUTPUT" | grep -c "bigdir/${long_name}-")"
if [ "$printed_files" -ne 50 ]; then
  fail "large changed-file list: expected 50 printed paths, got $printed_files"
fi

echo
if [ "$TESTS_FAILED" -ne 0 ]; then
  echo "$TESTS_FAILED of $TESTS_RUN diff-base tests failed" >&2
  for failure in "${FAILURES[@]}"; do
    echo "  - $failure" >&2
  done
  exit 1
fi

echo "$TESTS_RUN diff-base tests passed"
