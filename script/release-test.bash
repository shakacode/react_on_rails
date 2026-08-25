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

write_changelog() {
  version="$1"
  cat >"${fake_repo}/CHANGELOG.md" <<CHANGELOG
### [Unreleased]

### [${version}] - 2026-08-23

#### Fixed

- Prepared release candidate.
CHANGELOG
}

write_current_version() {
  version="$1"
  version_dir="${fake_repo}/react_on_rails/lib/react_on_rails"
  mkdir -p "${version_dir}"
  printf 'module ReactOnRails\n  VERSION = "%s"\nend\n' "${version}" >"${version_dir}/version.rb"
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
  claim_state_file="${case_dir}/claim-state"
  handshake_log="${case_dir}/handshake.log"
  coordination_process_log="${case_dir}/coordination-process.log"
  coordination_descendant_log="${case_dir}/coordination-descendant.log"
  exception_group_log="${case_dir}/exception-group.log"

  mkdir -p "${fake_bin}" "${fake_repo}"
  : >"${coord_log}"
  : >"${bundle_log}"
  : >"${output_log}"
  git -C "${fake_repo}" init -q -b release/17.1.0
  write_changelog "17.1.0.rc.0"
  write_current_version "17.0.0"

  mkdir -p "${fake_repo}/script"
  cat >"${fake_repo}/script/release-claim" <<'FAKE_ATOMIC_CLAIM'
#!/usr/bin/env bash
set -euo pipefail

{
  printf 'claim-atomic'
  for argument in "$@"; do
    printf '|%s' "${argument}"
  done
  printf '\n'
} >>"${TEST_COORD_LOG}"

renew_mode=0
for argument in "$@"; do
  test "${argument}" != --renew || renew_mode=1
done

if test "${renew_mode}" = 1; then
  case "${FAKE_ATOMIC_RENEW_MODE:-success}" in
    refused) exit 3 ;;
    refused-after-child-start)
      for _attempt in $(seq 1 200); do
        grep -q '^bundle:' "${TEST_BUNDLE_LOG}" 2>/dev/null && exit 3
        sleep 0.01
      done
      exit 91
      ;;
    unavailable) exit 91 ;;
  esac
fi

case "${FAKE_ATOMIC_CLAIM_MODE:-${FAKE_CLAIM_FAIL:-success}}" in
  foreign-race|refused)
    printf '%s\n%s\n' foreign-agent foreign-instance >"${TEST_CLAIM_STATE_FILE}"
    exit 3
    ;;
  unavailable) exit 91 ;;
esac

agent_id=""
instance_id=""
while test "$#" -gt 0; do
  case "$1" in
    --agent-id) agent_id="$2"; shift 2 ;;
    --instance-id) instance_id="$2"; shift 2 ;;
    *) shift ;;
  esac
done
test -n "${agent_id}" && test -n "${instance_id}"
printf '%s\n%s\n' "${agent_id}" "${instance_id}" >"${TEST_CLAIM_STATE_FILE}"
if test "${FAKE_STALL_CLAIM_AFTER_CREATE:-0}" = 1; then
  process_group="$(ps -o pgid= -p "$$" | tr -d ' ')"
  printf '%s:%s\n' "$$" "${process_group}" >"${TEST_COORDINATION_PROCESS_LOG}"
  trap '' TERM INT HUP
  exec sleep 30
