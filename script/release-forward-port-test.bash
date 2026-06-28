#!/usr/bin/env bash
# Test harness for `script/release-forward-port --changelog` (the CHANGELOG.md
# re-homing mode). Mirrors the structure of script/ci-changes-detector-test.bash:
# each case runs in an isolated mktemp git repo subshell, so the real repo's
# branches, remote, and working tree are never touched. Requires bash, git, and
# ruby (each case runs `ruby` on the script under test). Run with
# `bash script/release-forward-port-test.bash`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORWARD_PORT="$SCRIPT_DIR/release-forward-port"

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
FAILURES=()

fail() {
  local message="$1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES+=("$CURRENT_TEST: $message")
  # When invoked from inside a run_test subshell, also persist the message so
  # the outer summary can show the specific assertion rather than a generic
  # "subshell exited" line.
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
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/release-forward-port-test.XXXXXX")"
  subshell_failures="$tmpdir/failures.log"
  : > "$subshell_failures"
  before_failed="$TESTS_FAILED"

  case "$-" in
    *e*) had_errexit=true ;;
  esac

  set +e
  (
    set -euo pipefail
    SUBSHELL_FAILURES_FILE="$subshell_failures"
    export SUBSHELL_FAILURES_FILE
    cd "$tmpdir" || exit 1
    "$test_fn"
  )
  local rc=$?
  if [ "$had_errexit" = true ]; then
    set -e
  fi

  # Ingest detailed failure messages recorded inside the subshell so the final
  # summary reflects the actual assertion text instead of a generic exit code.
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

# Initialize a git repo with `main` checked out. Callers then write CHANGELOG.md
# fixtures and commit them on main and a release/X.Y.Z branch.
init_repo() {
  git init -q -b main
  git config user.email test@example.com
  git config user.name "Forward Port Test"
}

commit_all() {
  local message="$1"
  git add -A
  git commit -q -m "$message"
}

# Write CHANGELOG.md on main, commit, branch release/17.0.0, write the release
# CHANGELOG.md, commit, and return to main. Two heredocs are passed by file path.
seed_main_and_release() {
  local main_changelog="$1"
  local release_changelog="$2"
  local release_branch="${3:-release/17.0.0}"

  cp "$main_changelog" CHANGELOG.md
  commit_all "main changelog"

  git checkout -q -b "$release_branch"
  cp "$release_changelog" CHANGELOG.md
  commit_all "release changelog"

  git checkout -q main
}

run_changelog() {
  local source="${1:-release/17.0.0}"
  shift || true
  ruby "$FORWARD_PORT" --source "$source" --target main --changelog "$@"
}

# ---------------------------------------------------------------------------
# Fixtures: small helpers that emit CHANGELOG.md bodies to a path.
# ---------------------------------------------------------------------------

pr_link() {
  local number="$1"
  printf '[PR %s](https://github.com/shakacode/react_on_rails/pull/%s)' "$number" "$number"
}

# ---------------------------------------------------------------------------
# Cases
# ---------------------------------------------------------------------------

