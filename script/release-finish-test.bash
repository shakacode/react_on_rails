#!/usr/bin/env bash
# Test harness for script/release-finish. Requires bash and git. Run with
# `bash script/release-finish-test.bash`.
#
# Every case runs against a throwaway `mktemp -d` git repo and exercises only the
# dry-run output and the guard/abort paths. NOTHING here runs a real release,
# branch deletion, or push: promote stops at the rake-release confirmation under
# dry-run, and close-out only invokes the forward-port DRY-RUN plan plus printed
# branch-deletion. The harness never adds a network remote.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_FINISH="$SCRIPT_DIR/release-finish"

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
FAILURES=()

fail() {
  local message="$1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES+=("$CURRENT_TEST: $message")
  if [ -n "${SUBSHELL_FAILURES_FILE:-}" ]; then
    printf '%s\n' "$CURRENT_TEST: $message" >> "$SUBSHELL_FAILURES_FILE"
  fi
  echo "  FAIL: $message" >&2
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="${3:-output}"
  case "$haystack" in
    *"$needle"*) ;;
    *)
      fail "$label: expected to contain '$needle', got '$haystack'"
      return 1
      ;;
  esac
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="${3:-output}"
  case "$haystack" in
    *"$needle"*)
      fail "$label: expected NOT to contain '$needle', got '$haystack'"
      return 1
      ;;
    *) ;;
  esac
}

assert_status() {
  local expected="$1"
  local actual="$2"
  local label="${3:-status}"
  if [ "$expected" != "$actual" ]; then
    fail "$label: expected exit $expected, got $actual"
    return 1
  fi
}

run_test() {
  local test_fn="$1"
  CURRENT_TEST="$test_fn"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> $test_fn"

  local tmpdir before_failed had_errexit=false subshell_failures
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/release-finish-test.XXXXXX")"
  subshell_failures="$tmpdir/failures.log"
  : > "$subshell_failures"
  before_failed="$TESTS_FAILED"

  case "$-" in
    *e*) had_errexit=true ;;
  esac

  set +e
  (
    set -uo pipefail
    SUBSHELL_FAILURES_FILE="$subshell_failures"
    export SUBSHELL_FAILURES_FILE
    cd "$tmpdir" || exit 1
    "$test_fn"
  )
  local rc=$?
  if [ "$had_errexit" = true ]; then
    set -e
  fi

  if [ -s "$subshell_failures" ]; then
    while IFS= read -r failure_line; do
      [ -n "$failure_line" ] || continue
      TESTS_FAILED=$((TESTS_FAILED + 1))
      FAILURES+=("$failure_line")
    done < "$subshell_failures"
  fi
  rm -rf "$tmpdir"

  if [ "$rc" -ne 0 ] && [ "$TESTS_FAILED" -eq "$before_failed" ]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES+=("$CURRENT_TEST: subshell exited $rc (see stderr above for details)")
    echo "  FAIL: subshell exited $rc" >&2
  fi
}

# Build a throwaway repo that looks like a release line: main with a version
# file, a release/X.Y.Z branch carrying a fix and a vX.Y.Z.rc.N tag, and a local
# "origin" remote that is a SEPARATE throwaway clone in the same tmp tree, so
# `git fetch origin` and the forward-port `origin/release/X.Y.Z` ref resolve with
# no network. The remote is a local bare repo: a real `git push` would only ever
# touch that throwaway, never a network remote — and these tests never reach an
# unguarded push anyway.
setup_release_repo() {
  local origin_dir="$PWD/origin.git"
  git init -q --bare "$origin_dir"

  git init -q -b main work
  cd work || exit 1
  git config user.email test@example.com
  git config user.name "Release Finish Test"
  git remote add origin "$origin_dir"

  mkdir -p react_on_rails/lib/react_on_rails
  printf 'module ReactOnRails\n  VERSION = "1.0.0"\nend\n' > react_on_rails/lib/react_on_rails/version.rb
  printf 'core\n' > app.txt
  printf '## [Unreleased]\n\n## [1.0.0.rc.0]\n- Fix something\n' > CHANGELOG.md
  git add .
  git commit -qm "beta work"
  git push -q origin main

  git checkout -q -b release/1.0.0
  printf 'fix\n' > fix.txt
  git add .
  git commit -qm "Fix SSR regression"
  git tag v1.0.0.rc.0
  git push -q origin release/1.0.0

  # Refresh remote-tracking refs (origin/main, origin/release/1.0.0) so the
  # forward-port dry-run resolves the source even when our own --dry-run prints
  # the `git fetch` instead of running it.
  git fetch -q origin
  # Leave the operator checked out on the release branch (promote's starting point).
}

# Run release-finish with stdin closed (no TTY), capturing combined output.
# Returns the exit status in RF_STATUS and output in RF_OUT.
run_rf() {
  RF_OUT="$(ruby "$RELEASE_FINISH" "$@" </dev/null 2>&1)"
  RF_STATUS=$?
}

# --- promote: happy-path dry-run -------------------------------------------

