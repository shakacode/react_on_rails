#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for pr-security-preflight.
# Run with: ruby .agents/skills/pr-batch/bin/pr-security-preflight-test.rb

require "fileutils"
require "minitest/autorun"
require "open3"
require "shellwords"
require "tmpdir"

SCRIPT = File.expand_path("pr-security-preflight", __dir__)

class PrSecurityPreflightTest < Minitest::Test
  def test_warning_terms_in_trusted_issue_text_do_not_block
    with_fake_gh("warning-issue") do |env, trust_config_path, _log_path|
      out, status = run_script(env, "--repo", "owner/repo", "--trust-config", trust_config_path, "123")

      assert status.success?, out
      assert_includes out, "SECURITY_PREFLIGHT_OK"
      assert_includes out, "Suspicious text warnings:"
      assert_includes out, "issue body by justin808"
      refute_includes out, "SECURITY_PREFLIGHT_BLOCKED"
    end
  end

  def test_warning_terms_in_added_pr_diff_lines_block_and_fetch_diff_once
    with_fake_gh("warning-diff") do |env, trust_config_path, log_path|
      out, status = run_script(env, "--repo", "owner/repo", "--trust-config", trust_config_path, "123")

      refute status.success?, out
      assert_equal 2, status.exitstatus
      assert_includes out, "SECURITY_PREFLIGHT_BLOCKED"
      assert_includes out, "- #123: suspicious text"
      assert_includes out, ".github/workflows/test.yml:diff line"
      assert_includes out, "Suspicious text warnings: none"
      assert_equal 1, full_diff_call_count(log_path)
    end
  end

  def test_participant_findings_header_includes_hidden_participants
    with_fake_gh("untrusted-participant") do |env, trust_config_path, _log_path|
      out, status = run_script(env, "--repo", "owner/repo", "--trust-config", trust_config_path, "123")

      refute status.success?, out
      assert_equal 2, status.exitstatus
      assert_includes out, "Untrusted or hidden participant findings:"
      assert_includes out, "unknown-user"
    end
  end

  private

  def run_script(env, *)
    Open3.capture2e(env, "ruby", SCRIPT, *)
  end

  def with_fake_gh(mode)
    Dir.mktmpdir("pr-security-preflight-test") do |dir|
      log_path = File.join(dir, "gh.log")
      trust_config_path = File.join(dir, "trusted-github-actors.yml")
      gh_path = File.join(dir, "gh")

      File.write(trust_config_path, <<~YAML)
        trusted_users:
          - justin808
        trusted_bots: []
        trusted_teams: []
      YAML
      File.write(gh_path, fake_gh_script(log_path))
      FileUtils.chmod(0o755, gh_path)

      env = {
        "PATH" => "#{dir}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH')}",
        "PREFLIGHT_TEST_MODE" => mode
      }
      yield env, trust_config_path, log_path
    end
  end

  def full_diff_call_count(log_path)
    File.readlines(log_path).count do |line|
      line.include?("pr diff 123 --repo owner/repo") && !line.include?("--name-only")
    end
  end

  def fake_gh_script(log_path)
    <<~SH
      #!/usr/bin/env bash
      set -e
      printf '%s\\n' "$*" >> #{Shellwords.shellescape(log_path)}

      mode="${PREFLIGHT_TEST_MODE}"

      if [ "$1" = "api" ] && [ "$2" = "repos/owner/repo/issues/123" ]; then
        if [ "$mode" = "warning-diff" ]; then
          cat <<'JSON'
      {"number":123,"title":"Test PR","html_url":"https://github.com/owner/repo/pull/123","body":"","user":{"login":"justin808"},"pull_request":{}}
      JSON
        else
          cat <<'JSON'
      {"number":123,"title":"Test issue","html_url":"https://github.com/owner/repo/issues/123","body":"Document GITHUB_TOKEN use.","user":{"login":"justin808"}}
      JSON
        fi
        exit 0
      fi

      if [ "$1" = "api" ] && [ "$2" = "graphql" ]; then
        if [ "$mode" = "warning-diff" ]; then
          cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":123,"title":"Test PR","url":"https://github.com/owner/repo/pull/123","headRefOid":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","author":{"login":"justin808"},"participants":{"totalCount":1,"pageInfo":{"hasNextPage":false},"nodes":[{"login":"justin808","url":"https://github.com/justin808","__typename":"User"}]},"timelineItems":{"totalCount":1,"pageInfo":{"hasNextPage":false},"nodes":[{"__typename":"PullRequestCommit","commit":{"authors":{"nodes":[{"user":{"login":"justin808"}}]}}}]}}}}}
      JSON
        elif [ "$mode" = "untrusted-participant" ]; then
          cat <<'JSON'
      {"data":{"repository":{"issue":{"number":123,"title":"Test issue","url":"https://github.com/owner/repo/issues/123","author":{"login":"justin808"},"participants":{"totalCount":2,"pageInfo":{"hasNextPage":false},"nodes":[{"login":"justin808","url":"https://github.com/justin808","__typename":"User"},{"login":"unknown-user","url":"https://github.com/unknown-user","__typename":"User"}]},"timelineItems":{"totalCount":0,"pageInfo":{"hasNextPage":false},"nodes":[]}}}}}
      JSON
        else
          cat <<'JSON'
      {"data":{"repository":{"issue":{"number":123,"title":"Test issue","url":"https://github.com/owner/repo/issues/123","author":{"login":"justin808"},"participants":{"totalCount":1,"pageInfo":{"hasNextPage":false},"nodes":[{"login":"justin808","url":"https://github.com/justin808","__typename":"User"}]},"timelineItems":{"totalCount":0,"pageInfo":{"hasNextPage":false},"nodes":[]}}}}}
      JSON
        fi
        exit 0
      fi

      if [ "$1" = "api" ] && [ "$2" = "repos/owner/repo/issues/123/comments?per_page=100" ]; then
        printf '[[]]'
        exit 0
      fi

      if [ "$1" = "api" ] && [ "$2" = "repos/owner/repo/pulls/123/comments?per_page=100" ]; then
        printf '[[]]'
        exit 0
      fi

      if [ "$1" = "api" ] && [ "$2" = "repos/owner/repo/pulls/123/reviews?per_page=100" ]; then
        printf '[[]]'
        exit 0
      fi

      if [ "$1" = "api" ] && [ "$2" = "repos/owner/repo/collaborators/unknown-user/permission" ]; then
        printf '{"permission":"none"}'
        exit 0
      fi

      if [ "$1" = "pr" ] && [ "$2" = "diff" ]; then
        for arg in "$@"; do
          if [ "$arg" = "--name-only" ]; then
            printf '.github/workflows/test.yml\\n'
            exit 0
          fi
        done
        cat <<'DIFF'
      diff --git a/.github/workflows/test.yml b/.github/workflows/test.yml
      index 0000000..1111111 100644
      --- a/.github/workflows/test.yml
      +++ b/.github/workflows/test.yml
      +echo "$GITHUB_TOKEN"
      DIFF
        exit 0
      fi

      printf 'unexpected gh call: %s\\n' "$*" >&2
      exit 1
    SH
  end
end
