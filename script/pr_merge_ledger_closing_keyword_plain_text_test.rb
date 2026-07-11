# frozen_string_literal: true

require "minitest/autorun"
require_relative "pr_merge_ledger_test_helpers"

# rubocop:disable Metrics/ClassLength
class PrMergeLedgerClosingKeywordPlainTextTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

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

  def test_repeated_unmatched_backticks_before_plain_closeout_allow_strict_closeout
    unmatched_lines = Array.new(999) { |index| "line #{index} has an unmatched `backtick" }
    output, status = run_fixture(fixture_with_body("#{unmatched_lines.join("\n")}\nFixes #4410\n"))

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

  def test_list_paragraph_continuation_over_empty_noninterrupting_ordered_marker_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- Intro\n  2.\n\n      Fixes #4410\n"))

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
end
# rubocop:enable Metrics/ClassLength