# rc.0 + rc.1 + branch [Unreleased] all collapse into main's [Unreleased]; a PR
# already present on main is de-duplicated; a stray rc section on main is dropped.
test_collapses_rc_sections_and_branch_unreleased_into_main_unreleased() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Existing main fix**: already here. $(pr_link 100) by [a](https://github.com/a).

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **rc0 leftover**: a prior pick stamped this onto main. $(pr_link 50) by [a](https://github.com/a).

### [16.6.0] - 2026-04-09

#### Added

- **Old stable**: shipped. $(pr_link 1) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Branch unreleased fix**: newest on the branch. $(pr_link 300) by [a](https://github.com/a).

### [17.0.0.rc.1] - 2026-06-02

#### Added

- **rc1 feature**: added in rc1. $(pr_link 200) by [a](https://github.com/a).

#### Fixed

- **Existing main fix**: already here. $(pr_link 100) by [a](https://github.com/a).

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **rc0 leftover**: a prior pick stamped this onto main. $(pr_link 50) by [a](https://github.com/a).

### [16.6.0] - 2026-04-09

#### Added

- **Old stable**: shipped. $(pr_link 1) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md

  local out
  out="$(run_changelog)"
  assert_contains "$out" "Summary: 3 entries to add, 1 entry already present, 1 RC section to drop." "summary"
  assert_contains "$out" "### [17.0.0.rc.0]" "drop section listing"

  local changelog
  changelog="$(cat CHANGELOG.md)"
  # All three branch entries land under Unreleased.
  assert_contains "$changelog" "Branch unreleased fix" "rehomed branch unreleased"
  assert_contains "$changelog" "rc1 feature" "rehomed rc1"
  assert_contains "$changelog" "rc0 leftover" "rehomed rc0"
  # Existing main entry stays exactly once (deduped by PR number).
  local occurrences
  occurrences="$(grep -c "Existing main fix" CHANGELOG.md)"
  [ "$occurrences" -eq 1 ] || fail "expected 1 'Existing main fix', got $occurrences"
  # The stray rc.0 SECTION header is gone from main.
  assert_not_contains "$changelog" "### [17.0.0.rc.0]" "rc0 header dropped"
  # The unrelated stable section is preserved.
  assert_contains "$changelog" "### [16.6.0]" "stable section kept"
}

# --dry-run previews the additions and removals but never writes CHANGELOG.md.
test_dry_run_previews_without_writing() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Main fix**: here. $(pr_link 100) by [a](https://github.com/a).

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **Stray rc section**: on main. $(pr_link 50) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **New branch entry**: from rc0. $(pr_link 200) by [a](https://github.com/a).

- **Stray rc section**: on main. $(pr_link 50) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md

  local before out after
  before="$(cat CHANGELOG.md)"
  out="$(run_changelog release/17.0.0 --dry-run)"
  after="$(cat CHANGELOG.md)"

  assert_contains "$out" "Entries to ADD under [Unreleased]:" "dry-run add header"
  assert_contains "$out" "New branch entry" "dry-run shows addition"
  assert_contains "$out" "RC-header sections to DROP" "dry-run drop header"
  assert_contains "$out" "### [17.0.0.rc.0]" "dry-run drop listing"
  assert_contains "$out" "DRY RUN: CHANGELOG.md was not modified" "dry-run notice"
  [ "$before" = "$after" ] || fail "dry-run must not modify CHANGELOG.md"
}

# De-duplication is by PR number even when the entry prose differs between the
# release branch and main (e.g. main reworded the same PR's entry).
test_dedupes_by_pr_number_even_with_different_prose() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Reworded on main**: main's phrasing of the fix. $(pr_link 222) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [17.0.0.rc.1] - 2026-06-02

#### Fixed

- **Original branch wording**: the branch phrasing of the same fix. $(pr_link 222) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md

  local out
  out="$(run_changelog)"
  assert_contains "$out" "0 entries to add" "nothing added (PR deduped)"
  assert_contains "$out" "1 entry already present" "deduped entry counted"

  # main keeps only its own wording; the branch wording is not appended.
  assert_contains "$(cat CHANGELOG.md)" "Reworded on main" "main wording kept"
  assert_not_contains "$(cat CHANGELOG.md)" "Original branch wording" "branch wording skipped"
}

# Multiple distinct entries that share one PR number are all carried over (the
# dedup key is "PR already on main", not "PR seen once"); two entries from the
# same new PR both land.
test_multiple_entries_same_new_pr_all_carry_over() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Pre-existing**: main entry. $(pr_link 1) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **First change from PR**: part one. $(pr_link 500) by [a](https://github.com/a).

#### Fixed

- **Second change from PR**: part two. $(pr_link 500) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md

  local out
  out="$(run_changelog)"
  # Both entries from PR 500 are new to main; both must be added.
  assert_contains "$out" "First change from PR" "first PR-500 entry"
  assert_contains "$out" "Second change from PR" "second PR-500 entry"

  local changelog
  changelog="$(cat CHANGELOG.md)"
  assert_contains "$changelog" "First change from PR" "first added"
  assert_contains "$changelog" "Second change from PR" "second added"
}

# Entries regroup under their #### headings (Added / Changed / Fixed), with the
# target's existing entries kept first within each heading, and the blank-line
# house style preserved.
test_entries_regroup_under_headings_in_order() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### Added

- **Main added**: first. $(pr_link 10) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **Branch added**: second. $(pr_link 20) by [a](https://github.com/a).

#### Fixed

- **Branch fixed**: a fix. $(pr_link 30) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md
  run_changelog >/dev/null

  # The two Added entries share one #### Added block, main's first.
  local added_block
  added_block="$(awk '/^#### Added$/{flag=1} /^#### Fixed$/{flag=0} flag' CHANGELOG.md)"
  assert_contains "$added_block" "Main added" "main added present"
  assert_contains "$added_block" "Branch added" "branch added merged into same block"
  # Order: main's entry precedes the branch's within the merged block.
  case "$added_block" in
    *"Main added"*"Branch added"*) ;;
    *) fail "expected 'Main added' before 'Branch added' in merged Added block" ;;
  esac
  # A separate #### Fixed block exists for the fix.
  assert_contains "$(cat CHANGELOG.md)" "#### Fixed" "fixed heading present"
  # Blank line after each heading (house style): "#### Added" then empty line.
  assert_contains "$(cat CHANGELOG.md)" "$(printf '#### Added\n\n- ')" "blank line after heading"
}

# Idempotency: running the reconciliation twice leaves the changelog unchanged
# on the second run (everything is already present).
test_second_run_is_noop() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Main**: x. $(pr_link 1) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **Branch**: y. $(pr_link 2) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md

  run_changelog >/dev/null
  commit_all "apply reconciliation"
  local after_first
  after_first="$(cat CHANGELOG.md)"

  local out
  out="$(run_changelog)"
  assert_contains "$out" "0 entries to add" "second run adds nothing"
  assert_contains "$out" "Nothing to reconcile" "second run is a no-op"
  [ "$after_first" = "$(cat CHANGELOG.md)" ] || fail "second run must not change CHANGELOG.md"
}

# An empty branch [Unreleased] with no matching rc sections (e.g. nothing to
# forward-port yet) is a clean no-op, not an error.
test_no_release_entries_is_clean_noop() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Main**: x. $(pr_link 1) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [16.6.0] - 2026-04-09

#### Added

- **Old stable**: shipped. $(pr_link 1) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md

  local before out after
  before="$(cat CHANGELOG.md)"
  out="$(run_changelog)"
  after="$(cat CHANGELOG.md)"
  assert_contains "$out" "0 entries to add" "no entries to add"
  assert_contains "$out" "Nothing to reconcile" "clean no-op"
  [ "$before" = "$after" ] || fail "no-op run must not modify CHANGELOG.md"
}

# Multi-line entries (continuation/detail lines and nested bullets) are carried
# over intact, not truncated to the first line.
test_multiline_entry_preserved() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **[Pro]** **Multi-line feature**: summary line.
  A second descriptive line with more detail.
  $(pr_link 250) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md
  run_changelog >/dev/null

  local changelog
  changelog="$(cat CHANGELOG.md)"
  assert_contains "$changelog" "Multi-line feature" "summary preserved"
  assert_contains "$changelog" "A second descriptive line with more detail." "continuation preserved"
  assert_contains "$changelog" "/pull/250" "pr link preserved"
}

