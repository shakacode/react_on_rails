#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "time"
BOUNDARY = "0.95"
MAX_SAMPLE = "64"
BENCHER_URL = "https://bencher.dev/perf/react-on-rails-t8a9ncxo"
# Threshold direction: :lower for "regression = drop" measures (rps),
# :upper for "regression = climb" measures (latency, failure rate).
THRESHOLDS = [
  ["rps", :lower],
  ["p50_latency", :upper],
  ["p90_latency", :upper],
  ["p99_latency", :upper],
  ["failed_pct", :upper]
].freeze

def env!(key)
  ENV.fetch(key) do
    warn "#{key} is required"
    exit 1
  end
end

SUITE_NAME = env!("BENCHMARK_SUITE_NAME")
REPORT_MARKER = env!("BENCHER_REPORT_MARKER")
env!("BENCHER_API_TOKEN")
BENCHMARK_JSON = ENV.fetch("BENCHMARK_JSON", "bench_results/benchmark.json")
REPORT_HTML = ENV.fetch("BENCHER_REPORT_HTML", "bench_results/bencher_report.html")
CHUNK_PREFIX = "bench_results/bencher_chunk"

def capture_command(*args)
  stdout, stderr, status = Open3.capture3(*args)
  warn stderr unless stderr.empty?
  [stdout, status]
end

def github_run_url
  "#{ENV.fetch('GITHUB_SERVER_URL')}/#{ENV.fetch('GITHUB_REPOSITORY')}/actions/runs/#{ENV.fetch('GITHUB_RUN_ID')}"
end

def branch_and_start_point_args
  case ENV.fetch("GITHUB_EVENT_NAME")
  when "push"
    ["main", []]
  when "pull_request"
    [
      ENV.fetch("GITHUB_HEAD_REF"),
      [
        "--start-point", ENV.fetch("GITHUB_BASE_REF"),
        "--start-point-hash", ENV.fetch("GITHUB_BASE_SHA"),
        "--start-point-clone-thresholds",
        "--start-point-reset"
      ]
    ]
  when "workflow_dispatch"
    branch = ENV.fetch("GITHUB_REF_NAME")
    return [branch, []] if branch == "main"

    stdout, = capture_command(
      "gh", "api", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/compare/main...#{branch}",
      "--jq", ".merge_base_commit.sha"
    )
    start_point_args = ["--start-point", "main", "--start-point-clone-thresholds", "--start-point-reset"]
    merge_base = stdout.strip

    if merge_base.empty?
      puts "Could not find merge-base with main via GitHub API, continuing without hash"
    else
      puts "Found merge-base via API: #{merge_base}"
      start_point_args.insert(2, "--start-point-hash", merge_base)
    end

    [branch, start_point_args]
  else
    warn "Unexpected event type: #{ENV.fetch('GITHUB_EVENT_NAME')}"
    exit 1
  end
end

def threshold_args(measure, direction)
  lower, upper = direction == :lower ? [BOUNDARY, "_"] : ["_", BOUNDARY]
  [
    "--threshold-measure", measure,
    "--threshold-test", "t_test",
    "--threshold-max-sample-size", MAX_SAMPLE,
    "--threshold-lower-boundary", lower,
    "--threshold-upper-boundary", upper
  ]
end

def bencher_args(branch, start_point_args)
  [
    "bencher", "run",
    "--project", "react-on-rails-t8a9ncxo",
    "--branch", branch,
    *start_point_args,
    "--testbed", "github-actions",
    "--adapter", "json",
    "--file", BENCHMARK_JSON,
    "--err",
    "--quiet",
    "--format", "html",
    *THRESHOLDS.flat_map { |measure, direction| threshold_args(measure, direction) }
  ]
end

def run_bencher(branch, start_point_args)
  stdout, stderr, status = Open3.capture3(*bencher_args(branch, start_point_args))
  File.write(REPORT_HTML, stdout)
  warn stderr unless stderr.empty?
  [stderr, status.exitstatus]
end

def retry_without_start_point_hash?(stderr, exit_code)
  # \bAlerts?\b avoids false matches on URL paths like "/alerts/..." that Bencher prints in stderr.
  exit_code != 0 &&
    stderr.match?(/Head Version.*not found/) &&
    !stderr.match?(/\bAlerts?\b|threshold violation|boundary violation/i)
end

def alert?(stderr, exit_code)
  exit_code != 0 && stderr.match?(/\bAlerts?\b|threshold violation|boundary violation/i)
end

def append_step_summary(markdown)
  File.open(ENV.fetch("GITHUB_STEP_SUMMARY"), "a") { |file| file.write(markdown) }
