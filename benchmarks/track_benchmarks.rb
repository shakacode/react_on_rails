#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

require_relative "lib/github"
require_relative "lib/github_cli"
require_relative "lib/regression_report"
require_relative "lib/bencher_runner"
require_relative "lib/bencher_report"
require_relative "lib/benchmark_table"
require_relative "lib/pr_report_poster"

MAX_SAMPLE = BencherRunner::MAX_SAMPLE
THRESHOLDS = BencherRunner::THRESHOLDS

def env!(key)
  ENV.fetch(key) do
    warn "#{key} is required"
    exit 1
  end
end

BENCHMARK_JSON = ENV.fetch("BENCHMARK_JSON", "bench_results/benchmark.json")
REPORT_JSON = ENV.fetch("BENCHER_REPORT_JSON", "bench_results/bencher_report.json")
# Written by the bench scripts (BmfCollector#write_display_json); carries the
# summary-table columns Bencher never sees (p90, raw Status), keyed by the same
# canonical name as the report so the join is exact.
# NOTE: benchmark_config.rb independently defines DISPLAY_JSON with the same default
# path; the bench scripts and this tracker run as separate programs, so keep them in sync.
DISPLAY_JSON = ENV.fetch("BENCHMARK_DISPLAY_JSON", "bench_results/benchmark_display.json")
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

def threshold_args(measure, direction, boundary)
  bencher_runner.threshold_args(measure, direction, boundary)
end

def bencher_args(branch, start_point_args)
  bencher_runner.args(branch, start_point_args)
end

def run_bencher(branch, start_point_args)
  bencher_runner.run(branch, start_point_args)
end

def append_step_summary(markdown)
  File.open(ENV.fetch("GITHUB_STEP_SUMMARY"), "a") { |file| file.write(markdown) }
end

def post_report_to_summary(markdown)
  return if markdown.empty?

  append_step_summary("## #{SUITE_NAME} Bencher Report\n\n")
  append_step_summary(markdown)
end

def bencher_runner
  @bencher_runner ||= BencherRunner.new(benchmark_json: BENCHMARK_JSON, report_json: REPORT_JSON)
end

def stale_comment_ids(before:)
  pr_report_poster.stale_comment_ids(before:)
end

def delete_stale_report_comments(before:)
  pr_report_poster.delete_stale_comments(before:)
end

def replace_pr_comments(markdown)
  return unless ENV.fetch("GITHUB_EVENT_NAME") == "pull_request"

  pr_report_poster.replace(markdown)
end

def pr_report_poster
  @pr_report_poster ||= PrReportPoster.from_env(suite_name: SUITE_NAME, marker: REPORT_MARKER)
end

# The display rows written by the bench scripts (BmfCollector#write_display_json).
def display_rows
  return [] unless File.exist?(DISPLAY_JSON)

  parsed = JSON.parse(File.read(DISPLAY_JSON))
  unless parsed.is_a?(Array)
    # Mirror the write side (BmfCollector#write_display_json warns on a non-array
    # sidecar). Without this the table would silently disappear on a contract break,
    # and a main regression hand-off could store an empty summary with no diagnostic.
    Github.warning("#{DISPLAY_JSON} is not a JSON array (got #{parsed.class}); skipping the summary table")
    return []
  end

  parsed
rescue JSON::ParserError => e
  Github.warning("Could not parse #{DISPLAY_JSON} (#{e.message}); skipping the summary table")
  []
end

# The Markdown summary table: display rows joined with the Bencher report by
# benchmark name, with tracked values highlighted by significance. Empty string
# when there are no rows (nothing to post). suite_name is passed in rather than read
# from the SUITE_NAME constant (which is only assigned inside the
# __FILE__ == $PROGRAM_NAME block) so this stays callable from specs/require-only
# contexts without raising NameError.
def rendered_report(report, suite_name)
  rows = display_rows
  return "" if rows.empty?

  BenchmarkTable.new(title: "#{suite_name} Benchmark Summary", rows:, report:).to_markdown
end

# Body for the report-regressions hand-off. Normally the rendered table; but if the
# display sidecar was missing/corrupt rendered_report returned "" — don't hand off an
# empty-bodied regression issue. Substitute a run-URL pointer (and shout via ::error::)
# so report-regressions still files something actionable.
def regression_handoff_summary(report_markdown)
  return report_markdown unless report_markdown.empty?

  warn "::error::Bencher flagged a regression on main but the summary table could not be " \
       "rendered (the display sidecar was missing or invalid); the auto-filed issue will link " \
       "the run instead of showing the table. Investigate: #{Github.run_url}"
  "_Summary table unavailable (the benchmark display sidecar was missing or empty). " \
    "See the Bencher dashboard and the workflow run: #{Github.run_url}_"
