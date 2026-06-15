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
  unset PMA_TEST_OPEN_JSON PMA_TEST_CLOSED_JSON
  export PMA_TEST_OPEN_JSON="$open_json"
  export PMA_TEST_CLOSED_JSON="$closed_json"
}

fail() {
  local message="$1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES+=("$CURRENT_TEST: $message")
  echo "  FAIL: $message" >&2
  return 1
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
      printf '%s\t%s\n' "b00b00" "Mention issue (#9999) before final text"
      printf '%s\t%s\n' "f00f00" "Revert 'feat: foo (#4010)' (#4012)"
      printf '%s\t%s\n' "dad000" "Revert \"Merge pull request #4015 from shakacode/example\" (#4020)"
      printf '%s\t%s\n' "bad999" "Revert \"Merge pull request #4016 from shakacode/example\""
      printf '%s\t%s\n' "fedcba" "Duplicate mention (#4014)"
      printf '%s\t%s\n' "999999" "No pull request marker"
    } | pma_scope_parse_git_log
  )"

  expected="$(
    printf '%s\t%s\t%s\n' "4014" "fedcba" "Duplicate mention (#4014)"
    printf '%s\t%s\t%s' "4015" "def456" "Merge pull request #4015 from shakacode/example"
    printf '\n%s\t%s\t%s' "4012" "f00f00" "Revert 'feat: foo (#4010)' (#4012)"
    printf '\n%s\t%s\t%s' "4020" "dad000" "Revert \"Merge pull request #4015 from shakacode/example\" (#4020)"
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
    "body": "Resolved\n\n<!-- post-merge-audit-finding v1\naudit: 2026-06-14\tpost-rc\nfingerprint: pr-3724:\tchangelog-server-bundle-load-error\naffected_prs: 3724, 3725\n-->"
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
      "pr-3724: changelog-server-bundle-load-error" \
      "3842" \
      "CLOSED" \
      "3724,3725" \
      "2026-06-14 post-rc" \
      "https://github.com/shakacode/react_on_rails/issues/3842"
  )"

  assert_equals "$expected" "$out" "issue markers"
}

test_open_markers_create_carry_over_and_suppress_to_audit() {
  local tmpdir repo fake_bin open_json closed_json base out actual expected carry fingerprints

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  repo="$tmpdir/repo"
  fake_bin="$tmpdir/bin"
  open_json="$tmpdir/open.json"
  closed_json="$tmpdir/closed.json"
  mkdir -p "$repo" "$fake_bin"
  cat > "$open_json" <<'JSON'
[
  {
    "number": 89,
    "state": "OPEN",
    "url": "https://example.test/issues/89",
    "body": "<!-- post-merge-audit-finding v1\naudit: current-audit\nfingerprint: pr-4014:open-finding\naffected_prs: 4014\n-->"
  }
]
JSON
  printf '[]\n' > "$closed_json"
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
  carry="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("carry_over_prs").join(",")' <<< "$out")"
  fingerprints="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("existing_fingerprints").map { |fp| fp.fetch("state") }.join(",")' <<< "$out")"
  expected=""

  rm -rf "$tmpdir"
  assert_equals "$expected" "$actual" "open markers suppress to_audit"
  assert_equals "4014" "$carry" "open markers remain carry-over context"
  assert_equals "OPEN" "$fingerprints" "open markers remain dedupe context"
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

test_default_base_ignores_rc_tags_on_merged_side_branches() {
  local tmpdir repo fake_bin open_json closed_json out base_ref actual

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
  git -C "$repo" tag v1.0.0.rc.1
  git -C "$repo" checkout --quiet -b next-release
  git -C "$repo" commit --quiet --allow-empty -m "Next release candidate"
  git -C "$repo" tag v2.0.0.rc.1
  git -C "$repo" checkout --quiet main
  git -C "$repo" commit --quiet --allow-empty -m "Main line before side merge"
  git -C "$repo" merge --quiet --no-ff next-release -m "Merge pull request #4010 from test/next-release"
  git -C "$repo" commit --quiet --allow-empty -m "Main line change (#4014)"

  out="$(
    cd "$repo" &&
      env -u BASH_ENV PATH="$fake_bin:$PATH" "$RESOLVER" --head HEAD --repo owner/repo --json
  )"
  base_ref="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("base").fetch("ref")' <<< "$out")"
  actual="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("to_audit").join(",")' <<< "$out")"

  rm -rf "$tmpdir"
  assert_equals "v1.0.0.rc.1" "$base_ref" "default base on mainline"
  assert_equals "4010,4014" "$actual" "default-base to_audit"
}

test_default_base_uses_nearest_rc_on_first_parent_history() {
  local tmpdir repo fake_bin open_json closed_json base out base_ref actual

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
  git -C "$repo" tag -a v1.0.0.rc.1 -m "first rc"
  git -C "$repo" commit --quiet --allow-empty -m "Second release candidate"
  git -C "$repo" tag -a v1.0.0.rc.2 -m "second rc"
  git -C "$repo" tag -a v9.0.0.rc.2 -m "same commit higher rc"
  git -C "$repo" tag -a v9.0.0.rc.1 "$base" -m "newer tag on older rc"
  git -C "$repo" commit --quiet --allow-empty -m "Main line change (#4014)"

  out="$(
    cd "$repo" &&
      env -u BASH_ENV PATH="$fake_bin:$PATH" "$RESOLVER" --head HEAD --repo owner/repo --json
  )"
  base_ref="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("base").fetch("ref")' <<< "$out")"
  actual="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("to_audit").join(",")' <<< "$out")"

  rm -rf "$tmpdir"
  assert_equals "v9.0.0.rc.2" "$base_ref" "nearest default base on first-parent history"
  assert_equals "4014" "$actual" "nearest default-base to_audit"
}

test_resolver_rejects_base_outside_head_history() {
  local tmpdir repo side_sha out rc

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  repo="$tmpdir/repo"
  mkdir -p "$repo"

  git -C "$repo" init --quiet --initial-branch=main
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" commit --quiet --allow-empty -m "base"
  git -C "$repo" checkout --quiet -b other-release
  git -C "$repo" commit --quiet --allow-empty -m "Other release candidate"
  side_sha="$(git -C "$repo" rev-parse HEAD)"
  git -C "$repo" checkout --quiet main
  git -C "$repo" commit --quiet --allow-empty -m "Main line change (#4014)"

  set +e
  out="$(
    cd "$repo" &&
      env -u BASH_ENV "$RESOLVER" --base "$side_sha" --head HEAD --repo owner/repo --json 2>&1
  )"
  rc=$?
  set -e

  rm -rf "$tmpdir"

  assert_equals "1" "$rc" "non-ancestor range rc"
  case "$out" in
    *"base ref is not on the first-parent history of head ref"*) ;;
    *)
      fail "non-ancestor range error message missing: $out"
      ;;
  esac
}

test_resolver_rejects_base_outside_first_parent_history() {
  local tmpdir repo side_sha out rc

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  repo="$tmpdir/repo"
  mkdir -p "$repo"

  git -C "$repo" init --quiet --initial-branch=main
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" commit --quiet --allow-empty -m "base"
  git -C "$repo" checkout --quiet -b side
  git -C "$repo" commit --quiet --allow-empty -m "Side branch boundary"
  side_sha="$(git -C "$repo" rev-parse HEAD)"
  git -C "$repo" checkout --quiet main
  git -C "$repo" commit --quiet --allow-empty -m "Main line before merge (#4013)"
  git -C "$repo" merge --quiet --no-ff side -m "Merge pull request #4014 from test/side"

  set +e
  out="$(
    cd "$repo" &&
      env -u BASH_ENV "$RESOLVER" --base "$side_sha" --head HEAD --repo owner/repo --json 2>&1
  )"
  rc=$?
  set -e

  rm -rf "$tmpdir"

  assert_equals "1" "$rc" "side-branch base rc"
  case "$out" in
    *"base ref is not on the first-parent history of head ref"*) ;;
    *)
      fail "side-branch base error message missing: $out"
      ;;
  esac
}

