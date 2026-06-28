#!/usr/bin/env bash
# Test harness for script/ci-changes-detector. Requires bash, git, and perl
# (perl is used for inline fixture rewrites). Run with
# `bash script/ci-changes-detector-test.bash`.

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

run_test() {
  local test_fn="$1"
  CURRENT_TEST="$test_fn"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "-> $test_fn"

  local tmpdir before_failed had_errexit=false subshell_failures
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/ci-changes-detector-test.XXXXXX")"
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

setup_repo() {
  git init -b main >/dev/null
  git config user.email test@example.com
  git config user.name "CI Detector Test"

  mkdir -p docs react_on_rails/lib/react_on_rails packages/react-on-rails/src
  mkdir -p packages/react-on-rails-pro-node-renderer/src
  mkdir -p react_on_rails/spec/react_on_rails
  mkdir -p react_on_rails/app/helpers
  mkdir -p react_on_rails_pro/app/controllers/react_on_rails_pro/rolling_deploy
  mkdir -p react_on_rails_pro/spec/dummy/spec/requests
  mkdir -p benchmarks/lib
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
  cat > packages/react-on-rails/src/template.ts <<'TS'
export const template = `
// runtime fixture text
`;
TS
  cat > packages/react-on-rails-pro-node-renderer/src/example.ts <<'TS'
export function render(): string {
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
  cat > react_on_rails/app/helpers/react_on_rails_helper.rb <<'RUBY'
module ReactOnRails
  module Helper
    def react_component
      "ok"
    end
  end
end
RUBY
  cat > benchmarks/lib/sample.rb <<'RUBY'
module BenchmarkSample
  def self.call
    "ok"
  end
end
RUBY
  cat > react_on_rails_pro/app/controllers/react_on_rails_pro/rolling_deploy/bundles_controller.rb <<'RUBY'
module ReactOnRailsPro
  module RollingDeploy
    class BundlesController
      def call
        "ok"
      end
    end
  end
end
RUBY
  cat > react_on_rails_pro/spec/dummy/spec/requests/posts_page_spec.rb <<'RUBY'
RSpec.describe "posts page" do
  it "renders" do
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

write_file_change() {
  local path="$1"
  local content="${2:-changed}"

  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$content" > "$path"
  commit_change "change $path"
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

# Regression for PR #3597: an internal docs/planning YAML (e.g.
# internal/contributor-info/demo-fleet.yml) used to fall through to the
# uncategorized catch-all, forcing the entire test + benchmark suite to run.
test_internal_non_markdown_docs_are_non_runtime_only() {
  setup_repo
  write_file_change "internal/contributor-info/demo-fleet.yml" "fleet: []"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": true' "internal yaml output"
  assert_contains "$out" '"non_runtime_only": true' "internal yaml output"
  assert_contains "$out" '"run_lint": false' "internal yaml output"
  assert_contains "$out" '"run_ruby_tests": false' "internal yaml output"
  assert_contains "$out" '"benchmarks_changed": false' "internal yaml output"
}

# Regression for PR #3597: a GitHub issue template (.github/ISSUE_TEMPLATE/*.yml)
# is repo metadata, not CI infrastructure, and must not trigger any test suite.
test_issue_template_changes_are_non_runtime_only() {
  setup_repo
  write_file_change ".github/ISSUE_TEMPLATE/rc-release-tracking.yml" "name: RC release"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": true' "issue template output"
  assert_contains "$out" '"non_runtime_only": true' "issue template output"
  assert_contains "$out" '"run_lint": false' "issue template output"
  assert_contains "$out" '"run_ruby_tests": false' "issue template output"
}

# Regression for PR #3597 (the exact file set): mixed internal markdown +
# internal YAML + an issue-template YAML in one docs-only PR stays non-runtime,
# so it never triggers the benchmark suite.
test_docs_pr_with_internal_and_issue_template_yaml_is_non_runtime_only() {
  setup_repo
  mkdir -p internal/contributor-info .github/ISSUE_TEMPLATE
  printf 'design notes\n' > internal/contributor-info/rc-testing-plan.md
  printf 'fleet: []\n' > internal/contributor-info/demo-fleet.yml
  printf 'name: RC release\n' > .github/ISSUE_TEMPLATE/rc-release-tracking.yml
  commit_change "docs-only RC planning PR"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": true' "docs PR output"
  assert_contains "$out" '"non_runtime_only": true' "docs PR output"
  assert_contains "$out" '"run_lint": false' "docs PR output"
  assert_contains "$out" '"run_ruby_tests": false' "docs PR output"
  assert_contains "$out" '"run_js_tests": false' "docs PR output"
  assert_contains "$out" '"benchmarks_changed": false' "docs PR output"
}

# Regression for PR #4006: a docs-only PR under docs-internal/ that also ships a
# binary asset (the .png infographic) used to fall through to the uncategorized
# catch-all, forcing the ENTIRE JS + Ruby + Pro test suite to run. The markdown
# itself was always caught by the *.md extension; the image was not, and
# docs-internal/ was not recognized as a documentation directory the way docs/
# and internal/ are. Everything under docs-internal/ is internal documentation
# and must stay non-runtime regardless of file type.
test_docs_internal_tree_with_image_asset_is_non_runtime_only() {
  setup_repo
  mkdir -p docs-internal/rsc-architecture-deep-dive/images
  printf '# Deep dive\n' > docs-internal/rsc-architecture-deep-dive/00-START-HERE.md
  printf 'binary-ish png bytes\n' > docs-internal/rsc-architecture-deep-dive/images/flow.png
  commit_change "internal architecture docs with infographic"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": true' "docs-internal image output"
  assert_contains "$out" '"non_runtime_only": true' "docs-internal image output"
  assert_contains "$out" '"run_lint": false' "docs-internal image output"
  assert_contains "$out" '"run_ruby_tests": false' "docs-internal image output"
  assert_contains "$out" '"run_js_tests": false' "docs-internal image output"
  assert_contains "$out" '"benchmarks_changed": false' "docs-internal image output"
}

# Companion to PR #4006: the contract is that EVERYTHING under docs-internal/ is
# non-runtime regardless of file type, not just markdown and images. A plain
# non-markdown text file (here a .yml) is matched by the docs-internal/ directory
# globs alone — .yml is not one of the extensions the documentation branch
# recognizes, so without those globs it would hit the uncategorized catch-all and
# force the full suite, exactly as the .png did. Mirrors the internal/ sibling
# (test_internal_non_markdown_docs_are_non_runtime_only).
test_docs_internal_non_markdown_file_is_non_runtime_only() {
  setup_repo
  write_file_change "docs-internal/rsc-architecture-deep-dive/metrics.yml" "rps: 1000"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": true' "docs-internal yaml output"
  assert_contains "$out" '"non_runtime_only": true' "docs-internal yaml output"
  assert_contains "$out" '"run_lint": false' "docs-internal yaml output"
  assert_contains "$out" '"run_ruby_tests": false' "docs-internal yaml output"
  assert_contains "$out" '"run_js_tests": false' "docs-internal yaml output"
  assert_contains "$out" '"benchmarks_changed": false' "docs-internal yaml output"
}

# Isolation guard for PR #4006: the binary asset ALONE (no accompanying markdown)
# must be non-runtime. The combined regression test above ships both a .md and the
# .png; the .md is caught by *.md whether or not the docs-internal/ globs exist, so
# this strips it to prove the image is precisely what those globs rescue from the
# catch-all. Defends against a future partial revert (e.g. dropping the binary glob
# while keeping a docs-internal/**/*.md one) that the combined test would not catch.
test_docs_internal_image_only_is_non_runtime_only() {
  setup_repo
  write_file_change "docs-internal/rsc-architecture-deep-dive/images/flow.png" "binary-ish png bytes"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": true' "docs-internal image-only output"
  assert_contains "$out" '"non_runtime_only": true' "docs-internal image-only output"
  assert_contains "$out" '"run_js_tests": false' "docs-internal image-only output"
  assert_contains "$out" '"run_ruby_tests": false' "docs-internal image-only output"
}

# Guard: the docs-internal/ globs must not swallow a genuine runtime change shipped
# in the same PR. An internal doc paired with a real core-gem source edit still runs
# the Ruby suite and benchmarks — non_runtime_only flips false the moment any non-doc
# file appears, exactly as it does for the other documentation directories.
test_docs_internal_doc_plus_runtime_source_still_runs_tests() {
  setup_repo
  mkdir -p docs-internal/rsc-architecture-deep-dive
  printf '# Deep dive\n' > docs-internal/rsc-architecture-deep-dive/00-START-HERE.md
  # A genuine executable edit (string value change, not a comment) to core gem code.
  perl -0pi -e 's/"ok"/"changed"/' react_on_rails/lib/react_on_rails/example.rb
  commit_change "internal docs plus real source change"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "docs-internal mixed output"
  assert_contains "$out" '"run_ruby_tests": true' "docs-internal mixed output"
  # Core gem source underlies all three benchmark suites.
  assert_contains "$out" '"run_core_benchmarks": true' "docs-internal mixed output"
}

# Regression for PR #3717: agent/editor tooling under .claude/** and .agents/**
# is non-runtime. The .claude/skills symlink (a tracked path with no extension)
# used to miss every category and hit the catch-all, forcing the full test +
# benchmark suite — Bencher even posted results on that docs-only PR.
test_agent_tooling_changes_are_non_runtime_only() {
  setup_repo
  mkdir -p .agents/skills/verify .claude .cursor
  printf 'verify skill\n' > .agents/skills/verify/SKILL.md
  # Mirror the offending file: an extensionless path under .claude/ (the PR added
  # it as a symlink; the detector categorizes purely by path, so a plain file at
  # the same path exercises the same case branch).
  printf '../.agents/skills\n' > .claude/skills
  # Exercise extensionless files under the other agent/editor tooling globs too.
  printf 'entry\n' > .agents/skills/verify/run
  printf 'rules\n' > .cursor/rules
  commit_change "convert claude commands to agent skills"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": true' "agent tooling output"
  assert_contains "$out" '"non_runtime_only": true' "agent tooling output"
  assert_contains "$out" '"run_lint": false' "agent tooling output"
  assert_contains "$out" '"run_ruby_tests": false' "agent tooling output"
  assert_contains "$out" '"run_js_tests": false' "agent tooling output"
  assert_contains "$out" '"benchmarks_changed": false' "agent tooling output"
}

# Regression for PR #3697 (the exact file set): a CI-infrastructure PR — a
# suite-specific workflow YAML plus the detector's own test harness — must still
# run the relevant TEST suites to validate the change, but must NOT run any
# benchmark suite. CI plumbing can't move runtime performance, so a Bencher run
# is noise. The script/ harness lands in the CI-infra arm (all tests, no bench),
# and pro-integration-tests.yml runs pro dummy tests but is guarded out of the
# BENCH_* flags.
test_ci_infrastructure_only_change_runs_tests_but_skips_benchmarks() {
  setup_repo
  mkdir -p .github/workflows script
  printf 'name: Pro integration\non: [pull_request]\n' > .github/workflows/pro-integration-tests.yml
  printf '# detector test harness tweak\n' >> script/ci-changes-detector-test.bash
  commit_change "ci: fix pro dummy integration gating"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": false' "ci infra output"
  assert_contains "$out" '"non_runtime_only": false' "ci infra output"
  # Tests still run to validate the CI change (script/ forces the full suite,
  # pro-integration-tests.yml independently requests pro dummy tests) ...
  assert_contains "$out" '"run_ruby_tests": true' "ci infra output"
  assert_contains "$out" '"run_pro_dummy_tests": true' "ci infra output"
  assert_contains "$out" '"run_pro_node_renderer_tests": true' "ci infra output"
  # ... but every benchmark suite is off.
  assert_contains "$out" '"run_core_benchmarks": false' "ci infra output"
  assert_contains "$out" '"run_pro_benchmarks": false' "ci infra output"
  assert_contains "$out" '"run_pro_node_renderer_benchmarks": false' "ci infra output"
}

# A suite-specific workflow YAML on its own runs only that suite's tests, not the
# hosted CI-infrastructure suite, and never benchmarks — editing the workflow can't
# move performance. This is the part of #3697 that the CI-infra arm doesn't cover.
test_suite_workflow_file_runs_its_tests_but_no_benchmark() {
  setup_repo
  mkdir -p .github/workflows
  printf 'name: Pro integration\non: [pull_request]\n' > .github/workflows/pro-integration-tests.yml
  commit_change "tweak pro integration workflow"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_ruby_tests": false' "workflow-only output"
  assert_contains "$out" '"run_js_tests": false' "workflow-only output"
  assert_contains "$out" '"run_dummy_tests": false' "workflow-only output"
  assert_contains "$out" '"run_pro_tests": false' "workflow-only output"
  assert_contains "$out" '"run_pro_dummy_tests": true' "workflow-only output"
  assert_contains "$out" '"run_pro_node_renderer_tests": false' "workflow-only output"
  assert_contains "$out" '"run_core_benchmarks": false' "workflow-only output"
  assert_contains "$out" '"run_pro_benchmarks": false' "workflow-only output"
  assert_contains "$out" '"run_pro_node_renderer_benchmarks": false' "workflow-only output"
}

# A CI-infra change mixed with a real runtime-source change DOES benchmark: the
# genuine source edit sets the BENCH_* flags the workflow/script changes don't.
test_ci_infra_plus_runtime_source_still_benchmarks() {
  setup_repo
  mkdir -p .github/workflows
  printf 'name: Pro integration\non: [pull_request]\n' > .github/workflows/pro-integration-tests.yml
  # A genuine executable edit (string value change, not a comment) to core gem code.
  perl -0pi -e 's/"ok"/"changed"/' react_on_rails/lib/react_on_rails/example.rb
  commit_change "ci tweak plus real source change"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "mixed output"
  assert_contains "$out" '"run_ruby_tests": true' "mixed output"
  # Core gem source underlies all three benchmark suites.
  assert_contains "$out" '"run_core_benchmarks": true' "mixed output"
  assert_contains "$out" '"run_pro_benchmarks": true' "mixed output"
  assert_contains "$out" '"run_pro_node_renderer_benchmarks": true' "mixed output"
}

# Genuine node-renderer package source must benchmark the node-renderer suite —
# the case the spurious #3697 run pretended to cover.
test_node_renderer_source_change_runs_node_renderer_benchmark() {
  setup_repo
  printf 'export const x = 1;\n' > packages/react-on-rails-pro-node-renderer/src/example.ts
  commit_change "node renderer source change"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_pro_node_renderer_benchmarks": true' "node renderer output"
  assert_contains "$out" '"run_pro_benchmarks": true' "node renderer output"
  # Node renderer changes don't touch the core suite.
  assert_contains "$out" '"run_core_benchmarks": false' "node renderer output"
}

# An uncategorized file (e.g. a new CI/tooling dotfile like .ci-dependency-versions,
# the #3855 case) runs the full TEST suite for safety, but must NOT benchmark:
# unknown files are almost always tooling, not a hot runtime path, so a Bencher
# run here is pure noise. Main pushes benchmark unconditionally, so a genuinely
# new runtime path is still measured once it lands.
test_uncategorized_file_runs_tests_but_skips_benchmarks() {
  setup_repo
  write_file_change ".ci-dependency-versions" "ruby: 3.2"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "uncategorized output"
  # Full test suite still runs (the safety the catch-all is there for).
  assert_contains "$out" '"run_ruby_tests": true' "uncategorized output"
  assert_contains "$out" '"run_pro_tests": true' "uncategorized output"
  # ... but no benchmark suite.
  assert_contains "$out" '"run_core_benchmarks": false' "uncategorized output"
  assert_contains "$out" '"run_pro_benchmarks": false' "uncategorized output"
  assert_contains "$out" '"run_pro_node_renderer_benchmarks": false' "uncategorized output"
}

# Spec-only changes run the gem tests but never benchmark: specs are not shipped,
# so they cannot move runtime performance (#3854 changed only CI-config specs yet
# ran the core+pro suites).
test_rspec_only_change_skips_benchmarks() {
  setup_repo
  write_file_change "react_on_rails/spec/react_on_rails/some_bench_spec.rb"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_ruby_tests": true' "rspec-bench output"
  assert_contains "$out" '"run_core_benchmarks": false' "rspec-bench output"
  assert_contains "$out" '"run_pro_benchmarks": false' "rspec-bench output"
  assert_contains "$out" '"run_pro_node_renderer_benchmarks": false' "rspec-bench output"
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

test_ruby_block_comment_only_change_skips_heavy_tests_but_keeps_lint() {
  setup_repo
  perl -0pi -e 's/module ReactOnRails/=begin\nExplains the fixture.\n=end\nmodule ReactOnRails/' \
    react_on_rails/lib/react_on_rails/example.rb
  commit_change "ruby block comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": true' "ruby block comment output"
  assert_contains "$out" '"run_lint": true' "ruby block comment output"
  assert_contains "$out" '"run_ruby_tests": false' "ruby block comment output"
}

test_wrapping_ruby_code_with_block_comment_delimiters_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/module ReactOnRails/=begin\nmodule ReactOnRails/' react_on_rails/lib/react_on_rails/example.rb
  printf '\n=end\n' >> react_on_rails/lib/react_on_rails/example.rb
  commit_change "comment out ruby code"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "commented ruby code output"
  assert_contains "$out" '"run_ruby_tests": true' "commented ruby code output"
}

test_javascript_block_comment_only_change_skips_heavy_tests_but_keeps_lint() {
  setup_repo
  perl -0pi -e 's/export function/\/\*\n * Explains the fixture.\n *\/\nexport function/' \
    packages/react-on-rails/src/example.ts
  commit_change "js comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": true' "js comment output"
  assert_contains "$out" '"run_lint": true' "js comment output"
  assert_contains "$out" '"run_js_tests": false' "js comment output"
}

test_wrapping_code_with_block_comment_delimiters_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/export function/\/\*\nexport function/' packages/react-on-rails/src/example.ts
  printf '\n*/\n' >> packages/react-on-rails/src/example.ts
  commit_change "comment out code"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "commented code output"
  assert_contains "$out" '"run_js_tests": true' "commented code output"
}

test_prose_comment_containing_webpack_is_not_a_runtime_directive() {
  setup_repo
  perl -0pi -e 's/export function/\/\/ Documents a webpack migration note.\nexport function/' \
    packages/react-on-rails/src/example.ts
  commit_change "webpack prose comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": true' "webpack prose output"
  assert_contains "$out" '"run_js_tests": false' "webpack prose output"
}

test_webpack_magic_comment_keyword_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/export function/\/\/ webpackChunkName: "example"\nexport function/' \
    packages/react-on-rails/src/example.ts
  commit_change "webpack directive comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "webpack directive output"
  assert_contains "$out" '"run_js_tests": true' "webpack directive output"
}

test_prose_comment_containing_encoding_is_not_a_runtime_directive() {
  setup_repo
  perl -0pi -e 's/class Example/class Example\n    # Documents response encoding: utf-8./' \
    react_on_rails/lib/react_on_rails/example.rb
  commit_change "encoding prose comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": true' "encoding prose output"
  assert_contains "$out" '"run_ruby_tests": false' "encoding prose output"
}

test_typescript_suppression_comment_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/export function/\/\/ \@ts-expect-error documents expected type failure\nexport function/' \
    packages/react-on-rails/src/example.ts
  commit_change "typescript directive comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "typescript directive output"
  assert_contains "$out" '"run_js_tests": true' "typescript directive output"
}

test_code_line_starting_with_plus_plus_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/  return .ok.;/  \/\/ Count calls.\n  ++counter;\n  return counter.toString();/' \
    packages/react-on-rails/src/example.ts
  commit_change "prefix increment code"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "prefix increment output"
  assert_contains "$out" '"run_js_tests": true' "prefix increment output"
}

