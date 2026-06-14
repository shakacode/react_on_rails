#!/usr/bin/env bash
# shellcheck disable=SC2329  # test/assert fns are invoked indirectly via run_test "$name"
# Unit tests for the pure helpers in post-merge-audit-scope. These cover the
# parsing/diff logic that is most error-prone by hand (and that gates the
# carry-over / fingerprint-dedup the audit relies on). Live gh/git resolution
# is exercised by `post-merge-audit-scope --self-check`, not here.
#
# Run with: bash .agents/skills/post-merge-audit/bin/post-merge-audit-scope-test.bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source the resolver without running main (guarded by BASH_SOURCE == $0).
# shellcheck source=/dev/null
source "$SCRIPT_DIR/post-merge-audit-scope"
# The sourced script sets `set -euo pipefail`; drop errexit so a single failing
# assertion reports and continues instead of aborting the whole suite.
set +e

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
FAILURES=()

fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES+=("$CURRENT_TEST: $1")
  echo "  FAIL: $1" >&2
}

assert_eq() {
  local got="$1" want="$2" label="${3:-value}"
  if [ "$got" != "$want" ]; then
    fail "$label: expected '$want', got '$got'"
  fi
}

run_test() {
  CURRENT_TEST="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> $1"
  "$1"
}

# --- pma_extract_prs --------------------------------------------------------

test_extract_basic() {
  local out
  out="$(printf 'feat: thing (#3610)\nfix: other (#3592)\n' | pma_extract_prs | paste -sd, -)"
  assert_eq "$out" "3592,3610" "sorted unique PR numbers"
}

test_extract_ignores_prose_hashes() {
  # Only the trailing (#N) merge form counts; "#3592" in prose must not leak in.
  local out
  out="$(printf 'fix: classify errors, refs #3592 and #1 (#3610)\n' | pma_extract_prs | paste -sd, -)"
  assert_eq "$out" "3610" "prose #refs ignored"
}

test_extract_dedupes() {
  local out
  out="$(printf 'a (#42)\nb (#42)\nc (#7)\n' | pma_extract_prs | paste -sd, -)"
  assert_eq "$out" "7,42" "duplicate PR numbers collapsed"
}

test_extract_empty() {
  local out
  out="$(printf 'no pr ref here\njust prose\n' | pma_extract_prs | paste -sd, -)"
  assert_eq "$out" "" "no matches yields empty"
}

# --- pma_parse_affected -----------------------------------------------------

test_affected_comma_and_space() {
  local out
  out="$(printf 'affected_prs: 3786,3784, 3817\n' | pma_parse_affected | paste -sd, -)"
  assert_eq "$out" "3784,3786,3817" "comma/space separated affected_prs"
}

test_affected_single() {
  local out
  out="$(printf 'header\naffected_prs: 3794\nfooter\n' | pma_parse_affected | paste -sd, -)"
  assert_eq "$out" "3794" "single affected pr"
}

test_affected_none() {
  local out
  out="$(printf 'no marker here\n' | pma_parse_affected | paste -sd, -)"
  assert_eq "$out" "" "no affected_prs line"
}

# --- pma_parse_fingerprints -------------------------------------------------

test_fingerprints_multi() {
  local body out
  body="$(printf '<!-- post-merge-audit-finding v1\nfingerprint: pr-3784:unresolved-threads\naffected_prs: 3784\n-->\nfingerprint: process:confidence-gate-enforcement\n')"
  out="$(printf '%s' "$body" | pma_parse_fingerprints | paste -sd, -)"
  assert_eq "$out" "pr-3784:unresolved-threads,process:confidence-gate-enforcement" "all fingerprint values"
}

test_fingerprints_none() {
  local out
  out="$(printf 'just a normal issue body\n' | pma_parse_fingerprints | paste -sd, -)"
  assert_eq "$out" "" "no fingerprint line"
}

# --- pma_diff_prs -----------------------------------------------------------

test_diff_removes_carryover() {
  local dir merged carry out
  dir="$(mktemp -d "${TMPDIR:-/tmp}/pma-scope-test.XXXXXX")"
  merged="$dir/merged"; carry="$dir/carry"
  printf '3784\n3786\n3791\n3817\n' > "$merged"
  printf '3786\n3817\n' > "$carry"
  out="$(pma_diff_prs "$merged" "$carry" | paste -sd, -)"
  assert_eq "$out" "3784,3791" "merged minus carry-over"
  rm -rf "$dir"
}

test_diff_empty_carry() {
  local dir merged carry out
  dir="$(mktemp -d "${TMPDIR:-/tmp}/pma-scope-test.XXXXXX")"
  merged="$dir/merged"; carry="$dir/carry"
  printf '5\n3\n9\n' > "$merged"
  : > "$carry"
  out="$(pma_diff_prs "$merged" "$carry" | paste -sd, -)"
  assert_eq "$out" "3,5,9" "empty carry-over returns all, sorted"
  rm -rf "$dir"
}

run_test test_extract_basic
run_test test_extract_ignores_prose_hashes
run_test test_extract_dedupes
run_test test_extract_empty
run_test test_affected_comma_and_space
run_test test_affected_single
run_test test_affected_none
run_test test_fingerprints_multi
run_test test_fingerprints_none
run_test test_diff_removes_carryover
run_test test_diff_empty_carry

echo
if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "PASS: $TESTS_RUN tests"
  exit 0
fi
echo "FAIL: $TESTS_FAILED of $TESTS_RUN tests failed" >&2
for f in "${FAILURES[@]}"; do
  echo "  - $f" >&2
done
exit 1
