#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for pr-file-touch-map.
# Run with: ruby .agents/skills/plan-pr-batch/bin/pr-file-touch-map-test.rb

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"
require "shellwords"

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

  # An invalid head branch (rejected before any git call) must NOT gate the
  # reachable-SHA fetch of headRefOid: the OID fetch is independent of branch
  # validity (per #4065 review). A fake `git` records its fetch args so we can
  # assert the OID refspec was attempted even though the branch was invalid.
  def test_head_oid_fetch_runs_even_when_branch_invalid
    oid = "a" * 40
    with_fake_git do |log_path, env|
      meta = { head_ref: "bad:ref", head_repo: "owner/repo", head_oid: oid }
      with_path(env) do
        PrFileTouchMap.fetch_head_from_repo(meta, "refs/tmp/head")
      end
      log = File.exist?(log_path) ? File.read(log_path) : ""
      assert_includes log, "#{oid}:refs/tmp/head", "OID fetch should run despite invalid branch"
      refute_includes log, "refs/heads/bad:ref", "invalid branch must not be fetched"
    end
  end

  # A fake `git` that succeeds for `check-ref-format` and records `fetch` args,
  # while failing the fetch (exit 1) so no network is touched.
  def with_fake_git
    Dir.mktmpdir do |dir|
      log_path = File.join(dir, "git.log")
      git = File.join(dir, "git")
      File.write(git, <<~SH)
        #!/usr/bin/env bash
        if [ "$1" = "check-ref-format" ]; then exit 0; fi
        if [ "$1" = "fetch" ]; then echo "$@" >> #{Shellwords.shellescape(log_path)}; exit 1; fi
        exit 0
      SH
      FileUtils.chmod(0o755, git)
      yield log_path, { "PATH" => "#{dir}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH')}" }
    end
  end

  def with_path(env)
    original = ENV.fetch("PATH")
    ENV["PATH"] = env.fetch("PATH")
    yield
  ensure
    ENV["PATH"] = original
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

  def test_files_api_copied_owns_both_paths
    out = PrFileTouchMap.parse_files_api(
      '[[{"filename":"lib/copy.rb","status":"copied","previous_filename":"lib/src.rb"}]]',
      repo: "owner/repo", pr_number: 7, changed_files: 1
    )
    assert_equal ["lib/copy.rb", "lib/src.rb"], out["paths"]
    assert_equal [{ "old" => "lib/src.rb", "new" => "lib/copy.rb" }], out["renames"]
  end

  def test_files_api_rejects_copied_without_previous
    assert_raises(PrFileTouchMap::Error) do
      PrFileTouchMap.parse_files_api(
        '[[{"filename":"lib/copy.rb","status":"copied"}]]',
        repo: "o/r", pr_number: 7, changed_files: 1
      )
    end
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

  def test_reconcile_agreeing_sources_are_verified
    local = PrFileTouchMap.parse_name_status("M\tlib/a.rb\nA\tlib/b.rb\n", repo: "o/r", pr_number: 7, changed_files: 2)
    api = PrFileTouchMap.parse_files_api(
      '[[{"filename":"lib/a.rb","status":"modified"},{"filename":"lib/b.rb","status":"added"}]]',
      repo: "o/r", pr_number: 7, changed_files: 2
    )
    out = PrFileTouchMap.reconcile(local, api, repo: "o/r", pr_number: 7, changed_files: 2)
    assert_equal "verified", out["source"]
    assert_equal ["lib/a.rb", "lib/b.rb"], out["paths"]
  end

  def test_reconcile_disagreement_is_unknown
    local = PrFileTouchMap.parse_name_status("M\tlib/a.rb\nA\tlib/b.rb\n", repo: "o/r", pr_number: 7, changed_files: 2)
    api = PrFileTouchMap.parse_files_api(
      '[[{"filename":"lib/a.rb","status":"modified"}]]', repo: "o/r", pr_number: 7, changed_files: 1
    )
    out = PrFileTouchMap.reconcile(local, api, repo: "o/r", pr_number: 7, changed_files: 2)
    assert_equal "UNKNOWN", out["source"]
    assert_empty out["paths"]
  end

  def test_reconcile_missing_source_is_unknown
    local = PrFileTouchMap.parse_name_status("M\tlib/a.rb\n", repo: "o/r", pr_number: 7, changed_files: 1)
    assert_equal "UNKNOWN", PrFileTouchMap.reconcile(local, nil, repo: "o/r", pr_number: 7, changed_files: 1)["source"]
    assert_equal "UNKNOWN", PrFileTouchMap.reconcile(nil, local, repo: "o/r", pr_number: 7, changed_files: 1)["source"]
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

  def test_rejects_zero_pr
    out, status = Open3.capture2e("ruby", SCRIPT, "0", "--repo", "owner/repo")
    refute status.success?
    assert_includes out, "positive integer PR number is required"
  end

  def test_rejects_bad_repo_form
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