test_comment_like_template_literal_change_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/runtime fixture text/changed fixture text/' packages/react-on-rails/src/template.ts
  commit_change "template literal text"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "template literal output"
  assert_contains "$out" '"run_js_tests": true' "template literal output"
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

test_core_app_comment_only_change_skips_heavy_tests_but_keeps_lint() {
  setup_repo
  perl -0pi -e 's/    def react_component/    # Document the helper.\n    def react_component/' \
    react_on_rails/app/helpers/react_on_rails_helper.rb
  commit_change "core app comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": false' "core app comment output"
  assert_contains "$out" '"non_runtime_only": true' "core app comment output"
  assert_contains "$out" '"run_lint": true' "core app comment output"
  assert_contains "$out" '"run_ruby_tests": false' "core app comment output"
}

test_core_app_source_change_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/"ok"/"changed"/' react_on_rails/app/helpers/react_on_rails_helper.rb
  commit_change "core app source"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "core app source output"
  assert_contains "$out" '"run_ruby_tests": true' "core app source output"
}

# Regression for PR #3474: a comment-only change to a controller under
# react_on_rails_pro/app/ used to fall through to the uncategorized catch-all,
# which forced the entire test + benchmark suite to run.
test_pro_app_comment_only_change_runs_pro_lint_only() {
  setup_repo
  perl -0pi -e 's/    class BundlesController/    class BundlesController\n      # Document the controller./' \
    react_on_rails_pro/app/controllers/react_on_rails_pro/rolling_deploy/bundles_controller.rb
  commit_change "pro app comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": false' "pro app comment output"
  assert_contains "$out" '"non_runtime_only": true' "pro app comment output"
  assert_contains "$out" '"run_lint": false' "pro app comment output"
  assert_contains "$out" '"run_pro_lint": true' "pro app comment output"
  assert_contains "$out" '"run_pro_tests": false' "pro app comment output"
  assert_contains "$out" '"run_ruby_tests": false' "pro app comment output"
}