end

def post_report_to_summary
  return unless File.size?(REPORT_HTML)

  append_step_summary("## #{SUITE_NAME} Bencher Report\n")
  append_step_summary(File.read(REPORT_HTML))
end

def split_report_for_comments
  # Clear leftover chunks from prior runs so post_report_comment_chunks doesn't
  # mix fresh output with stale data (matters on self-hosted/cached runners).
  Dir.glob("#{CHUNK_PREFIX}*.html").each { |path| File.delete(path) }
  return true if system({ "BENCHER_REPORT_MARKER" => REPORT_MARKER },
                        "ruby", "benchmarks/split_html_report.rb", REPORT_HTML, CHUNK_PREFIX)

  warn "Failed to split HTML report; skipping PR comments"
  false
end

def stale_comment_ids(before:)
  # Marker + cutoff are passed via env so the jq filter reads them through `env.X`,
  # avoiding the Ruby-#dump vs jq-string-escape mismatch that interpolated strings invite.
  # The cutoff makes the GC skip comments the current run just posted (same marker).
  stdout, stderr, status = Open3.capture3(
    { "MARKER" => REPORT_MARKER, "CUTOFF_TS" => before },
    "gh", "api", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/#{ENV.fetch('PR_NUMBER')}/comments",
    "--paginate",
    "--jq", ".[] | select(.body | startswith(env.MARKER)) | select(.created_at < env.CUTOFF_TS) | .id"
  )
  warn stderr unless stderr.empty?
  return [] unless status.success?

  stdout.lines.map(&:strip).reject(&:empty?)
end

