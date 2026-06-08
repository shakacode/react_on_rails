#!/usr/bin/env ruby
# frozen_string_literal: true

# Files a single GitHub issue for benchmark regressions CONFIRMED on main.
#
# A main-push alert is non-fatal until a fresh-runner confirmation rerun re-alerts on
# the same benchmark+measure (see track_benchmarks.rb confirmation mode). Each confirmed
# suite/shard records a regression-confirmed.json payload (see regression_report.rb) that
# the workflow uploads as an artifact. This script runs once, after the confirmation
# matrix, reads every confirmed payload, and reports them serially through
# RegressionIssueReporter. Doing it in one process is what makes the dedup/upsert safe:
# parallel suites reporting directly would create duplicate issues and clobber the shared
# comment.
#
# This job owns the final pass/fail: a confirmed regression fails the workflow (exit 1)
# AND files the issue; no confirmed payloads means every first-run alert was cleared as
# noise (or short-circuited as ignored upstream), so it exits 0.
#
# Usage: ruby benchmarks/report_regressions.rb <confirmed-artifacts-dir>

require "json"

require_relative "lib/github"
require_relative "lib/github_cli"
require_relative "lib/regression_report"

BENCHER_URL = "https://bencher.dev/perf/react-on-rails-t8a9ncxo"

# Creates (or updates) the single per-commit regression issue and upserts one
# section per suite into a shared comment. Only safe to drive from a single
# process — see the file header.
# rubocop:disable Metrics/ClassLength
class RegressionIssueReporter
  LABEL = "performance-regression"
  CACHE_MISS = :cache_miss
  ISSUE_NUMBER_UNKNOWN_AFTER_CREATE = :issue_number_unknown_after_create
  COMMENT_ID_UNKNOWN_AFTER_CREATE = :comment_id_unknown_after_create

  def self.report(summary:, **attributes)
    new(**attributes).report(summary)
  end

  def initialize(suite_name:, github_run_url:, bencher_url:, issue_number_cache: nil, report_comment_id_cache: nil)
    @suite_name = suite_name
    @github_run_url = github_run_url
    @bencher_url = bencher_url
    @issue_number_cache = issue_number_cache
    @report_comment_id_cache = report_comment_id_cache
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

  attr_reader :suite_name, :github_run_url, :bencher_url, :issue_number_cache, :report_comment_id_cache, :commit_short

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
    cached_comment_id = cached_regression_comment_id
    return cached_comment_id unless cached_comment_id == CACHE_MISS

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

    stdout.lines.first.to_s.strip.tap do |comment_id|
      cache_regression_comment_id(comment_id) unless comment_id.empty?
    end
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
      return create_regression_comment(issue_number, body)
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
      stdin_data: JSON.generate(body:)
    )
  end

  def find_or_create_regression_issue
    cached_issue_number = cached_regression_issue_number
    return cached_issue_number unless cached_issue_number == CACHE_MISS

    issue_number = existing_regression_issue
    return nil if issue_number.nil?

    return cache_regression_issue_number(issue_number) unless issue_number.empty?

    create_regression_issue.tap do |created_issue_number|
      # nil means create_regression_issue already stored ISSUE_NUMBER_UNKNOWN_AFTER_CREATE;
      # this no-ops for nil so later suites still avoid duplicate issue creation.
      cache_regression_issue_number(created_issue_number)
    end
  end

  def cached_regression_issue_number
    return CACHE_MISS unless issue_number_cache

    issue_number_cache.fetch(issue_title, CACHE_MISS).then do |cached_issue_number|
      cached_issue_number == ISSUE_NUMBER_UNKNOWN_AFTER_CREATE ? nil : cached_issue_number
    end
  end

  def cache_regression_issue_number(issue_number)
    issue_number_cache&.store(issue_title, issue_number) unless issue_number.to_s.empty?
    issue_number
  end

  def cached_regression_comment_id
    return CACHE_MISS unless report_comment_id_cache

    report_comment_id_cache.fetch(comment_marker, CACHE_MISS).then do |cached_comment_id|
      cached_comment_id == COMMENT_ID_UNKNOWN_AFTER_CREATE ? nil : cached_comment_id
    end
  end

  def cache_regression_comment_id(comment_id)
    report_comment_id_cache&.store(comment_marker, comment_id) unless comment_id.to_s.empty?
    comment_id
  end

  def create_regression_comment(issue_number, body)
    stdout = GithubCli.capture_success(
      "gh", "api", "-X", "POST",
      "repos/#{github_repository}/issues/#{issue_number}/comments",
      "--input", "-",
      "--jq", ".id",
      error_message: "Failed to create regression report comment on issue ##{issue_number}",
      stdin_data: JSON.generate(body:)
    )
    return false unless stdout

    comment_id = stdout.lines.first.to_s.strip
    if comment_id.empty?
      report_comment_id_cache&.store(comment_marker, COMMENT_ID_UNKNOWN_AFTER_CREATE)
      Github.warning(
        "Created regression report comment on issue ##{issue_number} but could not parse its id; " \
        "this suite and later suites in this run will be marked as failed to avoid duplicate comments."
      )
      return false
    end

    cache_regression_comment_id(comment_id)
    true
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
      issue_number_cache&.store(issue_title, ISSUE_NUMBER_UNKNOWN_AFTER_CREATE)
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
      using a Student's t-test (95% confidence interval, up to 64 sample history), and
      **confirmed by a second run on a fresh runner** (re-tested against main's baseline)
      that re-alerted on the same benchmark+measure — so this is unlikely to be runner noise.

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

def confirmed_payload_paths(artifacts_dir)
  # Recursive glob so it works regardless of how download-artifact nests each
  # suite's artifact under the download path.
  Dir.glob(File.join(artifacts_dir, "**", RegressionReport::CONFIRMED_FILENAME))
end

def load_payload(path)
  parsed = JSON.parse(File.read(path))
  required_keys = [
    RegressionReport::SUITE_NAME,
    RegressionReport::FIRST_RUN_SUMMARY,
    RegressionReport::CONFIRMATION_SUMMARY
  ]
  unless parsed.is_a?(Hash) && required_keys.all? { |key| parsed.key?(key) }
    raise "expected a JSON object with #{required_keys.join(', ')}"
  end

  parsed
rescue StandardError => e
  # A regression was confirmed but its report is unreadable/corrupt. Surface it and
  # let the caller fail rather than silently dropping the suite from the issue.
  warn "::error::Failed to read confirmed regression payload #{path}: #{e.class}: #{e.message}"
  nil
end

# The per-shard evidence block for one confirmed payload: the first-run table and the
# confirmation-run table side by side (the comparison is what a reader wants).
def shard_summary(payload)
  shard_label = payload.fetch(RegressionReport::SHARD_LABEL, "").to_s
  heading = shard_label.empty? ? "" : "#### Shard #{shard_label}\n\n"
  first_run = payload.fetch(RegressionReport::FIRST_RUN_SUMMARY, "").to_s
  confirmation = payload.fetch(RegressionReport::CONFIRMATION_SUMMARY, "").to_s
  <<~MARKDOWN
    #{heading}**First run**

    #{first_run}

    **Confirmation run** (fresh runner, re-tested against main's baseline)

    #{confirmation}
  MARKDOWN
end

# Reports the confirmed regressions. Returns:
#   :clean  — no confirmed payloads (every first-run alert cleared as noise / ignored)
#   :filed  — at least one confirmed regression filed/updated successfully
#   :error  — a payload was unreadable or filing the issue failed (operational failure)
def report_regressions(artifacts_dir)
  paths = confirmed_payload_paths(artifacts_dir)

  if paths.empty?
    puts "No confirmed benchmark regressions to report."
    return :clean
  end

  payloads = paths.map { |path| load_payload(path) }
  readable = payloads.compact

  # One section per suite: a sharded suite emits one payload per shard, so combine
  # them rather than filing a section per shard. Suites sorted for stable output.
  by_suite = readable.group_by { |payload| payload.fetch(RegressionReport::SUITE_NAME) }
  issue_number_cache = {}
  report_comment_id_cache = {}
  reported_ok = by_suite.keys.sort.map do |suite_name|
    report_suite(
      suite_name,
      by_suite.fetch(suite_name),
      issue_number_cache:,
      report_comment_id_cache:
    )
  end.all?

  # Fail if any payload was unreadable: a lost report must not pass as success.
  return :error unless reported_ok && readable.size == payloads.size

  :filed
end

def report_suite(suite_name, payloads, issue_number_cache: nil, report_comment_id_cache: nil)
  # Order shard summaries by shard number ("2/5" before "10/5"); each already
  # self-labels with its shard in its headers, so concatenation reads cleanly.
  summary = payloads
            .sort_by { |payload| payload.fetch(RegressionReport::SHARD_LABEL, "").split("/").first.to_i }
            .map { |payload| shard_summary(payload) }
            .join("\n")
  puts "Filing confirmed regression report for #{suite_name} (#{payloads.size} shard report(s))"

  issue_number = RegressionIssueReporter.report(
    suite_name:,
    github_run_url: Github.run_url,
    bencher_url: BENCHER_URL,
    summary:,
    issue_number_cache:,
    report_comment_id_cache:
  )

  if issue_number.empty?
    warn "::error::Failed to file regression issue for #{suite_name}"
    return false
  end

  puts "Reported #{suite_name} confirmed regression to issue ##{issue_number}"
  true
end

if __FILE__ == $PROGRAM_NAME
  artifacts_dir = ARGV.fetch(0, "confirmed-artifacts")
  case report_regressions(artifacts_dir)
  when :clean
    exit 0
  when :filed
    # A regression was confirmed on a fresh runner and the issue filed/updated. This
    # job owns the final pass/fail, so fail the workflow to surface the regression.
    warn "::error::Confirmed benchmark regression(s) on main; see the filed performance-regression issue."
    exit 1
  else
    exit 1
  end
end
