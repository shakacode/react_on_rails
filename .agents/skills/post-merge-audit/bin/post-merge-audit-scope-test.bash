#!/usr/bin/env bash
# Unit tests for post-merge-audit-scope parsing helpers.
# Run with: bash .agents/skills/post-merge-audit/bin/post-merge-audit-scope-test.bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER="$SCRIPT_DIR/post-merge-audit-scope"

if [ ! -f "$RESOLVER" ]; then
  echo "missing resolver: $RESOLVER" >&2
  exit 1
fi

# shellcheck source=.agents/skills/post-merge-audit/bin/post-merge-audit-scope
source "$RESOLVER"

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
FAILURES=()

make_fake_gh() {
  local path="$1"
  local open_json="$2"
  local closed_json="$3"

  cat > "$path" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "search" ] && [ "${2:-}" = "issues" ]; then
  state=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --state)
        state="${2:-}"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  case "$state" in
    open)
      cat "$PMA_TEST_OPEN_JSON"
      ;;
    closed)
      cat "$PMA_TEST_CLOSED_JSON"
      ;;
    *)
      echo "unexpected gh issue search state: $state" >&2
      exit 1
      ;;
  esac
else
  echo "unexpected gh invocation: $*" >&2
  exit 1
fi
BASH
  chmod +x "$path"
  export PMA_TEST_OPEN_JSON="$open_json"
  export PMA_TEST_CLOSED_JSON="$closed_json"
}

fail() {
  local message="$1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES+=("$CURRENT_TEST: $message")
  echo "  FAIL: $message" >&2
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local label="${3:-value}"

  if [ "$expected" != "$actual" ]; then
    fail "$label: expected '$expected', got '$actual'"
    return 1
  fi
}

run_test() {
  local test_fn="$1"
  CURRENT_TEST="$test_fn"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> $test_fn"

  local before_failed="$TESTS_FAILED"
  set +e
  (
    set -euo pipefail
    "$test_fn"
  )
  local rc=$?
  set -u

  if [ "$rc" -ne 0 ] && [ "$TESTS_FAILED" -eq "$before_failed" ]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES+=("$CURRENT_TEST: subshell exited $rc (see stderr above for details)")
    echo "  FAIL: subshell exited $rc" >&2
  fi
}

test_parse_git_log_extracts_squash_and_merge_subject_prs_once() {
  local out expected

  out="$(
    {
      printf '%s\t%s\n' "abc123" "Fix audit scope resolver (#4014)"
      printf '%s\t%s\n' "def456" "Merge pull request #4015 from shakacode/example"
      printf '%s\t%s\n' "fedcba" "Duplicate mention (#4014)"
      printf '%s\t%s\n' "999999" "No pull request marker"
    } | pma_scope_parse_git_log
  )"

  expected="$(
    printf '%s\t%s\t%s\n' "4014" "abc123" "Fix audit scope resolver (#4014)"
    printf '%s\t%s\t%s' "4015" "def456" "Merge pull request #4015 from shakacode/example"
  )"

  assert_equals "$expected" "$out" "parsed PR log"
}

test_extract_issue_markers_from_json_keeps_fingerprint_state_and_affected_prs() {
  local out expected

  out="$(
    cat <<'JSON' | pma_scope_extract_issue_markers_from_json
[
  {
    "number": 3842,
    "state": "CLOSED",
    "url": "https://github.com/shakacode/react_on_rails/issues/3842",
    "body": "Resolved\n\n<!-- post-merge-audit-finding v1\naudit: 2026-06-14-post-rc\nfingerprint: pr-3724:changelog-server-bundle-load-error\naffected_prs: 3724, 3725\n-->"
  },
  {
    "number": 3900,
    "state": "OPEN",
    "url": "https://github.com/shakacode/react_on_rails/issues/3900",
    "body": "No marker here"
  }
]
JSON
  )"

  expected="$(
    printf '%s\t%s\t%s\t%s\t%s\t%s' \
      "pr-3724:changelog-server-bundle-load-error" \
      "3842" \
      "CLOSED" \
      "3724,3725" \
      "2026-06-14-post-rc" \
      "https://github.com/shakacode/react_on_rails/issues/3842"
  )"

  assert_equals "$expected" "$out" "issue markers"
}