def delete_stale_report_comments(before:)
  stale_comment_ids(before: before).each do |comment_id|
    puts "Deleting stale #{SUITE_NAME} Bencher report comment #{comment_id}"
    system("gh", "api", "-X", "DELETE", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/comments/#{comment_id}")
  end
end

def post_report_comment_chunks
  chunk_files = Dir["#{CHUNK_PREFIX}*.html"].sort_by do |chunk_file|
    chunk_file[/bencher_chunk(?:\.(\d+))?\.html\z/, 1].to_i
  end

  posted_any = false
  any_failed = false
  chunk_files.each do |chunk_file|
    puts "Posting #{chunk_file} (#{File.size(chunk_file)} bytes)..."
    if system("gh", "pr", "comment", ENV.fetch("PR_NUMBER"), "--body-file", chunk_file)
      posted_any = true
    else
      warn "Failed to post #{chunk_file}"
      any_failed = true
    end
  end

  [posted_any, any_failed]
end

def replace_pr_comments
  return unless ENV.fetch("GITHUB_EVENT_NAME") == "pull_request"
  return unless File.size?(REPORT_HTML)

  return unless split_report_for_comments

  # Capture cutoff before posting so the GC sweeps only pre-existing comments and leaves
  # the chunks this run just posted intact. If every post fails the GC is skipped entirely
  # and the prior run's comments stay visible.
  cutoff_ts = Time.now.utc.iso8601
  posted_any, any_failed = post_report_comment_chunks

  if posted_any
    delete_stale_report_comments(before: cutoff_ts)
  else
    warn "No #{SUITE_NAME} chunks were posted successfully; keeping prior Bencher comments in place."
  end

  return unless any_failed

  fallback_body = <<~MARKDOWN
    #{REPORT_MARKER}
    **#{SUITE_NAME} Bencher report chunks were too large to post as PR comments.**

    View the full report in the job summary: #{github_run_url}
  MARKDOWN
  system("gh", "pr", "comment", ENV.fetch("PR_NUMBER"), "--body", fallback_body)
end

def formatted_summary(title, path)
  return "" unless File.exist?(path)

  stdout, status = Open3.capture2("column", "-t", "-s", "\t", path)
  body = status.success? ? stdout : File.read(path)

  <<~MARKDOWN

    ### #{title}

    ```
    #{body}
    ```
  MARKDOWN
end

def benchmark_summary
  [
    formatted_summary("#{SUITE_NAME} Rails Benchmark Summary", "bench_results/summary.txt"),
    formatted_summary("#{SUITE_NAME} Node Renderer Benchmark Summary", "bench_results/node_renderer_summary.txt")
  ].join
end

def ensure_regression_label
  system(
    "gh", "label", "create", "performance-regression",
    "--description", "Automated: benchmark regression detected on main",
    "--color", "D93F0B",
    "--force"
  )
end

def existing_regression_issue
  stdout, status = capture_command(
    "gh", "issue", "list",
    "--label", "performance-regression",
    "--state", "open",
    "--limit", "1",
    "--json", "number",
    "--jq", ".[0].number // empty"
  )
  return "" unless status.success?

  stdout.strip
end

def comment_on_regression_issue(issue_number, summary)
  commit_short = ENV.fetch("GITHUB_SHA")[0, 7]
  commit_url = "#{ENV.fetch('GITHUB_SERVER_URL')}/#{ENV.fetch('GITHUB_REPOSITORY')}/commit/#{ENV.fetch('GITHUB_SHA')}"
  body = <<~MARKDOWN
    ## New #{SUITE_NAME} regression detected

    **Commit:** [`#{commit_short}`](#{commit_url}) by @#{ENV.fetch('GITHUB_ACTOR')}
    **Workflow run:** [Run ##{ENV.fetch('GITHUB_RUN_NUMBER')}](#{github_run_url})
    #{summary}

    > View the full Bencher report in the workflow run summary or on the [Bencher dashboard](#{BENCHER_URL}).
  MARKDOWN

  system("gh", "issue", "comment", issue_number, "--body", body)
end

def create_regression_issue(summary)
  commit_short = ENV.fetch("GITHUB_SHA")[0, 7]
  commit_url = "#{ENV.fetch('GITHUB_SERVER_URL')}/#{ENV.fetch('GITHUB_REPOSITORY')}/commit/#{ENV.fetch('GITHUB_SHA')}"
  body = <<~MARKDOWN
    ## Performance Regression Detected on main

    A statistically significant #{SUITE_NAME} performance regression was detected by
    [Bencher](#{BENCHER_URL}) using a Student's t-test (95% confidence
    interval, up to 64 sample history).

    | Detail | Value |
    |--------|-------|
    | **Commit** | [`#{commit_short}`](#{commit_url}) |
    | **Pushed by** | @#{ENV.fetch('GITHUB_ACTOR')} |
    | **Workflow run** | [Run ##{ENV.fetch('GITHUB_RUN_NUMBER')}](#{github_run_url}) |
    | **Bencher dashboard** | [View history](#{BENCHER_URL}) |
    #{summary}

    ### What to do

    1. Check the workflow run for the full Bencher HTML report
    2. Review the Bencher dashboard to see which metrics regressed
    3. Investigate the commit; expected trade-off or unintended regression?
    4. If unintended, open a fix PR and reference this issue
    5. Close this issue once resolved; subsequent regressions will open a new one

    ---
    *This issue was created automatically by the benchmark CI workflow.*
  MARKDOWN

  system(
    "gh", "issue", "create",
    "--title", "Performance Regression Detected on main (#{commit_short})",
    "--label", "performance-regression",
    "--body", body
  )
end

def main_push?
  ENV.fetch("GITHUB_EVENT_NAME") == "push" && ENV.fetch("GITHUB_REF") == "refs/heads/main"
end

unless File.exist?(BENCHMARK_JSON)
  warn "Benchmark JSON file not found: #{BENCHMARK_JSON}"
  exit 1
end

branch, start_point_args = branch_and_start_point_args
stderr, bencher_exit_code = run_bencher(branch, start_point_args)

if retry_without_start_point_hash?(stderr, bencher_exit_code)
  retry_args = start_point_args.dup
  if (hash_arg_index = retry_args.index("--start-point-hash"))
    retry_args.slice!(hash_arg_index, 2)
  end
  puts "Start-point hash not found in Bencher; retrying without --start-point-hash"
  puts "::warning::Start-point hash not found in Bencher; falling back to latest baseline for comparison"
  stderr, bencher_exit_code = run_bencher(branch, retry_args)
end

post_report_to_summary
replace_pr_comments

if main_push? && bencher_exit_code != 0
  if alert?(stderr, bencher_exit_code)
    ensure_regression_label
    summary = benchmark_summary
    issue_number = existing_regression_issue

    if issue_number.empty?
      create_regression_issue(summary)
    else
      puts "Open regression issue already exists: ##{issue_number}; adding comment"
      comment_on_regression_issue(issue_number, summary)
    end

    puts "::warning::Bencher flagged a #{SUITE_NAME} regression on main (exit #{bencher_exit_code}). " \
         "See the open regression issue (label: performance-regression), the Bencher dashboard, " \
         "and the workflow run: #{github_run_url}"
  else
    warn "::error::Bencher exited #{bencher_exit_code} on main with no regression alert in stderr for #{SUITE_NAME}; " \
         "this indicates an operational failure (auth/API/network/CLI), not a performance regression. " \
         "Check the logs above."
    exit bencher_exit_code
  end
end