end

# A real performance regression: Bencher raised at least one active alert in the
# JSON report. Deterministic — no stderr grepping. nil report (operational failure
# with no parseable stdout) is not a regression.
def regression?(report)
  report&.regression? || false
end

# The names of the benchmarks Bencher raised an active alert for, deduped. Read from
# the same alerts[] as #regression?, so it is exactly the set of rows the summary
# table flags 🔴. Handed off to report-regressions so it can decide which benchmarks
# regressed without re-parsing the rendered table. Empty when there is no report or no
# alert carried a benchmark name.
def regressed_benchmark_names(report)
  return [] unless report

  report.alerts.filter_map(&:benchmark).uniq
end

# A missing start-point baseline (operational, not a regression): retrying without
# the start-point hash falls back to the latest baseline. The no-regression guard is
# load-bearing — a real regression must not be silently re-run against a different
# baseline. The stderr match detects the operational error, not an alert.
def retry_without_start_point_hash?(stderr, exit_code, report)
  exit_code != 0 &&
    stderr.match?(/Head Version.*not found/) &&
    !regression?(report)
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
  stderr, bencher_exit_code, report = run_bencher(branch, start_point_args)

  if retry_without_start_point_hash?(stderr, bencher_exit_code, report)
    retry_args = start_point_args.dup
    if (hash_arg_index = retry_args.index("--start-point-hash"))
      retry_args.slice!(hash_arg_index, 2)
    end
    puts "Start-point hash not found in Bencher; retrying without --start-point-hash"
    Github.warning("Start-point hash not found in Bencher; falling back to latest baseline for comparison")
    # The retry's stderr is unused: regression classification reads the JSON report,
    # and this path only triggers when the first run had no regression.
    _retry_stderr, bencher_exit_code, report = run_bencher(branch, retry_args)
  end

  # Build the Markdown summary table once; the same body feeds the job summary, the
  # PR comment, and (on a main regression) the report-regressions hand-off.
  report_markdown = rendered_report(report, SUITE_NAME)
  post_report_to_summary(report_markdown)
  pr_event = ENV.fetch("GITHUB_EVENT_NAME") == "pull_request"
  if report.nil? && pr_event
    # A nil report means Bencher produced no parseable output (operational failure). On
    # a PR, replacing the comment now would delete the previous run's real report and
    # make an auth/API/network failure look like a normal un-highlighted summary, while
    # the job still exits 0. Keep the prior comment intact and surface the failure
    # instead. (post_report_to_summary above is per-run and clobbers nothing.)
    Github.warning(
      "Bencher produced no report for #{SUITE_NAME} (operational failure); " \
      "keeping the previous PR comment intact instead of overwriting it with an un-highlighted table."
    )
  elsif pr_event && regression?(report) && report_markdown.empty?
    # A real regression but no table to render (display sidecar missing/empty). Don't
    # leave the stale PR comment looking unchanged — post the run-URL fallback (which
    # also emits ::error::) so the regression is visible in the PR thread, mirroring the
    # main-push report-regressions hand-off.
    replace_pr_comments(regression_handoff_summary(report_markdown))
  else
    replace_pr_comments(report_markdown)
  end

  if main_push? && bencher_exit_code != 0
    if regression?(report)
      # Record the regression for the post-matrix report-regressions job rather than
      # filing the issue here: parallel matrix suites would otherwise race to create
      # duplicate issues and clobber each other's sections in the shared comment.
      # Use the un-sharded suite name so that job can combine a suite's shards into a
      # single section (shard_label keeps their ordering deterministic).
      handoff_summary = regression_handoff_summary(report_markdown)
      begin
        File.write(
          REGRESSION_REPORT_JSON,
          JSON.generate(
            RegressionReport::SUITE_NAME => ENV.fetch("BENCHMARK_SUITE_GROUP", SUITE_NAME),
            RegressionReport::SHARD_LABEL => ENV.fetch("BENCHMARK_SHARD_LABEL", ""),
            RegressionReport::SUMMARY => handoff_summary,
            RegressionReport::REGRESSED_BENCHMARKS => regressed_benchmark_names(report)
          )
        )
        Github.warning(
          "Bencher flagged a #{SUITE_NAME} regression on main (exit #{bencher_exit_code}). " \
          "The report-regressions job will file the issue. " \
          "See the Bencher dashboard and the workflow run: #{Github.run_url}"
        )
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