fi
FAKE_ATOMIC_CLAIM
  chmod +x "${fake_repo}/script/release-claim"

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
  doctor)
    test "${FAKE_DOCTOR_FAIL:-0}" != 1 || exit 91
    if test -n "${FAKE_DOCTOR_PAYLOAD:-}"; then
      printf '%s\n' "${FAKE_DOCTOR_PAYLOAD}"
      exit 0
    fi
    printf '{"version":"0.1.0","status":"ok","backend":"%s","backend_url":"https://coord.example.test"}\n' \
      "${FAKE_DOCTOR_BACKEND:-http}"
    ;;
  status)
    test "${FAKE_STATUS_FAIL:-0}" != 1 || exit 91
    count=0
    test ! -f "${TEST_STATUS_COUNT_FILE}" || count="$(cat "${TEST_STATUS_COUNT_FILE}")"
    count=$((count + 1))
    printf '%s\n' "${count}" >"${TEST_STATUS_COUNT_FILE}"
    if test "${FAKE_SUCCESS_STATUS_DESCENDANT:-0}" = 1 && test "${count}" = 1; then
      process_group="$(ps -o pgid= -p "$$" | tr -d ' ')"
      printf '%s:%s\n' "$$" "${process_group}" >"${TEST_COORDINATION_PROCESS_LOG}"
      sh -c 'trap "" TERM INT HUP; exec sleep 30' &
      printf '%s\n' "$!" >"${TEST_COORDINATION_DESCENDANT_LOG}"
    fi
    if test -n "${FAKE_STALL_STATUS_AFTER:-}" && test "${count}" -gt "${FAKE_STALL_STATUS_AFTER}"; then
      process_group="$(ps -o pgid= -p "$$" | tr -d ' ')"
      printf '%s:%s\n' "$$" "${process_group}" >"${TEST_COORDINATION_PROCESS_LOG}"
      trap '' TERM INT HUP
      sh -c 'trap "" TERM INT HUP; exec sleep 30' &
      printf '%s\n' "$!" >"${TEST_COORDINATION_DESCENDANT_LOG}"
      wait
    fi
    if test "${FAKE_PREFLIGHT_STATUS_MODE:-}" = malformed && test "${count}" = 1; then
      printf '{not-json\n'
      exit 0
    fi
    if { test "${count}" = 1 && test "${FAKE_PREFLIGHT_STATUS_MODE:-}" = empty-first; } || {
      test -z "${FAKE_PREFLIGHT_STATUS_MODE:-}" &&
        test ! -s "${TEST_CLAIM_STATE_FILE}" &&
        test -z "${RELEASE_COORDINATOR_ID:-}" &&
        test -z "${RELEASE_COORDINATOR_INSTANCE_ID:-}"
    }; then
      printf '{"version":"0.1.0","scope":{"kind":"target","repo":"%s","target":"%s"},' \
        "${TEST_REPO}" "${TEST_TARGET}"
      printf '"degraded":["not checked in target scope"],"claims":[],"heartbeats":[],"batches":[],"events":[]}\n'
      exit 0
    fi
    claim_status="active"
    claim_agent_id="${RELEASE_COORDINATOR_ID:-}"
    claim_instance_id="${RELEASE_COORDINATOR_INSTANCE_ID:-}"
    claim_machine_id="${AGENT_COORD_MACHINE_ID}"
    heartbeat_liveness="live"
    include_heartbeat=1
    if test -s "${TEST_CLAIM_STATE_FILE}"; then
      claim_agent_id="$(sed -n '1p' "${TEST_CLAIM_STATE_FILE}")"
      claim_instance_id="$(sed -n '2p' "${TEST_CLAIM_STATE_FILE}")"
    fi
    claim_expiry="2099-01-01T00:00:00Z"
    if test "${count}" = 1; then
      case "${FAKE_PREFLIGHT_STATUS_MODE:-}" in
        foreign-dead)
          claim_agent_id="foreign-agent"
          claim_instance_id="foreign-instance"
          claim_machine_id="foreign-machine"
          heartbeat_liveness="dead"
          ;;
        foreign-expired)
          claim_agent_id="foreign-agent"
          claim_instance_id="foreign-instance"
          claim_machine_id="foreign-machine"
          claim_expiry="2000-01-01T00:00:00Z"
          ;;
        foreign-missing-heartbeat)
          claim_agent_id="foreign-agent"
          claim_instance_id="foreign-instance"
          claim_machine_id="foreign-machine"
          include_heartbeat=0
          ;;
        foreign-active)
          claim_agent_id="foreign-agent"
          claim_instance_id="foreign-instance"
          claim_machine_id="foreign-machine"
          ;;
      esac
    fi
    if test "${count}" -gt "${FAKE_STATUS_CHANGE_AFTER:-1}"; then
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
    printf '{"version":"0.1.0","scope":{"kind":"target","repo":"%s","target":"%s"},' \
      "${TEST_REPO}" "${TEST_TARGET}"
    printf '"degraded":["not checked in target scope"],'
    printf '"claims":[{"status":"%s","repo":"%s","target":"%s",' \
      "${claim_status}" "${TEST_REPO}" "${TEST_TARGET}"
    printf '"branch":"%s","agent_id":"%s","instance_id":"%s",' \
      "${TEST_BRANCH}" "${claim_agent_id}" "${claim_instance_id}"
    printf '"machine_id":"%s","expires_at":"%s"}],' \
      "${claim_machine_id}" "${claim_expiry}"
    if test "${include_heartbeat}" = 1; then
      printf '"heartbeats":[{"agent_id":"%s","instance_id":"%s",' \
        "${claim_agent_id}" "${claim_instance_id}"
      printf '"machine_id":"%s","branch":"%s","target":"%s#%s","liveness":"%s"}],' \
        "${claim_machine_id}" "${TEST_BRANCH}" "${TEST_REPO}" "${TEST_TARGET}" "${heartbeat_liveness}"
    else
      printf '"heartbeats":[],'
    fi
    printf '"batches":[],"events":[]}\n'
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
  claim)
    case "${FAKE_CLAIM_FAIL:-}" in
      refused) exit 3 ;;
      unavailable) exit 91 ;;
    esac
    claim_agent_id=""
    claim_instance_id=""
    while test "$#" -gt 0; do
      case "$1" in
        --agent-id) claim_agent_id="$2"; shift 2 ;;
        --instance-id) claim_instance_id="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    test -n "${claim_agent_id}" && test -n "${claim_instance_id}" || exit 93
    printf '%s\n%s\n' "${claim_agent_id}" "${claim_instance_id}" >"${TEST_CLAIM_STATE_FILE}"
    if test "${FAKE_STALL_CLAIM_AFTER_CREATE:-0}" = 1; then
      trap '' TERM INT HUP
      exec sleep 30
    fi
    ;;
  release)
    test "${FAKE_RELEASE_FAIL:-0}" != 1 || exit 93
    release_agent_id=""
    release_instance_id=""
    while test "$#" -gt 0; do
      case "$1" in
        --agent-id) release_agent_id="$2"; shift 2 ;;
        --instance-id) release_instance_id="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    test -s "${TEST_CLAIM_STATE_FILE}" || exit 96
    test "${release_agent_id}" = "$(sed -n '1p' "${TEST_CLAIM_STATE_FILE}")" || exit 96
    test "${release_instance_id}" = "$(sed -n '2p' "${TEST_CLAIM_STATE_FILE}")" || exit 96
    : >"${TEST_CLAIM_STATE_FILE}"
    ;;
  *)
    exit 94
    ;;
esac
FAKE_COORD

  cat >"${fake_bin}/bundle" <<'FAKE_BUNDLE'
#!/usr/bin/env bash
set -euo pipefail

test -z "${FAKE_BUNDLE_START_DELAY:-}" || sleep "${FAKE_BUNDLE_START_DELAY}"
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
  guard)
    exec ruby -e '
      require ENV.fetch("TEST_RELEASE_GUARD")
      ReleaseLeaseGuard.activate!(dry_run: false)
    '
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

  cat >"${fake_bin}/release-echild-harness" <<'ECHILD_HARNESS'
#!/usr/bin/env ruby
# frozen_string_literal: true

load ENV.fetch("TEST_RELEASE_SCRIPT")

class EchildTestSupervisor < ReleaseSupervisor
  private

  def spawn_release_group(...)
    result = super
    File.write(ENV.fetch("TEST_EXCEPTION_GROUP_LOG"), "#{result.fetch(1)}\n")
    result
  end

  def nonblocking_child_status(_child_pid)
    raise Errno::ECHILD
  end
end

exit EchildTestSupervisor.new(ARGV).run
ECHILD_HARNESS

  cat >"${fake_bin}/release-subreaper-failure-harness" <<'SUBREAPER_FAILURE_HARNESS'
#!/usr/bin/env ruby
# frozen_string_literal: true

load ENV.fetch("TEST_RELEASE_SCRIPT")

class SubreaperFailureTestSupervisor < ReleaseSupervisor
  private

  def enable_descendant_reaping!
    raise SupervisorError, "injected descendant reaping failure"
  end
end

exit SubreaperFailureTestSupervisor.new(ARGV).run
SUBREAPER_FAILURE_HARNESS

  cat >"${fake_bin}/release-unverified-child-harness" <<'UNVERIFIED_CHILD_HARNESS'
#!/usr/bin/env ruby
# frozen_string_literal: true

load ENV.fetch("TEST_RELEASE_SCRIPT")

class UnverifiedChildTestSupervisor < ReleaseSupervisor
  def run
    ready_reader, ready_writer = IO.pipe
    child_pid = fork do
      ready_reader.close
      Signal.trap("TERM", "IGNORE")
      ready_writer.puts(Process.getpgrp)
      ready_writer.close
      sleep 30
    end
    ready_writer.close
    inherited_pgid = Integer(ready_reader.gets, 10)
    raise "fixture child unexpectedly established its own process group" if inherited_pgid == child_pid

    stop_unverified_child(child_pid, grace: 0.1)
    begin
      Process.waitpid(child_pid, Process::WNOHANG)
      raise "unverified child was not reaped"
    rescue Errno::ECHILD
      child_pid = nil
      0
    end
  ensure
    ready_reader&.close
    ready_writer&.close unless ready_writer&.closed?
    if child_pid
      begin
        Process.kill("KILL", child_pid)
      rescue Errno::ESRCH
        nil
      end
      begin
        Process.waitpid(child_pid)
      rescue Errno::ECHILD
        nil
      end
    end
  end

  private

  public :stop_unverified_child
end

exit UnverifiedChildTestSupervisor.new([]).run
UNVERIFIED_CHILD_HARNESS

  chmod +x "${fake_bin}/agent-coord" "${fake_bin}/bundle" "${fake_bin}/release-handshake-harness" \
    "${fake_bin}/release-exception-harness" "${fake_bin}/release-subreaper-failure-harness" \
    "${fake_bin}/release-unverified-child-harness" "${fake_bin}/release-echild-harness"

  export PATH="${fake_bin}:${PATH}"
  export TEST_COORD_LOG="${coord_log}"
  export TEST_BUNDLE_LOG="${bundle_log}"
  export TEST_HEARTBEAT_COUNT_FILE="${heartbeat_count_file}"
  export TEST_STATUS_COUNT_FILE="${status_count_file}"
  export TEST_CLAIM_STATE_FILE="${claim_state_file}"
  export TEST_HANDSHAKE_LOG="${handshake_log}"
  export TEST_COORDINATION_PROCESS_LOG="${coordination_process_log}"
  export TEST_COORDINATION_DESCENDANT_LOG="${coordination_descendant_log}"
  export TEST_EXCEPTION_GROUP_LOG="${exception_group_log}"
  export TEST_RELEASE_SCRIPT="${release_script}"
  export TEST_RELEASE_GUARD="${repo_root}/rakelib/release_lease_guard"
  export TEST_REPO="shakacode/react_on_rails"
  export TEST_TARGET="release-line:17.1.0"
  export TEST_BRANCH="release/17.1.0"
  export RELEASE_COORDINATOR_ID="release-17.1.0-test-instance"
  export RELEASE_COORDINATOR_INSTANCE_ID="test-instance"
  export AGENT_COORD_MACHINE_ID="test-machine"
  export AGENT_COORD_API_URL="https://coord.example.test"
  export AGENT_COORD_API_TOKEN="${fake_secret}"
  unset AGENT_COORD_BACKEND AGENT_COORD_REF AGENT_COORD_STATE_ROOT AGENT_COORD_STATUS_STATE_ROOT
  export REACT_ON_RAILS_RELEASE_HEARTBEAT_INTERVAL="0.1"
  export REACT_ON_RAILS_RELEASE_TERMINATION_GRACE="0.5"
  unset FAKE_STATUS_FAIL FAKE_STATUS_AFTER_FIRST FAKE_STATUS_CHANGE_AFTER FAKE_PREFLIGHT_STATUS_MODE
  unset FAKE_FAIL_HEARTBEAT_AFTER FAKE_STALL_HEARTBEAT_AFTER
  unset FAKE_STALL_STATUS_AFTER FAKE_SUCCESS_STATUS_DESCENDANT
  unset FAKE_RELEASE_FAIL FAKE_CLAIM_FAIL FAKE_STALL_CLAIM_AFTER_CREATE FAKE_ATOMIC_CLAIM_MODE
  unset FAKE_ATOMIC_RENEW_MODE
  unset FAKE_DOCTOR_FAIL FAKE_DOCTOR_BACKEND FAKE_DOCTOR_PAYLOAD
  unset FAKE_BUNDLE_MODE FAKE_BUNDLE_START_DELAY FAKE_HANDSHAKE_MODE FAKE_EXCEPTION_MODE
  unset FAKE_HANDSHAKE_IGNORE_TERM
  unset REACT_ON_RAILS_RELEASE_COORDINATION_TIMEOUT
  unset REACT_ON_RAILS_RELEASE_CLAIM_RENEWAL_INTERVAL
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

run_echild_release() {
  (
    cd "${fake_repo}"
    "${fake_bin}/release-echild-harness" "$@"
  ) >"${output_log}" 2>&1
}

run_subreaper_failure_release() {
  (
    cd "${fake_repo}"
    "${fake_bin}/release-subreaper-failure-harness" "$@"
  ) >"${output_log}" 2>&1
}

