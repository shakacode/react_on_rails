#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for pr-file-touch-map.
# Run with: ruby .agents/skills/plan-pr-batch/bin/pr-file-touch-map-test.rb

require "minitest/autorun"
require "open3"

SCRIPT = File.expand_path("pr-file-touch-map", __dir__)
load SCRIPT

class PrFileTouchMapTest < Minitest::Test
  def test_name_status_rename_and_copy_own_both_paths
    out = PrFileTouchMap.parse_name_status(
      "M\tlib/a.rb\nA\tlib/b.rb\nD\tlib/c.rb\nR096\tlib/old.rb\tlib/new.rb\nC100\tsrc/orig.rb\tsrc/copy.rb\n",
      repo: "owner/repo", pr_number: 7, changed_files: 5
    )
    assert_equal ["lib/a.rb", "lib/b.rb", "lib/c.rb", "lib/new.rb", "lib/old.rb", "src/copy.rb", "src/orig.rb"],
                 out["paths"]
    assert_equal [{ "old" => "lib/old.rb", "new" => "lib/new.rb" }, { "old" => "src/orig.rb", "new" => "src/copy.rb" }],
                 out["renames"]
    assert_equal "local-diff", out["source"]
  end

  def test_name_status_empty
    out = PrFileTouchMap.parse_name_status("", repo: "o/r", pr_number: 7, changed_files: nil)
    assert_empty out["paths"]
    assert_nil out["changed_files"]
  end

  def test_files_api_valid_with_rename
    out = PrFileTouchMap.parse_files_api(
      '[[{"filename":"lib/a.rb","status":"modified"},' \
      '{"filename":"lib/new.rb","status":"renamed","previous_filename":"lib/old.rb"}]]',
      repo: "owner/repo", pr_number: 7, changed_files: 2
    )
    assert_equal ["lib/a.rb", "lib/new.rb", "lib/old.rb"], out["paths"]
    assert_equal "files-api", out["source"]
  end

  def test_files_api_rejects_renamed_without_previous
    assert_raises(PrFileTouchMap::Error) do
      PrFileTouchMap.parse_files_api(
        '[[{"filename":"lib/new.rb","status":"renamed"}]]',
        repo: "o/r", pr_number: 7, changed_files: 1
      )
    end
  end

  def test_files_api_rejects_count_mismatch
    assert_raises(PrFileTouchMap::Error) do
      PrFileTouchMap.parse_files_api(
        '[[{"filename":"lib/a.rb","status":"modified"}]]',
        repo: "o/r", pr_number: 7, changed_files: 5
      )
    end
  end

  def test_files_api_rejects_cap_error_object_and_empty
    assert_raises(PrFileTouchMap::Error) do
      PrFileTouchMap.parse_files_api(
        '[[{"filename":"lib/a.rb","status":"modified"}]]',
        repo: "o/r", pr_number: 7, changed_files: PrFileTouchMap::FILES_API_CAP
      )
    end
    assert_raises(PrFileTouchMap::Error) do
      PrFileTouchMap.parse_files_api('{"message":"Not Found"}', repo: "o/r", pr_number: 7, changed_files: 1)
    end
    assert_raises(PrFileTouchMap::Error) do
      PrFileTouchMap.parse_files_api("", repo: "o/r", pr_number: 7, changed_files: 1)
    end
  end

  def test_unknown_result_shape
    out = PrFileTouchMap.unknown_result(repo: "o/r", pr_number: 7, changed_files: nil)
    assert_equal "UNKNOWN", out["source"]
    assert_empty out["paths"]
    assert_nil out["changed_files"]
  end

  def test_text_summary_renders_paths_and_renames
    data = {
      "pr" => 7, "repo" => "o/r", "source" => "local-diff", "changed_files" => 2,
      "paths" => %w[a b], "renames" => [{ "old" => "x", "new" => "y" }]
    }
    text = PrFileTouchMap.text_summary(data)
    assert_includes text, "PR #7 (o/r)"
    assert_includes text, "x -> y"
  end

  def test_self_check_passes
    out, status = Open3.capture2e("ruby", SCRIPT, "--self-check")
    assert status.success?, out
    assert_includes out, "self-check passed"
  end

  def test_help_exits_zero
    out, status = Open3.capture2e("ruby", SCRIPT, "--help")
    assert status.success?, out
    assert_includes out, "Usage: pr-file-touch-map"
  end

  def test_rejects_non_integer_pr
    out, status = Open3.capture2e("ruby", SCRIPT, "not-a-pr", "--repo", "owner/repo")
    refute status.success?
    assert_includes out, "positive integer PR number is required"
  end

  def test_rejects_bad_repo_form
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "owneronly")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end
end
