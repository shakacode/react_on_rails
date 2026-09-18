#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ruby_executable="$(ruby -rrbconfig -e 'print RbConfig.ruby')"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/react-on-rails-release-test.XXXXXX")"
trap 'rm -rf "${test_root}"' EXIT

pass_count=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %d - %s\n' "${pass_count}" "$1"
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "${expected}" "${file}" || fail "${file} did not contain: ${expected}"
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if grep -Fq -- "${unexpected}" "${file}"; then
    fail "${file} unexpectedly contained: ${unexpected}"
  fi
}

wait_for_log() {
  local file="$1"
  local pattern="$2"
  local attempt
  for attempt in $(seq 1 100); do
    grep -Fq -- "${pattern}" "${file}" 2>/dev/null && return 0
    sleep 0.05
  done
  return 1
}

wait_for_group_exit() {
  local pgid="$1"
  local attempt
  for attempt in $(seq 1 100); do
    ! kill -0 -- "-${pgid}" 2>/dev/null && return 0
    sleep 0.05
  done
  return 1
}

setup_case() {
  local name="$1"
  case_dir="${test_root}/${name}"
  fake_repo="${case_dir}/repo"
  fake_bin="${case_dir}/bin"
  output_log="${case_dir}/output.log"
  bundle_log="${case_dir}/bundle.log"
  mkdir -p "${fake_repo}/script" "${fake_repo}/rakelib" \
    "${fake_repo}/react_on_rails/lib/react_on_rails" "${fake_bin}"

  cp "${repo_root}/script/release" "${fake_repo}/script/release"
  cp "${repo_root}/rakelib/release_changelog_selector.rb" "${fake_repo}/rakelib/release_changelog_selector.rb"
  cp "${repo_root}/rakelib/release_lease_guard.rb" "${fake_repo}/rakelib/release_lease_guard.rb"
  chmod +x "${fake_repo}/script/release"

  cat >"${fake_repo}/CHANGELOG.md" <<'CHANGELOG'
### [Unreleased]

### [17.1.0.rc.0] - 2026-08-23

- Release candidate.
CHANGELOG
  cat >"${fake_repo}/react_on_rails/lib/react_on_rails/version.rb" <<'VERSION'
module ReactOnRails
  VERSION = "17.0.4"
end
VERSION

  cat >"${fake_bin}/git" <<'RUBY'
#!/usr/bin/env ruby
case ARGV
when ["rev-parse", "--show-toplevel"]
  puts ENV.fetch("TEST_FAKE_REPO")
when ["branch", "--show-current"]
  puts ENV.fetch("TEST_BRANCH")
else
  warn "unexpected git arguments: #{ARGV.inspect}"
  exit 2
end
RUBY

  cat >"${fake_bin}/bundle" <<'RUBY'
#!/usr/bin/env ruby
require "json"

log = ENV.fetch("TEST_BUNDLE_LOG")
contract = ENV.fetch("REACT_ON_RAILS_RELEASE_LEASE_CONTRACT", "")
File.open(log, "a") do |file|
  file.puts "args:#{ARGV.join("|")}"
  file.puts "supervised:#{ENV.fetch("REACT_ON_RAILS_RELEASE_SUPERVISED", "")}"
  file.puts "contract:#{contract}"
  file.puts "start:#{Process.pid}:#{Process.getpgrp}"
end

unless contract.empty?
  require File.join(ENV.fetch("TEST_FAKE_REPO"), "rakelib", "release_lease_guard")
  ReleaseLeaseGuard.activate!(dry_run: false)
  ReleaseLeaseGuard.fence!
  parsed = JSON.parse(contract)
  forbidden = %w[agent_id instance_id machine_id]
  abort "coordination identity leaked into contract" unless (parsed.keys & forbidden).empty?
  File.open(log, "a") { |file| file.puts "guard:pass" }
end

case ENV.fetch("TEST_BUNDLE_MODE", "success")
when "success"
  exit 0
when "failure"
  exit 7
when "sleep"
  Signal.trap("TERM") do
    File.open(log, "a") { |file| file.puts "signal:TERM" }
    exit 143
  end
  File.open(log, "a") { |file| file.puts "sleeping" }
  sleep 30
else
  abort "unknown TEST_BUNDLE_MODE"
end
RUBY

  chmod +x "${fake_bin}/git" "${fake_bin}/bundle"
  ln -s "${ruby_executable}" "${fake_bin}/ruby"
  for command_name in gh pnpm npm gem; do
    ln -s /usr/bin/true "${fake_bin}/${command_name}"
  done

  export PATH="${fake_bin}:/usr/bin:/bin:/usr/sbin:/sbin"
  export TEST_FAKE_REPO="${fake_repo}"
  export TEST_BUNDLE_LOG="${bundle_log}"
  export TEST_BRANCH="release/17.1.0"
  export TEST_BUNDLE_MODE="success"
  unset AGENT_COORD_API_URL AGENT_COORD_API_TOKEN AGENT_COORD_MACHINE_ID
  unset RELEASE_COORDINATOR_ID RELEASE_COORDINATOR_INSTANCE_ID
  : >"${output_log}"
  : >"${bundle_log}"
}

