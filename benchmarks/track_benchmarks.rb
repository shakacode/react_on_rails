#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/track_benchmarks"

BENCHMARK_JSON = TrackBenchmarks::Config::BENCHMARK_JSON
REPORT_JSON = TrackBenchmarks::Config::REPORT_JSON
DISPLAY_JSON = TrackBenchmarks::Config::DISPLAY_JSON
CANDIDATE_REPORT_JSON = TrackBenchmarks::Config::CANDIDATE_REPORT_JSON
CONFIRMED_REPORT_JSON = TrackBenchmarks::Config::CONFIRMED_REPORT_JSON
CANDIDATE_INPUT_DIR = TrackBenchmarks::Config::CANDIDATE_INPUT_DIR

def env!(key)
  TrackBenchmarks::Config.env!(key)
end

def confirmation_mode?
  TrackBenchmarks::BranchArgs.confirmation_mode?
end

def slugify(value)
  TrackBenchmarks::BranchArgs.slugify(value)
end

def confirmation_branch(run_id, suite_name)
  TrackBenchmarks::BranchArgs.confirmation_branch(run_id, suite_name)
end

def confirmation_start_point_args
  TrackBenchmarks::BranchArgs.confirmation_start_point_args
end

def branch_and_start_point_args
  TrackBenchmarks::BranchArgs.branch_and_start_point_args
end

def run_bencher!(branch, start_point_args)
  TrackBenchmarks::BencherRun.run_bencher!(bencher_runner, branch, start_point_args)
end

def normalized_bencher_exit_code(exit_code, report)
  TrackBenchmarks::BencherRun.normalized_exit_code(exit_code, report)
end

def append_step_summary(markdown)
  TrackBenchmarks::Summary.append_step_summary(markdown)
end

def post_report_to_summary(markdown, suite_name = nil)
  suite_name ||= Object.const_get(:SUITE_NAME) if Object.const_defined?(:SUITE_NAME)
  raise ArgumentError, "suite_name is required outside script execution" unless suite_name

  TrackBenchmarks::Summary.post_report_to_summary(markdown, suite_name)
end

def bencher_runner
  @bencher_runner ||= BencherRunner.new(benchmark_json: BENCHMARK_JSON, report_json: REPORT_JSON)
end

def replace_pr_comments(markdown)
  TrackBenchmarks::PrComments.replace(markdown) { pr_report_poster }
end

def pr_report_poster
  # Keep this behind replace_pr_comments so non-PR runs never require PR env vars.
  @pr_report_poster ||= PrReportPoster.from_env(suite_name: SUITE_NAME, marker: REPORT_MARKER)
end

def display_rows
  TrackBenchmarks::Summary.display_rows(DISPLAY_JSON)
end

def rendered_report(report, suite_name)
  TrackBenchmarks::Summary.rendered_report(report, suite_name, DISPLAY_JSON)
end

def regression_handoff_summary(report_markdown)
  TrackBenchmarks::Summary.regression_handoff_summary(report_markdown)
end

def regression?(report)
  TrackBenchmarks::Summary.regression?(report)
end

def regressed_benchmark_names(report)
  TrackBenchmarks::Summary.regressed_benchmark_names(report)
end

def regressed_alert_pairs(report)
  TrackBenchmarks::Summary.regressed_alert_pairs(report)
end

def load_candidate(dir)
  TrackBenchmarks::Confirmation.load_candidate(dir)
end

def confirmation_outcome(report, bencher_exit_code, candidate_alerts)
  TrackBenchmarks::Confirmation.outcome(report, bencher_exit_code, candidate_alerts)
end

def describe_alert(alert)
  TrackBenchmarks::Confirmation.describe_alert(alert)
end

def retry_without_start_point_hash?(stderr, exit_code, report)
  TrackBenchmarks::BencherRun.retry_without_start_point_hash?(stderr, exit_code, report)
end

def main_push?
  TrackBenchmarks::RegressionPayloads.main_push?
end

def report_main_push_candidate(report, report_markdown, bencher_exit_code, suite_name)
  TrackBenchmarks::RegressionPayloads.report_main_push_candidate(report, report_markdown, bencher_exit_code, suite_name)
end

def write_candidate(report, report_markdown, suite_name)
  TrackBenchmarks::RegressionPayloads.write_candidate(report, report_markdown, suite_name)
end

def write_confirmed(confirmed_alerts, first_run_summary, confirmation_markdown, suite_name)
  TrackBenchmarks::RegressionPayloads.write_confirmed(
    confirmed_alerts,
    first_run_summary,
    confirmation_markdown,
    suite_name
  )
end

def append_confirmation_summary(status, confirmed_alerts, suite_name)
  TrackBenchmarks::Confirmation.append_summary(status, confirmed_alerts, suite_name)
end

def run_confirmation(report, bencher_exit_code, confirmation_markdown, suite_name)
  TrackBenchmarks::Confirmation.run(report, bencher_exit_code, confirmation_markdown, suite_name)
end

def finish_confirmation(status, confirmed_alerts, suite_name)
  TrackBenchmarks::Confirmation.finish(status, confirmed_alerts, suite_name)
end

# Only run the benchmark tracking when invoked as a script; `require`-ing the file
# (e.g. from specs) just loads the compatibility helpers above.
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

  TrackBenchmarks::Cli.new(suite_name: SUITE_NAME, report_marker: REPORT_MARKER).run
end
