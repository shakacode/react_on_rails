#!/usr/bin/env bash
# Test harness for script/convert. Requires bash and ruby. Run with
# `bash script/convert-test.bash`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERT="$SCRIPT_DIR/convert"

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

assert_json_key_absent() {
  local json_file="$1"
  local key="$2"

  if ruby -rjson -e 'abort if JSON.parse(File.read(ARGV[0])).dig("pnpm", "overrides").key?(ARGV[1])' \
    "$json_file" "$key"; then
    return 0
  fi

  fail "expected pnpm.overrides to omit $key"
  return 1
}

assert_json_key_present() {
  local json_file="$1"
  local key="$2"

  if ruby -rjson -e 'abort unless JSON.parse(File.read(ARGV[0])).dig("pnpm", "overrides").key?(ARGV[1])' \
    "$json_file" "$key"; then
    return 0
  fi

  fail "expected pnpm.overrides to keep $key"
  return 1
}

run_test() {
  local test_fn="$1"
  CURRENT_TEST="$test_fn"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> $test_fn"

  local tmpdir before_failed
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/convert-test.XXXXXX")"
  before_failed="$TESTS_FAILED"

  set +e
  (
    set -euo pipefail
    cd "$tmpdir" || exit 1
    "$test_fn"
  )
  local rc=$?
  set -e

  if [ "$rc" -ne 0 ] && [ "$TESTS_FAILED" -eq "$before_failed" ]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES+=("$CURRENT_TEST: subshell exited $rc (see stderr above for details)")
    echo "  FAIL: subshell exited $rc" >&2
  fi

  if [ "$rc" -ne 0 ] && [ "${KEEP_CONVERT_TEST_TMP:-}" = "1" ]; then
    echo "  Keeping failed fixture at $tmpdir" >&2
  else
    rm -rf "$tmpdir"
  fi
}

write_fixture() {
  mkdir -p script packages/react-on-rails-pro react_on_rails/spec/dummy/config
  cp "$CONVERT" script/convert

  cat > package.json <<'JSON'
{
  "name": "react-on-rails-fixture",
  "dependencies": {
    "react": "19.2.0",
    "react-dom": "19.2.0"
  },
  "devDependencies": {
    "@testing-library/react": "16.3.0",
    "eslint": "9.0.0",
    "globals": "16.0.0",
    "knip": "5.0.0",
    "publint": "0.3.0"
  },
  "pnpm": {
    "overrides": {
      "react": "$react",
      "react-dom": "$react-dom",
      "app>react": "^18.3.1",
      "app>react-dom": "^18.3.1",
      "react_on_rails>react": "^19.2.0",
      "react_on_rails>react-dom": "^19.2.0",
      "react-on-rails-pro>react": "~19.2.7",
      "react-on-rails-pro>react-dom": "~19.2.7",
      "react-on-rails-pro>react-on-rails-rsc": "19.2.1",
      "react-on-rails-pro-node-renderer>react": "~19.2.7",
      "react-on-rails-pro-node-renderer>react-dom": "~19.2.7",
      "react-on-rails-pro-node-renderer>react-on-rails-rsc": "19.2.1",
      "react_on_rails_pro_dummy>react": "~19.2.7",
      "react_on_rails_pro_dummy>react-dom": "~19.2.7",
      "react_on_rails_pro_dummy>react-on-rails-rsc": "19.2.1",
      "sentry-testkit>express": "npm:empty-npm-package@1.0.0"
    }
  }
}
JSON

  cat > packages/react-on-rails-pro/package.json <<'JSON'
{
  "name": "react-on-rails-pro",
  "scripts": {
    "test:non-rsc": "jest tests --testPathIgnorePatterns=\"tests/.*(RSC|stream).*\""
  },
  "dependencies": {
    "react": "19.2.0",
    "react-dom": "19.2.0"
  }
}
JSON

  cat > react_on_rails/spec/dummy/package.json <<'JSON'
{
  "name": "react_on_rails_dummy",
  "dependencies": {
    "@dr.pogodin/react-helmet": "3.0.0",
    "react": "19.2.0",
    "react-dom": "19.2.0"
  }
}
JSON

  cat > react_on_rails/spec/dummy/config/routes.rb <<'RUBY'
Rails.application.routes.draw do
  get "client_side_activity" => "pages#client_side_activity"
  get "server_side_activity" => "pages#server_side_activity"
end
RUBY

  mkdir -p \
    react_on_rails/spec/dummy/app/views/pages \
    react_on_rails/spec/dummy/client/app/startup \
    react_on_rails/spec/dummy/spec/requests \
    react_on_rails/spec/dummy/spec/system
  touch \
    react_on_rails/spec/dummy/app/views/pages/client_side_activity.html.erb \
    react_on_rails/spec/dummy/app/views/pages/server_side_activity.html.erb \
    react_on_rails/spec/dummy/client/app/startup/ActivityTabSwitcher.tsx \
    react_on_rails/spec/dummy/spec/requests/activity_component_spec.rb \
    react_on_rails/spec/dummy/spec/system/activity_spec.rb
}

test_strips_react_19_only_workspace_overrides() {
  write_fixture

  ruby script/convert

  local removed_key
  for removed_key in \
    "react_on_rails>react" \
    "react_on_rails>react-dom" \
    "react-on-rails-pro>react" \
    "react-on-rails-pro>react-dom" \
    "react-on-rails-pro>react-on-rails-rsc" \
    "react-on-rails-pro-node-renderer>react" \
    "react-on-rails-pro-node-renderer>react-dom" \
    "react-on-rails-pro-node-renderer>react-on-rails-rsc" \
    "react_on_rails_pro_dummy>react" \
    "react_on_rails_pro_dummy>react-dom" \
    "react_on_rails_pro_dummy>react-on-rails-rsc"; do
    assert_json_key_absent package.json "$removed_key"
  done

  assert_json_key_present package.json "react"
  assert_json_key_present package.json "react-dom"
  assert_json_key_present package.json "app>react"
  assert_json_key_present package.json "sentry-testkit>express"
}

run_test test_strips_react_19_only_workspace_overrides

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "PASS: $TESTS_RUN tests"
else
  echo "FAIL: $TESTS_FAILED of $TESTS_RUN tests failed" >&2
  printf ' - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi
