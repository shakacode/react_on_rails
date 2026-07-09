# frozen_string_literal: true

require "minitest/autorun"
require_relative "pr_merge_ledger_test_helpers"

class PrMergeLedgerClosingKeywordBlockquoteTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

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

  def test_compact_nested_blockquote_tabbed_paragraph_continuation_allows_strict_closeout
    output, status = run_fixture(fixture_with_body(">>\tFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
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
end
