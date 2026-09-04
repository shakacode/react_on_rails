#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for fetch-pr-review-data.
# Run with: ruby .agents/skills/address-review/bin/fetch-pr-review-data-test.rb

require "minitest/autorun"
require "open3"

SCRIPT = File.expand_path("fetch-pr-review-data", __dir__)
load SCRIPT

class FetchPrReviewDataTest < Minitest::Test
  ISSUE_RAW = <<~JSON
    [[
      {"id":1,"node_id":"IC_1","body":"first","user":{"login":"alice"},"created_at":"2026-01-01T00:00:00Z"},
      {"id":2,"node_id":"IC_2","body":"<!-- address-review-summary -->\\nold","user":{"login":"bot"},"created_at":"2026-01-02T00:00:00Z"}
    ],[
      {"id":3,"node_id":"IC_3","body":"<!-- address-review-summary -->\\nnew \\ud83c\\udf89","user":{"login":"bot"},"created_at":"2026-01-03T00:00:00Z"},
      {"id":4,"node_id":"IC_4","body":"<!-- address-review-status -->\\nnot a cutoff","user":{"login":"bot"},"created_at":"2026-01-04T00:00:00Z"}
    ]]
  JSON

  REVIEWS_RAW = <<~JSON
    [[
      {"id":10,"body":"fix the nil guard","state":"COMMENTED","user":{"login":"alice"},"submitted_at":"2026-01-04T00:00:00Z"},
      {"id":11,"body":"","state":"APPROVED","user":{"login":"bob"}}
    ]]
  JSON

  INLINE_RAW = <<~JSON
    [[
      {"id":20,"node_id":"RC_20","path":"a.rb","user":{"login":"alice"}},
      {"id":21,"node_id":"RC_21","path":"b.rb","user":{"login":"alice"}},
      {"id":22,"node_id":"RC_22","path":"c.rb","user":{"login":"alice"}}
    ]]
  JSON

  THREADS_RAW = <<~JSON
    [{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[
      {"id":"T_A","isResolved":true,"comments":{"nodes":[{"id":"RC_20","databaseId":20}]}},
      {"id":"T_B","isResolved":false,"comments":{"nodes":[{"id":"RC_21","databaseId":21}]}}
    ]}}}}}]
  JSON

  def assembled
    FetchPrReviewData.assemble(
      repo: "owner/repo", pr_number: 1234,
      issue_raw: ISSUE_RAW, reviews_raw: REVIEWS_RAW, inline_raw: INLINE_RAW, threads_raw: THREADS_RAW
    )
  end

  def test_cutoff_is_latest_summary_marker_and_ignores_newer_status
    assert_equal "2026-01-03T00:00:00Z", assembled["review_cutoff_at"]
  end

  def test_drops_empty_review_summaries
    assert_equal([10], assembled["review_summaries"].map { |r| r["id"] })
  end

  def test_joins_thread_metadata_by_node_id
    by_id = assembled["inline_comments"].to_h { |c| [c["id"], c] }
    assert_equal "T_A", by_id[20]["thread_id"]
    assert_equal true, by_id[20]["is_resolved"]
    assert_equal "T_B", by_id[21]["thread_id"]
    assert_equal false, by_id[21]["is_resolved"]
    # Orphan comment with no matching thread.
    assert_nil by_id[22]["thread_id"]
    assert_equal false, by_id[22]["is_resolved"]
  end

  def test_issue_comments_include_markers
    assert_equal 4, assembled["issue_comments"].length
  end

  def test_handles_empty_and_blank_inputs
    out = FetchPrReviewData.assemble(
      repo: "o/r", pr_number: 7, issue_raw: "", reviews_raw: "[]", inline_raw: "[[]]", threads_raw: nil
    )
    assert_equal "", out["review_cutoff_at"]
    assert_equal 0, out["inline_comments"].length
    assert_equal 0, out["review_threads"].length
  end

  def test_text_summary_counts
    text = FetchPrReviewData.text_summary(assembled)
    assert_includes text, "inline_comments: 3 (1 in resolved threads)"
    assert_includes text, "review_threads: 2 (1 resolved)"
  end

  def test_self_check_passes
    out, status = Open3.capture2("ruby", SCRIPT, "--self-check")
    assert status.success?, out
    assert_includes out, "self-check passed"
  end

  def test_help_exits_zero
    out, status = Open3.capture2e("ruby", SCRIPT, "--help")
    assert status.success?, out
    assert_includes out, "Usage: fetch-pr-review-data"
  end

  def test_rejects_non_integer_pr
    out, status = Open3.capture2e("ruby", SCRIPT, "not-a-number", "--repo", "owner/repo")
    refute status.success?
    assert_includes out, "positive integer PR number is required"
  end

  def test_rejects_zero_pr
    out, status = Open3.capture2e("ruby", SCRIPT, "0", "--repo", "owner/repo")
    refute status.success?
    assert_includes out, "positive integer PR number is required"
  end

  def test_rejects_bad_repo_form
    # gh is not reached for a malformed --repo, so this passes without network.
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "owneronly")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  def test_rejects_repo_with_extra_path_segment
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "a/b/c")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  def test_rejects_repo_with_empty_owner
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "/repo")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end
end
