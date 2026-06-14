#!/usr/bin/env bash
# Test harness for script/check-single-react-resolution.mjs. Self-contained:
# requires bash and node. Run with
# `bash script/check-single-react-resolution-test.bash`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER="$SCRIPT_DIR/check-single-react-resolution.mjs"

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

  local tmpdir before_failed
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/check-single-react-resolution-test.XXXXXX")"
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

  if [ "$rc" -ne 0 ] && [ "${KEEP_SINGLE_REACT_RESOLUTION_TEST_TMP:-}" = "1" ]; then
    echo "  Keeping failed fixture at $tmpdir" >&2
  else
    rm -rf "$tmpdir"
  fi
}

write_package() {
  local package_root="$1"
  local package_name="$2"
  local version="$3"
  shift 3

  mkdir -p "$package_root"
  printf '{ "name": "%s", "version": "%s" }\n' "$package_name" "$version" > "$package_root/package.json"

  local file
  for file in "$@"; do
    mkdir -p "$package_root/$(dirname "$file")"
    printf 'module.exports = {};\n' > "$package_root/$file"
  done
}

write_pnpm_style_install() {
  local app_dir="$1"
  local react_parent="${2:-$app_dir/node_modules}"
  local react_dom_parent="${3:-$app_dir/node_modules}"
  local react_version="${4:-1.0.0}"
  local react_dom_version="${5:-$react_version}"

  mkdir -p "$app_dir" "$react_parent" "$react_dom_parent"
  printf '{ "name": "fixture-app" }\n' > "$app_dir/package.json"

  write_package \
    "$react_parent/.pnpm/react@$react_version/node_modules/react" \
    react \
    "$react_version" \
    index.js \
    jsx-runtime.js \
    jsx-dev-runtime.js

  write_package \
    "$react_dom_parent/.pnpm/react-dom@${react_dom_version}_react@$react_version/node_modules/react-dom" \
    react-dom \
    "$react_dom_version" \
    index.js \
    client.js \
    server.js

  ln -s ".pnpm/react@$react_version/node_modules/react" "$react_parent/react"
  ln -s ".pnpm/react-dom@${react_dom_version}_react@$react_version/node_modules/react-dom" "$react_dom_parent/react-dom"
}

test_pnpm_virtual_store_sibling_links_pass() {
  write_pnpm_style_install "$PWD/app"

  local out rc
  set +e
  out="$(node "$CHECKER" app 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    fail "expected pnpm sibling symlinks to pass, got exit $rc"
    echo "$out" >&2
    return 1
  fi

  assert_contains "$out" "React/ReactDOM resolution check passed."
}

test_different_node_modules_parents_still_fail() {
  mkdir -p workspace
  write_pnpm_style_install "$PWD/workspace/app" "$PWD/workspace/app/node_modules" "$PWD/workspace/node_modules"

  local out rc
  set +e
  out="$(node "$CHECKER" workspace/app 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    fail "expected different node_modules parents to fail"
    echo "$out" >&2
    return 1
  fi

  assert_contains "$out" "mixes React installations"
}

test_version_mismatch_still_fails() {
  write_pnpm_style_install \
    "$PWD/app" \
    "$PWD/app/node_modules" \
    "$PWD/app/node_modules" \
    1.0.0 \
    2.0.0

  local out rc
  set +e
  out="$(node "$CHECKER" app 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    fail "expected mismatched React and ReactDOM versions to fail"
    echo "$out" >&2
    return 1
  fi

  assert_contains "$out" "mismatched versions"
}

test_multiple_react_roots_in_one_target_still_fail() {
  write_pnpm_style_install "$PWD/app"
  write_package "$PWD/app/alternate/node_modules/react" react 1.0.0 jsx-runtime.js
  rm "$PWD/app/node_modules/.pnpm/react@1.0.0/node_modules/react/jsx-runtime.js"
  ln -s "$PWD/app/alternate/node_modules/react/jsx-runtime.js" \
    "$PWD/app/node_modules/.pnpm/react@1.0.0/node_modules/react/jsx-runtime.js"

  local out rc
  set +e
  out="$(node "$CHECKER" app 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    fail "expected multiple react package roots to fail"
    echo "$out" >&2
    return 1
  fi

  assert_contains "$out" "resolves react specifiers from multiple installations"
}

test_cross_directory_divergence_is_only_noted() {
  write_pnpm_style_install \
    "$PWD/app-one" \
    "$PWD/app-one/node_modules" \
    "$PWD/app-one/node_modules" \
    1.0.0
  write_pnpm_style_install \
    "$PWD/app-two" \
    "$PWD/app-two/node_modules" \
    "$PWD/app-two/node_modules" \
    2.0.0

  local out rc
  set +e
  out="$(node "$CHECKER" app-one app-two 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    fail "expected cross-directory divergence to pass, got exit $rc"
    echo "$out" >&2
    return 1
  fi

  assert_contains "$out" "[NOTE] target directories use different React installations"
}

run_test test_pnpm_virtual_store_sibling_links_pass
run_test test_different_node_modules_parents_still_fail
run_test test_version_mismatch_still_fails
run_test test_multiple_react_roots_in_one_target_still_fail
run_test test_cross_directory_divergence_is_only_noted

if [ "$TESTS_FAILED" -ne 0 ]; then
  echo
  echo "$TESTS_FAILED of $TESTS_RUN tests failed:" >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi

echo
echo "All $TESTS_RUN tests passed."
