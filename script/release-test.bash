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
  status_count_file="${case_dir}/status-count"
  handshake_log="${case_dir}/handshake.log"
  coordination_process_log="${case_dir}/coordination-process.log"
  exception_group_log="${case_dir}/exception-group.log"

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
    count=0
    test ! -f "${TEST_STATUS_COUNT_FILE}" || count="$(cat "${TEST_STATUS_COUNT_FILE}")"
    count=$((count + 1))
    printf '%s\n' "${count}" >"${TEST_STATUS_COUNT_FILE}"
    claim_status="active"
    claim_agent_id="${RELEASE_COORDINATOR_ID}"
    claim_instance_id="${RELEASE_COORDINATOR_INSTANCE_ID}"
    claim_machine_id="${AGENT_COORD_MACHINE_ID}"
    claim_expiry="2099-01-01T00:00:00Z"
    if test "${count}" -gt 1; then
      case "${FAKE_STATUS_AFTER_FIRST:-active}" in
        released) claim_status="released" ;;
        replaced)
          claim_agent_id="replacement-agent"
          claim_instance_id="replacement-instance"
          claim_machine_id="replacement-machine"
          ;;
        expired) claim_expiry="2000-01-01T00:00:00Z" ;;
      esac
    fi
    printf '{"scope":{"kind":"target","repo":"%s","target":"%s"},' \
      "${TEST_REPO}" "${TEST_TARGET}"
    printf '"claims":[{"status":"%s","repo":"%s","target":"%s",' \
      "${claim_status}" "${TEST_REPO}" "${TEST_TARGET}"
    printf '"branch":"%s","agent_id":"%s","instance_id":"%s",' \
      "${TEST_BRANCH}" "${claim_agent_id}" "${claim_instance_id}"
    printf '"machine_id":"%s","expires_at":"%s"}],' \
      "${claim_machine_id}" "${claim_expiry}"
    printf '"heartbeats":[{"agent_id":"%s","instance_id":"%s",' \
      "${claim_agent_id}" "${claim_instance_id}"
    printf '"machine_id":"%s","branch":"%s","target":"%s#%s","liveness":"live"}]}\n' \
      "${claim_machine_id}" "${TEST_BRANCH}" "${TEST_REPO}" "${TEST_TARGET}"
    ;;
  heartbeat)
    count=0
    test ! -f "${TEST_HEARTBEAT_COUNT_FILE}" || count="$(cat "${TEST_HEARTBEAT_COUNT_FILE}")"
    count=$((count + 1))
    printf '%s\n' "${count}" >"${TEST_HEARTBEAT_COUNT_FILE}"
    if test -n "${FAKE_STALL_HEARTBEAT_AFTER:-}" && test "${count}" -gt "${FAKE_STALL_HEARTBEAT_AFTER}"; then
      process_group="$(ps -o pgid= -p "$$" | tr -d ' ')"
      printf '%s:%s\n' "$$" "${process_group}" >"${TEST_COORDINATION_PROCESS_LOG}"
      trap '' TERM INT HUP
      exec sleep 30
    fi
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

  cat >"${fake_bin}/release-handshake-harness" <<'HANDSHAKE_HARNESS'
#!/usr/bin/env ruby
# frozen_string_literal: true

load ENV.fetch("TEST_RELEASE_SCRIPT")

class HandshakeTestSupervisor < ReleaseSupervisor
  private

  def announce_process_group(writer, pgid)
    previous_term_handler = Signal.trap("TERM", "DEFAULT")
    Signal.trap("TERM", previous_term_handler)
    handler_state = previous_term_handler == "DEFAULT" ? "default" : "inherited"
    File.open(ENV.fetch("TEST_HANDSHAKE_LOG"), "a") do |file|
      file.puts("#{Process.pid}:#{pgid}:#{handler_state}")
    end
    Signal.trap("TERM", "IGNORE") if ENV["FAKE_HANDSHAKE_IGNORE_TERM"] == "1"
    case ENV.fetch("FAKE_HANDSHAKE_MODE")
    when "stall"
      sleep 30
    when "malformed"
      writer.puts("not-a-process-group")
      sleep 30
    else
      super
    end
  end
end

exit HandshakeTestSupervisor.new(ARGV).run
HANDSHAKE_HARNESS

  cat >"${fake_bin}/release-exception-harness" <<'EXCEPTION_HARNESS'
#!/usr/bin/env ruby
# frozen_string_literal: true

load ENV.fetch("TEST_RELEASE_SCRIPT")

class FailingReleaseOutput
  def puts(*)
    raise Errno::EPIPE
  end
end