test_pro_app_source_change_runs_pro_tests_only() {
  setup_repo
  perl -0pi -e 's/"ok"/"changed"/' \
    react_on_rails_pro/app/controllers/react_on_rails_pro/rolling_deploy/bundles_controller.rb
  commit_change "pro app source"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "pro app source output"
  assert_contains "$out" '"run_pro_tests": true' "pro app source output"
  # Scoped to Pro: a Pro app change must not drag in the core gem suite the way
  # the old uncategorized catch-all did.
  assert_contains "$out" '"run_ruby_tests": false' "pro app source output"
  assert_contains "$out" '"run_js_tests": false' "pro app source output"
}

test_pro_dummy_only_change_runs_pro_dummy_tests_without_pro_unit_tests() {
  setup_repo
  perl -0pi -e 's/renders/renders seeded data/' react_on_rails_pro/spec/dummy/spec/requests/posts_page_spec.rb
  commit_change "pro dummy spec"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_pro_dummy_tests": true' "pro dummy output"
  assert_contains "$out" '"run_pro_tests": false' "pro dummy output"
}

test_pro_node_renderer_comment_only_change_runs_pro_lint_only() {
  setup_repo
  perl -0pi -e 's/export function/\/\/ Explains the Pro node renderer fixture.\nexport function/' \
    packages/react-on-rails-pro-node-renderer/src/example.ts
  commit_change "pro node renderer comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": true' "pro node renderer comment output"
  assert_contains "$out" '"run_lint": false' "pro node renderer comment output"
  assert_contains "$out" '"run_pro_lint": true' "pro node renderer comment output"
  assert_contains "$out" '"run_pro_node_renderer_tests": false' "pro node renderer comment output"
}

test_mixed_comment_and_code_change_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's/    def call/    # Explain the fixture.\n    def call/' \
    react_on_rails/lib/react_on_rails/example.rb
  perl -0pi -e 's/"ok"/"changed"/' react_on_rails/lib/react_on_rails/example.rb
  commit_change "mixed comment and code"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "mixed output"
  assert_contains "$out" '"run_ruby_tests": true' "mixed output"
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

test_jsdoc_jsx_import_source_pragma_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's{export function}{/** \@jsxImportSource @emotion/react */\nexport function}' \
    packages/react-on-rails/src/example.ts
  commit_change "jsdoc jsx import source pragma"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "jsdoc pragma output"
  assert_contains "$out" '"run_js_tests": true' "jsdoc pragma output"
}

test_inline_block_comment_license_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's{export function}{/* \@license MIT */\nexport function}' \
    packages/react-on-rails/src/example.ts
  commit_change "inline block comment license"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "license directive output"
  assert_contains "$out" '"run_js_tests": true' "license directive output"
}

test_pure_annotation_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's{export function}{/* \@__PURE__ */\nexport function}' \
    packages/react-on-rails/src/example.ts
  commit_change "pure annotation"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "pure annotation output"
  assert_contains "$out" '"run_js_tests": true' "pure annotation output"
}

test_block_comment_with_trailing_code_remains_runtime_affecting() {
  setup_repo
  perl -0pi -e 's{export function}{/* note */ exports.flag = true;\nexport function}' \
    packages/react-on-rails/src/example.ts
  commit_change "block comment plus trailing code"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": false' "trailing code after block close output"
  assert_contains "$out" '"run_js_tests": true' "trailing code after block close output"
}

test_pro_only_changes_do_not_request_e2e() {
  setup_repo
  write_file_change "react_on_rails_pro/lib/react_on_rails_pro/example.rb"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_e2e_tests": false' "pro-only output"
}

test_rspec_only_changes_do_not_request_e2e() {
  setup_repo
  write_file_change "react_on_rails/spec/react_on_rails/some_spec.rb"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_ruby_tests": true' "rspec-only output"
  assert_contains "$out" '"run_dummy_tests": false' "rspec-only output"
  assert_contains "$out" '"run_e2e_tests": false' "rspec-only output"
}

test_generator_only_changes_do_not_request_e2e() {
  setup_repo
  write_file_change "react_on_rails/lib/generators/react_on_rails/install/example.rb"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_ruby_tests": true' "generator-only output"
  assert_contains "$out" '"run_generators": true' "generator-only output"
  assert_contains "$out" '"run_dummy_tests": false' "generator-only output"
  assert_contains "$out" '"run_e2e_tests": false' "generator-only output"
}

