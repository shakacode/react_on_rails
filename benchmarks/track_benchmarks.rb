#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "time"

require_relative "lib/github"
require_relative "lib/github_cli"
require_relative "lib/regression_report"
require_relative "lib/bencher_report"
require_relative "lib/benchmark_table"

MAX_SAMPLE = "64"
# Per-measure t-test boundaries (the confidence level Bencher uses for its
# prediction interval). Tuned from a sweep of recent main-branch reports so fewer
# than 1/20 commits raise a false regression across all benchmarks: rps and p50
# individually need ~0.9995 / ~0.9999 to clear that bar. failed_pct stays at 0.95
# because healthy runs sit at ~0 with near-zero variance, so its boundary rarely
# matters.
# Bencher's t-test threshold is a prediction interval, so each one-sided boundary B
# gives a per-test false-positive rate of ~(1 - B):
# https://bencher.dev/docs/explanation/thresholds/
# Direction: :lower for "regression = drop" measures (rps), :upper for
# "regression = climb" measures (latency, failure rate).
# p90/p99/max are intentionally NOT tracked: their tail noise can't meet the 1/20
# target at any usable boundary. p90 stays in the summary table for visibility only.
THRESHOLDS = [
  ["rps", :lower, "0.9995"],
  ["p50_latency", :upper, "0.9999"],
  ["failed_pct", :upper, "0.95"]
].freeze

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
  # "_" is Bencher's sentinel for "no boundary on this side".
  lower, upper = direction == :lower ? [boundary, "_"] : ["_", boundary]
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
    "--format", "json",
    *THRESHOLDS.flat_map { |measure, direction, boundary| threshold_args(measure, direction, boundary) }
  ]
end

def run_bencher(branch, start_point_args)
  stdout, stderr, status = Open3.capture3(*bencher_args(branch, start_point_args))
  warn stderr unless stderr.empty?
  # Bencher prints the JSON report to stdout, including on a non-zero "alert" exit
  # (a real regression, which we still want to publish). An empty stdout means an
  # operational failure with no report, so clear any stale file rather than
  # persisting/posting garbage or leaving a previous attempt's report behind.
  if stdout.empty?
    FileUtils.rm_f(REPORT_JSON)
    report = nil
  else
    File.write(REPORT_JSON, stdout)
    # Parse defensively: an unexpected shape raises BencherReport::FormatError. Fail
    # the job loudly, but with a targeted ::error:: annotation instead of a raw Ruby
    # backtrace so the failure is triageable in CI logs. This covers both the initial
    # run and the start-point-hash retry, since both go through run_bencher.
    begin
      report = BencherReport.parse(stdout)
    rescue BencherReport::FormatError => e
      warn "::error::Bencher JSON report has an unexpected shape — re-verify against " \
           "benchmarks/spec/bencher_report_spec.rb before bumping the CLI pin. #{e.message}"
      exit 1
    end
    # Cosmetic-but-diagnostic: if the report lists benchmarks but no shared perf-link
    # context, EVERY name renders unlinked (likely a report-shape drift). Surface it as a
    # ::warning:: — not a failure — so it is noticed without breaking the job over a link.
    if report.perf_links_unavailable?
      Github.warning(
        "Bencher report listed benchmarks but no perf-link context " \
        "(project/branch/testbed uuid); benchmark names will render unlinked. Re-verify the " \
        "report shape against benchmarks/spec/bencher_perf_url_spec.rb before bumping the CLI pin."
      )
    end
  end
  [stderr, status.exitstatus, report]
end

def append_step_summary(markdown)
  File.open(ENV.fetch("GITHUB_STEP_SUMMARY"), "a") { |file| file.write(markdown) }
end

def post_report_to_summary(markdown)
  return if markdown.empty?

  append_step_summary("## #{SUITE_NAME} Bencher Report\n\n")
  append_step_summary(markdown)
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

  Github.warning(
    "Failed to delete #{failed} stale #{SUITE_NAME} Bencher report comment(s); " \
    "they may remain visible."
  )
end

def replace_pr_comments(markdown)
  return unless ENV.fetch("GITHUB_EVENT_NAME") == "pull_request"
  return if markdown.empty?

  body = "#{REPORT_MARKER}\n#{markdown}"
  # Capture cutoff before posting so the GC sweeps only pre-existing comments and
  # leaves the one this run just posted intact. If the post fails the GC is skipped
  # entirely and the prior run's comment stays visible.
  cutoff_ts = Time.now.utc.iso8601
  # Send the body over stdin (--body-file -) rather than as a CLI argument so a
  # large report can't hit the OS argument-length limit.
  posted = GithubCli.run(
    "gh", "pr", "comment", ENV.fetch("PR_NUMBER"), "--body-file", "-",
    error_message: "Failed to post #{SUITE_NAME} benchmark report comment",
    stdin_data: body
  )

  if posted
    delete_stale_report_comments(before: cutoff_ts)
  else
    Github.warning("Failed to post #{SUITE_NAME} benchmark report comment; keeping prior comments in place.")
  end
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

  BenchmarkTable.new(title: "#{suite_name} Benchmark Summary", rows: rows, report: report).to_markdown
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
            RegressionReport::SUMMARY => handoff_summary
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