class ExceptionTestSupervisor < ReleaseSupervisor
  def initialize(argv)
    stdout = ENV.fetch("FAKE_EXCEPTION_MODE") == "after-spawn" ? FailingReleaseOutput.new : $stdout
    super(argv, stdout:)
  end

  private

  def spawn_release_group(...)
    result = super
    File.write(ENV.fetch("TEST_EXCEPTION_GROUP_LOG"), "#{result.fetch(1)}\n")
    result
  end

  def read_child_process_group!(...)
    pgid = super
    return pgid unless ENV.fetch("FAKE_EXCEPTION_MODE") == "after-handshake"

    File.write(ENV.fetch("TEST_EXCEPTION_GROUP_LOG"), "#{pgid}\n")
    raise SupervisorError, "injected failure after process-group handshake"
  end
end

exit ExceptionTestSupervisor.new(ARGV).run
EXCEPTION_HARNESS

  chmod +x "${fake_bin}/agent-coord" "${fake_bin}/bundle" "${fake_bin}/release-handshake-harness" \
    "${fake_bin}/release-exception-harness"

  export PATH="${fake_bin}:${PATH}"
  export TEST_COORD_LOG="${coord_log}"
  export TEST_BUNDLE_LOG="${bundle_log}"
  export TEST_HEARTBEAT_COUNT_FILE="${heartbeat_count_file}"
  export TEST_STATUS_COUNT_FILE="${status_count_file}"
  export TEST_HANDSHAKE_LOG="${handshake_log}"
  export TEST_COORDINATION_PROCESS_LOG="${coordination_process_log}"
  export TEST_EXCEPTION_GROUP_LOG="${exception_group_log}"
  export TEST_RELEASE_SCRIPT="${release_script}"
  export TEST_REPO="shakacode/react_on_rails"
  export TEST_TARGET="release-line:17.1.0"
  export TEST_BRANCH="release/17.1.0"
  export RELEASE_COORDINATOR_ID="release-17.1.0-test-instance"
  export RELEASE_COORDINATOR_INSTANCE_ID="test-instance"
  export AGENT_COORD_MACHINE_ID="test-machine"
  export AGENT_COORD_API_TOKEN="${fake_secret}"
  export REACT_ON_RAILS_RELEASE_HEARTBEAT_INTERVAL="0.1"
  export REACT_ON_RAILS_RELEASE_TERMINATION_GRACE="0.5"
  unset FAKE_STATUS_FAIL FAKE_STATUS_AFTER_FIRST FAKE_FAIL_HEARTBEAT_AFTER FAKE_STALL_HEARTBEAT_AFTER
  unset FAKE_BUNDLE_MODE FAKE_HANDSHAKE_MODE FAKE_EXCEPTION_MODE
  unset FAKE_HANDSHAKE_IGNORE_TERM
  unset REACT_ON_RAILS_RELEASE_COORDINATION_TIMEOUT
}

run_release() {
  (
    cd "${fake_repo}"
    "${release_script}" "$@"
  ) >"${output_log}" 2>&1
}

run_handshake_release() {
  (
    cd "${fake_repo}"
    "${fake_bin}/release-handshake-harness" "$@"
  ) >"${output_log}" 2>&1
}

run_exception_release() {
  (
    cd "${fake_repo}"
    "${fake_bin}/release-exception-harness" "$@"
  ) >"${output_log}" 2>&1
}

handshake_case_enabled() {
  test "${RELEASE_TEST_HANDSHAKE_CASE:-all}" = all || test "${RELEASE_TEST_HANDSHAKE_CASE}" = "$1"
}

supervisor_case_enabled() {
  test "${RELEASE_TEST_SUPERVISOR_CASE:-all}" = all || test "${RELEASE_TEST_SUPERVISOR_CASE}" = "$1"
}

wait_for_process_exit() {
  process_id="$1"
  for _attempt in $(seq 1 100); do
    ! kill -0 "${process_id}" 2>/dev/null && return 0
    sleep 0.05
  done
  return 1
}

assert_group_dead() {
  group_id="$1"
  case "${group_id}" in
    ''|*[!0-9]*) fail "invalid process group ${group_id}" ;;
  esac
  if kill -0 -- "-${group_id}" 2>/dev/null; then
    kill -KILL -- "-${group_id}" 2>/dev/null || true
    fail "process group ${group_id} survived wrapper shutdown"
  fi
}