test_fetch_issue_markers_cleans_inner_tmpdir_on_parse_failure() {
  local tmpdir fake_bin open_json closed_json markers open_markers scoped_tmpdirs rc leftovers

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  fake_bin="$tmpdir/bin"
  open_json="$tmpdir/open.json"
  closed_json="$tmpdir/closed.json"
  markers="$tmpdir/markers.tsv"
  open_markers="$tmpdir/open-markers.tsv"
  scoped_tmpdirs="$tmpdir/scoped"
  mkdir -p "$fake_bin" "$scoped_tmpdirs"
  printf '[]\n' > "$open_json"
  printf '{not-json}\n' > "$closed_json"
  make_fake_gh "$fake_bin/gh" "$open_json" "$closed_json"

  set +e
  PATH="$fake_bin:$PATH" PMA_SCOPE_TMPDIR="$scoped_tmpdirs" \
    pma_scope_fetch_issue_markers owner/repo 10 "$markers" "$open_markers" >/dev/null 2>&1
  rc=$?
  set -e

  leftovers="$(find "$scoped_tmpdirs" -mindepth 1 -maxdepth 1 -type d -print)"
  rm -rf "$tmpdir"

  assert_equals "1" "$rc" "parse failure rc"
  assert_equals "" "$leftovers" "inner tmpdir cleanup"
}

test_fetch_issue_markers_warns_when_search_hits_limit() {
  local tmpdir fake_bin open_json closed_json markers open_markers out rc

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  fake_bin="$tmpdir/bin"
  open_json="$tmpdir/open.json"
  closed_json="$tmpdir/closed.json"
  markers="$tmpdir/markers.tsv"
  open_markers="$tmpdir/open-markers.tsv"
  mkdir -p "$fake_bin"
  cat > "$open_json" <<'JSON'
[
  {"number": 1, "state": "OPEN", "url": "https://example.test/issues/1", "body": ""},
  {"number": 2, "state": "OPEN", "url": "https://example.test/issues/2", "body": ""}
]
JSON
  printf '[]\n' > "$closed_json"
  make_fake_gh "$fake_bin/gh" "$open_json" "$closed_json"

  set +e
  out="$(PATH="$fake_bin:$PATH" pma_scope_fetch_issue_markers owner/repo 2 "$markers" "$open_markers" 2>&1)"
  rc=$?
  set -e

  rm -rf "$tmpdir"
  assert_equals "0" "$rc" "limit warning rc"
  case "$out" in
    *"Warning: open issue search returned 2 results (limit=2)"*) ;;
    *)
      fail "limit warning missing: $out"
      ;;
  esac
}

test_limit_requires_positive_integer() {
  local out rc

  set +e
  out="$(env -u BASH_ENV "$RESOLVER" --limit nope --self-check 2>&1)"
  rc=$?
  set -e

  assert_equals "1" "$rc" "invalid limit rc"
  case "$out" in
    *"--limit must be a positive integer"*) ;;
    *)
      fail "invalid limit error message missing: $out"
      ;;
  esac
}

test_repo_requires_owner_repo_form() {
  local tmpdir repo out rc

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  repo="$tmpdir/repo"
  mkdir -p "$repo"
  git -C "$repo" init --quiet --initial-branch=main
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" commit --quiet --allow-empty -m "base"

  set +e
  out="$(cd "$repo" && env -u BASH_ENV "$RESOLVER" --head HEAD --repo owner --json 2>&1)"
  rc=$?
  set -e

  rm -rf "$tmpdir"
  assert_equals "1" "$rc" "invalid repo rc"
  case "$out" in
    *"--repo must be in OWNER/REPO form"*) ;;
    *)
      fail "invalid repo error message missing: $out"
      ;;
  esac
}

test_sourced_main_propagates_marker_fetch_failure_without_errexit() {
  local tmpdir repo fake_bin base out actual_rc

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  repo="$tmpdir/repo"
  fake_bin="$tmpdir/bin"
  mkdir -p "$repo" "$fake_bin"
  cat > "$fake_bin/gh" <<'BASH'
#!/usr/bin/env bash
echo "simulated gh failure" >&2
exit 1
BASH
  chmod +x "$fake_bin/gh"

  git -C "$repo" init --quiet --initial-branch=main
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" commit --quiet --allow-empty -m "base"
  base="$(git -C "$repo" rev-parse HEAD)"
  git -C "$repo" commit --quiet --allow-empty -m "Main line change (#4014)"

  out="$(
    bash -c '
      set +e
      set -u
      set -o pipefail
      source "$1"
      cd "$2"
      PATH="$3:$PATH" pma_scope_main --base "$4" --head HEAD --repo owner/repo --json 2>&1
      printf "\nrc=%s\n" "$?"
    ' bash "$RESOLVER" "$repo" "$fake_bin" "$base"
  )"
  actual_rc="$(printf '%s\n' "$out" | awk -F= '$1 == "rc" { print $2 }')"

  rm -rf "$tmpdir"
  assert_equals "1" "$actual_rc" "sourced marker fetch failure rc"
  case "$out" in
    *"failed to search open post-merge audit finding issues"*) ;;
    *)
      fail "marker fetch error message missing: $out"
      ;;
  esac
}