run_release() {
  (
    cd "${fake_repo}"
    "${fake_repo}/script/release" "$@"
  ) >"${output_log}" 2>&1
}

run_live_headless() {
  TEST_CASE_REPO="${fake_repo}" ruby -e '
    Process.setsid
    $stdin.reopen("/dev/null")
    Dir.chdir(ENV.fetch("TEST_CASE_REPO"))
    exec File.join(ENV.fetch("TEST_CASE_REPO"), "script", "release")
  ' >"${output_log}" 2>&1
}

start_live_headless() {
  TEST_CASE_REPO="${fake_repo}" ruby -e '
    Process.setsid
    $stdin.reopen("/dev/null")
    Dir.chdir(ENV.fetch("TEST_CASE_REPO"))
    exec File.join(ENV.fetch("TEST_CASE_REPO"), "script", "release")
  ' >"${output_log}" 2>&1 &
  wrapper_pid=$!
}

setup_case doctor-without-agent-coord
run_release --doctor || fail "release doctor failed without agent-coord"
assert_contains "${output_log}" "Release machine doctor: PASS"
assert_contains "${output_log}" "publication supervision: local process guard ready"
assert_not_contains "${output_log}" "agent-coord:"
pass "doctor validates only local release prerequisites"

setup_case doctor-missing-npm
rm "${fake_bin}/npm"
if PATH="${fake_bin}" run_release --doctor; then
  fail "release doctor accepted a PATH without npm"
fi
assert_contains "${output_log}" "install required release tool(s) on PATH: npm"
pass "doctor still validates publishing tools"

setup_case changelog-selected-dry-run
run_release --dry-run || fail "argumentless dry-run failed"
assert_contains "${bundle_log}" "args:exec|rake|release[17.1.0.rc.0,true]"
assert_contains "${bundle_log}" "contract:"
assert_not_contains "${bundle_log}" '"release_version"'
pass "dry-run selects the prepared changelog without a live contract"

setup_case positional-version
if run_release 17.1.0.rc.0; then
  fail "release accepted a positional version"
fi
assert_contains "${output_log}" "VERSION is read from CHANGELOG.md"
pass "release versions remain changelog-driven"

setup_case wrong-branch
export TEST_BRANCH="feature/not-a-release"
if run_live_headless; then
  fail "live release accepted a feature branch"
fi
assert_contains "${output_log}" "release must run from branch release/17.1.0"
pass "live release remains bound to its release branch"

setup_case live-without-agent-coord
run_live_headless || fail "live release failed without agent-coord"
assert_contains "${bundle_log}" "args:exec|rake|release[17.1.0.rc.0]"
assert_contains "${bundle_log}" "supervised:true"
assert_contains "${bundle_log}" "guard:pass"
assert_not_contains "${bundle_log}" "agent_id"
assert_not_contains "${bundle_log}" "machine_id"
assert_contains "${output_log}" "completed with status 0"
pass "live publication uses only the local supervisor contract"

setup_case live-failure-status
export TEST_BUNDLE_MODE="failure"
if run_live_headless; then
  fail "live release hid the child failure"
fi
assert_contains "${output_log}" "completed with status 7"
pass "release child failures propagate through the supervisor"

setup_case signal-cleanup
export TEST_BUNDLE_MODE="sleep"
start_live_headless
wait_for_log "${bundle_log}" "sleeping" || fail "release child did not become ready"
process_group="$(awk -F: '/^start:/ { print $3; exit }' "${bundle_log}")"
kill -TERM "${wrapper_pid}"
set +e
wait "${wrapper_pid}" 2>/dev/null
wrapper_status=$?
set -e
test "${wrapper_status}" -eq 143 || fail "signal exit was ${wrapper_status}, expected 143"
wait_for_group_exit "${process_group}" || fail "release process group survived wrapper interrupt"
assert_contains "${bundle_log}" "signal:TERM"
assert_contains "${output_log}" "Release interrupted by signal TERM"
pass "signals terminate the supervised release process group"

setup_case supervisor-death-cleanup
export TEST_BUNDLE_MODE="sleep"
start_live_headless
wait_for_log "${bundle_log}" "sleeping" || fail "release child did not become ready"
process_group="$(awk -F: '/^start:/ { print $3; exit }' "${bundle_log}")"
kill -KILL "${wrapper_pid}"
set +e
wait "${wrapper_pid}" 2>/dev/null
set -e
wait_for_group_exit "${process_group}" || fail "release process group survived supervisor death"
pass "the death watch terminates release work when its supervisor disappears"

printf '1..%d\n' "${pass_count}"
