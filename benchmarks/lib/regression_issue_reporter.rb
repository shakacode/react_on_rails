# frozen_string_literal: true

require "open3"

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
    ensure_regression_label
    issue_number = find_or_create_regression_issue
    if issue_number.empty?
      warn "::error::Failed to find or create regression issue for #{commit_short}"
      return ""
    end

    puts "Posting #{suite_name} regression report to ##{issue_number}"
    create_or_update_regression_comment(issue_number, summary)
    issue_number
  end

  private

  attr_reader :suite_name, :github_run_url, :bencher_url, :commit_short

  def ensure_regression_label
    system(
      "gh", "label", "create", LABEL,
      "--description", "Automated: benchmark regression detected on main",
      "--color", "D93F0B",
      "--force"
    )
  end

  def commit_url
    "#{ENV.fetch('GITHUB_SERVER_URL')}/#{ENV.fetch('GITHUB_REPOSITORY')}/commit/#{ENV.fetch('GITHUB_SHA')}"
  end

  def issue_title
    "Performance Regression Detected on main (#{commit_short})"
  end

  def existing_regression_issue
    stdout, stderr, status = Open3.capture3(
      { "TITLE" => issue_title },
      "gh", "issue", "list",
      "--label", LABEL,
      "--state", "open",
      "--limit", "100",
      "--json", "number,title",
      "--jq", ".[] | select(.title == env.TITLE) | .number"
    )
    warn stderr unless stderr.empty?
    return "" unless status.success?

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
    stdout, stderr, status = Open3.capture3(
      { "MARKER" => comment_marker },
      "gh", "api", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/#{issue_number}/comments",
      "--paginate",
      "--jq", ".[] | select(.body | startswith(env.MARKER)) | .id"
    )
    warn stderr unless stderr.empty?
    return "" unless status.success?

    stdout.lines.first.to_s.strip
  end

  def regression_comment_body(comment_id)
    stdout, stderr, status = Open3.capture3(
      "gh", "api", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/comments/#{comment_id}",
      "--jq", ".body"
    )
    warn stderr unless stderr.empty?
    return "" unless status.success?

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
    section = comment_section(summary)

    if comment_id.empty?
      body = "#{comment_header}#{section}"
      return system("gh", "issue", "comment", issue_number, "--body", body)
    end

    body = upsert_section(regression_comment_body(comment_id), section)
    system(
      "gh", "api", "-X", "PATCH",
      "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/comments/#{comment_id}",
      "-f", "body=#{body}"
    )
  end

  def find_or_create_regression_issue
    issue_number = existing_regression_issue
    return issue_number unless issue_number.empty?

    create_regression_issue
  end

  def create_regression_issue
    body = <<~MARKDOWN
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

    stdout, stderr, status = Open3.capture3(
      "gh", "issue", "create",
      "--title", issue_title,
      "--label", LABEL,
      "--body", body,
      "--json", "number",
      "--jq", ".number"
    )
    warn stderr unless stderr.empty?
    return "" unless status.success?

    stdout.strip
  end
end
