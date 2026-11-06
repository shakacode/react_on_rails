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
  local group_status
  for attempt in $(seq 1 100); do
    ! kill -0 -- "-${pgid}" 2>/dev/null && return 0
    if group_has_live_members "${pgid}"; then
      :
    else
      group_status=$?
      test "${group_status}" -eq 1 && return 0
    fi
    sleep 0.05
  done
  return 1
}

group_has_live_members() {
  local pgid="$1"
  local process_table
  process_table="$(ps -eo pgid=,stat=)" || return 2
  awk -v expected_pgid="${pgid}" '
    $1 == expected_pgid && $2 !~ /^Z/ { live = 1 }
    END { exit live ? 0 : 1 }
  ' <<<"${process_table}"
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
when "prompt"
  print "Proceed with release? [y/N] "
  answer = $stdin.gets
  File.open(log, "a") { |file| file.puts "answer:#{answer&.chomp}" }
  exit(answer == "y\n" ? 0 : 9)
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
  # Publishing sign-in: the fake npm and gh succeed; give RubyGems a stand-in credential in an isolated HOME.
  export HOME="${case_dir}/home"
  mkdir -p "${HOME}/.gem"
  printf -- '---\n:rubygems_api_key: rubygems_test_key\n' >"${HOME}/.gem/credentials"
  unset GEM_HOST_API_KEY XDG_DATA_HOME
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

run_live_in_pty() {
  TEST_CASE_REPO="${fake_repo}" TEST_CASE_OUTPUT="${output_log}" ruby -rpty -rtimeout -e '
    output = +""
    status = nil
    PTY.spawn(File.join(ENV.fetch("TEST_CASE_REPO"), "script", "release"), chdir: ENV.fetch("TEST_CASE_REPO")) do |reader, writer, pid|
      begin
        Timeout.timeout(10) do
          until output.include?("Proceed with release? [y/N] ")
            output << reader.readpartial(1024)
          end
          writer.write("y\n")
          loop { output << reader.readpartial(1024) }
        end
      rescue EOFError, Errno::EIO
        _, status = Process.wait2(pid)
      ensure
        Process.kill("KILL", pid) unless status
        Process.wait(pid) unless status
        File.write(ENV.fetch("TEST_CASE_OUTPUT"), output)
      end
    end
    exit(status&.exitstatus || 1)
  '
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

setup_case doctor-missing-signin
rm "${fake_bin}/npm" "${fake_bin}/gh"
ln -s /usr/bin/false "${fake_bin}/npm"
ln -s /usr/bin/false "${fake_bin}/gh"
rm "${HOME}/.gem/credentials"
if run_release --doctor; then
  fail "release doctor accepted missing publishing sign-in"
fi
assert_contains "${output_log}" "sign in before releasing:"
assert_contains "${output_log}" "npm: run \`npm login --registry https://registry.npmjs.org/\`"
assert_contains "${output_log}" "GitHub CLI: run \`gh auth login --hostname github.com\`"
assert_contains "${output_log}" "RubyGems: run \`gem signin\`"
pass "doctor names every missing publishing sign-in"

setup_case doctor-rubygems-env-key
rm "${HOME}/.gem/credentials"
GEM_HOST_API_KEY=rubygems_test_key run_release --doctor || fail "doctor rejected GEM_HOST_API_KEY"
assert_contains "${output_log}" "publishing sign-in: npm and GitHub CLI signed in, RubyGems API key present"
pass "doctor accepts a RubyGems key from GEM_HOST_API_KEY"

setup_case live-missing-signin
rm "${fake_bin}/npm"
ln -s /usr/bin/false "${fake_bin}/npm"
if run_release; then
  fail "live release started without npm sign-in"
fi
assert_contains "${output_log}" "npm: run \`npm login --registry https://registry.npmjs.org/\`"
assert_not_contains "${bundle_log}" "args:"
pass "live release stops before publishing when npm sign-in is missing"

setup_case live-missing-gh-signin
rm "${fake_bin}/gh"
ln -s /usr/bin/false "${fake_bin}/gh"
if run_release; then
  fail "live release started without GitHub CLI sign-in"
fi
assert_contains "${output_log}" "GitHub CLI: run \`gh auth login --hostname github.com\`"
assert_not_contains "${bundle_log}" "args:"
pass "live release stops before publishing when GitHub CLI sign-in is missing"

setup_case doctor-rubygems-empty-key
printf -- '---\n:rubygems_api_key:\n:other: value\n' >"${HOME}/.gem/credentials"
if run_release --doctor; then
  fail "doctor accepted an empty RubyGems key in the credentials file"
fi
assert_contains "${output_log}" "RubyGems: run \`gem signin\`"
pass "doctor rejects an empty RubyGems key"

setup_case doctor-rubygems-blank-env-key
if GEM_HOST_API_KEY="   " run_release --doctor; then
  fail "doctor fell back to the credentials file although a blank GEM_HOST_API_KEY wins in RubyGems"
fi
assert_contains "${output_log}" "RubyGems: run \`gem signin\`"
pass "doctor rejects a blank GEM_HOST_API_KEY even with a valid credentials file"

setup_case doctor-gh-active-account
rm "${fake_bin}/gh"
cat >"${fake_bin}/gh" <<'RUBY'
#!/usr/bin/env ruby
# Succeeds only for the active account, as gh does when an inactive account is stale.
exit(ARGV.include?("--active") ? 0 : 1)
RUBY
chmod +x "${fake_bin}/gh"
run_release --doctor || fail "doctor rejected a valid active github.com account"
pass "doctor checks only the active github.com account"

setup_case doctor-rubygems-xdg-key
rm "${HOME}/.gem/credentials"
rmdir "${HOME}/.gem"
mkdir -p "${HOME}/.local/share/gem"
printf -- '---\n:rubygems_api_key: rubygems_test_key\n' >"${HOME}/.local/share/gem/credentials"
run_release --doctor || fail "doctor rejected the XDG RubyGems credentials file"
pass "doctor reads the XDG RubyGems credentials file when no legacy file exists"

setup_case doctor-rubygems-legacy-file-wins
printf -- '---\n:other: value\n' >"${HOME}/.gem/credentials"
mkdir -p "${HOME}/.local/share/gem"
printf -- '---\n:rubygems_api_key: rubygems_test_key\n' >"${HOME}/.local/share/gem/credentials"
if run_release --doctor; then
  fail "doctor read the XDG key although RubyGems uses the legacy file"
fi
assert_contains "${output_log}" "RubyGems: run \`gem signin\`"
pass "doctor checks the credentials file RubyGems actually reads"

setup_case reconcile-needs-only-gh-signin
rm "${fake_bin}/npm" "${HOME}/.gem/credentials"
ln -s /usr/bin/false "${fake_bin}/npm"
run_release --reconcile-accelerated-rc || true
assert_not_contains "${output_log}" "sign in before releasing:"
# Positive proof it got past the sign-in check: the reconcile Rake task started.
assert_contains "${bundle_log}" "release:reconcile_accelerated_rc[17.1.0.rc.0]"
pass "accelerated RC reconciliation does not require npm or RubyGems sign-in"

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

setup_case interactive-terminal-handoff
export TEST_BUNDLE_MODE="prompt"
run_live_in_pty || fail "interactive release could not read confirmation from its terminal"
assert_contains "${bundle_log}" "answer:y"
assert_contains "${output_log}" "completed with status 0"
pass "interactive publication hands terminal input to the release process group"

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
