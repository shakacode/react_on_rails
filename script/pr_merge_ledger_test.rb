# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"

SCRIPT = File.expand_path("pr-merge-ledger", __dir__)

module PrMergeLedgerFixtureHelpers
  private

  def ledger(data)
    data.fetch("pull_requests").fetch(0)
  end

  def violation_codes(data)
    ledger(data).fetch("violations").map { |violation| violation.fetch("code") }
  end

  def unknown_field_names(data)
    ledger(data).fetch("unknown_fields").map { |field| field.fetch("field") }
  end

  def run_fixture(fixture_hash)
    Dir.mktmpdir("pr-merge-ledger-test") do |dir|
      fixture_path = File.join(dir, "fixture.json")
      File.write(fixture_path, JSON.pretty_generate(fixture_hash))
      stdout, stderr, status = Open3.capture3(
        "ruby",
        SCRIPT,
        "--fixture",
        fixture_path,
        "--strict",
        "--changelog-classification",
        "not_user_visible"
      )
      [stdout, status].tap do
        assert_empty stderr unless stderr.include?("ledger violations:")
      end
    end
  end

  def fixture(ci_readiness:, number: 123)
    {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => number,
        "title" => "Fixture PR",
        "url" => "https://github.com/shakacode/react_on_rails/pull/#{number}",
        "state" => "OPEN",
        "isDraft" => false,
        "baseRefName" => "main",
        "headRefName" => "codex/fixture",
        "headRefOid" => "abc123",
        "mergedAt" => nil,
        "reviewDecision" => "APPROVED",
        "body" => "Fixes #123"
      },
      "files" => ["script/pr-merge-ledger"],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [],
      "ci_readiness" => ci_readiness
    }
  end

  def ci_readiness(verdict:, checks:, number: 123, status: "known", required_used: true, message: nil)
    {
      "pr" => number,
      "status" => status,
      "verdict" => verdict,
      "required_used" => required_used,
      "failing" => checks.select { |check| check["bucket"] == "fail" },
      "pending" => checks.select { |check| check["bucket"] == "pending" },
      "checks" => checks,
      "message" => message
    }.compact
  end

  def ci_check(name, bucket:, state:, link: nil)
    {
      "name" => name,
      "state" => state,
      "bucket" => bucket,
      "link" => link
    }.compact
  end
end

class PrMergeLedgerTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

  def test_ready_ci_allows_strict_closeout
    output, status = run_fixture(
      fixture(
        ci_readiness: ci_readiness(
          verdict: "READY",
          checks: [
            ci_check("Lint JS and Ruby / build", bucket: "pass", state: "SUCCESS")
          ]
        )
      )
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty data.fetch("violations")
    assert_equal "READY", ledger(data).fetch("ci_readiness").fetch("verdict")
  end

  def test_failed_ci_blocks_strict_closeout_with_check_name
    output, status = run_fixture(
      fixture(
        number: 4444,
        ci_readiness: ci_readiness(
          number: 4444,
          verdict: "NOT_READY",
          checks: [
            ci_check(
              "JS unit tests for Renderer package / build (22)",
              bucket: "fail",
              state: "FAILURE",
              link: "https://github.com/shakacode/react_on_rails/actions/runs/28660148440/job/84998580503"
            )
          ]
        )
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    refute data.fetch("complete_allowed")
    ci_readiness = ledger(data).fetch("ci_readiness")
    assert_equal 4444, ci_readiness.fetch("pr")
    assert_equal "NOT_READY", ci_readiness.fetch("verdict")
    failing_check_names = ci_readiness.fetch("failing").map { |check| check.fetch("name") }
    assert_equal ["JS unit tests for Renderer package / build (22)"], failing_check_names
    assert_equal ["ci_check_failed"], violation_codes(data)
  end

  def test_check_rows_override_inconsistent_ready_ci_payload
    checks = [ci_check("lint", bucket: "fail", state: "FAILURE")]
    readiness = ci_readiness(verdict: "READY", checks:)
    readiness["failing"] = []
    readiness["pending"] = []

    output, status = run_fixture(fixture(ci_readiness: readiness))

    refute status.success?, output
    data = JSON.parse(output)
    ci_readiness = ledger(data).fetch("ci_readiness")
    assert_equal "NOT_READY", ci_readiness.fetch("verdict")
    failing_check_names = ci_readiness.fetch("failing").map { |check| check.fetch("name") }
    assert_equal ["lint"], failing_check_names
    assert_equal ["ci_check_failed"], violation_codes(data)
  end

  def test_pending_ci_blocks_strict_closeout
    output, status = run_fixture(
      fixture(
        ci_readiness: ci_readiness(
          verdict: "NOT_READY",
          checks: [
            ci_check("Integration Tests / build", bucket: "pending", state: "PENDING")
          ]
        )
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["ci_check_pending"], violation_codes(data)
  end

  def test_not_ready_ci_without_check_details_blocks_strict_closeout
    output, status = run_fixture(
      fixture(
        ci_readiness: ci_readiness(
          verdict: "NOT_READY",
          checks: []
        )
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["ci_not_ready"], violation_codes(data)
    message = ledger(data).fetch("violations").fetch(0).fetch("message")
    assert_match(/NOT_READY/, message)
  end

  def test_unknown_ci_blocks_strict_closeout
    output, status = run_fixture(
      fixture(
        ci_readiness: ci_readiness(
          status: "UNKNOWN",
          verdict: "UNKNOWN",
          checks: [],
          message: "no active current-head check rows were returned"
        )
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["ci_readiness.verdict"], unknown_field_names(data)
    assert_equal ["unknown_ci_readiness"], violation_codes(data)
  end

  def test_cancel_only_ci_without_explicit_verdict_is_unknown
    output, status = run_fixture(
      fixture(
        ci_readiness: {
          "pr" => 123,
          "status" => "known",
          "required_used" => true,
          "checks" => [
            ci_check("required-pr-gate", bucket: "cancel", state: "CANCELLED")
          ]
        }
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    ci_readiness = ledger(data).fetch("ci_readiness")
    assert_equal "UNKNOWN", ci_readiness.fetch("verdict")
    assert_equal ["ci_readiness.verdict"], unknown_field_names(data)
    assert_equal ["unknown_ci_readiness"], violation_codes(data)
  end

  def test_cancelled_row_with_passing_check_is_not_ready
    output, status = run_fixture(
      fixture(
        ci_readiness: {
          "pr" => 123,
          "status" => "known",
          "required_used" => true,
          "checks" => [
            ci_check("required-pr-gate", bucket: "pass", state: "SUCCESS"),
            ci_check("rspec-package-tests", bucket: "cancel", state: "CANCELLED")
          ]
        }
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    ci_readiness = ledger(data).fetch("ci_readiness")
    assert_equal "NOT_READY", ci_readiness.fetch("verdict")
    pending_check_names = ci_readiness.fetch("pending").map { |check| check.fetch("name") }
    assert_equal ["rspec-package-tests"], pending_check_names
    assert_equal ["ci_check_cancelled"], violation_codes(data)
  end
end

# rubocop:disable Metrics/ClassLength
class PrMergeLedgerClosingKeywordTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

  def test_backticked_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This should close the issue, but `Fixes #4410` will not."))

    refute status.success?, output
    data = JSON.parse(output)
    refute_includes ledger(data).fetch("pr").keys, "body_text"
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_backticked_issue_reference_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close: Fixes `#4410`."))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_backticked_closing_keyword_only_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close: `Fixes` #4410."))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_soft_wrapped_backticked_closing_keyword_only_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close:\n`Fixes`\n#4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_soft_wrapped_backticked_issue_reference_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close:\nFixes\n`#4410`\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_soft_wrapped_open_multiline_inline_issue_reference_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close:\nFixes `\n#4410`\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_soft_wrapped_plain_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("Fixes\n#4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_code_formatted_closing_keyword_scan_includes_max_body_line
    body = ((["plain prose"] * 999) + ["`Fixes #4410`"]).join("\n")
    output, status = run_fixture(fixture_with_body(body))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1000, violation.fetch("line")
  end

  def test_code_formatted_closing_keyword_scan_truncation_blocks_strict_closeout
    body = ((["plain prose"] * 1_000) + ["`Fixes #4410`"]).join("\n")
    output, status = run_fixture(fixture_with_body(body))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["unknown_pr_body_closing_keyword_scan"], violation_codes(data)
    assert_equal ["pr.body_code_formatted_closing_keyword_scan"], unknown_field_names(data)
  end

  def test_code_formatted_closing_keyword_scan_oversized_line_blocks_strict_closeout
    body = "#{'a' * 100_001}\nFixes #4410\n"
    output, status = run_fixture(fixture_with_body(body))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["unknown_pr_body_closing_keyword_scan"], violation_codes(data)
    assert_equal ["pr.body_code_formatted_closing_keyword_scan"], unknown_field_names(data)
  end

  def test_code_formatted_closing_keyword_on_non_default_branch_allows_strict_closeout
    output, status = run_fixture(
      fixture_with_body("This will not close the issue from a release branch: `Fixes #4410`.").tap do |dataset|
        dataset.fetch("pull_request")["baseRefName"] = "release/17.0.0"
      end
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_long_non_default_branch_body_skips_closing_keyword_scan_unknown
    body = ((["plain prose"] * 1_000) + ["`Fixes #4410`"]).join("\n")
    output, status = run_fixture(
      fixture_with_body(body).tap do |dataset|
        dataset.fetch("pull_request")["baseRefName"] = "release/17.0.0"
      end
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
    assert_empty unknown_field_names(data)
  end

  def test_backticked_url_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body("This will not close: `Fixes https://github.com/shakacode/react_on_rails/issues/4410`.")
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(%r{https://github\.com/shakacode/react_on_rails/issues/4410}, violation.fetch("message"))
  end

  def test_backticked_colon_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close: `Fixes: #4410`."))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes: #4410/, violation.fetch("message"))
  end

  def test_plain_colon_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("Fixes: #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_backticked_closing_keyword_with_backslash_before_delimiter_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close: `Fixes #4410\\`."))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_multiline_inline_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close: `Fixes #4410\nbecause it is code`."))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_multiline_inline_code_over_noninterrupting_ordered_marker_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("`Fixes #4410\n2) more text here\nend`\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_split_multiline_inline_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close: `Fixes\n#4410`."))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_blockquoted_split_multiline_inline_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("> `Fixes\n> #4410`\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_blockquoted_multiline_inline_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("> `Fixes #4410\n> still code`\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_fenced_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          This should close the issue, but a fenced code block will not.

          ```text
          Fixes #4410
          ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_fenced_code_colon_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ```text
          Closes: #4410
          ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Closes: #4410/, violation.fetch("message"))
  end

  def test_split_fenced_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ```text
          Fixes
          #4410
          ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_large_fenced_code_block_stops_accumulating_after_first_report
    filler = (["x" * 200] * 996).join("\n")
    output, status = run_fixture(fixture_with_body("```text\nFixes\n#4410\n#{filler}\n```\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_blockquoted_fenced_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          > ```text
          > Fixes #4410
          > ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_root_fenced_code_after_blockquote_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          > quoted context
          ```text
          Fixes #4410
          ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_unquoted_closing_keyword_after_blockquote_fence_allows_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          > ```text
          > example

          Fixes #4410
        MARKDOWN
      )
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_fence_opener_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ```text Fixes #4410
          ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_backtick_fence_with_backtick_in_info_allows_plain_closing_keyword
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ``` te`xt
          Fixes #4410
          ```
        MARKDOWN
      )
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_tilde_fence_with_backtick_in_info_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ~~~ te`xt
          Fixes #4410
          ~~~
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_nested_shorter_fence_keeps_closing_keyword_inside_outer_code_block
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ````markdown
          ```text
          Fixes #4410
          ```
          ````
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_indented_fence_marker_does_not_close_fenced_block
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ```markdown
              ```
          Fixes #4410
          ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_quoted_fence_marker_does_not_close_root_fenced_block
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ```markdown
          > ```
          Fixes #4410
          ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close.\n\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_split_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("    Fixes\n    #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_thematic_break_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("---\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_setext_heading_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("Summary\n---\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_setext_underline_without_paragraph_allows_paragraph_closing_keyword
    output, status = run_fixture(fixture_with_body("===\n    Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_link_reference_definition_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_html_comment_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<!-- link issue -->\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_html_block_tag_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<div>\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_html_comment_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<!-- Fixes #4410 -->\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_multiline_html_comment_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<!--\nFixes #4410\n-->\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_multiline_html_comment_split_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<!--\nFixes\n#4410\n-->\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_html_block_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<div>\nFixes #4410\n</div>\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_html_block_continues_until_blank_line_after_closing_tag
    output, status = run_fixture(fixture_with_body("<div>\n</div>\nFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_html_block_blank_line_before_closeout_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("<div>\n</div>\n\nFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_raw_html_block_blank_line_does_not_end_before_closeout
    output, status = run_fixture(fixture_with_body("<pre>\n\nFixes #4410\n</pre>\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_type_7_html_block_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<ins>\nFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_type_7_html_block_with_quoted_greater_than_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<ins title=\">\">\nFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_item_html_block_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- <div>\n  Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_gfm_table_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("A | B\n--|--\n1 | 2\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_gfm_table_inside_fenced_code_does_not_leak_state_to_following_indented_closeout
    output, status = run_fixture(fixture_with_body("```text\nA | B\n--|--\n```\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 5, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_gfm_table_no_pipe_body_row_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("A | B\n--|--\nno pipe\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_gfm_table_mismatched_delimiter_cell_count_allows_paragraph_continuation
    output, status = run_fixture(fixture_with_body("A | B\n--- | --- | ---\n    Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_gfm_table_single_hyphen_delimiter_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("A | B\n:-: | -:\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_gfm_one_column_table_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("| Issue |\n| --- |\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_gfm_table_escaped_pipe_cell_before_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("| f\\|oo | bar |\n| --- | --- |\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_gfm_table_long_delimiter_cells_do_not_backtrack
    long_separator_line = "#{'-' * 32_000} | #{'-' * 32_000}"
    output, status = run_fixture(fixture_with_body("A | B\n#{long_separator_line}\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_gfm_table_escaped_pipe_cells_do_not_backtrack
    escaped_pipe_header_cell = "\\| " * 20_000
    output, status = run_fixture(
      fixture_with_body("#{escaped_pipe_header_cell} | B\n--- | ---\n    Fixes #4410\n")
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_blockquoted_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("> This will not close.\n>\n>     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_blockquote_indented_code_after_root_text_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("Root paragraph.\n>     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_blockquote_indented_paragraph_continuation_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("> This remains prose.\n>     Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_blockquote_tabbed_paragraph_continuation_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("> \tFixes #4410\n>  \tFixes #4411\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_blockquote_tabbed_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body(">   \tFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_nested_blockquote_tabbed_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("> > \tFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_blockquote_lazy_indented_paragraph_continuation_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("> This remains prose.\n    Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_blockquote_blank_before_root_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("> This quote ended.\n>\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_tab_expanded_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close.\n\n \tFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_indented_paragraph_continuation_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("This remains prose\n    Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_ordered_list_non_one_marker_does_not_interrupt_paragraph_before_indented_closeout
    output, status = run_fixture(fixture_with_body("This remains prose\n2. details\n    Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_ordered_list_non_one_marker_before_blank_keeps_root_indented_closeout
    output, status = run_fixture(fixture_with_body("This remains prose\n2. details\n\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_ordered_list_one_marker_interrupts_paragraph_before_indented_closeout
    output, status = run_fixture(fixture_with_body("This starts a paragraph\n1. details\n\n       Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_ordered_list_non_one_marker_at_root_before_indented_closeout_blocks
    output, status = run_fixture(fixture_with_body("2. details\n\n       Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_plain_pipe_paragraph_continuation_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("This | remains prose\n    Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_table_separator_without_header_allows_paragraph_closing_keyword
    output, status = run_fixture(fixture_with_body("--|--\n    Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_indented_pipe_line_does_not_start_gfm_table_before_plain_closing_keyword
    output, status = run_fixture(fixture_with_body("    A | B\n--|--\n    Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_indented_code_inside_list_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          1. Closeout evidence:

                 Fixes #4410
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_indented_code_after_list_heading_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          - # Summary
                Fixes #4410
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_indented_fenced_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          - Closeout evidence:

              ```text
              Fixes #4410
              ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_marker_fenced_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          - ```text
            Fixes #4410
            ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_same_line_nested_list_marker_fenced_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          - - ```text
              Fixes #4410
              ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_plain_closeout_after_same_line_nested_list_marker_fence_allows_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          - - ```text
              example
              ```
          Fixes #4410
        MARKDOWN
      )
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_nested_list_marker_tilde_fenced_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          - a
            - b
              - ~~~text
                Fixes #4410
                ~~~
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_outdented_closing_keyword_after_list_fence_allows_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          - ```text
            example
          Fixes #4410
            ```
        MARKDOWN
      )
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_list_marker_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("-     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_empty_list_marker_indented_code_continuation_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("-\n      Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_item_link_reference_then_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- [ref]: /url\n      Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_item_html_comment_then_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- <!-- note -->\n      Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_marker_indented_code_continuation_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("-     code\n      Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_ordered_list_marker_indented_code_continuation_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("1.     code\n       Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_marker_tab_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("-   \tFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_marker_tab_aligned_prose_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("-  \tFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_blockquoted_list_marker_tab_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("> - \tFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_blockquote_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- >     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_nested_blockquote_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- > >     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_nested_blockquote_plain_closeout_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("- > > Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_same_line_nested_list_blockquote_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- - >     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_same_line_nested_list_blockquote_plain_closeout_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("- - > Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_nested_list_blockquote_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- a\n  - b\n    - >     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_same_line_nested_list_marker_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- -     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_deep_same_line_nested_list_marker_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- - -     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_very_deep_same_line_nested_list_marker_indented_code_blocks_strict_closeout
    nested_markers = Array.new(100, "- ").join
    output, status = run_fixture(fixture_with_body("#{nested_markers}    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_deep_same_line_nested_list_marker_plain_closeout_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("- - - Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_list_blockquote_tab_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- > \tFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_quoted_list_blockquote_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("> - >     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_plain_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("Fixes #4410"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_escaped_backticks_around_closing_keyword_allow_strict_closeout
    output, status = run_fixture(fixture_with_body("Escaped backticks stay prose: \\`Fixes #4410\\`."))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_unmatched_backtick_before_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("Unmatched `backtick remains prose.\nFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_unmatched_backtick_before_paragraph_boundary_allows_strict_closeout
    output, status = run_fixture(
      fixture_with_body("Summary has an unmatched `backtick.\n\nFixes #4410\n\nTests: `ruby test`\n")
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_unmatched_backtick_before_list_boundary_allows_plain_closing_keyword
    output, status = run_fixture(
      fixture_with_body("Summary has an unmatched `backtick.\n- Fixes #4410 `cmd`\n")
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_unmatched_backtick_before_heading_boundary_allows_plain_closing_keyword
    output, status = run_fixture(
      fixture_with_body("Summary has an unmatched `backtick.\n# Fixes #4410 `cmd`\n")
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_list_continuation_closing_keyword_allows_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          1. Closeout evidence:

              Fixes #4410
        MARKDOWN
      )
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_list_paragraph_continuation_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("- This remains prose\n      Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_list_paragraph_continuation_over_noninterrupting_ordered_marker_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- Intro\n  2. details\n\n      Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_paragraph_continuation_over_noninterrupting_ordered_marker_heading_text_allows_closeout
    output, status = run_fixture(fixture_with_body("- Intro\n  2. # details\n      Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_nested_list_marker_with_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- a\n  - b\n    -     Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_nested_list_marker_plain_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("- a\n  - b\n    - Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_reduced_blockquote_depth_after_fence_allows_plain_closing_keyword
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          > > ```text
          > > example
          > > ```
          > Fixes #4410
        MARKDOWN
      )
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_list_continuation_with_tab_stop_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("1. Closeout evidence:\n\n   \tFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_tab_indented_list_fence_closer_allows_following_plain_closing_keyword
    output, status = run_fixture(fixture_with_body("- ```\n\tcode\n\t```\n  Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_plain_closing_keyword_between_inline_code_spans_allows_strict_closeout
    output, status = run_fixture(
      fixture_with_body("Update `ledger` and Fixes #4410 while documenting `keyword`.")
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  private

  def fixture_with_body(body)
    fixture(
      ci_readiness: ci_readiness(
        verdict: "READY",
        checks: [ci_check("required-pr-gate", bucket: "pass", state: "SUCCESS")]
      )
    ).tap do |dataset|
      dataset.fetch("pull_request")["body"] = body
    end
  end
end
# rubocop:enable Metrics/ClassLength