test_promote_dry_run_prints_commands_and_runs_nothing() {
  setup_release_repo
  run_rf promote 1.0.0 --dry-run

  assert_status 0 "$RF_STATUS" "promote dry-run status"
  assert_contains "$RF_OUT" "Promote 1.0.0 (runbook step 4)" "promote dry-run"
  assert_contains "$RF_OUT" "Resolved accepted RC tag: v1.0.0.rc.0" "promote dry-run"
  assert_contains "$RF_OUT" 'DRY RUN: would run: bundle exec rake release[1.0.0]' "promote dry-run"
  assert_contains "$RF_OUT" "update-changelog release" "promote dry-run"
  assert_contains "$RF_OUT" "nothing was executed" "promote dry-run"
}

# The dry-run must never tag, publish, or otherwise mutate the repo.
test_promote_dry_run_does_not_execute_release() {
  setup_release_repo
  local head_before
  head_before="$(git rev-parse HEAD)"
  run_rf promote 1.0.0 --dry-run

  assert_status 0 "$RF_STATUS" "promote dry-run no-op status"
  # Dry-run prints the fetch rather than running it (no real outward git ops).
  assert_contains "$RF_OUT" "DRY RUN: would run: git fetch origin" "promote dry-run should not really fetch"
  # No new v1.0.0 (final) tag, and HEAD unchanged.
  if git rev-parse -q --verify refs/tags/v1.0.0 >/dev/null 2>&1; then
    fail "promote dry-run created the final tag v1.0.0"
  fi
  assert_status "$head_before" "$(git rev-parse HEAD)" "promote dry-run HEAD unchanged"
}

# --- promote: explicit rc tag ----------------------------------------------

test_promote_accepts_explicit_rc_tag() {
  setup_release_repo
  run_rf promote 1.0.0 --rc-tag v1.0.0.rc.0 --dry-run

  assert_status 0 "$RF_STATUS" "promote explicit rc-tag status"
  assert_contains "$RF_OUT" 'DRY RUN: would run: bundle exec rake release[1.0.0]' "promote explicit rc-tag"
}

# --- promote: guard — wrong branch -----------------------------------------

test_promote_aborts_when_not_on_release_branch() {
  setup_release_repo
  git checkout -q main
  run_rf promote 1.0.0 --dry-run

  assert_status 1 "$RF_STATUS" "promote wrong-branch status"
  assert_contains "$RF_OUT" "not on release/1.0.0" "promote wrong-branch"
  assert_not_contains "$RF_OUT" "rake release[1.0.0]" "promote wrong-branch should stop before release"
}

# --- promote: guard — drifted tip ------------------------------------------

test_promote_aborts_when_tip_drifted_from_rc_tag() {
  setup_release_repo
  # Add a commit after the rc tag so the tip no longer matches v1.0.0.rc.0.
  printf 'drift\n' > drift.txt
  git add .
  git commit -qm "post-rc drift"
  run_rf promote 1.0.0 --dry-run

  assert_status 1 "$RF_STATUS" "promote drift status"
  assert_contains "$RF_OUT" "has drifted from the accepted RC tag v1.0.0.rc.0" "promote drift"
  assert_not_contains "$RF_OUT" "would run: bundle exec rake release" "promote drift should stop before release"
}

# --- promote: guard — dirty tree -------------------------------------------

test_promote_aborts_on_dirty_worktree() {
  setup_release_repo
  printf 'dirty\n' >> fix.txt
  run_rf promote 1.0.0 --dry-run

  assert_status 1 "$RF_STATUS" "promote dirty status"
  assert_contains "$RF_OUT" "working tree is not clean" "promote dirty"
}

# --- promote: guard — missing rc tag ---------------------------------------

test_promote_aborts_when_no_rc_tag_found() {
  setup_release_repo
  git tag -d v1.0.0.rc.0 >/dev/null
  run_rf promote 1.0.0 --dry-run

  assert_status 1 "$RF_STATUS" "promote missing-tag status"
  assert_contains "$RF_OUT" "no vX.Y.Z.rc.N tag found for 1.0.0" "promote missing-tag"
}

test_promote_aborts_when_explicit_rc_tag_absent() {
  setup_release_repo
  run_rf promote 1.0.0 --rc-tag v1.0.0.rc.9 --dry-run

  assert_status 1 "$RF_STATUS" "promote bad explicit tag status"
  assert_contains "$RF_OUT" "v1.0.0.rc.9 does not exist" "promote bad explicit tag"
}

# Highest rc index wins when several rc tags exist.
test_promote_selects_highest_rc_tag() {
  setup_release_repo
  git tag v1.0.0.rc.1
  git tag v1.0.0.rc.2
  run_rf promote 1.0.0 --dry-run

  assert_status 0 "$RF_STATUS" "promote highest-rc status"
  assert_contains "$RF_OUT" "Resolved accepted RC tag: v1.0.0.rc.2" "promote highest-rc"
}

# --- promote: confirmation safety (no --yes, no TTY) ------------------------

