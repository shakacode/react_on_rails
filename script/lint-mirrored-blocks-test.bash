#!/usr/bin/env bash
# Regression test harness for bin/lint-mirrored-blocks. Requires bash, git, and
# ruby. Run with `bash script/lint-mirrored-blocks-test.bash`.
#
# Focus: the MIRROR VALUES OF: value-set mode, and specifically that stacked
# MIRROR VALUES OF: markers over one region (as used by the CONTROL_MESSAGE_TYPES
# triangle) do not leak tokens from a marker's own comment line into the guarded
# value set. See the leak/masking scenarios below.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LINTER="$REPO_ROOT/bin/lint-mirrored-blocks"

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
FAILURES=()

fail() {
  local message="$1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES+=("$CURRENT_TEST: $message")
  if [ -n "${SUBSHELL_FAILURES_FILE:-}" ]; then
    printf '%s\n' "$CURRENT_TEST: $message" >> "$SUBSHELL_FAILURES_FILE"
  fi
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

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="${3:-output}"
  case "$haystack" in
    *"$needle"*)
      fail "$label: expected NOT to contain '$needle', got '$haystack'"
      return 1
      ;;
    *) ;;
  esac
}

run_test() {
  local test_fn="$1"
  CURRENT_TEST="$test_fn"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> $test_fn"

  local tmpdir before_failed had_errexit=false subshell_failures
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/lint-mirrored-blocks-test.XXXXXX")"
  subshell_failures="$tmpdir/failures.log"
  : > "$subshell_failures"
  before_failed="$TESTS_FAILED"

  case "$-" in
    *e*) had_errexit=true ;;
  esac

  set +e
  (
    set -uo pipefail
    SUBSHELL_FAILURES_FILE="$subshell_failures"
    export SUBSHELL_FAILURES_FILE
    cd "$tmpdir" || exit 1
    "$test_fn"
  )
  local rc=$?
  if [ "$had_errexit" = true ]; then
    set -e
  fi

  if [ -s "$subshell_failures" ]; then
    while IFS= read -r failure_line; do
      [ -n "$failure_line" ] || continue
      TESTS_FAILED=$((TESTS_FAILED + 1))
      FAILURES+=("$failure_line")
    done < "$subshell_failures"
  fi
  rm -rf "$tmpdir"

  if [ "$rc" -ne 0 ] && [ "$TESTS_FAILED" -eq "$before_failed" ]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES+=("$CURRENT_TEST: subshell exited $rc (see stderr above for details)")
    echo "  FAIL: subshell exited $rc" >&2
  fi
}

# Create a temp git repo whose MIRROR_ROOTS include the two package roots the
# linter already scans, then copy in the real linter. The linter reads
# `git ls-files`, so fixtures must be tracked.
setup_repo() {
  git init -b main >/dev/null 2>&1
  git config user.email test@example.com
  git config user.name "Mirror Lint Test"
  mkdir -p bin packages/react-on-rails/src packages/react-on-rails-pro/src
  cp "$LINTER" bin/lint-mirrored-blocks
  chmod +x bin/lint-mirrored-blocks
}

commit_all() {
  git add -A >/dev/null 2>&1
  git commit -qm fixtures >/dev/null 2>&1
}

