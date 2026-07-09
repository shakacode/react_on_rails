# frozen_string_literal: true

require "minitest/autorun"
require_relative "pr_merge_ledger_test_helpers"

# rubocop:disable Metrics/ClassLength
class PrMergeLedgerClosingKeywordInlineTest < Minitest::Test
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
end
# rubocop:enable Metrics/ClassLength