# Without --dry-run and without a TTY, an outward op (the rake release) must NOT
# run: confirm? aborts because there is no TTY and --yes was not given. This is
# the guard that keeps `rake release` from ever firing unattended.
test_promote_without_tty_and_without_yes_aborts_before_release() {
  setup_release_repo
  run_rf promote 1.0.0

  assert_status 1 "$RF_STATUS" "promote no-tty status"
  assert_contains "$RF_OUT" "no TTY for confirmation" "promote no-tty"
  # Real promotion never happened: no final tag.
  if git rev-parse -q --verify refs/tags/v1.0.0 >/dev/null 2>&1; then
    fail "promote without TTY created the final tag v1.0.0"
  fi
}

# --- close-out: happy-path dry-run -----------------------------------------

test_close_out_dry_run_prints_plan_and_runs_nothing() {
  setup_release_repo
  git checkout -q main
  run_rf close-out 1.0.0 --dry-run

  assert_status 0 "$RF_STATUS" "close-out dry-run status"
  assert_contains "$RF_OUT" "Close out 1.0.0 (runbook step 5)" "close-out dry-run"
  # The real forward-port DRY-RUN plan is shown (it resolves origin/release/1.0.0).
  assert_contains "$RF_OUT" "Release forward-port plan" "close-out dry-run"
  assert_contains "$RF_OUT" "PICK" "close-out dry-run picks the fix"
  assert_contains "$RF_OUT" 'DRY RUN: would run: git push origin --delete release/1.0.0' "close-out dry-run"
  assert_contains "$RF_OUT" "nothing was executed" "close-out dry-run"
}

# The forward-port plan must exclude rc version-bump style commits; here it only
# picks the real fix, never the branch deletion is executed.
test_close_out_dry_run_does_not_delete_branch() {
  setup_release_repo
  git checkout -q main
  run_rf close-out 1.0.0 --dry-run

  assert_status 0 "$RF_STATUS" "close-out no-delete status"
  # origin ref for the release branch is still present after a dry-run.
  if ! git rev-parse -q --verify refs/remotes/origin/release/1.0.0 >/dev/null 2>&1; then
    fail "close-out dry-run removed the origin release ref"
  fi
}

# --- close-out: guard — not on main ----------------------------------------

test_close_out_aborts_when_not_on_main() {
  setup_release_repo
  # Still on release/1.0.0 from setup.
  run_rf close-out 1.0.0 --dry-run

  assert_status 1 "$RF_STATUS" "close-out wrong-branch status"
  assert_contains "$RF_OUT" "not on main" "close-out wrong-branch"
}

# --- close-out: guard — dirty tree -----------------------------------------

test_close_out_aborts_on_dirty_worktree() {
  setup_release_repo
  git checkout -q main
  printf 'dirty\n' >> app.txt
  run_rf close-out 1.0.0 --dry-run

  assert_status 1 "$RF_STATUS" "close-out dirty status"
  assert_contains "$RF_OUT" "working tree is not clean" "close-out dirty"
}

# --- shared: argument validation -------------------------------------------

test_rejects_rc_version_argument() {
  setup_release_repo
  run_rf promote 1.0.0.rc.1 --dry-run

  assert_status 2 "$RF_STATUS" "rc-version-arg status"
  assert_contains "$RF_OUT" "version must be a stable X.Y.Z" "rc-version-arg"
}

test_rejects_missing_version() {
  setup_release_repo
  run_rf promote --dry-run

  assert_status 2 "$RF_STATUS" "missing-version status"
  assert_contains "$RF_OUT" "version X.Y.Z is required" "missing-version"
}

test_rejects_unknown_subcommand() {
  setup_release_repo
  run_rf ship 1.0.0

  assert_status 2 "$RF_STATUS" "unknown-subcommand status"
  assert_contains "$RF_OUT" "unknown subcommand" "unknown-subcommand"
}

test_help_exits_zero() {
  setup_release_repo
  run_rf --help

  assert_status 0 "$RF_STATUS" "help status"
  assert_contains "$RF_OUT" "Orchestrates the release-train runbook steps 4" "help"
}

run_test test_promote_dry_run_prints_commands_and_runs_nothing
run_test test_promote_dry_run_does_not_execute_release
run_test test_promote_accepts_explicit_rc_tag
run_test test_promote_aborts_when_not_on_release_branch
run_test test_promote_aborts_when_tip_drifted_from_rc_tag
run_test test_promote_aborts_on_dirty_worktree
run_test test_promote_aborts_when_no_rc_tag_found
run_test test_promote_aborts_when_explicit_rc_tag_absent
run_test test_promote_selects_highest_rc_tag
run_test test_promote_without_tty_and_without_yes_aborts_before_release
run_test test_close_out_dry_run_prints_plan_and_runs_nothing
run_test test_close_out_dry_run_does_not_delete_branch
run_test test_close_out_aborts_when_not_on_main
run_test test_close_out_aborts_on_dirty_worktree
run_test test_rejects_rc_version_argument
run_test test_rejects_missing_version
run_test test_rejects_unknown_subcommand
run_test test_help_exits_zero

echo
echo "release-finish tests: $TESTS_RUN run, $TESTS_FAILED failed"

if [ "$TESTS_FAILED" -ne 0 ]; then
  printf '\nFailures:\n' >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi
