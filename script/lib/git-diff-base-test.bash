#!/usr/bin/env bash
# Test harness for script/lib/git-diff-base. Self-contained: no extra binaries
# beyond bash + git. Run from anywhere with `bash script/lib/git-diff-base-test.bash`.
# Exits 0 on success, 1 on first failure (per-test); reports pass/fail counts.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=script/lib/git-diff-base
source "$SCRIPT_DIR/git-diff-base"

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
FAILURES=()

# Helper: report a failure with context and continue the suite.
fail() {
  local message="$1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES+=("$CURRENT_TEST: $message")
  echo "  FAIL: $message" >&2
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local label="${3:-value}"
  if [ "$expected" != "$actual" ]; then
    fail "$label: expected '$expected', got '$actual'"
    return 1
  fi
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

# Run a single test function in a subshell so its env vars, cwd, and any
# accidental state leakage stay isolated from the rest of the suite.
run_test() {
  local test_fn="$1"
  CURRENT_TEST="$test_fn"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "→ $test_fn"

  local tmpdir
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/git-diff-base-test.XXXXXX")"
  local before_failed="$TESTS_FAILED"
  local had_errexit=false

  case "$-" in
    *e*)
      had_errexit=true
      ;;
  esac

  set +e
  (
    set -euo pipefail
    cd "$tmpdir" || exit 1
    "$test_fn"
  )
  local rc=$?
  if [ "$had_errexit" = true ]; then
    set -e
  fi
  rm -rf "$tmpdir"

  # The subshell runs assertions that increment TESTS_FAILED in the child
  # process only, so its non-zero exit is the signal we use to count failures
  # in the parent process below.
  if [ "$rc" -ne 0 ] && [ "$TESTS_FAILED" -eq "$before_failed" ]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES+=("$CURRENT_TEST: subshell exited $rc without explicit assertion failure")
    echo "  FAIL: subshell exited $rc" >&2
  fi
}

# ---------------------------------------------------------------------------
# Pure-function tests (no git repo required beyond cwd)
# ---------------------------------------------------------------------------

test_remote_branch_strips_origin_prefix() {
  local out
  out="$(git_diff_base_remote_branch "origin/main")" || { fail "command failed"; return 1; }
  assert_equals "main" "$out" "origin/main"

  out="$(git_diff_base_remote_branch "refs/remotes/origin/feature-x")" || { fail "command failed"; return 1; }
  assert_equals "feature-x" "$out" "refs/remotes/origin/feature-x"
}

test_remote_branch_rejects_non_origin() {
  if git_diff_base_remote_branch "main" 2>/dev/null; then
    fail "expected non-zero for bare branch name"
    return 1
  fi
  if git_diff_base_remote_branch "refs/heads/main" 2>/dev/null; then
    fail "expected non-zero for refs/heads/main"
    return 1
  fi
}

test_fetch_refspec_format() {
  local out
  out="$(git_diff_base_fetch_refspec "main")"
  assert_equals "+refs/heads/main:refs/remotes/origin/main" "$out" "main refspec"
}

test_fetch_depth_uses_default_when_unset() {
  local out
  out="$(GIT_DIFF_BASE_FETCH_DEPTH='' git_diff_base_fetch_depth 2>/dev/null)"
  assert_equals "50" "$out" "default depth"
}

test_fetch_depth_accepts_valid_env() {
  local out
  out="$(GIT_DIFF_BASE_FETCH_DEPTH=100 git_diff_base_fetch_depth 2>/dev/null)"
  assert_equals "100" "$out" "env-set depth"
}

test_fetch_depth_strips_whitespace() {
  local out
  out="$(GIT_DIFF_BASE_FETCH_DEPTH="  25  " git_diff_base_fetch_depth 2>/dev/null)"
  assert_equals "25" "$out" "padded depth"
}

test_fetch_depth_forces_base_10() {
  # "08" would be invalid octal under naive arithmetic; the parser should
  # accept it as decimal 8.
  local out
  out="$(GIT_DIFF_BASE_FETCH_DEPTH=08 git_diff_base_fetch_depth 2>/dev/null)"
  assert_equals "8" "$out" "leading-zero depth"
}

test_fetch_depth_warns_and_defaults_on_zero() {
  # mktemp into the per-test tmpdir (run_test's cwd) so files are unique and
  # swept up by run_test's rm -rf even when an assertion fails. /tmp/...$$
  # leaks on failure because $$ in a subshell is the parent PID.
  local out warning warn_file
  warn_file="$(mktemp depth-warn.XXXXXX)"
  out="$(GIT_DIFF_BASE_FETCH_DEPTH=0 git_diff_base_fetch_depth 2>"$warn_file")"
  warning="$(cat "$warn_file")"
  assert_equals "50" "$out" "fallback depth"
  assert_contains "$warning" "invalid fetch depth" "warning text"
}

test_fetch_depth_warns_and_defaults_on_garbage() {
  local out warning warn_file
  warn_file="$(mktemp depth-warn.XXXXXX)"
  out="$(GIT_DIFF_BASE_FETCH_DEPTH=abc git_diff_base_fetch_depth 2>"$warn_file")"
  warning="$(cat "$warn_file")"
  assert_equals "50" "$out" "fallback depth"
  assert_contains "$warning" "invalid fetch depth" "warning text"
}

test_max_attempts_uses_default_when_unset() {
  local out
  out="$(GIT_DIFF_BASE_MAX_ATTEMPTS='' git_diff_base_max_attempts 2>/dev/null)"
  assert_equals "8" "$out" "default attempts"
}

test_max_attempts_caps_at_30() {
  local out warning warn_file
  warn_file="$(mktemp cap-warn.XXXXXX)"
  out="$(GIT_DIFF_BASE_MAX_ATTEMPTS=99 git_diff_base_max_attempts 2>"$warn_file")"
  warning="$(cat "$warn_file")"
  assert_equals "30" "$out" "capped attempts"
  assert_contains "$warning" "exceeds cap" "cap warning"
}

test_max_attempts_warns_on_invalid() {
  local out warning warn_file
  warn_file="$(mktemp attempts-warn.XXXXXX)"
  out="$(GIT_DIFF_BASE_MAX_ATTEMPTS=foo git_diff_base_max_attempts 2>"$warn_file")"
  warning="$(cat "$warn_file")"
  assert_equals "8" "$out" "fallback attempts"
  assert_contains "$warning" "invalid GIT_DIFF_BASE_MAX_ATTEMPTS" "warning text"
}

test_unshallow_timeout_default() {
  local out
  out="$(GIT_DIFF_BASE_UNSHALLOW_TIMEOUT_SECONDS='' git_diff_base_unshallow_timeout_seconds 2>/dev/null)"
  assert_equals "300" "$out" "default timeout"
}

test_unshallow_timeout_accepts_zero() {
  local out
  out="$(GIT_DIFF_BASE_UNSHALLOW_TIMEOUT_SECONDS=0 git_diff_base_unshallow_timeout_seconds 2>/dev/null)"
  assert_equals "0" "$out" "zero timeout (disabled)"
}

test_unshallow_timeout_warns_on_invalid() {
  local out warning warn_file
  warn_file="$(mktemp timeout-warn.XXXXXX)"
  out="$(GIT_DIFF_BASE_UNSHALLOW_TIMEOUT_SECONDS=banana git_diff_base_unshallow_timeout_seconds 2>"$warn_file")"
  warning="$(cat "$warn_file")"
  assert_equals "300" "$out" "fallback timeout"
  assert_contains "$warning" "invalid GIT_DIFF_BASE_UNSHALLOW_TIMEOUT_SECONDS" "warning text"
}