test_dummy_app_changes_request_e2e() {
  setup_repo
  write_file_change "react_on_rails/spec/dummy/app/views/pages/example.html.erb"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_e2e_tests": true' "dummy app output"
}

test_core_ruby_changes_request_e2e() {
  setup_repo
  write_file_change "react_on_rails/lib/react_on_rails/example.rb"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_dummy_tests": true' "core ruby output"
  assert_contains "$out" '"run_e2e_tests": true' "core ruby output"
}

test_core_js_changes_request_e2e() {
  setup_repo
  write_file_change "packages/react-on-rails/src/example.ts"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"run_e2e_tests": true' "core js output"
}

test_benchmark_source_change_lints_and_flags_benchmarks_only() {
  setup_repo
  write_file_change "benchmarks/generate_matrix.rb"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"benchmarks_changed": true' "benchmark source output"
  assert_contains "$out" '"run_lint": true' "benchmark source output"
  # Benchmark scripts have no coverage in the gem suite, dummy app, or Pro stack.
  assert_contains "$out" '"run_ruby_tests": false' "benchmark source output"
  assert_contains "$out" '"run_dummy_tests": false' "benchmark source output"
  assert_contains "$out" '"run_e2e_tests": false' "benchmark source output"
  assert_contains "$out" '"run_pro_tests": false' "benchmark source output"
  assert_contains "$out" '"run_core_benchmarks": false' "benchmark source output"
  assert_contains "$out" '"run_pro_benchmarks": false' "benchmark source output"
  assert_contains "$out" '"run_pro_node_renderer_benchmarks": false' "benchmark source output"
}