run_unverified_child_harness() {
  "${fake_bin}/release-unverified-child-harness" >"${output_log}" 2>&1
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

wait_for_group_exit() {
  group_id="$1"
  for _attempt in $(seq 1 100); do
    ! kill -0 -- "-${group_id}" 2>/dev/null && return 0
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
  assert_not_contains "${coord_log}" $'claim-atomic|'
  assert_not_contains "${coord_log}" $'claim|'
  assert_not_contains "${coord_log}" $'release|'
}

assert_secret_absent() {
  assert_not_contains "${output_log}" "${fake_secret}"
  assert_not_contains "${coord_log}" "${fake_secret}"
  assert_not_contains "${bundle_log}" "${fake_secret}"
}

setup_case doctor-success
run_release --doctor || fail "release doctor failed"
assert_contains "${coord_log}" $'doctor|--json|'
assert_empty "${bundle_log}"
assert_contains "${output_log}" "Release machine doctor: PASS"
assert_not_contains "${coord_log}" $'status|'
assert_no_coordination_mutation
assert_secret_absent
pass "doctor validates the shared backend with read-only checks"

setup_case doctor-local-backend
export FAKE_DOCTOR_BACKEND="local"
if run_release --doctor; then
  fail "release doctor accepted a local backend"
fi
assert_contains "${coord_log}" $'doctor|--json|'
assert_not_contains "${coord_log}" $'status|'
assert_no_coordination_mutation
assert_contains "${output_log}" "shared HTTP backend"
assert_secret_absent
pass "doctor rejects local coordination mode"

setup_case live-local-backend-selector
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export AGENT_COORD_STATE_ROOT="${case_dir}/local-coordination"
if run_release; then
  fail "live release accepted a local coordination selector"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "unset local/backend selector variable(s): AGENT_COORD_STATE_ROOT"
assert_secret_absent
pass "live mode rejects local coordination before claim or release work"

setup_case live-wrong-backend
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_DOCTOR_BACKEND="local"
if run_release; then
  fail "live release accepted a non-HTTP coordination backend"
fi
assert_contains "${coord_log}" $'doctor|--json|'
assert_no_coordination_mutation
assert_empty "${bundle_log}"
assert_contains "${output_log}" "agent-coord must use the shared HTTP backend"
assert_secret_absent
pass "live mode rejects a non-HTTP backend before claim or release work"

setup_case live-unhealthy-backend
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_DOCTOR_FAIL=1
if run_release; then
  fail "live release accepted an unhealthy coordination backend"
fi
assert_contains "${coord_log}" $'doctor|--json|'
assert_no_coordination_mutation
assert_empty "${bundle_log}"
assert_contains "${output_log}" "verify the private HTTP backend URL and token"
assert_secret_absent
pass "live mode rejects an unhealthy backend before claim or release work"

setup_case doctor-missing-token
unset AGENT_COORD_API_TOKEN
if run_release --doctor; then
  fail "release doctor accepted a missing backend token"
fi
assert_empty "${coord_log}"
assert_contains "${output_log}" "AGENT_COORD_API_TOKEN is missing"
assert_secret_absent
pass "doctor names the missing private token setup action"

setup_case doctor-missing-npm
doctor_path="${case_dir}/doctor-path"
mkdir -p "${doctor_path}"
for command_name in agent-coord git gh bundle pnpm gem bash; do
  ln -s "$(command -v "${command_name}")" "${doctor_path}/${command_name}"
done
ln -s "$(ruby -rrbconfig -e 'print RbConfig.ruby')" "${doctor_path}/ruby"
if PATH="${doctor_path}" run_release --doctor; then
  fail "release doctor accepted a PATH without npm"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "install required release tool(s) on PATH: npm"
assert_secret_absent
pass "doctor requires npm because the release task invokes it directly"

setup_case doctor-backend-failure
export FAKE_DOCTOR_FAIL=1
if run_release --doctor; then
  fail "release doctor accepted an unhealthy backend"
fi
assert_contains "${coord_log}" $'doctor|--json|'
assert_no_coordination_mutation
assert_contains "${output_log}" "verify the private HTTP backend URL and token"
assert_secret_absent
pass "doctor reports backend health or authentication failure without diagnostics"

setup_case doctor-malformed-shape
export FAKE_DOCTOR_PAYLOAD='[]'
if run_release --doctor; then
  fail "release doctor accepted a non-object payload"
fi
assert_contains "${coord_log}" $'doctor|--json|'
assert_no_coordination_mutation
assert_contains "${output_log}" "agent-coord doctor returned malformed JSON"
assert_not_contains "${output_log}" "TypeError"
assert_not_contains "${output_log}" "script/release:"
assert_secret_absent
pass "doctor rejects structurally malformed JSON without a stack trace"

setup_case changelog-selected-dry-run
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID AGENT_COORD_MACHINE_ID AGENT_COORD_API_TOKEN
run_release --dry-run || fail "argumentless dry-run failed"
assert_empty "${coord_log}"
assert_contains "${bundle_log}" 'args|exec|rake|release[17.1.0.rc.0,true]'
assert_contains "${bundle_log}" 'contract:'
pass "dry-run selects the first prepared changelog version"

setup_case missing-changelog-version
cat >"${fake_repo}/CHANGELOG.md" <<'CHANGELOG'
### [Unreleased]

### [17.1.0.rc.0] - 2026-08-23

#### Fixed
CHANGELOG
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
if run_release; then
  fail "live release accepted an empty changelog section"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "No releasable version found in CHANGELOG.md."
assert_contains "${output_log}" "Then rerun: script/release"
assert_secret_absent
pass "empty changelog selection stops before coordination"

setup_case first-valid-changelog-version
cat >"${fake_repo}/CHANGELOG.md" <<'CHANGELOG'
### [99.0.0] - 2020-01-01

- Historical content before the marker.

### [Unreleased]

### [not-a-release] - 2026-08-24

- Draft heading.

### [17.1.0.rc.1] - 2026-08-24

- Prepared next release candidate.

### [17.1.0.rc.0] - 2026-08-23

- Older release candidate.
CHANGELOG
run_release --dry-run || fail "dry-run did not skip invalid changelog headings"
assert_contains "${bundle_log}" 'args|exec|rake|release[17.1.0.rc.1,true]'
assert_empty "${coord_log}"
pass "selection uses the first valid version section after Unreleased"

setup_case stale-changelog-version
write_current_version "17.1.0.rc.1"
if run_release --dry-run; then
  fail "dry-run accepted a changelog version behind the current checkout"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "does not advance the current checkout version 17.1.0.rc.1"
pass "selection rejects a stale release candidate"

setup_case positional-version
if run_release --dry-run 17.1.0.rc.0; then
  fail "dry-run accepted a positional version"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "VERSION is read from CHANGELOG.md; do not pass it."
pass "wrapper rejects positional versions"

setup_case stable-main-dry-run
git -C "${fake_repo}" switch -q -c main
write_changelog "17.1.0"
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID AGENT_COORD_MACHINE_ID AGENT_COORD_API_TOKEN
run_release --dry-run || fail "stable main dry-run failed"
assert_empty "${coord_log}"
assert_contains "${bundle_log}" 'args|exec|rake|release[17.1.0,true]'
assert_contains "${bundle_log}" 'contract:'
pass "stable main dry-run uses the documented release path"

setup_case automatic-coordination
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
FAKE_BUNDLE_MODE=success run_release || fail "automatic coordination release failed"
assert_contains "${coord_log}" $'claim-atomic|'
assert_not_contains "${coord_log}" $'claim|'
assert_contains "${coord_log}" $'heartbeat|'
assert_contains "${coord_log}" $'status|'
assert_contains "${coord_log}" $'release|'
assert_contains "${bundle_log}" 'args|exec|rake|release[17.1.0.rc.0]'
assert_secret_absent
pass "live mode acquires and cleans up a process-owned release lease"

setup_case managed-acquisition-empty-status
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_PREFLIGHT_STATUS_MODE=empty-first
FAKE_BUNDLE_MODE=success run_release || fail "managed release rejected an unclaimed release line"
status_line="$(awk -F'|' '$1 == "status" { print NR; exit }' "${coord_log}")"
claim_line="$(awk -F'|' '$1 == "claim-atomic" { print NR; exit }' "${coord_log}")"
test -n "${status_line}" && test -n "${claim_line}" && test "${status_line}" -lt "${claim_line}" || \
  fail "managed acquisition did not read authoritative status before claim"
assert_contains "${bundle_log}" 'args|exec|rake|release[17.1.0.rc.0]'
assert_secret_absent
pass "an authoritative unclaimed status permits managed acquisition"

setup_case managed-atomic-claim-race
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_ATOMIC_CLAIM_MODE=foreign-race
if run_release; then
  fail "managed release took over a claim created during acquisition"
fi
assert_contains "${coord_log}" $'claim-atomic|'
assert_not_contains "${coord_log}" $'claim|'
assert_not_contains "${coord_log}" $'release|'
assert_empty "${bundle_log}"
assert_secret_absent
pass "managed acquisition atomically refuses an intervening foreign claim"

for foreign_mode in dead expired missing-heartbeat; do
  setup_case "managed-acquisition-foreign-${foreign_mode}"
  unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
  export FAKE_PREFLIGHT_STATUS_MODE="foreign-${foreign_mode}"
  if run_release; then
    fail "managed release acquired over a foreign ${foreign_mode} claim"
  fi
  assert_contains "${coord_log}" $'status|'
  assert_not_contains "${coord_log}" $'claim|'
  assert_not_contains "${coord_log}" $'release|'
  assert_empty "${bundle_log}"
  assert_contains "${output_log}" "release line already has an active foreign claim"
  assert_secret_absent
  pass "foreign ${foreign_mode} claims block managed acquisition without takeover"
done

setup_case managed-acquisition-status-unavailable
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_STATUS_FAIL=1
if run_release; then
  fail "managed release continued after authoritative status became unavailable"
fi
assert_contains "${coord_log}" $'status|'
assert_not_contains "${coord_log}" $'claim|'
assert_not_contains "${coord_log}" $'release|'
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release-line pre-acquisition status is unavailable or UNKNOWN"
assert_secret_absent
pass "unavailable status fails closed before managed acquisition"

setup_case managed-acquisition-status-malformed
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_PREFLIGHT_STATUS_MODE=malformed
if run_release; then
  fail "managed release continued after malformed authoritative status"
fi
assert_contains "${coord_log}" $'status|'
assert_not_contains "${coord_log}" $'claim|'
assert_not_contains "${coord_log}" $'release|'
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release-line pre-acquisition status is malformed or UNKNOWN"
assert_secret_absent
pass "malformed status fails closed before managed acquisition"

setup_case fresh-process-identities
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
FAKE_BUNDLE_MODE=success run_release || fail "first automatically coordinated release failed"
FAKE_BUNDLE_MODE=success run_release || fail "second automatically coordinated release failed"
claim_instances="$(
  awk -F'|' '$1 == "claim-atomic" { for (i = 1; i <= NF; i += 1) if ($i == "--instance-id") print $(i + 1) }' \
    "${coord_log}"
)"
test "$(printf '%s\n' "${claim_instances}" | sed '/^$/d' | wc -l | tr -d ' ')" = 2 || \
  fail "expected two generated claim identities"
