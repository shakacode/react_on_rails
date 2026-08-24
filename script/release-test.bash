#!/usr/bin/env bash

set -euo pipefail

repo_root="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
release_script="${repo_root}/script/release"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/react-on-rails-release-test.XXXXXX")"
fake_secret="coord-secret-must-never-appear"
tests_run=0

cleanup() {
  if test "${RELEASE_TEST_KEEP_TMP:-0}" = 1; then
    printf 'release test files retained at %s\n' "${test_root}" >&2
    return
  fi
  rm -rf "${test_root}"
}
trap cleanup EXIT

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

pass() {
  tests_run=$((tests_run + 1))
  printf 'ok %d - %s\n' "${tests_run}" "$1"
}

assert_contains() {
  file="$1"
  expected="$2"
  grep -F -- "${expected}" "${file}" >/dev/null || fail "${file} did not contain ${expected}"
}

assert_not_contains() {
  file="$1"
  unexpected="$2"
  if grep -F -- "${unexpected}" "${file}" >/dev/null; then
    fail "${file} unexpectedly contained ${unexpected}"
  fi
}

assert_empty() {
  file="$1"
  test ! -s "${file}" || fail "${file} was not empty"
}

setup_case() {
  case_name="$1"
  case_dir="${test_root}/${case_name}"
  fake_bin="${case_dir}/bin"
  fake_repo="${case_dir}/repo"
  coord_log="${case_dir}/agent-coord.log"
  bundle_log="${case_dir}/bundle.log"
  output_log="${case_dir}/output.log"
  heartbeat_count_file="${case_dir}/heartbeat-count"

  mkdir -p "${fake_bin}" "${fake_repo}"
  : >"${coord_log}"
  : >"${bundle_log}"
  : >"${output_log}"
  git -C "${fake_repo}" init -q -b release/17.1.0

  cat >"${fake_bin}/agent-coord" <<'FAKE_COORD'
#!/usr/bin/env bash
set -euo pipefail

command_name="${1:-}"
shift || true
{
  printf '%s' "${command_name}"
  for argument in "$@"; do
    printf '|%s' "${argument}"
  done
  printf '|machine=%s\n' "${AGENT_COORD_MACHINE_ID:-}"
} >>"${TEST_COORD_LOG}"

# The supervisor must not forward backend diagnostics because they can contain
# credentials even when a backend or test double behaves badly.
printf 'fake backend diagnostic: %s\n' "${AGENT_COORD_API_TOKEN:-}" >&2

case "${command_name}" in
  status)
    test "${FAKE_STATUS_FAIL:-0}" != 1 || exit 91
    printf '{"scope":{"kind":"target","repo":"%s","target":"%s"},' \
      "${TEST_REPO}" "${TEST_TARGET}"
    printf '"claims":[{"status":"active","repo":"%s","target":"%s",' \
      "${TEST_REPO}" "${TEST_TARGET}"
    printf '"branch":"%s","agent_id":"%s","instance_id":"%s",' \
      "${TEST_BRANCH}" "${RELEASE_COORDINATOR_ID}" "${RELEASE_COORDINATOR_INSTANCE_ID}"
    printf '"machine_id":"%s","expires_at":"2099-01-01T00:00:00Z"}],' \
      "${AGENT_COORD_MACHINE_ID}"
    printf '"heartbeats":[{"agent_id":"%s","instance_id":"%s",' \
      "${RELEASE_COORDINATOR_ID}" "${RELEASE_COORDINATOR_INSTANCE_ID}"
    printf '"machine_id":"%s","branch":"%s","target":"%s#%s","liveness":"live"}]}\n' \
      "${AGENT_COORD_MACHINE_ID}" "${TEST_BRANCH}" "${TEST_REPO}" "${TEST_TARGET}"
    ;;
  heartbeat)
    count=0
    test ! -f "${TEST_HEARTBEAT_COUNT_FILE}" || count="$(cat "${TEST_HEARTBEAT_COUNT_FILE}")"
    count=$((count + 1))
    printf '%s\n' "${count}" >"${TEST_HEARTBEAT_COUNT_FILE}"
    if test -n "${FAKE_FAIL_HEARTBEAT_AFTER:-}" && test "${count}" -gt "${FAKE_FAIL_HEARTBEAT_AFTER}"; then
      exit 92
    fi
    ;;
  claim|release)
    exit 93
    ;;
  *)
    exit 94
    ;;
esac
FAKE_COORD

  cat >"${fake_bin}/bundle" <<'FAKE_BUNDLE'
#!/usr/bin/env bash
set -euo pipefail

process_group="$(ps -o pgid= -p "$$" | tr -d ' ')"
{
  printf 'bundle:%s:%s\n' "$$" "${process_group}"
  printf 'args'
  for argument in "$@"; do
    printf '|%s' "${argument}"
  done
  printf '\ncontract:%s\n' "${REACT_ON_RAILS_RELEASE_LEASE_CONTRACT:-}"
} >>"${TEST_BUNDLE_LOG}"

record_liveness() {
  ruby -rjson -e '
    contract = JSON.parse(ENV.fetch("REACT_ON_RAILS_RELEASE_LEASE_CONTRACT"))
    io = IO.for_fd(contract.fetch("liveness_fd"), autoclose: false)
    state = io.read_nonblock(1, exception: false)
    File.open(ENV.fetch("TEST_BUNDLE_LOG"), "a") do |file|
      file.puts(state.nil? ? "liveness:eof" : "liveness:#{state}")
    end
  '
}

record_termination() {
  record_liveness
  printf 'termination:signal\n' >>"${TEST_BUNDLE_LOG}"
  exit 143
}