# The "#NNNN" shorthand (no /pull/ URL) is recognized for de-duplication.
test_hash_shorthand_pr_reference_dedupes() {
  init_repo

  cat > main.md <<'EOF'
# Change Log

### [Unreleased]

#### Fixed

- **Main shorthand entry**: fixed in #321.
EOF

  cat > release.md <<'EOF'
# Change Log

### [Unreleased]

### [17.0.0.rc.0] - 2026-05-30

#### Fixed

- **Branch shorthand entry**: same fix, also #321.
EOF

  seed_main_and_release main.md release.md

  local out
  out="$(run_changelog)"
  assert_contains "$out" "0 entries to add" "shorthand PR deduped"
  assert_not_contains "$(cat CHANGELOG.md)" "Branch shorthand entry" "branch shorthand skipped"
}

# Default (no --changelog) mode is unaffected: a dry-run with no eligible commits
# still prints the cherry-pick plan, NOT the changelog reconciliation plan.
test_default_mode_unchanged_without_flag() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]
EOF
  cp main.md CHANGELOG.md
  # A real version.rb so the default cherry-pick mode's version-drift guard has
  # something to read (keeps stderr clean); this mode is unrelated to --changelog.
  mkdir -p react_on_rails/lib/react_on_rails
  printf 'module ReactOnRails\n  VERSION = "17.0.0"\nend\n' \
    > react_on_rails/lib/react_on_rails/version.rb
  commit_all "init"
  git checkout -q -b release/17.0.0
  # No new commits on the branch beyond main, so the plan is empty.
  git checkout -q main

  local out
  out="$(ruby "$FORWARD_PORT" --source release/17.0.0 --target main --dry-run)"
  assert_contains "$out" "Release forward-port plan" "cherry-pick plan header"
  assert_not_contains "$out" "CHANGELOG.md reconciliation plan" "no reconciliation in default mode"
  assert_contains "$out" "DRY RUN: no branches were checked out" "default dry-run notice"
}