test "$(printf '%s\n' "${claim_instances}" | sed '/^$/d' | sort -u | wc -l | tr -d ' ')" = 2 || \
  fail "release invocations reused a process identity"
printf '%s\n' "${claim_instances}" | while IFS= read -r instance_id; do
  case "${instance_id}" in
    ????????-????-????-????-????????????) ;;
    *) fail "generated release identity was not a UUID: ${instance_id}" ;;
  esac
done
assert_secret_absent
pass "each live invocation generates a fresh UUID identity"

setup_case automatic-claim-refusal
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_CLAIM_FAIL=refused
if run_release; then
  fail "automatic coordination ignored an existing claim"
fi
assert_contains "${coord_log}" $'claim-atomic|'
assert_not_contains "${coord_log}" $'claim|'
assert_not_contains "${coord_log}" $'heartbeat|'
assert_not_contains "${coord_log}" $'release|'
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release-line lease claim was refused"
assert_secret_absent
pass "existing release-line claim refusal stops before release work"

setup_case automatic-claim-response-lost
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_STALL_CLAIM_AFTER_CREATE=1
export REACT_ON_RAILS_RELEASE_COORDINATION_TIMEOUT=30
(
  cd "${fake_repo}"
  exec "${release_script}"
) >"${output_log}" 2>&1 &
wrapper_pid=$!
for _attempt in $(seq 1 200); do
  test -s "${claim_state_file}" && test -s "${coordination_process_log}" && break
  sleep 0.05
