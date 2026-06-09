# frozen_string_literal: true

require "time"

require_relative "github"
require_relative "github_cli"

# Posts the per-suite Bencher Markdown report to a pull request and cleans up
# older comments with the same marker.
class PrReportPoster
  def initialize(repository:, pr_number:, suite_name:, marker:)
    @repository = repository
    @pr_number = pr_number
    @suite_name = suite_name
    @marker = marker
  end

  # Requires GITHUB_REPOSITORY and PR_NUMBER in ENV. GitHub Actions sets both
  # during pull_request events; ENV.fetch raises KeyError if either is absent.
  def self.from_env(suite_name:, marker:)
    new(
      repository: ENV.fetch("GITHUB_REPOSITORY"),
      pr_number: ENV.fetch("PR_NUMBER"),
      suite_name:,
      marker:
    )
  end

  def replace(markdown)
    return if markdown.empty?

    cutoff_ts = Time.now.utc.iso8601
    if post_comment(markdown)
      delete_stale_comments(before: cutoff_ts)
    else
      Github.warning("Failed to post #{suite_name} benchmark report comment; keeping prior comments in place.")
    end
  end

  private

  attr_reader :repository, :pr_number, :suite_name, :marker

  def delete_stale_comments(before:)
    failed = 0
    stale_comment_ids(before:).each do |comment_id|
      puts "Deleting stale #{suite_name} Bencher report comment #{comment_id}"
      next if GithubCli.run(
        "gh", "api", "-X", "DELETE", "repos/#{repository}/issues/comments/#{comment_id}",
        error_message: "Failed to delete stale #{suite_name} Bencher report comment #{comment_id}"
      )

      failed += 1
    end
    return if failed.zero?

    Github.warning(
      "Failed to delete #{failed} stale #{suite_name} Bencher report comment(s); " \
      "they may remain visible."
    )
  end

  def stale_comment_ids(before:)
    # Marker + cutoff are passed via env so the jq filter reads them through `env.X`,
    # avoiding Ruby/JQ escaping mismatches from interpolated strings.
    stdout, status = GithubCli.capture(
      "gh", "api", "repos/#{repository}/issues/#{pr_number}/comments",
      "--paginate",
      "--jq", ".[] | select(.body | startswith(env.MARKER)) | select(.created_at < env.CUTOFF_TS) | .id",
      env: { "MARKER" => marker, "CUTOFF_TS" => before },
      error_message: "Failed to list stale #{suite_name} Bencher report comments"
    )
    return [] unless status.success?

    stdout.lines.map(&:strip).reject(&:empty?).grep(/\A\d+\z/)
  end

  def post_comment(markdown)
    # Send the body over stdin (--body-file -) rather than as a CLI argument so a
    # large report can't hit the OS argument-length limit.
    GithubCli.run(
      "gh", "pr", "comment", pr_number, "--body-file", "-",
      error_message: "Failed to post #{suite_name} benchmark report comment",
      stdin_data: "#{marker}\n#{markdown}"
    )
  end
end
