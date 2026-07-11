# frozen_string_literal: true

require "minitest/autorun"
require_relative "pr_merge_ledger_test_helpers"

# rubocop:disable Metrics/ClassLength
class PrMergeLedgerClosingKeywordLinkReferenceTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

  def test_link_reference_definition_same_line_title_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_definition_angle_destination_title_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: <my url> \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_definition_escaped_angle_destination_title_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: <my \\<url> \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_definition_escaped_closing_angle_destination_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: <my\\>url> \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_list_item_link_reference_definition_same_line_title_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- [foo]: /url \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_nested_list_item_link_reference_definition_same_line_title_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- - [foo]: /url \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_child_list_item_link_reference_definition_after_parent_paragraph_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- Intro\n  - [foo]: /url \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_malformed_link_reference_definition_with_extra_title_text_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url \"title\" ok Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_malformed_angle_link_reference_without_closing_angle_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[foo]: <url \"Fixes #4410\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_malformed_angle_link_reference_with_unescaped_angle_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[foo]: <my <url> \"Fixes #4410\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_malformed_raw_link_reference_with_unbalanced_parenthesis_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url( \"Fixes #4410\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_whitespace_only_link_reference_label_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[   ]: /url \"Fixes #4410\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_whitespace_only_link_reference_label_only_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[   ]:\n/url \"Fixes #4410\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_overlong_link_reference_label_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[#{'a' * 1000}]: /url \"Fixes #4410\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_backslash_heavy_raw_link_reference_destination_blocks_without_backtracking
    backslash_destination = "\\" * 20_000
    output, status = run_fixture(fixture_with_body("[foo]: #{backslash_destination} \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_multiline_title_blank_line_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url '\n\nFixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_link_reference_multiline_title_blank_after_closeout_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url '\nFixes #4410\n\n'\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_link_reference_multiline_title_new_list_item_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url \"\n- Fixes #4410\n\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_link_reference_multiline_title_list_boundary_clears_title_state
    output, status = run_fixture(fixture_with_body("[foo]: /url \"\n- item\nFixes #4410\n\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_list_item_link_reference_multiline_title_new_item_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("- [foo]: /url \"\n- Fixes #4410\n\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_blockquoted_link_reference_multiline_title_blank_after_closeout_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("> [foo]: /url \"\n> Fixes #4410\n>\n> \"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_blockquoted_list_link_reference_multiline_title_blank_after_closeout_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("> - [foo]: /url \"\n>   Fixes #4410\n>\n>   \"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_multiline_link_reference_title_lookahead_cache_reuses_closing_line
    require_relative "pr_merge_ledger/closing_keyword_scanner"
    probe = Class.new { include PrMergeLedger::ClosingKeywordScanner }.new
    body_lines = ["[foo]: /url \"\n", *(["plain prose\n"] * 998), "\"\n"]
    markdown_state = {
      "body_lines" => body_lines,
      "line_index" => 0,
      "opening_fence" => nil,
      "current_blockquote_depth" => 0,
      "blockquote_depth" => 0,
      "list_content_indent" => nil,
      "html_block" => nil,
      "paragraph_continuation_active" => false,
      "list_paragraph_continuation_active" => false,
      "setext_heading_candidate_active" => false,
      "gfm_table_header_candidate_active" => false,
      "gfm_table_header_candidate_cell_count" => nil,
      "gfm_table_block_active" => false,
      "link_reference_destination_allowed" => false,
      "link_reference_title_allowed" => false,
      "link_reference_title_delimiter" => "\"",
      "link_reference_title_lookahead" => nil
    }

    assert probe.send(:active_link_reference_title_closes_later?, "\"", markdown_state)
    markdown_state["line_index"] = 500

    assert probe.send(:active_link_reference_title_closes_later?, "\"", markdown_state)
    cache = markdown_state.fetch("link_reference_title_lookahead")
    assert_equal 999, cache.fetch(:through_line_index)
    assert cache.fetch(:closes_later)
  end

  def test_link_reference_multiline_title_type_7_html_line_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url \"\nFixes #4410\n<ins>\n\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_multiline_title_fence_after_closeout_allows_visible_closeout
    output, status = run_fixture(
      fixture_with_body("[foo]: /url \"\nFixes #4410\n```\n\"\n```\n")
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_link_reference_multiline_title_fence_boundary_clears_title_state
    output, status = run_fixture(
      fixture_with_body("[foo]: /url \"\n```\ncode\n```\nFixes #4410\n\"\n")
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_link_reference_multiline_title_table_after_closeout_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url \"\nFixes #4410\n| a | b |\n| - | - |\n\"\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_link_reference_multiline_title_table_boundary_clears_title_state
    output, status = run_fixture(
      fixture_with_body("[foo]: /url \"\n| a | b |\n| - | - |\n# Heading\nFixes #4410\n\"\n")
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_link_reference_definition_escaped_title_delimiter_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url \"foo \\\" Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_definition_split_destination_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]:\n/url \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_nested_list_link_reference_definition_split_destination_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("- - [foo]:\n    /url \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_definition_label_only_crlf_split_destination_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]:\r\n/url \"Fixes #4410\"\r\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_definition_split_title_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url\n  \"Fixes #4410\"\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_definition_multiline_title_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url '\nFixes #4410\n'\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 2, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_link_reference_definition_multiline_title_split_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url '\nFixes\n#4410\n'\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_link_reference_multiline_title_invalid_closer_allows_visible_closeout
    output, status = run_fixture(fixture_with_body("[foo]: /url '\ntitle' Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_adjacent_link_reference_multiline_titles_each_report_split_closing_keyword
    output, status = run_fixture(
      fixture_with_body("[foo]: /url '\nFixes\n#4410\n'\n\n[bar]: /url '\nResolves\n#4411\n'\n")
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal %w[code_formatted_closing_keyword code_formatted_closing_keyword], violation_codes(data)
    violations = ledger(data).fetch("violations")
    assert_equal([3, 8], violations.map { |violation| violation.fetch("line") })
    assert_match(/Fixes\s+#4410/, violations[0].fetch("message"))
    assert_match(/Resolves\s+#4411/, violations[1].fetch("message"))
  end

  def test_link_reference_definition_does_not_interrupt_paragraph_before_indented_closeout
    output, status = run_fixture(fixture_with_body("Intro\n[foo]: /url\n    Fixes #4410\n"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end
end
# rubocop:enable Metrics/ClassLength
