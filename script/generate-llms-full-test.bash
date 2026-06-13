#!/usr/bin/env bash
# Test harness for script/generate-llms-full.mjs. Self-contained: requires bash
# and node. Run with `bash script/generate-llms-full-test.bash`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATOR_SOURCE="$SCRIPT_DIR/generate-llms-full.mjs"

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
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/generate-llms-full-test.XXXXXX")"
  before_failed="$TESTS_FAILED"

  set +e
  (
    set -euo pipefail
    cd "$tmpdir" || exit 1
    "$test_fn"
  )
  local rc=$?
  if [ "$rc" -ne 0 ] && [ "${KEEP_GENERATE_LLMS_FULL_TEST_TMP:-}" = "1" ]; then
    echo "  Keeping failed fixture at $tmpdir" >&2
  else
    rm -rf "$tmpdir"
  fi

  if [ "$rc" -ne 0 ] && [ "$TESTS_FAILED" -eq "$before_failed" ]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES+=("$CURRENT_TEST: subshell exited $rc (see stderr above for details)")
    echo "  FAIL: subshell exited $rc" >&2
  fi
}

write_fixture() {
  mkdir -p script docs/oss/getting-started docs/oss/core-concepts docs/pro
  cp "$GENERATOR_SOURCE" script/generate-llms-full.mjs
  : > docs/.llms-exclusions
  : > docs/.llms-known-redirects

  cat > docs/sidebars.ts <<'TS'
const sidebars = {
  docsSidebar: [
    'introduction',
    {
      type: 'category',
      label: 'Getting Started',
      link: { type: 'generated-index', title: 'Getting Started' },
      items: ['getting-started/quick-start'],
    },
    {
      type: 'category',
      label: 'Core Concepts',
      link: { type: 'generated-index', title: 'Core Concepts' },
      items: ['core-concepts/how-react-on-rails-works'],
    },
    {
      type: 'category',
      label: 'React on Rails Pro',
      link: { type: 'doc', id: 'pro/react-on-rails-pro' },
      items: ['pro/installation'],
    },
  ],
};

export default sidebars;
TS

  cat > docs/llms-full-preamble.md <<'MD'
# Fixture Preamble

Use https://reactonrails.com/docs/introduction as the OSS hub.
MD

  cat > docs/oss/introduction.md <<'MD'
# Introduction

Welcome.
MD

  cat > docs/oss/getting-started/quick-start.md <<'MD'
# Quick Start

Install React on Rails.
MD

  cat > docs/oss/core-concepts/how-react-on-rails-works.md <<'MD'
# How React on Rails Works

Architecture overview.
MD

  cat > docs/pro/react-on-rails-pro.md <<'MD'
---
slug: /pro
---

# React on Rails Pro

Pro overview.
MD

  cat > docs/pro/installation.md <<'MD'
# Pro Installation

Install Pro.
MD

  cat > llms.txt <<'MD'
# React on Rails

- OSS hub: https://reactonrails.com/docs/introduction
- Getting Started: https://reactonrails.com/docs/getting-started/quick-start
- Core Concepts: https://reactonrails.com/docs/core-concepts/how-react-on-rails-works
- Pro hub: https://reactonrails.com/docs/pro
MD

  node script/generate-llms-full.mjs >/dev/null
}

test_complete_sidebar_top_level_sections_pass_check() {
  write_fixture
  node script/generate-llms-full.mjs --check >/dev/null
}

test_missing_sidebar_top_level_section_fails_check() {
  write_fixture
  awk '!/^- Core Concepts: /' llms.txt > llms.txt.next
  mv llms.txt.next llms.txt

  local out rc
  set +e
  out="$(node script/generate-llms-full.mjs --check 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    fail "expected --check to fail when llms.txt removes a sidebar top-level section"
    return 1
  fi
  assert_contains "$out" "llms.txt does not represent sidebar top-level section"
  assert_contains "$out" "Core Concepts"
}

test_unresolvable_sidebar_top_level_entry_fails_check() {
  write_fixture
  awk '
    /^  ],/ {
      print "    {"
      print "      type: '\''category'\'',"
      print "      label: '\''External Only'\'',"
      print "      items: [{ type: '\''link'\'', href: '\''https://example.com'\'', label: '\''External'\'' }],"
      print "    },"
    }
    { print }
  ' docs/sidebars.ts > docs/sidebars.ts.next
  mv docs/sidebars.ts.next docs/sidebars.ts

  local out rc
  set +e
  out="$(node script/generate-llms-full.mjs --check 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    fail "expected --check to fail when a sidebar top-level entry has no resolvable doc IDs"
    return 1
  fi
  assert_contains "$out" "top-level entry has no resolvable doc IDs"
  assert_contains "$out" "External Only"
}

test_split_threshold_exceeded_fails_check() {
  write_fixture
  node -e "process.stdout.write('x'.repeat(2100 * 1024))" >> docs/oss/introduction.md

  local out rc
  set +e
  out="$(node script/generate-llms-full.mjs --check 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    fail "expected --check to fail when llms-full.txt exceeds the split threshold"
    return 1
  fi
  assert_contains "$out" "above the 2048 KiB split threshold"
}

run_test test_complete_sidebar_top_level_sections_pass_check
run_test test_missing_sidebar_top_level_section_fails_check
run_test test_unresolvable_sidebar_top_level_entry_fails_check
run_test test_split_threshold_exceeded_fails_check

if [ "$TESTS_FAILED" -ne 0 ]; then
  echo
  echo "$TESTS_FAILED of $TESTS_RUN generate-llms-full tests failed:" >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi

echo "$TESTS_RUN generate-llms-full tests passed"