done
if ! test -s "${claim_state_file}" || ! test -s "${coordination_process_log}"; then
  cleanup_stalled_wrapper "${wrapper_pid}"
  fail "claim was not accepted before simulating its lost response"
fi
coordination_id="$(cut -d: -f1 "${coordination_process_log}")"
case "${coordination_id}" in
  ''|*[!0-9]*)
    cleanup_stalled_wrapper "${wrapper_pid}"
    fail "invalid coordination process ${coordination_id}"
    ;;
esac
kill -KILL "${coordination_id}"
if ! wait_for_process_exit "${wrapper_pid}"; then
  cleanup_stalled_wrapper "${wrapper_pid}"
  fail "release did not stop after an accepted claim response was lost"
fi
if wait "${wrapper_pid}"; then
  fail "release continued after an accepted claim response was lost"
fi
assert_contains "${coord_log}" $'claim-atomic|'
assert_contains "${coord_log}" $'release|'
assert_not_contains "${coord_log}" $'--force|'
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release-line atomic claim is unavailable or UNKNOWN"
assert_secret_absent
pass "accepted claims with lost responses receive exact-identity cleanup"

setup_case signal-during-claim-acquisition
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_STALL_CLAIM_AFTER_CREATE=1
export REACT_ON_RAILS_RELEASE_COORDINATION_TIMEOUT=5
(
  cd "${fake_repo}"
  exec "${release_script}"
) >"${output_log}" 2>&1 &
wrapper_pid=$!
for _attempt in $(seq 1 100); do
  test -s "${claim_state_file}" && break
  sleep 0.05
done
test -s "${claim_state_file}" || fail "claim was not accepted before the acquisition signal"
kill -TERM "${wrapper_pid}"
if ! wait_for_process_exit "${wrapper_pid}"; then
  cleanup_stalled_wrapper "${wrapper_pid}"
  fail "signal during claim acquisition did not stop the wrapper"
fi
if wait "${wrapper_pid}"; then
  fail "signal during claim acquisition exited successfully"
fi
assert_contains "${coord_log}" $'claim-atomic|'
assert_contains "${coord_log}" $'release|'
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release-line atomic claim is unavailable or UNKNOWN"
assert_secret_absent
pass "claim acquisition signals retain handlers through exact-identity cleanup"

setup_case automatic-release-failure-cleanup
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_BUNDLE_MODE=failure
if run_release; then
  fail "failed release command exited successfully"
fi
assert_contains "${coord_log}" $'claim-atomic|'
assert_contains "${coord_log}" $'release|'
test "$(tail -n 1 "${coord_log}" | cut -d'|' -f1)" = release || fail "failed release did not clean up last"
assert_secret_absent
pass "failed release work cleans up its process-owned claim"

setup_case missing-identity
unset RELEASE_COORDINATOR_INSTANCE_ID
if run_release; then
  fail "live release accepted missing identity"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "RELEASE_COORDINATOR_INSTANCE_ID"
assert_secret_absent
pass "live mode refuses missing identity"

setup_case wrong-branch
git -C "${fake_repo}" switch -q -c main
if run_release; then
  fail "live release accepted the wrong branch"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release/17.1.0"
assert_secret_absent
pass "live mode requires the matching release branch"

setup_case prerelease-feature-branch
git -C "${fake_repo}" switch -q -c feature/release-test
if run_release --dry-run; then
  fail "prerelease dry-run accepted a feature branch"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release/17.1.0"
pass "prerelease mode rejects feature branches"

setup_case mismatched-release-branch
write_changelog "17.2.0"
if run_release --dry-run; then
  fail "stable dry-run accepted a mismatched release branch"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release/17.2.0"
pass "stable mode rejects mismatched release branches"

setup_case reconciliation-main
git -C "${fake_repo}" switch -q -c main
write_changelog "17.1.0"
if run_release --reconcile-accelerated-rc; then
  fail "accelerated reconciliation accepted stable main"
fi
assert_empty "${coord_log}"
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release/17.1.0"
pass "accelerated reconciliation remains release-branch-only"

setup_case matching-state
FAKE_BUNDLE_MODE=success run_release || fail "matching live release failed"
assert_contains "${bundle_log}" 'args|exec|rake|release[17.1.0.rc.0]'
group_count="$(awk -F: '/^(bundle|child):/ { print $3 }' "${bundle_log}" | sort -u | wc -l | tr -d ' ')"
test "${group_count}" = 1 || fail "release processes did not share one process group"
assert_contains "${coord_log}" 'heartbeat|--agent-id|release-17.1.0-test-instance|--instance-id|test-instance'
assert_contains "${coord_log}" '|--repo|shakacode/react_on_rails|--target|release-line:17.1.0'
assert_contains "${coord_log}" '|--branch|release/17.1.0|'
assert_contains "${bundle_log}" '"release_version":"17.1.0.rc.0"'
assert_contains "${coord_log}" '|machine=test-machine'
process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
assert_contains "${output_log}" "process group ${process_group}"
assert_no_coordination_mutation
assert_secret_absent
pass "matching state runs one identity-bound process group"

setup_case external-identity-ownership-before-heartbeat
export FAKE_PREFLIGHT_STATUS_MODE=foreign-active
if run_release; then
  fail "external release identity heartbeated without owning the release-line claim"