test_run_test_counts_non_final_assertion_failure() {
  # This fixture is invoked indirectly by run_test. The final assertion is only
  # reachable if run_test stops running tests under set -e.
  # shellcheck disable=SC2329
  intentionally_fail_first_assertion_then_pass() {
    # shellcheck disable=SC2317
    assert_equals "expected" "actual" "intentional harness failure"
    # shellcheck disable=SC2317
    assert_equals "still-runs" "still-runs" "final assertion"
  }

  local before_run="$TESTS_RUN"
  local before_failed="$TESTS_FAILED"
  local before_failure_count="${#FAILURES[@]}"
  local out_file err_file
  out_file="$(mktemp harness-self-test-out.XXXXXX)"
  err_file="$(mktemp harness-self-test-err.XXXXXX)"

  run_test intentionally_fail_first_assertion_then_pass >"$out_file" 2>"$err_file"

  local observed_failed="$TESTS_FAILED"

  TESTS_RUN="$before_run"
  TESTS_FAILED="$before_failed"
  FAILURES=("${FAILURES[@]:0:before_failure_count}")

  if [ "$observed_failed" -le "$before_failed" ]; then
    fail "run_test did not count a non-final assertion failure"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Repo-required tests (use a small fixture in cwd / per-test tempdir)
# ---------------------------------------------------------------------------

# Build a minimal local "remote" + clone pair inside the current tempdir.
# After this returns, cwd is the clone repo with the named branches and refs.
setup_repo_fixture() {
  local clone_kind="${1:-full}"
  local depth="${2:-2}"

  git -c init.defaultBranch=main init --bare remote.git >/dev/null
  git -c init.defaultBranch=main init seed >/dev/null
  (
    cd seed || exit 1
    git config user.email "t@example.com"
    git config user.name "test"
    git commit --allow-empty -m "c1" >/dev/null
    git commit --allow-empty -m "c2" >/dev/null
    git commit --allow-empty -m "c3" >/dev/null
    git commit --allow-empty -m "c4" >/dev/null
    git commit --allow-empty -m "c5" >/dev/null
    git checkout -b feature >/dev/null 2>&1
    git commit --allow-empty -m "feat-1" >/dev/null
    git commit --allow-empty -m "feat-2" >/dev/null
    git checkout main >/dev/null 2>&1
    git remote add origin "$PWD/../remote.git"
    git push origin main feature >/dev/null 2>&1
  )

  if [ "$clone_kind" = "shallow" ]; then
    # git ignores --depth on local-path clones unless the URL uses file://,
    # so the shallow-clone fixtures must use the URL form to actually become
    # shallow. See: man git-clone, "LOCAL CLONES".
    git clone --depth "$depth" --branch feature "file://$PWD/remote.git" clone >/dev/null 2>&1
  else
    git clone "$PWD/remote.git" clone >/dev/null 2>&1
  fi
  cd clone || return 1
  git config user.email "t@example.com"
  git config user.name "test"
  # Clones default to fetching only the checked-out branch, so make sure the
  # base branch is also tracked locally for the deepen path tests.
  git fetch origin main:refs/remotes/origin/main >/dev/null 2>&1 || true
}

test_verify_ref_recognizes_existing_refs() {
  setup_repo_fixture full
  if ! git_diff_base_verify_ref HEAD; then
    fail "HEAD should verify in a non-empty repo"
    return 1
  fi
  if git_diff_base_verify_ref ""; then
    fail "empty ref must not verify"
    return 1
  fi
  if git_diff_base_verify_ref "definitely-not-a-ref-$$"; then
    fail "unknown ref must not verify"
    return 1
  fi
}

test_is_shallow_repository_detects_full_clone() {
  setup_repo_fixture full
  if git_diff_base_is_shallow_repository; then
    fail "full clone should not be marked shallow"
    return 1
  fi
}

test_is_shallow_repository_detects_shallow_clone() {
  setup_repo_fixture shallow 2
  if ! git_diff_base_is_shallow_repository; then
    fail "shallow clone should be marked shallow"
    return 1
  fi
}

test_sha_ref_classifies_full_length_sha() {
  setup_repo_fixture full
  local sha
  sha="$(git rev-parse HEAD)"
  if ! git_diff_base_sha_ref "$sha"; then
    fail "$sha should classify as a SHA"
    return 1
  fi
}

test_sha_ref_rejects_existing_branch_name() {
  setup_repo_fixture full
  # "main" is hex-empty (not all hex), so it fails on the character class first;
  # but "feature" likewise fails. We need a hex-only branch name to exercise the
  # branch-vs-SHA disambiguation, so create one.
  git branch deadbeef >/dev/null 2>&1
  if git_diff_base_sha_ref "deadbeef" 2>/dev/null; then
    fail "hex branch name should not classify as a SHA"
    return 1
  fi
}

test_sha_ref_rejects_non_hex_strings() {
  setup_repo_fixture full
  if git_diff_base_sha_ref "main" 2>/dev/null; then
    fail "main is not a hex string"
    return 1
  fi
  if git_diff_base_sha_ref "" 2>/dev/null; then
    fail "empty string is not a SHA"
    return 1
  fi
}

test_resolve_full_clone_happy_path() {
  setup_repo_fixture full
  git checkout feature >/dev/null 2>&1
  local out err_file
  err_file="$(mktemp resolve-err.XXXXXX)"
  if ! out="$(git_diff_base_resolve "origin/main" "HEAD" strict 2>"$err_file")"; then
    fail "resolve failed; stderr was: $(cat "$err_file")"
    return 1
  fi
  local expected
  expected="$(git rev-parse origin/main)"
  assert_equals "$expected" "$out" "merge base SHA"
}

test_resolve_rejects_invalid_policy() {
  setup_repo_fixture full
  local err
  err="$(git_diff_base_resolve "origin/main" "HEAD" yolo 2>&1)" && {
    fail "expected non-zero exit for invalid policy"
    return 1
  }
  assert_contains "$err" "unknown initial fetch policy 'yolo'" "policy error message"
}

test_resolve_shallow_deepens_to_find_merge_base() {
  setup_repo_fixture shallow 1
  # Without deepening, feature only sees its own tip; main is far enough back
  # that the merge base requires history beyond the shallow boundary.
  local out err_file
  err_file="$(mktemp resolve-err.XXXXXX)"
  if ! out="$(GIT_DIFF_BASE_FETCH_DEPTH=2 GIT_DIFF_BASE_MAX_ATTEMPTS=8 \
      git_diff_base_resolve "origin/main" "HEAD" strict 2>"$err_file")"; then
    fail "resolve failed in shallow clone; stderr was: $(cat "$err_file")"
    return 1
  fi
  # Sanity check: the returned SHA must at least be a real commit object now.
  if ! git cat-file -e "$out^{commit}" 2>/dev/null; then
    fail "deepen path returned non-commit '$out'"
    return 1
  fi
}

test_resolve_full_clone_missing_base_ref_errors() {
  setup_repo_fixture full
  local err
  err="$(git_diff_base_resolve "origin/does-not-exist" "HEAD" strict 2>&1)" && {
    fail "expected non-zero exit for missing base ref"
    return 1
  }
  # In a full clone the unshallow fetch becomes a plain fetch and reports the
  # error from origin; either of two messages is acceptable depending on git
  # version, so look for the shared "fetch" + base ref words.
  assert_contains "$err" "does-not-exist" "error mentions missing ref"
}

test_resolve_lenient_continues_after_initial_fetch_failure() {
  # check-docs-sidebar uses the lenient policy so a failed initial fetch (e.g.,
  # transient network blip) does not abort when local cached history already
  # contains the merge base. setup_repo_fixture shallow 3 keeps is_shallow=true
  # but pulls enough history that origin/main + feat-2 share an ancestor in
  # the cached refs. Breaking the origin URL forces the initial fetch to fail
  # so the lenient-only continuation path is exercised.
  setup_repo_fixture shallow 3
  git remote set-url origin "file:///nonexistent-repo"
  local out err_file
  err_file="$(mktemp resolve-err.XXXXXX)"
  if ! out="$(git_diff_base_resolve "origin/main" "HEAD" lenient 2>"$err_file")"; then
    fail "lenient policy should succeed with cached history; stderr was: $(cat "$err_file")"
    return 1
  fi
  if ! git cat-file -e "$out^{commit}" 2>/dev/null; then
    fail "lenient path returned non-commit '$out'"
    return 1
  fi
}

test_resolve_cross_repo_sha_hint_appears() {
  # The hint only fires from the bottom of git_diff_base_resolve after the
  # deepen+unshallow loop has run. To exercise that path, the clone must be
  # shallow (so the loop runs) and a current_remote_branch must be discoverable
  # (otherwise the early-fail at the top short-circuits with a different
  # message). GITHUB_HEAD_REF supplies the latter without needing a real
  # tracking branch.
  setup_repo_fixture shallow 1
  local fake_sha="0000000000000000000000000000000000000001"
  local err
  err="$( \
    GITHUB_HEAD_REF=feature \
    GIT_DIFF_BASE_FETCH_DEPTH=2 \
    GIT_DIFF_BASE_MAX_ATTEMPTS=1 \
    GIT_DIFF_BASE_UNSHALLOW_TIMEOUT_SECONDS=10 \
    git_diff_base_resolve "$fake_sha" "HEAD" strict 2>&1 1>/dev/null \
  )" && {
    fail "expected non-zero exit for foreign SHA"
    return 1
  }
  assert_contains "$err" "different repository" "cross-repo hint"
}

# ---------------------------------------------------------------------------
# Suite runner
# ---------------------------------------------------------------------------

ALL_TESTS=(
  test_remote_branch_strips_origin_prefix
  test_remote_branch_rejects_non_origin
  test_fetch_refspec_format
  test_fetch_depth_uses_default_when_unset
  test_fetch_depth_accepts_valid_env
  test_fetch_depth_strips_whitespace
  test_fetch_depth_forces_base_10
  test_fetch_depth_warns_and_defaults_on_zero
  test_fetch_depth_warns_and_defaults_on_garbage
  test_max_attempts_uses_default_when_unset
  test_max_attempts_caps_at_30
  test_max_attempts_warns_on_invalid
  test_unshallow_timeout_default
  test_unshallow_timeout_accepts_zero
  test_unshallow_timeout_warns_on_invalid
  test_run_test_counts_non_final_assertion_failure
  test_verify_ref_recognizes_existing_refs
  test_is_shallow_repository_detects_full_clone
  test_is_shallow_repository_detects_shallow_clone
  test_sha_ref_classifies_full_length_sha
  test_sha_ref_rejects_existing_branch_name
  test_sha_ref_rejects_non_hex_strings
  test_resolve_full_clone_happy_path
  test_resolve_rejects_invalid_policy
  test_resolve_shallow_deepens_to_find_merge_base
  test_resolve_full_clone_missing_base_ref_errors
  test_resolve_lenient_continues_after_initial_fetch_failure
  test_resolve_cross_repo_sha_hint_appears
)

main() {
  for t in "${ALL_TESTS[@]}"; do
    run_test "$t"
  done

  echo
  echo "Tests run: $TESTS_RUN, failed: $TESTS_FAILED"
  if [ "$TESTS_FAILED" -gt 0 ]; then
    echo
    echo "Failures:" >&2
    for f in "${FAILURES[@]}"; do
      echo "  - $f" >&2
    done
    exit 1
  fi
}

main "$@"
