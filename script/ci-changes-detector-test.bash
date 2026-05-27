#!/usr/bin/env bash
# Test harness for script/ci-changes-detector. Self-contained: no extra
# binaries beyond bash + git. Run with `bash script/ci-changes-detector-test.bash`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECTOR="$SCRIPT_DIR/ci-changes-detector"

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
FAILURES=()

fail() {
  local message="$1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES+=("$CURRENT_TEST: $message")
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

run_test() {
  local test_fn="$1"
  CURRENT_TEST="$test_fn"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> $test_fn"

  local tmpdir before_failed had_errexit=false
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/ci-changes-detector-test.XXXXXX")"
  before_failed="$TESTS_FAILED"

  case "$-" in
    *e*) had_errexit=true ;;
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

  if [ "$rc" -ne 0 ] && [ "$TESTS_FAILED" -eq "$before_failed" ]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES+=("$CURRENT_TEST: subshell exited $rc (see stderr above for details)")
    echo "  FAIL: subshell exited $rc" >&2
  fi
}

setup_repo() {
  git init -b main >/dev/null
  git config user.email test@example.com
  git config user.name "CI Detector Test"

  mkdir -p docs react_on_rails/lib/react_on_rails packages/react-on-rails/src
  mkdir -p react_on_rails/spec/react_on_rails
  cat > docs/guide.md <<'DOC'
# Guide
DOC
  cat > react_on_rails/lib/react_on_rails/example.rb <<'RUBY'
module ReactOnRails
  class Example
    def call
      "ok"
    end
  end
end
RUBY
  cat > packages/react-on-rails/src/example.ts <<'TS'
export function example(): string {
  return 'ok';
}
TS
  cat > react_on_rails/spec/react_on_rails/example_spec.rb <<'RUBY'
RSpec.describe "example" do
  it "works" do
    expect(true).to be(true)
  end
end
RUBY

  git add .
  git commit -m "initial fixture" >/dev/null
}

detector_output() {
  CI=true CI_JSON_OUTPUT=1 "$DETECTOR" HEAD~1 HEAD
}

commit_change() {
  local message="$1"
  git add .
  git commit -m "$message" >/dev/null
}

test_docs_changes_are_non_runtime_only() {
  setup_repo
  printf '\nMore docs.\n' >> docs/guide.md
  commit_change "docs"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": true' "docs output"
  assert_contains "$out" '"non_runtime_only": true' "docs output"
  assert_contains "$out" '"run_lint": false' "docs output"
}

test_ruby_comment_only_change_skips_heavy_tests_but_keeps_lint() {
  setup_repo
  perl -0pi -e 's/class Example/class Example\n    # Explain the fixture./' \
    react_on_rails/lib/react_on_rails/example.rb
  commit_change "ruby comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": false' "ruby comment output"
  assert_contains "$out" '"non_runtime_only": true' "ruby comment output"
  assert_contains "$out" '"run_lint": true' "ruby comment output"
  assert_contains "$out" '"run_ruby_tests": false' "ruby comment output"
  assert_contains "$out" '"run_dummy_tests": false' "ruby comment output"
}

test_javascript_block_comment_only_change_skips_heavy_tests_but_keeps_lint() {
  setup_repo
  perl -0pi -e 's/export function/\/** Explains the fixture. *\/\nexport function/' \
    packages/react-on-rails/src/example.ts
  commit_change "js comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": true' "js comment output"
  assert_contains "$out" '"run_lint": true' "js comment output"
  assert_contains "$out" '"run_js_tests": false' "js comment output"
}

test_spec_comment_only_change_skips_rspec() {
  setup_repo
  perl -0pi -e 's/it "works"/# Fixture intent.\n  it "works"/' \
    react_on_rails/spec/react_on_rails/example_spec.rb
  commit_change "spec comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": true' "spec comment output"
  assert_contains "$out" '"run_lint": true' "spec comment output"
  assert_contains "$out" '"run_ruby_tests": false' "spec comment output"
}

test_ruby_magic_comment_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/module ReactOnRails/# frozen_string_literal: true\n\nmodule ReactOnRails/' \
    react_on_rails/lib/react_on_rails/example.rb
  commit_change "ruby magic comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "ruby magic output"
  assert_contains "$out" '"run_ruby_tests": true' "ruby magic output"
}

test_executable_source_change_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/"ok"/"changed"/' react_on_rails/lib/react_on_rails/example.rb
  commit_change "runtime source"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "runtime source output"
  assert_contains "$out" '"run_ruby_tests": true' "runtime source output"
}

run_test test_docs_changes_are_non_runtime_only
run_test test_ruby_comment_only_change_skips_heavy_tests_but_keeps_lint
run_test test_javascript_block_comment_only_change_skips_heavy_tests_but_keeps_lint
run_test test_spec_comment_only_change_skips_rspec
run_test test_ruby_magic_comment_remains_runtime_affecting
run_test test_executable_source_change_remains_runtime_affecting

echo
echo "CI changes detector tests: $TESTS_RUN run, $TESTS_FAILED failed"

if [ "$TESTS_FAILED" -ne 0 ]; then
  printf '\nFailures:\n' >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi
