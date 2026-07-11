# frozen_string_literal: true

require "minitest/autorun"
require_relative "pr_merge_ledger_test_helpers"

# rubocop:disable Metrics/ClassLength
class PrMergeLedgerClosingKeywordCodeBlocksTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

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

  def test_split_fenced_code_closing_keyword_across_large_whitespace_gap_blocks_strict_closeout
    whitespace_line = "#{' ' * 99_000}\n"
    output, status = run_fixture(
      fixture_with_body("```text\nFixes\n#{whitespace_line}#{whitespace_line}#4410\n```\n")
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 5, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_visible_keyword_followed_by_hidden_fenced_issue_reference_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("Fixes\n```text\n#4410\n```\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes\s+#4410/, violation.fetch("message"))
  end

  def test_adjacent_split_fenced_code_blocks_each_report_closing_keyword
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ```text
          Fixes
          #4410
          ```
          ```text
          Resolves
          #4411
          ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal %w[code_formatted_closing_keyword code_formatted_closing_keyword], violation_codes(data)
    violations = ledger(data).fetch("violations")
    assert_equal([3, 7], violations.map { |violation| violation.fetch("line") })
    assert_match(/Fixes\s+#4410/, violations[0].fetch("message"))
    assert_match(/Resolves\s+#4411/, violations[1].fetch("message"))
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
end
# rubocop:enable Metrics/ClassLength