cleanup_stalled_wrapper() {
  wrapper_id="$1"
  coordination_id="$(cut -d: -f1 "${coordination_process_log}" 2>/dev/null || true)"
  test -z "${coordination_id}" || kill -KILL "${coordination_id}" 2>/dev/null || true
  if ! wait_for_process_exit "${wrapper_id}"; then
    kill -KILL "${wrapper_id}" 2>/dev/null || true
  fi
  wait "${wrapper_id}" 2>/dev/null || true
  release_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
  test -z "${release_group}" || kill -KILL -- "-${release_group}" 2>/dev/null || true
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

setup_case reconciliation
FAKE_BUNDLE_MODE=success run_release --reconcile-accelerated-rc 17.1.0.rc.0 || \
  fail "supervised accelerated RC reconciliation failed"
assert_contains "${bundle_log}" 'args|exec|rake|release:reconcile_accelerated_rc[17.1.0.rc.0]'
assert_no_coordination_mutation
assert_secret_absent
pass "accelerated RC reconciliation uses the supervised release contract"

if supervisor_case_enabled heartbeat-timeout; then
  setup_case stalled-heartbeat-timeout
  export FAKE_STALL_HEARTBEAT_AFTER=1
  export FAKE_BUNDLE_MODE=hold
  export REACT_ON_RAILS_RELEASE_COORDINATION_TIMEOUT=0.2
  (
    cd "${fake_repo}"
    exec "${release_script}" 17.1.0.rc.0
  ) >"${output_log}" 2>&1 &
  wrapper_pid=$!
  for _attempt in $(seq 1 100); do
    test -s "${coordination_process_log}" && break
    sleep 0.05
  done
  test -s "${coordination_process_log}" || fail "stalled heartbeat never started"
  if ! wait_for_process_exit "${wrapper_pid}"; then
    cleanup_stalled_wrapper "${wrapper_pid}"
    fail "stalled heartbeat did not stop the release within its coordination timeout"
  fi
  if wait "${wrapper_pid}"; then
    fail "release with a stalled heartbeat exited successfully"
  fi
  coordination_id="$(cut -d: -f1 "${coordination_process_log}")"
  process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
  assert_group_dead "${process_group}"
  ! kill -0 "${coordination_id}" 2>/dev/null || fail "stalled heartbeat process survived timeout"
  assert_contains "${output_log}" "Release lease refresh failed"
  assert_contains "${bundle_log}" "liveness:eof"
  assert_no_coordination_mutation
  assert_secret_absent
  pass "stalled heartbeat is bounded and terminates the release group"
fi

if supervisor_case_enabled heartbeat-signal; then
  setup_case signal-during-heartbeat
  export FAKE_STALL_HEARTBEAT_AFTER=1
  export FAKE_BUNDLE_MODE=hold
  export REACT_ON_RAILS_RELEASE_COORDINATION_TIMEOUT=5
  (
    cd "${fake_repo}"
    exec "${release_script}" 17.1.0.rc.0
  ) >"${output_log}" 2>&1 &
  wrapper_pid=$!
  for _attempt in $(seq 1 100); do
    test -s "${coordination_process_log}" && break
    sleep 0.05
  done
  test -s "${coordination_process_log}" || fail "heartbeat never stalled before signal"
  kill -TERM "${wrapper_pid}"
  if ! wait_for_process_exit "${wrapper_pid}"; then
    cleanup_stalled_wrapper "${wrapper_pid}"
    fail "signal during heartbeat did not stop the wrapper"
  fi
  if wait "${wrapper_pid}"; then
    fail "signal during heartbeat exited successfully"
  fi
  coordination_id="$(cut -d: -f1 "${coordination_process_log}")"
  process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
  assert_group_dead "${process_group}"
  ! kill -0 "${coordination_id}" 2>/dev/null || fail "heartbeat process survived wrapper signal"
  assert_contains "${output_log}" "signal TERM"
  assert_contains "${bundle_log}" "liveness:eof"
  assert_no_coordination_mutation
  assert_secret_absent
  pass "signal during heartbeat terminates coordination and release groups"
fi

for exception_mode in after-spawn after-handshake; do
  if supervisor_case_enabled "exception-${exception_mode}"; then
    setup_case "exception-${exception_mode}"
    export FAKE_EXCEPTION_MODE="${exception_mode}"
    export FAKE_BUNDLE_MODE=hold
    if run_exception_release 17.1.0.rc.0; then
      fail "${exception_mode} supervisor exception exited successfully"
    fi
    process_group="$(cat "${exception_group_log}")"
    assert_group_dead "${process_group}"
    assert_no_coordination_mutation
    assert_secret_absent
    pass "${exception_mode} supervisor exception terminates the release group"
  fi
done

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

for claim_loss in released replaced expired; do
  setup_case "claim-${claim_loss}"
  export FAKE_STATUS_AFTER_FIRST="${claim_loss}"
  export FAKE_FAIL_HEARTBEAT_AFTER=4
  export FAKE_BUNDLE_MODE=hold
  export REACT_ON_RAILS_RELEASE_HEARTBEAT_INTERVAL=0.5
  if run_release 17.1.0.rc.0; then
    fail "release stayed live after its claim became ${claim_loss}"
  fi
  process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
  test -n "${process_group}" || fail "claim-${claim_loss} case never started the release group"
  assert_contains "${output_log}" "terminating process group ${process_group}"
  assert_contains "${bundle_log}" "liveness:eof"
  assert_contains "${bundle_log}" "termination:signal"
  test "$(cat "${status_count_file}")" = 2 || fail "claim-${claim_loss} did not stop on its second status read"
  test "$(cat "${heartbeat_count_file}")" = 2 || fail "claim-${claim_loss} did not retain its heartbeat identity"
  assert_no_coordination_mutation
  assert_secret_absent
  article="a"
  test "${claim_loss}" != expired || article="an"
  pass "successful heartbeat cannot mask ${article} ${claim_loss} claim"
done

if handshake_case_enabled stalled; then
  setup_case stalled-handshake
  export FAKE_HANDSHAKE_MODE=stall
  export FAKE_HANDSHAKE_IGNORE_TERM=1
  export REACT_ON_RAILS_RELEASE_HANDSHAKE_TIMEOUT=0.2
  if run_handshake_release 17.1.0.rc.0; then
    fail "release accepted a stalled process-group handshake"
  fi
  assert_contains "${output_log}" "timed out while establishing release process group"
  group_id="$(awk -F: 'NR == 1 { print $2 }' "${handshake_log}")"
  assert_group_dead "${group_id}"
  assert_no_coordination_mutation
  assert_secret_absent
  pass "stalled process-group handshake is bounded and terminated"
fi

if handshake_case_enabled malformed; then
  setup_case malformed-handshake
  export FAKE_HANDSHAKE_MODE=malformed
  export REACT_ON_RAILS_RELEASE_HANDSHAKE_TIMEOUT=0.5
  if run_handshake_release 17.1.0.rc.0; then
    fail "release accepted a malformed process-group handshake"
  fi
  assert_contains "${output_log}" "release child did not report its process group"
  group_id="$(awk -F: 'NR == 1 { print $2 }' "${handshake_log}")"
  assert_group_dead "${group_id}"
  assert_no_coordination_mutation
  assert_secret_absent
  pass "malformed process-group handshake is terminated"
fi

if handshake_case_enabled signal; then
  setup_case signal-during-handshake
  export FAKE_HANDSHAKE_MODE=stall
  export FAKE_BUNDLE_MODE=hold
  export REACT_ON_RAILS_RELEASE_HANDSHAKE_TIMEOUT=5
  (
    cd "${fake_repo}"
    exec "${fake_bin}/release-handshake-harness" 17.1.0.rc.0
  ) >"${output_log}" 2>&1 &
  wrapper_pid=$!
  for _attempt in $(seq 1 100); do
    { test -s "${handshake_log}" || test -s "${bundle_log}"; } && break
    sleep 0.05
  done
  { test -s "${handshake_log}" || test -s "${bundle_log}"; } || fail "handshake child never started"
  kill -TERM "${wrapper_pid}"
  if ! wait_for_process_exit "${wrapper_pid}"; then
    child_id="$(awk -F: 'NR == 1 { print $1 }' "${handshake_log}")"
    test -n "${child_id}" || child_id="$(awk -F: '/^bundle:/ { print $2; exit }' "${bundle_log}")"
    kill -KILL -- "-${child_id}" 2>/dev/null || true
    kill -KILL "${wrapper_pid}" 2>/dev/null || true
    wait "${wrapper_pid}" 2>/dev/null || true
    fail "signal during process-group handshake did not stop the wrapper"
  fi
  if wait "${wrapper_pid}"; then
    fail "signal during process-group handshake exited successfully"
  fi
  assert_contains "${output_log}" "signal TERM while establishing release process group"
  group_id="$(awk -F: 'NR == 1 { print $2 }' "${handshake_log}")"
  test -n "${group_id}" || group_id="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
  test "$(awk -F: 'NR == 1 { print $3 }' "${handshake_log}")" = default || \
    fail "handshake child inherited the supervisor TERM trap"
  assert_group_dead "${group_id}"
  assert_no_coordination_mutation
  assert_secret_absent
  pass "signal during process-group handshake is bounded and terminated"
fi

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