# Happy path: stacked markers over one region, all three sides agree.
test_stacked_markers_agree_pass() {
  setup_repo
  cat > packages/react-on-rails/src/a.ts <<'EOF'
// MIRROR VALUES OF: packages/react-on-rails-pro/src/b.ts
// MIRROR VALUES OF: packages/react-on-rails-pro/src/c.ts
const X = ['alpha', 'beta'] as const;
// MIRROR VALUES END
EOF
  cat > packages/react-on-rails-pro/src/b.ts <<'EOF'
// MIRROR VALUES OF: packages/react-on-rails/src/a.ts
const X = ['alpha', 'beta'] as const;
// MIRROR VALUES END
EOF
  cat > packages/react-on-rails-pro/src/c.ts <<'EOF'
// MIRROR VALUES OF: packages/react-on-rails/src/a.ts
const X = ['alpha', 'beta'] as const;
// MIRROR VALUES END
EOF
  commit_all
  local output
  output="$(ruby bin/lint-mirrored-blocks 2>&1)"
  local rc=$?
  [ "$rc" -eq 0 ] || fail "expected exit 0 for agreeing stacked markers, got $rc: $output"
  # a.ts carries two stacked markers (-> b.ts, -> c.ts); b.ts and c.ts each carry
  # one reciprocal marker. That is 4 markers across the two pairs a<->b and a<->c.
  assert_contains "$output" "4 MIRROR VALUES OF: markers across 2 value-mirrored pairs" "summary"
}

# Regression: a quoted token on the SECOND stacked marker's own comment line must
# NOT leak into the first marker's value set (it would create false drift).
test_stacked_marker_line_token_does_not_leak() {
  setup_repo
  cat > packages/react-on-rails/src/a.ts <<'EOF'
// MIRROR VALUES OF: packages/react-on-rails-pro/src/b.ts
// MIRROR VALUES OF: packages/react-on-rails-pro/src/c.ts 'LEAK'
const X = ['alpha', 'beta'] as const;
// MIRROR VALUES END
EOF
  cat > packages/react-on-rails-pro/src/b.ts <<'EOF'
// MIRROR VALUES OF: packages/react-on-rails/src/a.ts
const X = ['alpha', 'beta'] as const;
// MIRROR VALUES END
EOF
  cat > packages/react-on-rails-pro/src/c.ts <<'EOF'
// MIRROR VALUES OF: packages/react-on-rails/src/a.ts
const X = ['alpha', 'beta'] as const;
// MIRROR VALUES END
EOF
  commit_all
  local output
  output="$(ruby bin/lint-mirrored-blocks 2>&1)"
  local rc=$?
  [ "$rc" -eq 0 ] || fail "LEAK token on a stacked marker line was extracted (false drift), exit $rc: $output"
  assert_not_contains "$output" "LEAK" "output"
}

# Regression: a marker-line token equal to a real value must NOT mask a genuine
# one-sided deletion. a.ts drops 'beta' from its array but carries 'beta' in a
# marker-line path token; the drift against b.ts/c.ts must still be reported.
test_marker_line_token_does_not_mask_real_drift() {
  setup_repo
  cat > packages/react-on-rails/src/a.ts <<'EOF'
// MIRROR VALUES OF: packages/react-on-rails-pro/src/b.ts
// MIRROR VALUES OF: packages/react-on-rails-pro/src/c.ts 'beta'
const X = ['alpha'] as const;
// MIRROR VALUES END
EOF
  cat > packages/react-on-rails-pro/src/b.ts <<'EOF'
// MIRROR VALUES OF: packages/react-on-rails/src/a.ts
const X = ['alpha', 'beta'] as const;
// MIRROR VALUES END
EOF
  cat > packages/react-on-rails-pro/src/c.ts <<'EOF'
// MIRROR VALUES OF: packages/react-on-rails/src/a.ts
const X = ['alpha', 'beta'] as const;
// MIRROR VALUES END
EOF
  commit_all
  local output
  output="$(ruby bin/lint-mirrored-blocks 2>&1)"
  local rc=$?
  [ "$rc" -ne 0 ] || fail "real drift (a.ts missing beta) was masked by a marker-line token: $output"
  assert_contains "$output" "beta" "drift output"
}

setup_repo >/dev/null 2>&1 || true

run_test test_stacked_markers_agree_pass
run_test test_stacked_marker_line_token_does_not_leak
run_test test_marker_line_token_does_not_mask_real_drift

echo
echo "lint-mirrored-blocks tests: $TESTS_RUN run, $TESTS_FAILED failed"

if [ "$TESTS_FAILED" -ne 0 ]; then
  printf '\nFailures:\n' >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi
