# frozen_string_literal: true

module TrackBenchmarks
  # Runtime orchestration for benchmarks/track_benchmarks.rb.
  class Cli
    def initialize(suite_name:, report_marker:)
      @suite_name = suite_name
      @report_marker = report_marker
    end

    def run
      branch, start_point_args = BranchArgs.branch_and_start_point_args
      bencher_result = BencherRun.run_bencher!(bencher_runner, branch, start_point_args)
      bencher_exit_code, report = retry_without_start_point_hash(branch, start_point_args, bencher_result)
      bencher_exit_code = BencherRun.normalized_exit_code(bencher_exit_code, report)

      # Build the Markdown summary table once; the same body feeds the job summary, the
      # PR comment, and the candidate/confirmation hand-offs.
      report_markdown = Summary.rendered_report(report, suite_name, Config::DISPLAY_JSON)
      Summary.post_report_to_summary(report_markdown, suite_name)

      if BranchArgs.confirmation_mode?
        # Fresh-runner rerun of a main-push candidate. Owns its own exit code (confirmed /
        # cleared / inconclusive) and never posts PR comments.
        Confirmation.run(report, bencher_exit_code, report_markdown, suite_name)
      else
        post_pull_request_report(report, report_markdown)

        if RegressionPayloads.main_push? && bencher_exit_code != 0
          RegressionPayloads.report_main_push_candidate(report, report_markdown, bencher_exit_code, suite_name)
        end
      end
    end

    private

    attr_reader :suite_name, :report_marker

    def bencher_runner
      @bencher_runner ||= BencherRunner.new(benchmark_json: Config::BENCHMARK_JSON, report_json: Config::REPORT_JSON)
    end

    def pr_report_poster
      # Keep this behind replace_pr_comments so non-PR runs never require PR env vars.
      @pr_report_poster ||= PrReportPoster.from_env(suite_name:, marker: report_marker)
    end

    def retry_without_start_point_hash(branch, start_point_args, bencher_result)
      stderr = bencher_result.stderr
      bencher_exit_code = bencher_result.exit_code
      report = bencher_result.report
      unless BencherRun.retry_without_start_point_hash?(stderr, bencher_exit_code, report)
        return [bencher_exit_code, report]
      end

      retry_args = BencherRun.without_start_point_hash(start_point_args)
      puts "Start-point hash not found in Bencher; retrying without --start-point-hash"
      Github.warning("Start-point hash not found in Bencher; falling back to latest baseline for comparison")
      # The retry's stderr is unused: regression classification reads the JSON report,
      # and this path only triggers when the first run had no regression.
      retry_result = BencherRun.run_bencher!(bencher_runner, branch, retry_args)
      # Intentionally leave retry_result.stderr unused here. BencherRunner#run has
      # already emitted it; only the exit code and parsed report affect the outcome.
      [retry_result.exit_code, retry_result.report]
    end

    def post_pull_request_report(report, report_markdown)
      pr_event = ENV.fetch("GITHUB_EVENT_NAME", nil) == "pull_request"
      if report.nil? && pr_event
        # A nil report means Bencher produced no parseable output (operational failure). On
        # a PR, replacing the comment now would delete the previous run's real report and
        # make an auth/API/network failure look like a normal un-highlighted summary, while
        # the job still exits 0. Keep the prior comment intact and surface the failure
        # instead. (post_report_to_summary above is per-run and clobbers nothing.)
        Github.warning(
          "Bencher produced no report for #{suite_name} (operational failure); " \
          "keeping the previous PR comment intact instead of overwriting it with an un-highlighted table."
        )
      elsif pr_event && Summary.regression?(report) && report_markdown.empty?
        # A real regression but no table to render (display sidecar missing/empty). Don't
        # leave the stale PR comment looking unchanged — post the run-URL fallback (which
        # also emits ::error::) so the regression is visible in the PR thread, mirroring the
        # main-push candidate hand-off.
        PrComments.replace(Summary.regression_handoff_summary(report_markdown)) { pr_report_poster }
      else
        PrComments.replace(report_markdown) { pr_report_poster }
      end
    end
  end
end