# An empty main [Unreleased] (header only, no entries yet) receives the
# forward-ported entries with correct heading + blank-line formatting.
test_empty_main_unreleased_receives_entries() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

### [16.6.0] - 2026-04-09

#### Added

- **Old stable**: shipped. $(pr_link 1) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **Branch entry**: new. $(pr_link 9) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md
  run_changelog >/dev/null

  local changelog
  changelog="$(cat CHANGELOG.md)"
  assert_contains "$changelog" "$(printf '### [Unreleased]\n\n#### Added\n\n- **Branch entry**')" "entry under empty unreleased"
  assert_contains "$changelog" "### [16.6.0]" "stable section kept"
}

# A target with no ### [Unreleased] section is a clear error (the forward-port
# train always reconciles into [Unreleased]; a target without it is a misconfig).
test_target_without_unreleased_errors_clearly() {
  init_repo

  printf '# Change Log\n\n### [16.6.0] - 2026-04-09\n\n#### Added\n\n- x.\n' > CHANGELOG.md
  commit_all "init main without unreleased"
  git checkout -q -b release/17.0.0
  printf '# Change Log\n\n### [Unreleased]\n\n### [17.0.0.rc.0] - 2026-05-30\n\n#### Added\n\n- new. ' > CHANGELOG.md
  printf '[PR 9](https://github.com/shakacode/react_on_rails/pull/9).\n' >> CHANGELOG.md
  commit_all "release branch"
  git checkout -q main

  local out rc
  set +e
  out="$(ruby "$FORWARD_PORT" --source release/17.0.0 --target main --changelog 2>&1)"
  rc=$?
  set -e
  [ "$rc" -ne 0 ] || fail "expected non-zero exit when target lacks [Unreleased]"
  assert_contains "$out" "has no ### [Unreleased] section" "missing unreleased error"
}

