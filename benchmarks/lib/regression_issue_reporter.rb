# frozen_string_literal: true

require_relative "github_cli"

# rubocop:disable Metrics/ClassLength
class RegressionIssueReporter
  LABEL = "performance-regression"

  def self.report(summary:, **attributes)
    new(**attributes).report(summary)
  end

  def initialize(suite_name:, github_run_url:, bencher_url:)
    @suite_name = suite_name
    @github_run_url = github_run_url
    @bencher_url = bencher_url
    @commit_short = ENV.fetch("GITHUB_SHA")[0, 7]
  end

  def report(summary)
    return "" unless ensure_regression_label

    issue_number = find_or_create_regression_issue
    return "" if issue_number.nil? || issue_number.empty?

    puts "Posting #{suite_name} regression report to ##{issue_number}"
    return "" unless create_or_update_regression_comment(issue_number, summary)

    issue_number
  end

  private

  attr_reader :suite_name, :github_run_url, :bencher_url, :commit_short

  def ensure_regression_label
    GithubCli.run(
      "gh", "label", "create", LABEL,
      "--description", "Automated: benchmark regression detected on main",
      "--color", "D93F0B",
      "--force",
      error_message: "Failed to create or update #{LABEL} label"
    )
  end

  def commit_url
    "#{ENV.fetch('GITHUB_SERVER_URL')}/#{ENV.fetch('GITHUB_REPOSITORY')}/commit/#{ENV.fetch('GITHUB_SHA')}"
  end

  def issue_title
    "Performance Regression Detected on main (#{commit_short})"
  end

  def existing_regression_issue
    stdout = GithubCli.capture_success(
      "gh", "issue", "list",
      "--label", LABEL,
      "--state", "open",
      "--limit", "100",
      "--json", "number,title",
      "--jq", ".[] | select(.title == env.TITLE) | .number",
      error_message: "Failed to list existing #{LABEL} issues",
      env: { "TITLE" => issue_title }
    )
    # nil signals a `gh` failure (must abort, not create a duplicate); "" means no
    # matching issue exists yet (caller should create one).
    return nil unless stdout

    stdout.lines.first.to_s.strip
  end

  def comment_marker
    "<!-- BENCHMARK_REGRESSION_REPORT #{ENV.fetch('GITHUB_SHA')} -->"
  end

  def section_start
    "<!-- BENCHMARK_REGRESSION_SECTION #{suite_name} -->"
  end

  def section_end
    "<!-- /BENCHMARK_REGRESSION_SECTION #{suite_name} -->"
  end

  def regression_comment_id(issue_number)
    stdout = GithubCli.capture_success(
      "gh", "api", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/#{issue_number}/comments",
      "--paginate",
      "--jq", ".[] | select(.body | startswith(env.MARKER)) | .id",
      error_message: "Failed to list comments for regression issue ##{issue_number}",
      env: { "MARKER" => comment_marker }
    )
    # nil signals a `gh` failure (must abort, not post a duplicate); "" means no
    # existing report comment yet (caller should create one).
    return nil unless stdout

    stdout.lines.first.to_s.strip
  end

  def regression_comment_body(comment_id)
    stdout = GithubCli.capture_success(
      "gh", "api", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/comments/#{comment_id}",
      "--jq", ".body",
      error_message: "Failed to fetch regression issue comment #{comment_id}"
    )
    # nil signals a `gh` failure; the caller must abort rather than rewrite the
    # comment from an empty body (which would drop the header and other suites).
    return nil unless stdout

    stdout
  end

  def comment_header
    <<~MARKDOWN
      #{comment_marker}
      ## Benchmark regression reports for #{commit_short}

      **Commit:** [`#{commit_short}`](#{commit_url})
      **Workflow run:** [Run ##{ENV.fetch('GITHUB_RUN_NUMBER')}](#{github_run_url})
      **Bencher dashboard:** [View history](#{bencher_url})

    MARKDOWN
  end

  def comment_section(summary)
    <<~MARKDOWN
      #{section_start}
      ### #{suite_name}
      #{summary}

      > View the full Bencher report in the workflow run summary or on the [Bencher dashboard](#{bencher_url}).
      #{section_end}
    MARKDOWN
  end

  def upsert_section(body, section)
    start_index = body.index(section_start)
    end_index = body.index(section_end)

    if start_index && end_index && end_index > start_index
      end_index += section_end.length
      return "#{body[0...start_index]}#{section}#{body[end_index..]}"
    end

    "#{body.rstrip}\n\n#{section}"
  end

  def create_or_update_regression_comment(issue_number, summary)
    comment_id = regression_comment_id(issue_number)
    return false if comment_id.nil?

    section = comment_section(summary)

    if comment_id.empty?
      body = "#{comment_header}#{section}"
      return GithubCli.run(
        "gh", "issue", "comment", issue_number, "--body", body,
        error_message: "Failed to create regression report comment on issue ##{issue_number}"
      )
    end

    existing_body = regression_comment_body(comment_id)
    return false if existing_body.nil?

    body = upsert_section(existing_body, section)
    GithubCli.run(
      "gh", "api", "-X", "PATCH",
      "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/comments/#{comment_id}",
      "-f", "body=#{body}",
      error_message: "Failed to update regression report comment #{comment_id}"
    )
  end

  def find_or_create_regression_issue
    issue_number = existing_regression_issue
    return nil if issue_number.nil?
    return issue_number unless issue_number.empty?

    create_regression_issue
  end

  def create_regression_issue
    # `gh issue create` does not support --json/--jq; it prints the new issue URL
    # on stdout (e.g. https://github.com/owner/repo/issues/123). Parse the number
    # so callers get the same bare-number shape as existing_regression_issue.
    stdout = GithubCli.capture_success(
      "gh", "issue", "create",
      "--title", issue_title,
      "--label", LABEL,
      "--body", issue_body,
      error_message: "Failed to create regression issue for #{commit_short}"
    )
    return nil unless stdout

    number = stdout[%r{/issues/(\d+)\s*\z}, 1]
    warn "::error::Could not parse issue number from gh output: #{stdout.strip}" unless number
    number
  end

  def issue_body
    <<~MARKDOWN
      ## Performance Regression Detected on main

      Statistically significant benchmark regressions were detected by [Bencher](#{bencher_url})
      using a Student's t-test (95% confidence interval, up to 64 sample history).

      | Detail | Value |
      |--------|-------|
      | **Commit** | [`#{commit_short}`](#{commit_url}) |
      | **Pushed by** | @#{ENV.fetch('GITHUB_ACTOR')} |
      | **Workflow run** | [Run ##{ENV.fetch('GITHUB_RUN_NUMBER')}](#{github_run_url}) |
      | **Bencher dashboard** | [View history](#{bencher_url}) |

      ### What to do

      1. Check the workflow run for the full Bencher HTML report
      2. Review the Bencher dashboard to see which metrics regressed
      3. Investigate the commit; expected trade-off or unintended regression?
      4. If unintended, open a fix PR and reference this issue
      5. Close this issue once resolved; subsequent regressions will open a new one

      ---
      *This issue was created automatically by the benchmark CI workflow.*
    MARKDOWN
  end
end
# rubocop:enable Metrics/ClassLength