test_subtract_prs_preserves_all_merged_prs_when_carry_over_is_empty() {
  local tmpdir out expected

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  printf '%s\n' 4014 4015 > "$tmpdir/merged.txt"
  : > "$tmpdir/carry.txt"

  out="$(pma_scope_subtract_prs "$tmpdir/merged.txt" "$tmpdir/carry.txt")"
  expected="$(printf '%s\n%s' 4014 4015)"

  rm -rf "$tmpdir"
  assert_equals "$expected" "$out" "to_audit with empty carry-over"
}

test_resolver_uses_first_parent_for_merged_pr_scope() {
  local tmpdir repo fake_bin open_json closed_json base merge_sha out actual expected

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  repo="$tmpdir/repo"
  fake_bin="$tmpdir/bin"
  open_json="$tmpdir/open.json"
  closed_json="$tmpdir/closed.json"
  mkdir -p "$repo" "$fake_bin"
  printf '[]\n' > "$open_json"
  printf '[]\n' > "$closed_json"
  make_fake_gh "$fake_bin/gh" "$open_json" "$closed_json"

  git -C "$repo" init --quiet --initial-branch=main
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" commit --quiet --allow-empty -m "base"
  base="$(git -C "$repo" rev-parse HEAD)"
  git -C "$repo" checkout --quiet -b side
  git -C "$repo" commit --quiet --allow-empty -m "Historical import (#111)"
  git -C "$repo" checkout --quiet main
  git -C "$repo" merge --quiet --no-ff side -m "Merge pull request #222 from test/side"
  merge_sha="$(git -C "$repo" rev-parse HEAD)"

  out="$(
    cd "$repo" &&
      env -u BASH_ENV PATH="$fake_bin:$PATH" "$RESOLVER" --base "$base" --head HEAD --repo owner/repo --json
  )"
  actual="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("merged_prs").map { |pr| [pr.fetch("number"), pr.fetch("sha"), pr.fetch("subject")].join("\t") }' <<< "$out")"
  expected="$(printf '%s\t%s\t%s' "222" "$merge_sha" "Merge pull request #222 from test/side")"

  rm -rf "$tmpdir"
  assert_equals "$expected" "$actual" "first-parent merged PR scope"
}

test_closed_markers_do_not_suppress_to_audit() {
  local tmpdir repo fake_bin open_json closed_json base out actual expected fingerprints

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  repo="$tmpdir/repo"
  fake_bin="$tmpdir/bin"
  open_json="$tmpdir/open.json"
  closed_json="$tmpdir/closed.json"
  mkdir -p "$repo" "$fake_bin"
  printf '[]\n' > "$open_json"
  cat > "$closed_json" <<'JSON'
[
  {
    "number": 88,
    "state": "CLOSED",
    "url": "https://example.test/issues/88",
    "body": "<!-- post-merge-audit-finding v1\naudit: old-audit\nfingerprint: pr-4014:old-finding\naffected_prs: 4014\n-->"
  }
]
JSON
  make_fake_gh "$fake_bin/gh" "$open_json" "$closed_json"

  git -C "$repo" init --quiet --initial-branch=main
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" commit --quiet --allow-empty -m "base"
  base="$(git -C "$repo" rev-parse HEAD)"
  git -C "$repo" commit --quiet --allow-empty -m "Fix audit scope resolver (#4014)"

  out="$(
    cd "$repo" &&
      env -u BASH_ENV PATH="$fake_bin:$PATH" "$RESOLVER" --base "$base" --head HEAD --repo owner/repo --json
  )"
  actual="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("to_audit").join(",")' <<< "$out")"
  fingerprints="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("existing_fingerprints").map { |fp| fp.fetch("state") }.join(",")' <<< "$out")"
  expected="4014"

  rm -rf "$tmpdir"
  assert_equals "$expected" "$actual" "closed markers do not suppress to_audit"
  assert_equals "CLOSED" "$fingerprints" "closed markers remain dedupe context"
}

run_test test_parse_git_log_extracts_squash_and_merge_subject_prs_once
run_test test_extract_issue_markers_from_json_keeps_fingerprint_state_and_affected_prs
run_test test_subtract_prs_preserves_all_merged_prs_when_carry_over_is_empty
run_test test_resolver_uses_first_parent_for_merged_pr_scope
run_test test_closed_markers_do_not_suppress_to_audit

if [ "$TESTS_FAILED" -ne 0 ]; then
  printf '\n%d of %d tests failed:\n' "$TESTS_FAILED" "$TESTS_RUN" >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi

printf '\n%d tests passed.\n' "$TESTS_RUN"