# A SOURCE with no prerelease sections (e.g. forward-porting from release/16.6.0,
# a patch line) must NOT reach into the TARGET's RC base: a stray rc section on
# main belonging to an unrelated line must be left untouched. The branch's own
# [Unreleased] backport still re-homes. Regression for the target-RC-fallback bug.
test_non_prerelease_source_does_not_touch_target_rc_section() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Main fix**: here. $(pr_link 100) by [a](https://github.com/a).

### [17.0.0.rc.5] - 2026-06-16

#### Added

- **Stray rc5 on main**: belongs to the 17.0.0 line, not 16.6.0. $(pr_link 50) by [a](https://github.com/a).

### [16.6.0] - 2026-04-09

#### Added

- **Old stable**: shipped. $(pr_link 1) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Backport on 16.6 branch**: no rc sections here. $(pr_link 900) by [a](https://github.com/a).

### [16.6.0] - 2026-04-09

#### Added

- **Old stable**: shipped. $(pr_link 1) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md "release/16.6.0"

  local out
  out="$(run_changelog release/16.6.0)"
  # The branch [Unreleased] backport is still re-homed ...
  assert_contains "$out" "Backport on 16.6 branch" "backport re-homed"
  # ... but the unrelated 17.0.0 RC section is NOT dropped.
  assert_not_contains "$out" "RC-header sections to DROP" "no RC drop for non-prerelease source"

  local changelog
  changelog="$(cat CHANGELOG.md)"
  assert_contains "$changelog" "### [17.0.0.rc.5]" "stray rc5 section preserved"
  assert_contains "$changelog" "Stray rc5 on main" "stray rc5 entry preserved"
  assert_contains "$changelog" "Backport on 16.6 branch" "backport written under unreleased"
}

# De-duplication keys on the entry's OWN PR (the "[PR NNNN](...) by [author]"
# trailer), not on a PR it merely references. An entry that references PR 4227 but
# is itself PR 4234 must dedupe against main's PR 4234, and must NOT dedupe against
# a main entry that is PR 4227.
test_dedupes_on_own_pr_trailer_not_referenced_pr() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### Fixed

- **Already on main as 4234**: main's copy. [PR 4234](https://github.com/shakacode/react_on_rails/pull/4234) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [17.0.0.rc.0] - 2026-05-30

#### Fixed

- **Branch copy of 4234**: references [PR 4227](https://github.com/shakacode/react_on_rails/pull/4227) but is itself [PR 4234](https://github.com/shakacode/react_on_rails/pull/4234) by [a](https://github.com/a).
- **Genuinely new, references 4227**: follow-up to [PR 4227](https://github.com/shakacode/react_on_rails/pull/4227), itself [PR 4250](https://github.com/shakacode/react_on_rails/pull/4250) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md

  local out
  out="$(run_changelog)"
  # The 4234 branch entry is deduped (own PR matches main's 4234) ...
  assert_not_contains "$(cat CHANGELOG.md)" "Branch copy of 4234" "own-PR 4234 deduped"
  # ... while the 4250 entry (which only REFERENCES 4227) is added, not deduped.
  assert_contains "$(cat CHANGELOG.md)" "Genuinely new, references 4227" "referenced-PR not treated as own"
  assert_contains "$out" "1 entry to add" "exactly one new entry"
}

# UTF-8 content (e.g. the ⚠️ breaking-change marker) must parse and round-trip
# even when Ruby's default external encoding is US-ASCII (a C/POSIX-locale CI
# runner). Regression for the "invalid byte sequence in US-ASCII" failure.
test_utf8_changelog_parses_and_round_trips_under_ascii_locale() {
  init_repo

  cat > main.md <<EOF
# Change Log

### [Unreleased]

#### ⚠️ Breaking Changes

- **Existing breaking change**: ⚠️ already on main. $(pr_link 100) by [a](https://github.com/a).
EOF

  cat > release.md <<EOF
# Change Log

### [Unreleased]

### [17.0.0.rc.0] - 2026-05-30

#### Added

- **New ✨ feature**: emoji prose. $(pr_link 200) by [a](https://github.com/a).
EOF

  seed_main_and_release main.md release.md

  # Force a US-ASCII external encoding to reproduce the C-locale CI runner.
  local out
  out="$(LC_ALL=C LANG=C run_changelog)"
  assert_contains "$out" "New ✨ feature" "emoji entry added"

  local changelog
  changelog="$(cat CHANGELOG.md)"
  assert_contains "$changelog" "⚠️ Breaking Changes" "warning marker preserved"
  assert_contains "$changelog" "New ✨ feature" "new emoji entry written"
  # The file must remain valid UTF-8 after the rewrite.
  ruby -e 'exit(File.read("CHANGELOG.md", encoding: "UTF-8").valid_encoding? ? 0 : 1)' \
    || fail "rewritten CHANGELOG.md is not valid UTF-8"
}

# A missing CHANGELOG.md at the source ref is a clear, non-crashing error.
test_missing_source_changelog_errors_clearly() {
  init_repo

  printf '# Change Log\n\n### [Unreleased]\n' > CHANGELOG.md
  commit_all "init main"
  git checkout -q -b release/17.0.0
  git rm -q CHANGELOG.md
  commit_all "remove changelog on release branch"
  git checkout -q main

  local out rc
  set +e
  out="$(ruby "$FORWARD_PORT" --source release/17.0.0 --target main --changelog 2>&1)"
  rc=$?
  set -e
  [ "$rc" -ne 0 ] || fail "expected non-zero exit for missing source CHANGELOG.md"
  assert_contains "$out" "unable to read CHANGELOG.md" "missing changelog error"
}

run_test test_collapses_rc_sections_and_branch_unreleased_into_main_unreleased
run_test test_dry_run_previews_without_writing
run_test test_dedupes_by_pr_number_even_with_different_prose
run_test test_multiple_entries_same_new_pr_all_carry_over
run_test test_entries_regroup_under_headings_in_order
run_test test_second_run_is_noop
run_test test_no_release_entries_is_clean_noop
run_test test_multiline_entry_preserved
run_test test_hash_shorthand_pr_reference_dedupes
run_test test_empty_main_unreleased_receives_entries
run_test test_target_without_unreleased_errors_clearly
run_test test_non_prerelease_source_does_not_touch_target_rc_section
run_test test_dedupes_on_own_pr_trailer_not_referenced_pr
run_test test_utf8_changelog_parses_and_round_trips_under_ascii_locale
run_test test_default_mode_unchanged_without_flag
run_test test_missing_source_changelog_errors_clearly

echo
echo "Release forward-port changelog tests: $TESTS_RUN run, $TESTS_FAILED failed"

if [ "$TESTS_FAILED" -ne 0 ]; then
  printf '\nFailures:\n' >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi
