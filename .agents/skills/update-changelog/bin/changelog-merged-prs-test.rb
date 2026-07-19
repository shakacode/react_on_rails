#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for changelog-merged-prs.
# Run with: ruby .agents/skills/update-changelog/bin/changelog-merged-prs-test.rb

require "minitest/autorun"
require "open3"
require "fileutils"
require "tmpdir"

SCRIPT = File.expand_path("changelog-merged-prs", __dir__)
load SCRIPT

# First-parent history mixing a squash-merge subject, a merge-commit subject, a
# bare commit (no PR number, resolved via the API), and a direct version bump.
RANGE_SUBJECTS = [
  "Add RSC manifest verification (#3595)",
  "Merge pull request #3596 from shakacode/feature",
  "Refactor render path with emoji 🎉",
  "Bump version to 17.0.0"
].freeze

# Fake gh stub. Maps the bare commit's sha (%<bare_sha>s) to merged PR 3597 on
# base main, returns [] for every other commit, and answers repo-view queries.
FAKE_GH = <<~BASH
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "${1:-}" = "repo" ] && [ "${2:-}" = "view" ]; then
    for arg in "$@"; do
      case "$arg" in
        *defaultBranchRef*) echo "main"; exit 0 ;;
        *nameWithOwner*)    echo "shakacode/react_on_rails"; exit 0 ;;
      esac
    done
    echo "main"; exit 0
  fi
  if [ "${1:-}" = "api" ]; then
    for arg in "$@"; do
      case "$arg" in
        */commits/%<bare_sha>s/pulls)
          printf '[{"number":3597,"title":"Resolved via commit API","merged_at":"2026-01-01T00:00:00Z","base":{"ref":"main"}}]'
          exit 0 ;;
        */commits/*/pulls) printf '[]'; exit 0 ;;
      esac
    done
  fi
  echo "unexpected gh invocation: $*" >&2
  exit 1
BASH

class ChangelogMergedPrsTest < Minitest::Test
  # Inline PR-number extraction: squash suffix wins over the merge-commit form,
  # the merge-commit form matches, bare commits and nil return nil (the API
  # resolves them in the full pipeline).
  def test_inline_pr_number_extraction
    assert_equal "3595", ChangelogMergedPrs.inline_pr_number("Add RSC manifest verification (#3595)")
    assert_equal "3596", ChangelogMergedPrs.inline_pr_number("Merge pull request #3596 from shakacode/feature")
    assert_equal "3595", ChangelogMergedPrs.inline_pr_number("Merge pull request #10 from x (#3595)")
    assert_nil ChangelogMergedPrs.inline_pr_number("Refactor render path with emoji 🎉")
    assert_nil ChangelogMergedPrs.inline_pr_number(nil)
  end

  # commit-to-PR API parsing: only merged PRs on the default branch survive.
  def test_commit_pulls_filters_unmerged_and_other_base
    raw = <<~JSON
      [
        {"number":3597,"title":"Resolved via commit API","merged_at":"2026-01-01T00:00:00Z","base":{"ref":"main"}},
        {"number":1,"title":"open PR","merged_at":null,"base":{"ref":"main"}},
        {"number":2,"title":"other base","merged_at":"2026-01-02T00:00:00Z","base":{"ref":"release"}}
      ]
    JSON
    pulls = ChangelogMergedPrs.commit_pulls(raw, "main")
    assert_equal [{ "pr" => "3597", "title" => "Resolved via commit API" }], pulls
  end

  def test_commit_pulls_handles_blank_and_empty
    assert_empty ChangelogMergedPrs.commit_pulls("", "main")
    assert_empty ChangelogMergedPrs.commit_pulls(nil, "main")
    assert_empty ChangelogMergedPrs.commit_pulls("[]", "main")
  end

  # Dedup: PR rows collapse on number (first sighting kept); UNKNOWN rows key on
  # PR+sha so distinct unmapped commits all survive.
  def test_dedups_repeated_pr_numbers_keeps_distinct_unknown
    rows = [
      { "pr" => "3595", "sha" => "sha-a", "subject" => "Add feature (#3595)" },
      { "pr" => "3595", "sha" => "sha-b", "subject" => "Add feature (#3595)" },
      { "pr" => "UNKNOWN", "sha" => "sha-c", "subject" => "bump one" },
      { "pr" => "UNKNOWN", "sha" => "sha-d", "subject" => "bump two" }
    ]
    assert_equal(%w[sha-a sha-c sha-d], ChangelogMergedPrs.dedup_rows(rows).map { |row| row["sha"] })
  end

  # JSON render: PR numbers become integers, UNKNOWN stays a string, emoji survive.
  def test_json_render_coerces_pr_and_preserves_emoji
    rows = [
      { "pr" => "4040", "sha" => "abc123", "subject" => "Fix sweep 🎉 (#4040)" },
      { "pr" => "UNKNOWN", "sha" => "def456", "subject" => "Bump version" }
    ]
    json = ChangelogMergedPrs.to_json_rows(rows)
    assert_equal 4040, json[0]["pr"]
    assert_equal "Fix sweep 🎉 (#4040)", json[0]["subject"]
    assert_equal "UNKNOWN", json[1]["pr"]
  end

  def test_text_render_emits_tsv
    rows = [{ "pr" => "3595", "sha" => "abc123", "subject" => "Add RSC manifest verification (#3595)" }]
    assert_equal ["3595\tabc123\tAdd RSC manifest verification (#3595)"], ChangelogMergedPrs.text_lines(rows)
  end

  # End-to-end against a throwaway git repo + fake gh on PATH, mirroring the
  # bash test: squash suffix, merge-commit, commit-API fallback, UNKNOWN bump.
  def test_end_to_end_with_api_fallback_and_unknown
    with_fixture do |repo, bin_dir|
      json = run_script_json(repo, bin_dir)
      by_pr = json.to_h { |row| [row["pr"], row] }
      unknown = json.find { |row| row["pr"] == "UNKNOWN" }

      assert_equal([3595, 3596, 3597, "UNKNOWN"], json.map { |row| row["pr"] })
      assert_equal "Add RSC manifest verification (#3595)", by_pr[3595]["subject"]
      assert_equal "Merge pull request #3596 from shakacode/feature", by_pr[3596]["subject"]
      assert_equal "Resolved via commit API", by_pr[3597]["subject"]
      assert_equal "Bump version to 17.0.0", unknown["subject"]
      assert_equal 40, unknown["sha"].length
    end
  end

  def test_text_mode_first_line_is_squash_pr_tsv
    with_fixture do |repo, bin_dir|
      out = run_script(repo, bin_dir, "base..target", "--repo", "shakacode/react_on_rails", "--text")
      fields = out.lines.first.chomp.split("\t")

      assert_equal "3595", fields[0]
      assert_equal "Add RSC manifest verification (#3595)", fields[2]
    end
  end

  def test_self_check_passes
    out, status = Open3.capture2e("ruby", SCRIPT, "--self-check")
    assert status.success?, out
    assert_includes out, "self-check passed"
  end

  def test_help_exits_zero
    out, status = Open3.capture2e("ruby", SCRIPT, "--help")
    assert status.success?, out
    assert_includes out, "Usage: changelog-merged-prs"
  end

  def test_rejects_missing_range
    out, status = Open3.capture2e("ruby", SCRIPT)
    refute status.success?
    assert_includes out, "BASE..TARGET git range is required"
  end

  def test_rejects_bad_range_form
    out, status = Open3.capture2e("ruby", SCRIPT, "justonref")
    refute status.success?
    assert_includes out, "range must be in BASE..TARGET form"
  end

  def test_rejects_repo_with_extra_path_segment
    out, status = Open3.capture2e("ruby", SCRIPT, "a..b", "--repo", "a/b/c")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  def test_rejects_repo_with_empty_owner
    out, status = Open3.capture2e("ruby", SCRIPT, "a..b", "--repo", "/repo")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  private

  # Build a throwaway repo + fake gh on PATH, then yield (repo, bin_dir).
  def with_fixture
    Dir.mktmpdir("changelog-merged-prs-repo") do |repo|
      build_fixture_repo(repo)
      bin_dir = File.join(repo, "bin")
      FileUtils.mkdir_p(bin_dir)
      write_fake_gh(bin_dir, sha_for(repo, "Refactor render path"))
      yield repo, bin_dir
    end
  end

  def git(repo, *args)
    out, status = Open3.capture2e("git", "-C", repo, *args)
    raise "git #{args.join(' ')} failed: #{out}" unless status.success?

    out
  end

  def build_fixture_repo(repo)
    git(repo, "init", "-q")
    git(repo, "config", "user.email", "test@example.test")
    git(repo, "config", "user.name", "Test User")
    git(repo, "config", "commit.gpgsign", "false")
    git(repo, "commit", "-q", "--allow-empty", "-m", "Base commit")
    git(repo, "tag", "base")
    RANGE_SUBJECTS.each { |subject| git(repo, "commit", "-q", "--allow-empty", "-m", subject) }
    git(repo, "tag", "target")
  end

  def sha_for(repo, subject_fragment)
    line = git(repo, "log", "--first-parent", "--reverse", "--format=%H %s", "base..target")
           .lines.find { |row| row.include?(subject_fragment) }
    line.split(" ", 2).first
  end

  def write_fake_gh(bin_dir, bare_sha)
    path = File.join(bin_dir, "gh")
    File.write(path, format(FAKE_GH, bare_sha:))
    FileUtils.chmod(0o755, path)
  end

  def run_script(repo, bin_dir, *)
    env = { "PATH" => "#{bin_dir}:#{ENV.fetch('PATH')}" }
    out, status = Open3.capture2e(env, "ruby", SCRIPT, *, chdir: repo)
    raise "script failed: #{out}" unless status.success?

    out
  end

  def run_script_json(repo, bin_dir)
    JSON.parse(run_script(repo, bin_dir, "base..target", "--repo", "shakacode/react_on_rails"))
  end
end
