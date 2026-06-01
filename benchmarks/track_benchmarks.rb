#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "time"

require_relative "lib/github"
require_relative "lib/github_cli"
require_relative "lib/regression_report"

BOUNDARY = "0.95"
MAX_SAMPLE = "64"
# Threshold direction: :lower for "regression = drop" measures (rps),
# :upper for "regression = climb" measures (latency, failure rate).
THRESHOLDS = [
  ["rps", :lower],
  ["p50_latency", :upper],
  ["p90_latency", :upper],
  ["p99_latency", :upper],
  ["failed_pct", :upper]
].freeze

# Bencher exits non-zero both for a performance alert (a real regression) and for
# operational problems; we tell them apart by grepping stderr for these phrases.
# They are not a documented API contract, so the CLI is pinned in benchmark.yml and
# this must be re-verified on upgrade.
ALERT_PATTERN = /\bAlerts?\b|threshold violation|boundary violation/i

def env!(key)
  ENV.fetch(key) do
    warn "#{key} is required"
    exit 1
  end
end

BENCHMARK_JSON = ENV.fetch("BENCHMARK_JSON", "bench_results/benchmark.json")
REPORT_HTML = ENV.fetch("BENCHER_REPORT_HTML", "bench_results/bencher_report.html")
CHUNK_PREFIX = "bench_results/bencher_chunk"
REGRESSION_REPORT_JSON = File.join("bench_results", RegressionReport::FILENAME)

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

    stdout, status = GithubCli.capture(
      "gh", "api", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/compare/main...#{branch}",
      "--jq", ".merge_base_commit.sha",
      error_message: "Failed to resolve merge-base with main for #{branch}"
    )
    start_point_args = ["--start-point", "main", "--start-point-clone-thresholds", "--start-point-reset"]
    # On API failure GithubCli already emits ::error::; fall back to the latest
    # baseline rather than conflating a failed call with "no merge-base found".
    merge_base = status.success? ? stdout.strip : ""

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
  warn stderr unless stderr.empty?
  # Bencher prints the HTML report to stdout, including the alert report on a
  # non-zero "alert" exit (which we still want to publish). An empty stdout means
  # an operational failure with no report, so clear any stale file rather than
  # persisting/posting garbage or leaving a previous attempt's report behind.
  if stdout.empty?
    FileUtils.rm_f(REPORT_HTML)
  else
    File.write(REPORT_HTML, stdout)
  end
  [stderr, status.exitstatus]
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
  # Clear leftover chunks before splitting so a shorter new report doesn't leave
  # numbered chunks from the previous run lying around for the post step to pick up.
  Dir.glob("#{CHUNK_PREFIX}*.html").each { |path| File.delete(path) }
  return true if system({ "BENCHER_REPORT_MARKER" => REPORT_MARKER },
                        "ruby", "benchmarks/split_html_report.rb", REPORT_HTML, CHUNK_PREFIX)

  warn "::error::Failed to split HTML report for #{SUITE_NAME}; PR comments will not be posted"
  false
end

def stale_comment_ids(before:)
  # Marker + cutoff are passed via env so the jq filter reads them through `env.X`,
  # avoiding the Ruby-#dump vs jq-string-escape mismatch that interpolated strings invite.
  # The cutoff makes the GC skip comments the current run just posted (same marker).
  stdout, status = GithubCli.capture(
    "gh", "api", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/#{ENV.fetch('PR_NUMBER')}/comments",
    "--paginate",
    "--jq", ".[] | select(.body | startswith(env.MARKER)) | select(.created_at < env.CUTOFF_TS) | .id",
    env: { "MARKER" => REPORT_MARKER, "CUTOFF_TS" => before },
    error_message: "Failed to list stale #{SUITE_NAME} Bencher report comments"
  )
  return [] unless status.success?

  stdout.lines.map(&:strip).reject(&:empty?)
end

def delete_stale_report_comments(before:)
  failed = 0
  stale_comment_ids(before: before).each do |comment_id|
    puts "Deleting stale #{SUITE_NAME} Bencher report comment #{comment_id}"
    next if GithubCli.run(
      "gh", "api", "-X", "DELETE", "repos/#{ENV.fetch('GITHUB_REPOSITORY')}/issues/comments/#{comment_id}",
      error_message: "Failed to delete stale #{SUITE_NAME} Bencher report comment #{comment_id}"
    )

    failed += 1
  end
  return if failed.zero?

  warn "::warning::Failed to delete #{failed} stale #{SUITE_NAME} Bencher report comment(s); they may remain visible."
