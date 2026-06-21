#!/usr/bin/env bash
# Test harness for script/ci-required-hosted-gate.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/ci-required-hosted-gate"

TESTS_RUN=0
TESTS_FAILED=0
FAILURES=()

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
    *) fail "$label: expected '$needle' in '$haystack'" ;;
  esac
}

run_case() {
  local name="$1"
  local expected_rc="$2"
  local event_name="$3"
  local run_generators="$4"
  local should_run_hosted_ci="$5"
  local expected_output="${6:-}"

  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> $name"

  local output rc
  set +e
  output="$(
    GITHUB_EVENT_NAME="$event_name" \
      RUN_GENERATORS="$run_generators" \
      SHOULD_RUN_HOSTED_CI="$should_run_hosted_ci" \
      "$GATE" 2>&1
  )"
  rc=$?
  set -e

  if [ "$rc" -ne "$expected_rc" ]; then
    fail "$name: expected exit $expected_rc, got $rc; output: $output"
  fi

  if [ -n "$expected_output" ]; then
    assert_contains "$output" "$expected_output" "$name"
  fi
}

run_case \
  "blocks generator pull requests without hosted CI" \
  1 \
  "pull_request" \
  "true" \
  "false" \
  "Generator changes require hosted CI before merge."

run_case \
  "allows generator pull requests once hosted CI is requested" \
  0 \
  "pull_request" \
  "true" \
  "true"

run_case \
  "allows ordinary pull requests without hosted CI" \
  0 \
  "pull_request" \
  "false" \
  "false"

run_case \
  "allows merge queue generator checks" \
  0 \
  "merge_group" \
  "true" \
  "true"

run_case \
  "allows merge queue generator checks even without hosted PR state" \
  0 \
  "merge_group" \
  "true" \
  "false"

run_case \
  "allows non pull request events with unset event name" \
  0 \
  "" \
  "true" \
  "false"

if [ "$TESTS_FAILED" -ne 0 ]; then
  echo
  echo "$TESTS_FAILED of $TESTS_RUN tests failed"
  printf ' - %s\n' "${FAILURES[@]}"
  exit 1
fi

echo
echo "$TESTS_RUN tests passed"
