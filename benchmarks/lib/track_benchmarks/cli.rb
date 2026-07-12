# frozen_string_literal: true

module TrackBenchmarks
  # Runtime orchestration for benchmarks/track_benchmarks.rb.
  class Cli
    def initialize(suite_name:, report_marker:, env: ENV)
      @suite_name = suite_name
      @report_marker = report_marker
      @env = env
    end

    def run
      plan = BranchArgs.run_plan(env:)
      run_baseline(plan)
      head_result = BencherRun.run_bencher!(
        head_runner, plan.head_branch, BranchArgs.head_start_point_args(plan.baseline_branch)
      )
      report = head_result.report
      # Sample confirmation must run before anything consumes the report: it can
      # downgrade alerts, which changes the summary highlighting, regression
      # detection, the candidate hand-off, and the normalized exit code below.
      apply_sample_confirmation(report)
      bencher_exit_code = BencherRun.normalized_exit_code(head_result.exit_code, report)

      # Build the Markdown summary table once; the same body feeds the job summary, the
      # PR comment, and the candidate/confirmation hand-offs.
      report_markdown = Summary.rendered_report(report, suite_name, Config::DISPLAY_JSON)
      Summary.post_report_to_summary(report_markdown, suite_name)

      if BranchArgs.confirmation_mode?(env:)
        # Fresh-runner rerun of a main-push candidate. Owns its own exit code (confirmed /
        # cleared / inconclusive) and never posts PR comments.
        Confirmation.run(report, bencher_exit_code, report_markdown, suite_name)
      else
        post_pull_request_report(report, report_markdown)

        if RegressionPayloads.main_push?(env:) && bencher_exit_code != 0
          RegressionPayloads.report_main_push_candidate(report, report_markdown, bencher_exit_code, suite_name)
        end
      end
    end

    private

    attr_reader :suite_name, :report_marker, :env

    # Join both phases' per-sample values (display sidecars) and let the report
    # downgrade boundary crossings that did not reproduce across samples (#4580).
    # Either sidecar missing sample data (single-sample runs, failed routes, older
    # base refs whose bench scripts predate sampling) skips confirmation entirely —
    # fail open to single-sample behavior.
    def apply_sample_confirmation(report)
      return unless report

      head_samples = Summary.samples_by_name(Config::DISPLAY_JSON)
      base_samples = Summary.samples_by_name(Config::BASELINE_DISPLAY_JSON)
      return if head_samples.empty? || base_samples.empty?

      report.apply_sample_confirmation!(head_samples:, base_samples:)
      return unless report.unconfirmed_alert?

      names = report.unconfirmed_alerts.map { |alert| "#{alert.benchmark} (#{alert.measure})" }.uniq
      Github.notice(
        "Sample confirmation downgraded #{report.unconfirmed_alerts.length} Bencher alert(s) whose " \
        "base/head samples overlap: #{names.join(', ')}"
      )
    end

    # Records the base ref's results (measured moments ago on THIS runner) as the
    # comparison baseline: a fresh series on a throwaway per-run branch. The baseline
    # run configures no thresholds, so it can never alert — any non-zero exit is an
    # operational failure (auth/API/network/CLI) and aborts before the head run could
    # submit a comparison against a baseline that was never recorded.
    def run_baseline(plan)
      result = BencherRun.run_bencher!(
        baseline_runner, plan.baseline_branch, BranchArgs.baseline_start_point_args
      )
      return if result.exit_code.zero?

      warn "::error::Bencher baseline upload for #{suite_name} failed (exit #{result.exit_code}); " \
           "cannot run the relative comparison without a same-runner baseline. Check the logs above."
      exit result.exit_code
    end

    def baseline_runner
      @baseline_runner ||= BencherRunner.new(
        benchmark_json: Config::BASELINE_BENCHMARK_JSON,
        report_json: Config::BASELINE_REPORT_JSON,
        mode: :relative_baseline
      )
    end

    def head_runner
      @head_runner ||= BencherRunner.new(
        benchmark_json: Config::BENCHMARK_JSON,
        report_json: Config::REPORT_JSON,
        mode: :relative_head
      )
    end

    def pr_report_poster
      # Keep this behind replace_pr_comments so non-PR runs never require PR env vars.
      @pr_report_poster ||= PrReportPoster.from_env(suite_name:, marker: report_marker)
    end

    def post_pull_request_report(report, report_markdown)
      event_name = env.fetch("GITHUB_EVENT_NAME", nil)
      return unless event_name == "pull_request"

      if report.nil?
        # A nil report means Bencher produced no parseable output (operational failure). On
        # a PR, replacing the comment now would delete the previous run's real report and
        # make an auth/API/network failure look like a normal un-highlighted summary, while
        # the job still exits 0. Keep the prior comment intact and surface the failure
        # instead. (post_report_to_summary above is per-run and clobbers nothing.)
        Github.warning(
          "Bencher produced no report for #{suite_name} (operational failure); " \
          "keeping the previous PR comment intact instead of overwriting it with an un-highlighted table."
        )
      elsif Summary.regression?(report) && report_markdown.empty?
        # A real regression but no table to render (display sidecar missing/empty). Don't
        # leave the stale PR comment looking unchanged — post the run-URL fallback (which
        # also emits ::error::) so the regression is visible in the PR thread, mirroring the
        # main-push candidate hand-off.
        PrComments.replace(Summary.regression_handoff_summary(report_markdown), event_name:) { pr_report_poster }
      else
        PrComments.replace(report_markdown, event_name:) { pr_report_poster }
      end
    end
  end
end