test_benchmark_comment_only_change_is_non_runtime_but_keeps_lint() {
  setup_repo
  perl -0pi -e 's/module BenchmarkSample/# Describe the sample.\nmodule BenchmarkSample/' \
    benchmarks/lib/sample.rb
  commit_change "benchmark comment"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": true' "benchmark comment output"
  assert_contains "$out" '"run_lint": true' "benchmark comment output"
  assert_contains "$out" '"benchmarks_changed": false' "benchmark comment output"
  assert_contains "$out" '"run_ruby_tests": false' "benchmark comment output"
}

# Release tooling (rakelib/release.rake + script/release-* helpers) is covered
# ONLY by the release rspec suite, never by generators or JS. It must request the
# Ruby tests (so those specs run) AND lint (rubocop covers this Ruby/Bash) while
# keeping run_generators / run_js_tests false, so required-pr-gate
# (script/ci-required-hosted-gate) does not force the full hosted matrix. Before
# this arm existed, rakelib/release.rake hit the uncategorized catch-all and set
# run_generators=true.
#
# All five release-tooling paths share one contract, asserted identically via
# this helper so a one-character typo in any pattern can't silently fall through
# to the generator-sensitive script/* CI-infra arm.
assert_release_tooling_contract() {
  local out="$1"
  local label="$2"
  assert_contains "$out" '"docs_only": false' "$label"
  assert_contains "$out" '"non_runtime_only": false' "$label"
  # Rubocop must run so release tooling is linted (the lint job is hosted-gated
  # on run_lint; without this it would never lint these paths).
  assert_contains "$out" '"run_lint": true' "$label"
  # Release specs run (release_rake_helpers_spec / release_forward_port_script_spec).
  assert_contains "$out" '"run_ruby_tests": true' "$label"
  # Primary goal: NOT generator-sensitive, so required-pr-gate won't force hosted CI.
  assert_contains "$out" '"run_generators": false' "$label"
  assert_contains "$out" '"run_js_tests": false' "$label"
  # Release tooling does not exercise the dummy app, E2E, or benchmarks.
  assert_contains "$out" '"run_dummy_tests": false' "$label"
  assert_contains "$out" '"run_e2e_tests": false' "$label"
  assert_contains "$out" '"run_core_benchmarks": false' "$label"
}

test_release_rake_change_runs_ruby_tests_and_lint_without_generators() {
  setup_repo
  write_file_change "rakelib/release.rake" "task :release do; end"

  assert_release_tooling_contract "$(detector_output)" "release rake output"
}

# The release helper scripts under script/ must be caught by the release-tooling
# arm, not the broad script/* CI-infrastructure arm (which would set
# run_generators=true and force hosted CI). Same contract as release.rake.
test_release_finish_script_change_runs_ruby_tests_and_lint_without_generators() {
  setup_repo
  write_file_change "script/release-finish" "#!/usr/bin/env bash"

  assert_release_tooling_contract "$(detector_output)" "release-finish output"
}

# Per-path coverage for the remaining three release-tooling globs. Without these,
# a typo in any single pattern would route that path to the generator-sensitive
# script/* CI-infra arm undetected.
test_release_forward_port_script_change_runs_ruby_tests_and_lint_without_generators() {
  setup_repo
  write_file_change "script/release-forward-port" "#!/usr/bin/env bash"

  assert_release_tooling_contract "$(detector_output)" "release-forward-port output"
}

test_release_forward_port_test_change_runs_ruby_tests_and_lint_without_generators() {
  setup_repo
  write_file_change "script/release-forward-port-test.bash" "#!/usr/bin/env bash"

  assert_release_tooling_contract "$(detector_output)" "release-forward-port-test output"
}

test_release_finish_test_change_runs_ruby_tests_and_lint_without_generators() {
  setup_repo
  write_file_change "script/release-finish-test.bash" "#!/usr/bin/env bash"

  assert_release_tooling_contract "$(detector_output)" "release-finish-test output"
}

# Regression guard: a CHANGELOG.md-only change is documentation (matched by the
# *.md docs arm) and must stay skippable — docs_only / non_runtime_only true,
# every run_* false. Release stamping touches CHANGELOG.md, so this keeps that
# path from ever forcing CI.
test_changelog_only_change_is_non_runtime_only() {
  setup_repo
  write_file_change "CHANGELOG.md" "## [Unreleased]"

  local out
  out="$(detector_output)"
  assert_contains "$out" '"docs_only": true' "changelog output"
  assert_contains "$out" '"non_runtime_only": true' "changelog output"
  assert_contains "$out" '"run_lint": false' "changelog output"
  assert_contains "$out" '"run_ruby_tests": false' "changelog output"
  assert_contains "$out" '"run_js_tests": false' "changelog output"
  assert_contains "$out" '"run_generators": false' "changelog output"
  assert_contains "$out" '"benchmarks_changed": false' "changelog output"
}