test_sourced_main_help_does_not_change_shell_options() {
  local out expected

  out="$(
    bash -c '
      set +e
      set -u
      set -o pipefail
      source "$1"
      pma_scope_main --help >/dev/null
      set -o | awk '\''$1 == "errexit" || $1 == "nounset" || $1 == "pipefail" { print $1 "=" $2 }'\''
    ' bash "$RESOLVER"
  )"
  expected="$(
    printf '%s\n' \
      "errexit=off" \
      "nounset=on" \
      "pipefail=on"
  )"

  assert_equals "$expected" "$out" "sourced pma_scope_main shell options"
}

test_sourced_main_run_preserves_cwd_and_exit_trap() {
  local actual_rc_pwd expected_rc_pwd tmpdir repo fake_bin open_json closed_json base out expected_pwd

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/post-merge-audit-scope-test.XXXXXX")"
  repo="$tmpdir/repo"
  fake_bin="$tmpdir/bin"
  open_json="$tmpdir/open.json"
  closed_json="$tmpdir/closed.json"
  mkdir -p "$repo/subdir" "$fake_bin"
  printf '[]\n' > "$open_json"
  printf '[]\n' > "$closed_json"
  make_fake_gh "$fake_bin/gh" "$open_json" "$closed_json"

  git -C "$repo" init --quiet --initial-branch=main
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" commit --quiet --allow-empty -m "base"
  base="$(git -C "$repo" rev-parse HEAD)"
  git -C "$repo" commit --quiet --allow-empty -m "Main line change (#4014)"
  expected_pwd="$(cd "$repo/subdir" && pwd)"

  out="$(
    bash -c '
      set -uo pipefail
      source "$1"
      cd "$2/subdir"
      trap '\''printf caller-exit-trap >/dev/null'\'' EXIT
      PATH="$3:$PATH" pma_scope_main --base "$4" --head HEAD --repo owner/repo --json >/dev/null
      rc=$?
      printf "rc=%s\npwd=%s\ntrap=%s\n" "$rc" "$PWD" "$(trap -p EXIT)"
    ' bash "$RESOLVER" "$repo" "$fake_bin" "$base"
  )"
  expected_rc_pwd="$(
    printf 'rc=0\n'
    printf 'pwd=%s' "$expected_pwd"
  )"

  rm -rf "$tmpdir"
  actual_rc_pwd="$(printf '%s\n' "$out" | sed -n '1,2p')"
  assert_equals "$expected_rc_pwd" "$actual_rc_pwd" "sourced pma_scope_main caller context"
  case "$out" in
    *"printf caller-exit-trap >/dev/null"*) ;;
    *)
      fail "caller exit trap not preserved: $out"
      ;;
  esac
}

run_test test_parse_git_log_extracts_squash_and_merge_subject_prs_once
run_test test_extract_issue_markers_from_json_keeps_fingerprint_state_and_affected_prs
run_test test_open_markers_create_carry_over_and_suppress_to_audit
run_test test_resolver_uses_first_parent_for_merged_pr_scope
run_test test_closed_markers_do_not_suppress_to_audit
run_test test_default_base_ignores_rc_tags_on_merged_side_branches
run_test test_default_base_uses_nearest_rc_on_first_parent_history
run_test test_resolver_rejects_base_outside_head_history
run_test test_resolver_rejects_base_outside_first_parent_history
run_test test_fetch_issue_markers_cleans_inner_tmpdir_on_parse_failure
run_test test_fetch_issue_markers_warns_when_search_hits_limit
run_test test_limit_requires_positive_integer
run_test test_repo_requires_owner_repo_form
run_test test_sourced_main_propagates_marker_fetch_failure_without_errexit
run_test test_sourced_main_help_does_not_change_shell_options
run_test test_sourced_main_run_preserves_cwd_and_exit_trap

if [ "$TESTS_FAILED" -ne 0 ]; then
  printf '\n%d of %d tests failed:\n' "$TESTS_FAILED" "$TESTS_RUN" >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi

printf '\n%d tests passed.\n' "$TESTS_RUN"