fi
assert_contains "${coord_log}" $'status|'
assert_not_contains "${coord_log}" $'heartbeat|'
assert_empty "${bundle_log}"
assert_contains "${output_log}" "release claim agent_id does not match the wrapper contract"
assert_secret_absent
pass "external identities prove ownership before sending a heartbeat"

setup_case descendant-reaping-unavailable
if run_subreaper_failure_release; then
  fail "live release continued without descendant reaping"
fi
assert_contains "${coord_log}" $'doctor|--json|'
assert_no_coordination_mutation
assert_empty "${bundle_log}"
assert_contains "${output_log}" "injected descendant reaping failure"
assert_secret_absent
pass "live mode enables descendant reaping before claim or release work"

if supervisor_case_enabled unverified-child; then
  setup_case unverified-child-before-process-group
  run_unverified_child_harness || fail "unverified child termination harness failed"
  assert_secret_absent
  pass "pre-process-group TERM-resistant child is killed and reaped"
fi

setup_case stable-main-live
git -C "${fake_repo}" switch -q -c main
write_changelog "17.1.0"
export TEST_BRANCH="main"
FAKE_BUNDLE_MODE=success run_release || fail "stable main live release failed"
assert_contains "${bundle_log}" 'args|exec|rake|release[17.1.0]'
assert_contains "${coord_log}" '|--repo|shakacode/react_on_rails|--target|release-line:17.1.0'
assert_contains "${coord_log}" '|--branch|main|'
assert_contains "${bundle_log}" '"release_version":"17.1.0"'
assert_no_coordination_mutation
assert_secret_absent
pass "stable main live release binds the lease to main"

setup_case reconciliation
FAKE_BUNDLE_MODE=success run_release --reconcile-accelerated-rc || \
  fail "supervised accelerated RC reconciliation failed"
assert_contains "${bundle_log}" 'args|exec|rake|release:reconcile_accelerated_rc[17.1.0.rc.0]'
assert_no_coordination_mutation
assert_secret_absent
pass "accelerated RC reconciliation uses the supervised release contract"

setup_case successful-coordination-descendant-cleanup
export FAKE_SUCCESS_STATUS_DESCENDANT=1
FAKE_BUNDLE_MODE=success run_release || fail "release with successful coordination child failed"
test -s "${coordination_descendant_log}" || fail "successful coordination child did not fork its test descendant"
coordination_descendant="$(cat "${coordination_descendant_log}")"
if kill -0 "${coordination_descendant}" 2>/dev/null; then
  kill -KILL "${coordination_descendant}" 2>/dev/null || true
  fail "successful coordination descendant survived command completion"
fi
assert_secret_absent
pass "successful coordination commands clean up descendants before continuing"

if supervisor_case_enabled fence-status-signal; then
  setup_case signal-during-fence-status
  # External identities now perform one ownership read before heartbeat and one
  # after heartbeat before spawning. Stall the next read inside the release group.
  export FAKE_STALL_STATUS_AFTER=2
  export FAKE_BUNDLE_MODE=guard
  export REACT_ON_RAILS_RELEASE_HEARTBEAT_INTERVAL=5
  (
    cd "${fake_repo}"
    exec "${release_script}"
  ) >"${output_log}" 2>&1 &
  wrapper_pid=$!
  for _attempt in $(seq 1 100); do
    test -s "${coordination_descendant_log}" && break
    sleep 0.05
  done
  test -s "${coordination_descendant_log}" || fail "stalled fence status process never started"
  kill -TERM "${wrapper_pid}"
  if ! wait_for_process_exit "${wrapper_pid}"; then
    cleanup_stalled_wrapper "${wrapper_pid}"
    fail "signal during a stalled fence status read did not stop the wrapper"
  fi
  if wait "${wrapper_pid}"; then
    fail "signal during a stalled fence status read exited successfully"
  fi
  coordination_id="$(cut -d: -f1 "${coordination_process_log}")"
  coordination_group="$(cut -d: -f2 "${coordination_process_log}")"
  coordination_descendant="$(cat "${coordination_descendant_log}")"
  release_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
  test "${coordination_group}" = "${release_group}" || \
    fail "fence status process escaped the supervised release group"
  assert_group_dead "${release_group}"
  ! kill -0 "${coordination_id}" 2>/dev/null || fail "fence status process survived wrapper termination"
  ! kill -0 "${coordination_descendant}" 2>/dev/null || fail "fence status descendant survived wrapper termination"
  assert_contains "${output_log}" "signal TERM"
  assert_no_coordination_mutation
  assert_secret_absent
  pass "supervisor termination cleans up a stalled fence status process and descendants"
fi