test_empty_diff_skips_everything() {
  setup_repo
  git commit --allow-empty -m "no file changes" >/dev/null

  local out
  out="$(detector_output)"
  assert_contains "$out" '"non_runtime_only": true' "empty diff output"
  assert_contains "$out" '"run_lint": false' "empty diff output"
  assert_contains "$out" '"run_ruby_tests": false' "empty diff output"
  assert_contains "$out" '"benchmarks_changed": false' "empty diff output"
}

run_test test_empty_diff_skips_everything
run_test test_release_rake_change_runs_ruby_tests_and_lint_without_generators
run_test test_release_finish_script_change_runs_ruby_tests_and_lint_without_generators
run_test test_release_forward_port_script_change_runs_ruby_tests_and_lint_without_generators
run_test test_release_forward_port_test_change_runs_ruby_tests_and_lint_without_generators
run_test test_release_finish_test_change_runs_ruby_tests_and_lint_without_generators
run_test test_changelog_only_change_is_non_runtime_only
run_test test_docs_changes_are_non_runtime_only
run_test test_internal_non_markdown_docs_are_non_runtime_only
run_test test_issue_template_changes_are_non_runtime_only
run_test test_docs_pr_with_internal_and_issue_template_yaml_is_non_runtime_only
run_test test_docs_internal_tree_with_image_asset_is_non_runtime_only
run_test test_docs_internal_non_markdown_file_is_non_runtime_only
run_test test_docs_internal_image_only_is_non_runtime_only
run_test test_docs_internal_doc_plus_runtime_source_still_runs_tests
run_test test_agent_tooling_changes_are_non_runtime_only
run_test test_ci_infrastructure_only_change_runs_tests_but_skips_benchmarks
run_test test_suite_workflow_file_runs_its_tests_but_no_benchmark
run_test test_ci_infra_plus_runtime_source_still_benchmarks
run_test test_node_renderer_source_change_runs_node_renderer_benchmark
run_test test_uncategorized_file_runs_tests_but_skips_benchmarks
run_test test_rspec_only_change_skips_benchmarks
run_test test_ruby_comment_only_change_skips_heavy_tests_but_keeps_lint
run_test test_ruby_block_comment_only_change_skips_heavy_tests_but_keeps_lint
run_test test_wrapping_ruby_code_with_block_comment_delimiters_remains_runtime_affecting
run_test test_javascript_block_comment_only_change_skips_heavy_tests_but_keeps_lint
run_test test_wrapping_code_with_block_comment_delimiters_remains_runtime_affecting
run_test test_prose_comment_containing_webpack_is_not_a_runtime_directive
run_test test_webpack_magic_comment_keyword_remains_runtime_affecting
run_test test_prose_comment_containing_encoding_is_not_a_runtime_directive
run_test test_typescript_suppression_comment_remains_runtime_affecting
run_test test_code_line_starting_with_plus_plus_remains_runtime_affecting
run_test test_comment_like_template_literal_change_remains_runtime_affecting
run_test test_spec_comment_only_change_skips_rspec
run_test test_core_app_comment_only_change_skips_heavy_tests_but_keeps_lint
run_test test_core_app_source_change_remains_runtime_affecting
run_test test_pro_app_comment_only_change_runs_pro_lint_only
run_test test_pro_app_source_change_runs_pro_tests_only
run_test test_pro_dummy_only_change_runs_pro_dummy_tests_without_pro_unit_tests
run_test test_pro_node_renderer_comment_only_change_runs_pro_lint_only
run_test test_mixed_comment_and_code_change_remains_runtime_affecting
run_test test_ruby_magic_comment_remains_runtime_affecting
run_test test_executable_source_change_remains_runtime_affecting
run_test test_jsdoc_jsx_import_source_pragma_remains_runtime_affecting
run_test test_inline_block_comment_license_remains_runtime_affecting
run_test test_pure_annotation_remains_runtime_affecting
run_test test_block_comment_with_trailing_code_remains_runtime_affecting
run_test test_pro_only_changes_do_not_request_e2e
run_test test_rspec_only_changes_do_not_request_e2e
run_test test_generator_only_changes_do_not_request_e2e
run_test test_dummy_app_changes_request_e2e
run_test test_core_ruby_changes_request_e2e
run_test test_core_js_changes_request_e2e
run_test test_benchmark_source_change_lints_and_flags_benchmarks_only
run_test test_benchmark_comment_only_change_is_non_runtime_but_keeps_lint

echo
echo "CI changes detector tests: $TESTS_RUN run, $TESTS_FAILED failed"

if [ "$TESTS_FAILED" -ne 0 ]; then
  printf '\nFailures:\n' >&2
  printf '  - %s\n' "${FAILURES[@]}" >&2
  exit 1
fi