end

def post_report_comment_chunks
  chunk_files = Dir["#{CHUNK_PREFIX}*.html"].sort_by do |chunk_file|
    chunk_file[/bencher_chunk(?:\.(\d+))?\.html\z/, 1].to_i
  end

  posted_any = false
  any_failed = false
  chunk_files.each do |chunk_file|
    puts "Posting #{chunk_file} (#{File.size(chunk_file)} bytes)..."
    if GithubCli.run(
      "gh", "pr", "comment", ENV.fetch("PR_NUMBER"), "--body-file", chunk_file,
      error_message: "Failed to post #{chunk_file}"
    )
      posted_any = true
    else
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

    View the full report in the job summary: #{Github.run_url}
  MARKDOWN
  GithubCli.run(
    "gh", "pr", "comment", ENV.fetch("PR_NUMBER"), "--body", fallback_body,
    error_message: "Failed to post fallback #{SUITE_NAME} Bencher report comment"
  )
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

def alert?(stderr, exit_code)
  exit_code != 0 && stderr.match?(ALERT_PATTERN)
end

# A missing start-point baseline (not an alert): retrying without the start-point
# hash falls back to the latest baseline. The alert exclusion is load-bearing — a
# real regression must not be silently re-run against a different baseline.
def retry_without_start_point_hash?(stderr, exit_code)
  exit_code != 0 &&
    stderr.match?(/Head Version.*not found/) &&
    !stderr.match?(ALERT_PATTERN)
end

def main_push?
  ENV.fetch("GITHUB_EVENT_NAME") == "push" && ENV.fetch("GITHUB_REF") == "refs/heads/main"
end

# Only run the benchmark tracking when invoked as a script; `require`-ing the file
# (e.g. from specs) just loads the helpers above.
if __FILE__ == $PROGRAM_NAME
  # Check the input file before validating env vars — a missing benchmark.json is the more
  # actionable failure (almost always upstream `bench.rb` didn't produce results).
  unless File.exist?(BENCHMARK_JSON)
    warn "Benchmark JSON file not found: #{BENCHMARK_JSON}"
    exit 1
  end

  SUITE_NAME = env!("BENCHMARK_SUITE_NAME")
  REPORT_MARKER = env!("BENCHER_REPORT_MARKER")
  env!("BENCHER_API_TOKEN")

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
      # Record the regression for the post-matrix report-regressions job rather than
      # filing the issue here: parallel matrix suites would otherwise race to create
      # duplicate issues and clobber each other's sections in the shared comment.
      # Use the un-sharded suite name so that job can combine a suite's shards into a
      # single section (shard_label keeps their ordering deterministic).
      File.write(
        REGRESSION_REPORT_JSON,
        JSON.generate(
          suite_name: ENV.fetch("BENCHMARK_SUITE_GROUP", SUITE_NAME),
          shard_label: ENV.fetch("BENCHMARK_SHARD_LABEL", ""),
          summary: benchmark_summary
        )
        warn "::warning::Bencher flagged a #{SUITE_NAME} regression on main (exit #{bencher_exit_code}). " \
             "The report-regressions job will file the issue. " \
             "See the Bencher dashboard and the workflow run: #{Github.run_url}"
      rescue StandardError => e # rubocop:disable Metrics/BlockNesting
        # The suite still fails (exit 1 below), so the regression is surfaced; but the
        # hand-off payload is gone, so report-regressions can't auto-file the issue.
        warn "::error::Bencher flagged a #{SUITE_NAME} regression on main but its report payload " \
             "could not be written (#{e.class}: #{e.message}); the issue will NOT be auto-filed — " \
             "investigate using GitHub run logs: #{Github.run_url}"
      end
      exit 1
    else
      warn "::error::Bencher exited #{bencher_exit_code} on main with no regression alert for #{SUITE_NAME}; " \
           "this indicates an operational failure (auth/API/network/CLI), not a performance regression. " \
           "Check the logs above."
      exit bencher_exit_code
    end
  end
end
