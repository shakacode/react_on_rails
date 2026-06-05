#!/usr/bin/env ruby
# frozen_string_literal: true

# Files a single GitHub issue for benchmark regressions detected on main.
#
# Each benchmark matrix suite runs in its own parallel job; on a regression it
# records a regression.json payload (see track_benchmarks.rb) that the workflow
# uploads as an artifact. This script runs once, after the matrix, reads every
# payload, and reports them serially through RegressionIssueReporter. Doing it in
# one process is what makes the dedup/upsert safe: parallel suites reporting
# directly would create duplicate issues and clobber the shared comment.
#
# Usage: ruby benchmarks/report_regressions.rb <artifacts-dir>

require "json"

require_relative "lib/github"
require_relative "lib/github_cli"
require_relative "lib/regression_report"

BENCHER_URL = "https://bencher.dev/perf/react-on-rails-t8a9ncxo"

# TEMPORARY — benchmarks whose regressions must NOT open an issue, by the exact
# benchmark name Bencher reports (the leading-slash name shown in the summary table,
# matched against RegressionReport::REGRESSED_BENCHMARKS in each suite's payload).
#
# /posts_page: Pro spent weeks hard-500ing on every request (failed_pct = 100), so the
# route was effectively an instant error and Bencher built its rps/latency baseline
# from those bogus-fast failure responses. Now that the route is fixed, its real
# (slower) timings read as large regressions against that fast baseline and would file
# a spurious regression issue on every main push. We can't surgically delete just this
# benchmark's history in Bencher (the delete is blocked by a FOREIGN KEY constraint
# from its reports/alerts), so we suppress its issue here instead.
#
# REMOVE this entry (restoring unconditional filing) once the failure-era samples have
# rolled out of Bencher's 64-run t-test window for /posts_page: Pro on main — i.e. once
# the dashboard baseline reflects real timings again. After that a regression for it is
# genuine and must be reported. Tracking issue + full revert steps:
# https://github.com/shakacode/react_on_rails/issues/3669
IGNORED_REGRESSION_BENCHMARKS = ["/posts_page: Pro"].freeze

# Creates (or updates) the single per-commit regression issue and upserts one
# section per suite into a shared comment. Only safe to drive from a single
# process — see the file header.
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
    return "" if issue_number.nil?

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
    @commit_url ||= "#{github_server_url}/#{github_repository}/commit/#{github_sha}"
  end

  def issue_title
    @issue_title ||= "Performance Regression Detected on main (#{commit_short})"
  end

  def existing_regression_issue
    # Use the live issues list, not --search: the search index is eventually
    # consistent and could miss an issue another suite created moments earlier in
    # this same run, producing duplicates. The exact-title jq match is the real
    # dedup; the high --limit only guards re-runs whose (older) commit issue has
    # been pushed down the newest-first list by unrelated regression issues.
    stdout = GithubCli.capture_success(
      "gh", "issue", "list",
      "--label", LABEL,
      "--state", "open",
      "--limit", "500",
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
    @comment_marker ||= "<!-- BENCHMARK_REGRESSION_REPORT #{github_sha} -->"
  end

  def section_start
    @section_start ||= "<!-- BENCHMARK_REGRESSION_SECTION #{suite_name} -->"
  end

  def section_end
    @section_end ||= "<!-- /BENCHMARK_REGRESSION_SECTION #{suite_name} -->"
  end

  def regression_comment_id(issue_number)
    stdout = GithubCli.capture_success(
      "gh", "api", "repos/#{github_repository}/issues/#{issue_number}/comments",
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
      "gh", "api", "repos/#{github_repository}/issues/comments/#{comment_id}",
      "--jq", ".body",
      error_message: "Failed to fetch regression issue comment #{comment_id}"
    )
    # nil signals a `gh` failure; the caller must abort rather than rewrite the
    # comment from an empty body (which would drop the header and other suites).
    return nil unless stdout

    stdout
  end

  def comment_header
    @comment_header ||= <<~MARKDOWN
      #{comment_marker}
      ## Benchmark regression reports for #{commit_short}

      **Commit:** [`#{commit_short}`](#{commit_url})
      **Workflow run:** [Run ##{github_run_number}](#{github_run_url})
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
    # Send the body over stdin (--input -) rather than as a -f CLI argument: a
    # sharded suite's combined report can grow past the OS argument-length limit.
    GithubCli.run(
      "gh", "api", "-X", "PATCH",
      "repos/#{github_repository}/issues/comments/#{comment_id}",
      "--input", "-",
      error_message: "Failed to update regression report comment #{comment_id}",
      stdin_data: JSON.generate(body: body)
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

    # Match anywhere, not anchored to end-of-output: gh may append a trailing line
    # (e.g. a deprecation notice) after the URL. The issue was created either way,
    # so a parse miss is a warning, not an error.
    number = stdout[%r{/issues/(\d+)}, 1]
    unless number
      Github.warning(
        "Created the issue but could not parse its number from gh output " \
        "(#{stdout.strip.inspect}); its comment section may be missing"
      )
    end
    number
  end

  def issue_body
    @issue_body ||= <<~MARKDOWN
      ## Performance Regression Detected on main

      Statistically significant benchmark regressions were detected by [Bencher](#{bencher_url})
      using a Student's t-test (95% confidence interval, up to 64 sample history).

      | Detail | Value |
      |--------|-------|
      | **Commit** | [`#{commit_short}`](#{commit_url}) |
      | **Pushed by** | @#{github_actor} |
      | **Workflow run** | [Run ##{github_run_number}](#{github_run_url}) |
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

  def github_actor
    @github_actor ||= ENV.fetch("GITHUB_ACTOR")
  end

  def github_repository
    @github_repository ||= ENV.fetch("GITHUB_REPOSITORY")
  end

  def github_run_number
    @github_run_number ||= ENV.fetch("GITHUB_RUN_NUMBER")
  end

  def github_server_url
    @github_server_url ||= ENV.fetch("GITHUB_SERVER_URL")
  end

  def github_sha
    @github_sha ||= ENV.fetch("GITHUB_SHA")
  end
end
# rubocop:enable Metrics/ClassLength

def regression_payload_paths(artifacts_dir)
  # Recursive glob so it works regardless of how download-artifact nests each
  # suite's artifact under the download path.
  Dir.glob(File.join(artifacts_dir, "**", RegressionReport::FILENAME))
end

def load_payload(path)
  JSON.parse(File.read(path))
rescue StandardError => e
  # A regression was detected but its report is unreadable/corrupt. Surface it and
  # let the caller fail rather than silently dropping the suite from the issue.
  warn "::error::Failed to read regression payload #{path}: #{e.class}: #{e.message}"
  nil
end

# Returns the regressed benchmarks to suppress only when every payload reports its
# regressed benchmarks AND all of them are in IGNORED_REGRESSION_BENCHMARKS. Fails
# safe toward filing: no payloads, a payload missing the list (older writer / hand-off
# that couldn't name them), an empty list, or any non-ignored benchmark returns nil.
def suppressed_regressed_benchmarks(payloads)
  return nil if payloads.empty?

  per_payload = payloads.map { |payload| payload[RegressionReport::REGRESSED_BENCHMARKS] }
  return nil unless per_payload.all? { |names| names.is_a?(Array) && !names.empty? }

  regressed_benchmarks = per_payload.flatten.uniq
  return nil unless regressed_benchmarks.all? { |name| IGNORED_REGRESSION_BENCHMARKS.include?(name) }

  regressed_benchmarks
end

def report_regressions(artifacts_dir)
  paths = regression_payload_paths(artifacts_dir)

  if paths.empty?
    puts "No benchmark regressions were reported by any suite."
    return true
  end

  payloads = paths.map { |path| load_payload(path) }
  readable = payloads.compact

  # Skip filing when every regressed benchmark is temporarily ignored. Gated on all
  # payloads being readable: an unreadable payload is an unknown regression that could
  # be anything, so fall through and let the normal flow file (and then fail) rather
  # than suppress it.
  suppressed_benchmarks = suppressed_regressed_benchmarks(readable) if readable.size == payloads.size
  if suppressed_benchmarks
    # Surface as a run-summary notice (not a plain log line) so it is visible that the
    # suppression is active and still needs removing once the baseline recovers.
    Github.notice(
      "Benchmark regression issue suppressed: the only regressed benchmark(s) are " \
      "temporarily ignored (#{suppressed_benchmarks.join(', ')}). Remove " \
      "IGNORED_REGRESSION_BENCHMARKS in report_regressions.rb once their Bencher baseline recovers."
    )
    return true
  end

  # One section per suite: a sharded suite emits one payload per shard, so combine
  # them rather than filing a section per shard. Suites sorted for stable output.
  by_suite = readable.group_by { |payload| payload.fetch(RegressionReport::SUITE_NAME) }
  reported_ok = by_suite.keys.sort.map { |suite_name| report_suite(suite_name, by_suite.fetch(suite_name)) }.all?

  # Fail if any payload was unreadable: a lost report must not pass as success.
  reported_ok && readable.size == payloads.size
end

def report_suite(suite_name, payloads)
  # Order shard summaries by shard number ("2/5" before "10/5"); each already
  # self-labels with its shard in its headers, so concatenation reads cleanly.
  summary = payloads
            .sort_by { |payload| payload.fetch(RegressionReport::SHARD_LABEL, "").split("/").first.to_i }
            .map { |payload| payload.fetch(RegressionReport::SUMMARY) }
            .join("\n")
  puts "Filing regression report for #{suite_name} (#{payloads.size} shard report(s))"

  issue_number = RegressionIssueReporter.report(
    suite_name: suite_name,
    github_run_url: Github.run_url,
    bencher_url: BENCHER_URL,
    summary: summary
  )

  if issue_number.empty?
    warn "::error::Failed to file regression issue for #{suite_name}"
    return false
  end

  puts "Reported #{suite_name} regression to issue ##{issue_number}"
  true
end

if __FILE__ == $PROGRAM_NAME
  artifacts_dir = ARGV.fetch(0, "regression-artifacts")
  exit 1 unless report_regressions(artifacts_dir)
end
