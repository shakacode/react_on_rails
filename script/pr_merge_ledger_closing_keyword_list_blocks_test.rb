# frozen_string_literal: true

require "minitest/autorun"
require_relative "pr_merge_ledger_test_helpers"

# rubocop:disable Metrics/ClassLength
class PrMergeLedgerClosingKeywordListBlocksTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

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

  def test_empty_ordered_list_non_one_marker_before_blank_keeps_root_indented_closeout
    output, status = run_fixture(fixture_with_body("This remains prose\n2.\n\n    Fixes #4410\n"))

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

  def test_empty_list_marker_crlf_indented_code_continuation_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("-\r\n      Fixes #4410\r\n"))

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

  def test_nested_blockquoted_list_marker_tab_aligned_prose_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("> > - \tFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_blockquoted_nested_list_marker_tab_aligned_prose_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("> - - \tFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_blockquoted_nested_list_marker_tab_indented_code_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("> - -   \tFixes #4410\n"))

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

  def test_same_line_nested_list_paragraph_continuation_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("- - evidence\n      Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_same_line_nested_list_html_block_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- - <div>\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
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
end
# rubocop:enable Metrics/ClassLength
