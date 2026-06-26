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
  if [ -n "${FAILURE_FILE:-}" ]; then
    printf '%s\n' "$CURRENT_TEST: $message" >> "$FAILURE_FILE"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES+=("$CURRENT_TEST: $message")
  fi
  echo "  FAIL: $message" >&2
  return 1
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

  local tmpdir failure_file new_failures=0
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/generate-llms-full-test.XXXXXX")"
  failure_file="$tmpdir/.failures"
  : > "$failure_file"

  set +e
  (
    set -euo pipefail
    cd "$tmpdir" || exit 1
    FAILURE_FILE="$failure_file"
    "$test_fn"
  )
  local rc=$?

  if [ -s "$failure_file" ]; then
    while IFS= read -r failure; do
      FAILURES+=("$failure")
    done < "$failure_file"
    new_failures="$(wc -l < "$failure_file" | tr -d '[:space:]')"
    TESTS_FAILED=$((TESTS_FAILED + new_failures))
  fi

  if [ "$rc" -ne 0 ] && [ "${KEEP_GENERATE_LLMS_FULL_TEST_TMP:-}" = "1" ]; then
    echo "  Keeping failed fixture at $tmpdir" >&2
  else
    rm -rf "$tmpdir"
  fi

  if [ "$rc" -ne 0 ] && [ "${new_failures:-0}" -eq 0 ]; then
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

<p>
  <img src="images/architecture.svg" alt="Rails sends render requests to the Node Renderer." width="840" />
</p>

Also referenced inline: ![Data flow diagram](images/data-flow.svg)

A PNG screenshot is not a diagram and must pass through verbatim:

<p>
  <img src="images/screenshot.png" alt="App screenshot" width="840" />
</p>

An SVG diagram with empty alt degrades to a bare marker:

<p>
  <img src="images/no-alt.svg" alt="" width="840" />
</p>

A JSX example must not be rewritten:

```jsx
<img src={thumbnail} alt="thumbnail" />
```
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

test_validate_mode_allows_stale_generated_outputs() {
  write_fixture
  cat >> docs/oss/getting-started/quick-start.md <<'MD'

New source-only docs content.
MD

  node script/generate-llms-full.mjs --validate >/dev/null

  local out rc
  set +e
  out="$(node script/generate-llms-full.mjs --check 2>&1)"
  rc=$?
  set -e

  if [ "$rc" -eq 0 ]; then
    fail "expected --check to fail after source docs changed without regenerating llms-full.txt"
    return 1
  fi
  assert_contains "$out" "llms-full.txt is stale"
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
    BEGIN { inserted = 0 }
    /^  ],/ {
      print "    {"
      print "      type: '\''category'\'',"
      print "      label: '\''External Only'\'',"
      print "      items: [{ type: '\''link'\'', href: '\''https://example.com'\'', label: '\''External'\'' }],"
      print "    },"
      inserted = 1
    }
    { print }
    END { if (!inserted) exit 1 }
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

test_split_produces_oss_and_pro_files() {
  write_fixture

  if [ ! -f llms-full.txt ]; then
    fail "expected llms-full.txt (OSS tier) to be generated"
    return 1
  fi
  if [ ! -f llms-full-pro.txt ]; then
    fail "expected llms-full-pro.txt (Pro tier) to be generated"
    return 1
  fi

  local oss pro
  oss="$(cat llms-full.txt)"
  pro="$(cat llms-full-pro.txt)"

  # OSS tier carries OSS pages and points at the Pro companion, never Pro pages.
  assert_contains "$oss" "SOURCE: docs/oss/introduction.md"
  assert_contains "$oss" "companion file: ./llms-full-pro.txt"
  if printf '%s' "$oss" | grep -q "SOURCE: docs/pro/"; then
    fail "llms-full.txt (OSS tier) must not contain Pro pages"
  fi

  # Pro tier carries Pro pages and points back at the OSS companion.
  assert_contains "$pro" "SOURCE: docs/pro/installation.md"
  assert_contains "$pro" "companion file: ./llms-full.txt"
  if printf '%s' "$pro" | grep -q "SOURCE: docs/oss/"; then
    fail "llms-full-pro.txt (Pro tier) must not contain OSS pages"
  fi
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

test_svg_diagram_embeds_become_text_descriptions() {
  write_fixture

  local oss
  oss="$(cat llms-full.txt)"

  # The <p><img .svg/></p> embed is replaced by its alt text, and the raw <img>
  # tag (a dead relative path in the text reference) is gone.
  assert_contains "$oss" "[Diagram: Rails sends render requests to the Node Renderer.]"
  if printf '%s' "$oss" | grep -q "images/architecture.svg"; then
    fail "expected the SVG <img> embed to be replaced by its alt text"
  fi

  # The markdown ![alt](.svg) form is handled too.
  assert_contains "$oss" "[Diagram: Data flow diagram]"
  if printf '%s' "$oss" | grep -q "images/data-flow.svg"; then
    fail "expected the markdown .svg image to be replaced by its alt text"
  fi

  # A JSX <img> inside a fenced code block stays verbatim — it is a code
  # example, not a diagram embed.
  assert_contains "$oss" '<img src={thumbnail} alt="thumbnail" />'

  # A non-SVG image (PNG screenshot) is not a diagram and passes through
  # verbatim — only .svg embeds are rewritten.
  assert_contains "$oss" '<img src="images/screenshot.png" alt="App screenshot" width="840" />'

  # An SVG embed with empty alt degrades to a bare [Diagram] marker rather
  # than emitting an empty description or leaving the dead <img> path behind.
  assert_contains "$oss" "[Diagram]"
  if printf '%s' "$oss" | grep -q "images/no-alt.svg"; then
    fail "expected the empty-alt SVG <img> embed to collapse to a [Diagram] marker"
  fi
}

run_test test_complete_sidebar_top_level_sections_pass_check
run_test test_validate_mode_allows_stale_generated_outputs
run_test test_svg_diagram_embeds_become_text_descriptions
run_test test_split_produces_oss_and_pro_files
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
