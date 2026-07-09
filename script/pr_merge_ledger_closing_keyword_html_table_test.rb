# frozen_string_literal: true

require "minitest/autorun"
require_relative "pr_merge_ledger_test_helpers"

# rubocop:disable Metrics/ClassLength
class PrMergeLedgerClosingKeywordHtmlTableTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

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

  def test_multiline_html_comment_far_split_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<!--\nFixes\n#{' ' * 600}\n#4410\n-->\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_multiline_html_comment_max_line_split_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<!--\nFixes\n#{' ' * 99_999}\n#4410\n-->\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_adjacent_multiline_html_comments_each_report_split_closing_keyword
    output, status = run_fixture(fixture_with_body("<!--\nFixes\n#4410\n-->\n<!--\nResolves\n#4411\n-->\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal %w[code_formatted_closing_keyword code_formatted_closing_keyword], violation_codes(data)
    violations = ledger(data).fetch("violations")
    assert_equal([3, 7], violations.map { |violation| violation.fetch("line") })
    assert_match(/Fixes\s+#4410/, violations[0].fetch("message"))
    assert_match(/Resolves\s+#4411/, violations[1].fetch("message"))
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

  def test_source_html_block_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<source\nFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_textarea_html_block_continues_until_blank_line_after_closing_tag
    output, status = run_fixture(fixture_with_body("<textarea>\n</textarea>\nFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_textarea_html_block_blank_line_before_closeout_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("<textarea>\n\nFixes #4410\n</textarea>\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_non_gfm_type_6_tags_do_not_interrupt_paragraph_before_plain_closeout
    %w[search textarea].each do |tag_name|
      output, status = run_fixture(fixture_with_body("Intro\n<#{tag_name}>\nFixes #4410\n"))

      assert status.success?, output
      data = JSON.parse(output)
      assert data.fetch("complete_allowed")
      assert_empty violation_codes(data)
    end
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

  def test_self_closing_type_7_html_block_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("<ins />\nFixes #4410\n"))

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

  def test_malformed_type_7_html_attribute_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("<ins =>\nFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_malformed_type_7_html_attribute_name_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("<a h*#ref=\"hi\">\nFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_type_7_html_block_does_not_interrupt_paragraph_before_plain_closeout
    output, status = run_fixture(fixture_with_body("See details below.\n<br>\nFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_type_7_html_block_does_not_interrupt_list_paragraph_before_plain_closeout
    output, status = run_fixture(fixture_with_body("- Intro\n  <ins>\n      Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_child_list_item_type_7_html_after_parent_paragraph_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- Intro\n  - <ins>\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_closing_type_6_html_tag_interrupts_paragraph_before_closeout
    output, status = run_fixture(fixture_with_body("Intro\n</div>\nFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_malformed_type_7_closing_tag_with_attributes_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("</ins class=x>\nFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_type_7_html_closing_tag_allows_space_before_angle
    output, status = run_fixture(fixture_with_body("</ins >\nFixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_type_7_html_open_tag_without_closing_angle_does_not_backtrack
    output, status = run_fixture(fixture_with_body("<a#{' x' * 20_000}\nFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
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
end
# rubocop:enable Metrics/ClassLength