case "${FAKE_BUNDLE_MODE:-success}" in
  success)
    sh -c '
      process_group="$(ps -o pgid= -p "$$" | tr -d " ")"
      printf "child:%s:%s\n" "$$" "${process_group}" >>"$1"
    ' test-child "${TEST_BUNDLE_LOG}" &
    wait "$!"
    ;;
  hold)
    trap record_termination TERM INT HUP
    while :; do
      sleep 0.1
    done
    ;;
  *)
    exit 95
    ;;
esac
FAKE_BUNDLE

  chmod +x "${fake_bin}/agent-coord" "${fake_bin}/bundle"

  export PATH="${fake_bin}:${PATH}"
  export TEST_COORD_LOG="${coord_log}"
  export TEST_BUNDLE_LOG="${bundle_log}"
  export TEST_HEARTBEAT_COUNT_FILE="${heartbeat_count_file}"
  export TEST_REPO="shakacode/react_on_rails"
  export TEST_TARGET="release-line:17.1.0"
  export TEST_BRANCH="release/17.1.0"
  export RELEASE_COORDINATOR_ID="release-17.1.0-test-instance"
  export RELEASE_COORDINATOR_INSTANCE_ID="test-instance"
  export AGENT_COORD_MACHINE_ID="test-machine"
  export AGENT_COORD_API_TOKEN="${fake_secret}"
  export REACT_ON_RAILS_RELEASE_HEARTBEAT_INTERVAL="0.1"
  export REACT_ON_RAILS_RELEASE_TERMINATION_GRACE="0.5"
  unset FAKE_STATUS_FAIL FAKE_FAIL_HEARTBEAT_AFTER FAKE_BUNDLE_MODE
}

run_release() {
  (
    cd "${fake_repo}"
    "${release_script}" "$@"
  ) >"${output_log}" 2>&1
}

assert_no_coordination_mutation() {
  assert_not_contains "${coord_log}" $'claim|'
  assert_not_contains "${coord_log}" $'release|'
}

assert_secret_absent() {
  assert_not_contains "${output_log}" "${fake_secret}"
  assert_not_contains "${coord_log}" "${fake_secret}"
  assert_not_contains "${bundle_log}" "${fake_secret}"
}

setup_case dry-run
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID AGENT_COORD_MACHINE_ID AGENT_COORD_API_TOKEN
run_release --dry-run 17.1.0.rc.0 || fail "dry-run failed"
assert_empty "${coord_log}"
assert_contains "${bundle_log}" 'args|exec|rake|release[17.1.0.rc.0,true]'
assert_contains "${bundle_log}" 'contract:'
pass "dry-run needs no identity or coordination"

setup_case missing-identity
unset RELEASE_COORDINATOR_INSTANCE_ID
if run_release 17.1.0.rc.0; then
  fail "live release accepted missing identity"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "RELEASE_COORDINATOR_INSTANCE_ID"
assert_secret_absent
pass "live mode refuses missing identity"

setup_case wrong-branch
git -C "${fake_repo}" switch -q -c main
if run_release 17.1.0.rc.0; then
  fail "live release accepted the wrong branch"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release/17.1.0"
assert_secret_absent
pass "live mode requires the matching release branch"

setup_case matching-state
FAKE_BUNDLE_MODE=success run_release 17.1.0.rc.0 || fail "matching live release failed"
assert_contains "${bundle_log}" 'args|exec|rake|release[17.1.0.rc.0]'
group_count="$(awk -F: '/^(bundle|child):/ { print $3 }' "${bundle_log}" | sort -u | wc -l | tr -d ' ')"
test "${group_count}" = 1 || fail "release processes did not share one process group"
assert_contains "${coord_log}" 'heartbeat|--agent-id|release-17.1.0-test-instance|--instance-id|test-instance'
assert_contains "${coord_log}" '|--repo|shakacode/react_on_rails|--target|release-line:17.1.0'
assert_contains "${coord_log}" '|--branch|release/17.1.0|'
assert_contains "${coord_log}" '|machine=test-machine'
process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
assert_contains "${output_log}" "process group ${process_group}"
assert_no_coordination_mutation
assert_secret_absent
pass "matching state runs one identity-bound process group"

setup_case lease-failure
export FAKE_FAIL_HEARTBEAT_AFTER=1
export FAKE_BUNDLE_MODE=hold
export REACT_ON_RAILS_RELEASE_HEARTBEAT_INTERVAL=0.5
if run_release 17.1.0.rc.0; then
  fail "release stayed live after heartbeat failure"
fi
process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
test -n "${process_group}" || fail "lease-failure case never started the release group"
assert_contains "${output_log}" "terminating process group ${process_group}"
assert_contains "${bundle_log}" "liveness:eof"
assert_contains "${bundle_log}" "termination:signal"
assert_no_coordination_mutation
assert_secret_absent
pass "lease failure closes liveness and terminates the group"

setup_case signal
export FAKE_BUNDLE_MODE=hold
(
  cd "${fake_repo}"
  exec "${release_script}" 17.1.0.rc.0
) >"${output_log}" 2>&1 &
wrapper_pid=$!
for _attempt in $(seq 1 100); do
  test -s "${bundle_log}" && break
  sleep 0.05
done
test -s "${bundle_log}" || fail "signal case never started the release group"
kill -TERM "${wrapper_pid}"
if wait "${wrapper_pid}"; then
  fail "signal-interrupted release exited successfully"
fi
process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
assert_contains "${output_log}" "signal TERM"
assert_contains "${output_log}" "process group ${process_group}"
assert_contains "${bundle_log}" "liveness:eof"
assert_contains "${bundle_log}" "termination:signal"
assert_no_coordination_mutation
assert_secret_absent
pass "signals report and terminate the exact release process group"

printf '1..%d\n' "${tests_run}"
