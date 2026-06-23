# frozen_string_literal: true

module TrackBenchmarks
  # Report parsing, table rendering, and GitHub step-summary helpers.
  module Summary
    module_function

    def append_step_summary(markdown)
      File.open(ENV.fetch("GITHUB_STEP_SUMMARY"), "a") { |file| file.write(markdown) }
    end

    def post_report_to_summary(markdown, suite_name)
      return if markdown.empty?

      append_step_summary("## #{suite_name} Bencher Report\n\n")
      append_step_summary(markdown)
    end

    # The display rows written by the bench scripts (BmfCollector#write_display_json).
    def display_rows(display_json)
      return [] unless File.exist?(display_json)

      parsed = JSON.parse(File.read(display_json))
      unless parsed.is_a?(Array)
        # Mirror the write side (BmfCollector#write_display_json warns on a non-array
        # sidecar). Without this the table would silently disappear on a contract break,
        # and a main regression hand-off could store an empty summary with no diagnostic.
        Github.warning("#{display_json} is not a JSON array (got #{parsed.class}); skipping the summary table")
        return []
      end

      parsed
    rescue JSON::ParserError => e
      Github.warning("Could not parse #{display_json} (#{e.message}); skipping the summary table")
      []
    rescue SystemCallError => e
      Github.warning("Could not read #{display_json} (#{e.class}: #{e.message}); skipping the summary table")
      []
    end

    # The Markdown summary table: display rows joined with the Bencher report by
    # benchmark name, with tracked values highlighted by significance. Empty string
    # when there are no rows (nothing to post).
    def rendered_report(report, suite_name, display_json)
      rows = display_rows(display_json)
      return "" if rows.empty?

      BenchmarkTable.new(title: "#{suite_name} Benchmark Summary", rows:, report:).to_markdown
    end

    # Body for the report-regressions hand-off. Normally the rendered table; but if the
    # display sidecar was missing/corrupt rendered_report returned "" — don't hand off an
    # empty-bodied regression issue. Substitute a run-URL pointer (and shout via ::error::)
    # so report-regressions still files something actionable.
    def regression_handoff_summary(report_markdown, failure_context: "on main")
      return report_markdown unless report_markdown.empty?

      run_url = Github.run_url
      warn "::error::Bencher flagged a regression #{failure_context} but the summary table could not be " \
           "rendered (the display sidecar was missing or invalid); the auto-filed issue will link " \
           "the run instead of showing the table. Investigate: #{run_url}"
      "_Summary table unavailable (the benchmark display sidecar was missing or empty). " \
        "See the Bencher dashboard and the workflow run: #{run_url}_"
    end

    # A real performance regression: Bencher raised at least one active alert in the
    # JSON report. Deterministic — no stderr grepping. nil report (operational failure
    # with no parseable stdout) is not a regression.
    def regression?(report)
      report&.regression? || false
    end

    # The names of the benchmarks Bencher raised an active alert for, deduped. Read from
    # the same alerts[] as #regression?, so it is exactly the set of rows the summary
    # table flags red. Handed off to report-regressions so it can decide which benchmarks
    # regressed without re-parsing the rendered table. Empty when there is no report or no
    # alert carried a benchmark name.
    def regressed_benchmark_names(report)
      return [] unless report

      report.alerts.filter_map(&:benchmark).uniq
    end

    # The structured benchmark+measure pairs Bencher raised an active alert for, deduped.
    # Read from the same alerts[] as #regression?/#regressed_benchmark_names. Handed off in
    # the candidate so a confirmation rerun can require the SAME pair to re-alert (not just
    # any alert in the suite). An alert with no benchmark name is dropped — it can't be
    # matched. measure may be nil; the matcher falls back to name-only for those.
    def regressed_alert_pairs(report)
      return [] unless report

      report.alerts
            .select(&:benchmark)
            .map { |alert| RegressionReport.alert(alert.benchmark, alert.measure) }
            .uniq
    end
  end
end