if supervisor_case_enabled heartbeat-timeout; then
  setup_case stalled-heartbeat-timeout
  export FAKE_STALL_HEARTBEAT_AFTER=1
  export FAKE_BUNDLE_MODE=hold
  export REACT_ON_RAILS_RELEASE_COORDINATION_TIMEOUT=0.5
  (
    cd "${fake_repo}"
    exec "${release_script}"
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
    exec "${release_script}"
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
    if run_exception_release; then
      fail "${exception_mode} supervisor exception exited successfully"
    fi
    process_group="$(cat "${exception_group_log}")"
    assert_group_dead "${process_group}"
    assert_no_coordination_mutation
    assert_secret_absent
    pass "${exception_mode} supervisor exception terminates the release group"
  fi
done

setup_case managed-echild-retains-claim
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_BUNDLE_MODE=hold
if run_echild_release; then
  fail "managed release with unproven process-group termination exited successfully"
fi
process_group="$(cat "${exception_group_log}")"
wait_for_group_exit "${process_group}" || fail "death watch did not stop the unproven release group"
assert_contains "${coord_log}" $'claim-atomic|'
assert_not_contains "${coord_log}" $'release|'
assert_contains "${output_log}" "retaining release-line lease because process-group termination was not proven"
assert_secret_absent
pass "managed release retains its claim when process-group termination is unproven"

setup_case managed-claim-renewal
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_BUNDLE_MODE=hold
export REACT_ON_RAILS_RELEASE_CLAIM_RENEWAL_INTERVAL=0.2
(
  cd "${fake_repo}"
  exec "${release_script}"
) >"${output_log}" 2>&1 &
wrapper_pid=$!
for _attempt in $(seq 1 100); do
  grep -q $'claim-atomic|--renew|' "${coord_log}" 2>/dev/null && break
  sleep 0.05
done
if ! grep -q $'claim-atomic|--renew|' "${coord_log}" 2>/dev/null; then
  cleanup_stalled_wrapper "${wrapper_pid}"
  fail "managed release did not renew its claim before expiry"
fi
kill -TERM "${wrapper_pid}"
wait_for_process_exit "${wrapper_pid}" || cleanup_stalled_wrapper "${wrapper_pid}"
wait "${wrapper_pid}" || true
assert_contains "${coord_log}" $'release|'
assert_secret_absent
pass "managed release renews its exact claim during long-running work"

setup_case managed-claim-renewal-failure
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_BUNDLE_MODE=hold
export FAKE_BUNDLE_START_DELAY=0.5
export FAKE_ATOMIC_RENEW_MODE=refused-after-child-start
export REACT_ON_RAILS_RELEASE_CLAIM_RENEWAL_INTERVAL=0.2
if run_release; then
  fail "managed release stayed live after atomic claim renewal refusal"
fi
process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
test -n "${process_group}" || fail "managed renewal-failure case never started the release group"
assert_group_dead "${process_group}"
assert_contains "${coord_log}" $'claim-atomic|--renew|'
assert_contains "${coord_log}" $'release|'
assert_contains "${output_log}" "Release lease refresh failed"
assert_contains "${bundle_log}" "liveness:eof"
assert_contains "${bundle_log}" "termination:signal"
assert_secret_absent
pass "managed claim renewal refusal terminates the group before exact cleanup"

setup_case lease-failure
export FAKE_FAIL_HEARTBEAT_AFTER=1
export FAKE_BUNDLE_MODE=hold
export REACT_ON_RAILS_RELEASE_HEARTBEAT_INTERVAL=0.5
if run_release; then
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
  export FAKE_STATUS_CHANGE_AFTER=2
  export FAKE_FAIL_HEARTBEAT_AFTER=4
  export FAKE_BUNDLE_MODE=hold
  export REACT_ON_RAILS_RELEASE_HEARTBEAT_INTERVAL=0.5
  if run_release; then
    fail "release stayed live after its claim became ${claim_loss}"
  fi
  process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
  test -n "${process_group}" || fail "claim-${claim_loss} case never started the release group"
  assert_contains "${output_log}" "terminating process group ${process_group}"
  assert_contains "${bundle_log}" "liveness:eof"
  assert_contains "${bundle_log}" "termination:signal"
  test "$(cat "${status_count_file}")" = 3 || fail "claim-${claim_loss} did not stop on its third status read"
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
  if run_handshake_release; then
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
  if run_handshake_release; then
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
    exec "${fake_bin}/release-handshake-harness"
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
unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
export FAKE_BUNDLE_MODE=hold
(
  cd "${fake_repo}"
  exec "${release_script}"
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
assert_contains "${coord_log}" $'claim-atomic|'
assert_contains "${coord_log}" $'release|'
test "$(tail -n 1 "${coord_log}" | cut -d'|' -f1)" = release || fail "signal cleanup was not last"
assert_secret_absent
pass "signals terminate the release group and clean up the process-owned claim"

if supervisor_case_enabled death-watch-reader-error; then
  if ! RELEASE_SCRIPT="${release_script}" ruby <<'RUBY'
load ENV.fetch("RELEASE_SCRIPT")

ready_reader, ready_writer = IO.pipe
release_pid = Process.fork do
  ready_reader.close
  Process.setpgid(0, 0)
  ready_writer.write("1")
  ready_writer.close
  sleep 30
end
ready_writer.close
ready_reader.read(1)
ready_reader.close

liveness_reader, liveness_writer = IO.pipe
death_reader, death_writer = IO.pipe
ready_reader, ready_writer = IO.pipe
death_reader.close
pipes = ReleaseSupervisor::ReleasePipes.new(
  liveness_reader:,
  liveness_writer:,
  death_reader:,
  death_writer:,
  ready_reader:,
  ready_writer:
)

supervisor = ReleaseSupervisor.new([])
watcher_pid = supervisor.send(:fork_supervisor_death_watch, pipes, release_pid)
Process.waitpid(watcher_pid)

release_reaped = 100.times.any? do
  break true if Process.waitpid(release_pid, Process::WNOHANG)

  sleep 0.01
  false
end
unless release_reaped
  warn "release process group survived a death-watch reader error"
  Process.kill("KILL", -release_pid)
  Process.waitpid(release_pid)
  exit 1
end

begin
  Process.kill(0, -release_pid)
  warn "release process group survived a death-watch reader error"
  exit 1
rescue Errno::ESRCH
  nil
end
RUBY
  then
    fail "death-watch reader error did not kill the release process group"
  fi
  pass "death-watch reader errors still kill the release process group"
fi

if supervisor_case_enabled supervisor-death; then
  setup_case supervisor-death
  export FAKE_BUNDLE_MODE=hold
  (
    cd "${fake_repo}"
    exec "${release_script}"
  ) >"${output_log}" 2>&1 &
  wrapper_pid=$!
  for _attempt in $(seq 1 100); do
    test -s "${bundle_log}" && break
    sleep 0.05
  done
  test -s "${bundle_log}" || fail "supervisor-death case never started the release group"
  process_group="$(awk -F: '/^bundle:/ { print $3; exit }' "${bundle_log}")"
  kill -KILL "${wrapper_pid}"
  wait "${wrapper_pid}" 2>/dev/null || true
  if ! wait_for_group_exit "${process_group}"; then
    kill -KILL -- "-${process_group}" 2>/dev/null || true
    fail "release process group survived supervisor SIGKILL"
  fi
  assert_no_coordination_mutation
  assert_secret_absent
  pass "supervisor death immediately kills the release process group"
fi

printf '1..%d\n' "${tests_run}"
