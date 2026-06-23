# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "spec_helper"
require_relative "../track_benchmarks"
require_relative "../lib/bmf_helpers"

# track_benchmarks.rb runs its tracking flow only under `if __FILE__ == $PROGRAM_NAME`,
# so requiring it just loads the helpers. These pin the classification that decides
# whether a Bencher run is a real regression vs a missing-baseline retry — now read
# from the JSON report's alerts[] rather than by grepping stderr. The two are
# mutually exclusive by design: an alert must never trigger a start-point-hash retry,
# or a real regression would be silently re-measured against the wrong baseline.
RSpec.describe "track_benchmarks" do
  include BenchmarkEnvHelper

  def result(name, measures)
    { "benchmark" => { "name" => name }, "measures" => measures }
  end

  def rps_measure(value: 80.0)
    {
      "measure" => { "slug" => "rps", "name" => "rps" },
      "metric" => { "value" => value },
      "boundary" => { "baseline" => 100.0, "lower_limit" => 90.0, "upper_limit" => nil }
    }
  end

  def p50_measure(value: 7.0)
    {
      "measure" => { "slug" => "p50-latency", "name" => "p50_latency" },
      "metric" => { "value" => value },
      "boundary" => { "baseline" => 5.0, "lower_limit" => nil, "upper_limit" => 6.0 }
    }
  end

  def active_alert(benchmark: "/x", measure: "rps", limit: "lower")
    {
      "benchmark" => { "name" => benchmark },
      "threshold" => { "measure" => { "slug" => measure } },
      "metric" => { "value" => 1.0 },
      "limit" => limit,
      "status" => "active"
    }
  end

  def report_with_alert
    BencherReport.parse(
      JSON.generate(
        "results" => [[result("/x", [rps_measure])]],
        "alerts" => [active_alert]
      )
    )
  end

  def report_without_alert
    BencherReport.parse(JSON.generate("results" => [], "alerts" => []))
  end

  describe "#regression?" do
    it "is true when the report has an active alert" do
      expect(regression?(report_with_alert)).to be(true)
    end

    it "is false when the report has no active alert" do
      expect(regression?(report_without_alert)).to be(false)
    end

    it "is false when there is no report (operational failure, no stdout to parse)" do
      expect(regression?(nil)).to be(false)
    end
  end

  describe "#regressed_benchmark_names" do
    it "returns the deduped benchmark names from active alerts" do
      report = BencherReport.parse(
        JSON.generate(
          "results" => [[
            result("/posts_page: Pro", [rps_measure, p50_measure]),
            result("/other: Pro", [rps_measure])
          ]],
          "alerts" => [
            active_alert(benchmark: "/posts_page: Pro"),
            active_alert(benchmark: "/posts_page: Pro", measure: "p50-latency", limit: "upper"),
            active_alert(benchmark: "/other: Pro")
          ]
        )
      )
      expect(regressed_benchmark_names(report)).to contain_exactly("/posts_page: Pro", "/other: Pro")
    end

    it "is empty when there is no report" do
      expect(regressed_benchmark_names(nil)).to eq([])
    end

    it "is empty when there are no active alerts" do
      expect(regressed_benchmark_names(report_without_alert)).to eq([])
    end

    it "ignores non-active alerts (dismissed/silenced never count as regressions)" do
      report = BencherReport.parse(
        JSON.generate(
          "results" => [],
          "alerts" => [{ "benchmark" => { "name" => "/x: Pro" }, "status" => "dismissed" }]
        )
      )
      expect(regressed_benchmark_names(report)).to eq([])
    end
  end

  describe "#retry_without_start_point_hash?" do
    it "is true when the start-point head version is missing and there is no regression" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 1, report_without_alert)).to be(true)
    end

    it "is true when the head version is missing and no report was produced" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 1, nil)).to be(true)
    end

    it "is false when the report has an active alert (must not retry a real regression)" do
      report = report_with_alert
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 1, report)).to be(false)
      expect(regression?(report)).to be(true)
    end

    it "is false on success and for unrelated non-zero failures" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 0, report_without_alert)).to be(false)
      expect(retry_without_start_point_hash?("some other error", 1, report_without_alert)).to be(false)
    end
  end

  describe "#replace_pr_comments" do
    it "does not require CI event env outside pull requests" do
      with_env("GITHUB_EVENT_NAME" => nil) do
        expect(PrReportPoster).not_to receive(:from_env)

        expect { replace_pr_comments("report") }.not_to raise_error
      end
    end

    it "does not require PR comment env for an empty pull request report" do
      with_env("GITHUB_EVENT_NAME" => "pull_request") do
        expect(PrReportPoster).not_to receive(:from_env)

        expect { replace_pr_comments("") }.not_to raise_error
      end
    end
  end

  describe "#run_bencher!" do
    it "formats benchmark report persistence failures as GitHub Actions errors" do
      runner = instance_double(BencherRunner)
      allow(self).to receive(:bencher_runner).and_return(runner)
      allow(runner).to receive(:run).and_raise(BencherRunner::PersistenceError, "No space")

      expect do
        run_bencher!("branch", [])
      end.to(
        output(/::error::Benchmark report persistence failed: No space/).to_stderr
          .and(raise_error(SystemExit) { |e| expect(e.status).to eq(1) })
      )
    end

    it "formats Bencher report parse failures as GitHub Actions errors" do
      runner = instance_double(BencherRunner)
      allow(self).to receive(:bencher_runner).and_return(runner)
      allow(runner).to receive(:run).and_raise(BencherRunner::ReportParseError, "unexpected shape")

      expect do
        run_bencher!("branch", [])
      end.to(
        output(/::error::unexpected shape/).to_stderr
          .and(raise_error(SystemExit) { |e| expect(e.status).to eq(1) })
      )
    end

    it "does not relabel unexpected runtime failures as report persistence errors" do
      runner = instance_double(BencherRunner)
      allow(self).to receive(:bencher_runner).and_return(runner)
      allow(runner).to receive(:run).and_raise(RuntimeError, "parser bug")

      expect do
        run_bencher!("branch", [])
      end.to raise_error(RuntimeError, "parser bug")
    end
  end

  # Confirmation mode (BENCHMARK_MODE=confirm): a fresh-runner rerun of a main-push
  # candidate. These pin the synthetic-branch/reset-baseline targeting, the structured
  # alert pairs handed off to the confirmation, and the confirmed/cleared/inconclusive
  # classification that decides whether an issue is filed.
  describe "confirmation mode" do
    around do |example|
      snapshot = ENV.to_h
      example.run
    ensure
      ENV.replace(snapshot)
    end

    describe "#slugify / #confirmation_branch" do
      it "builds a branch-safe, never-main name unique per run and suite/shard" do
        expect(slugify("Pro (shard 1/2)")).to eq("pro-shard-1-2")
        expect(confirmation_branch("12345", "Pro (shard 1/2)")).to eq("confirm-main-12345-pro-shard-1-2")
      end
    end

    describe "#branch_and_start_point_args" do
      it "targets a throwaway branch and re-tests against main without polluting its series" do
        ENV["BENCHMARK_MODE"] = "confirm"
        ENV["GITHUB_RUN_ID"] = "777"
        ENV["BENCHMARK_SUITE_NAME"] = "Core"

        branch, start_point_args = branch_and_start_point_args
        expect(branch).to eq("confirm-main-777-core")
        expect(branch).not_to eq("main")
        expect(start_point_args).to eq(
          %w[--start-point main --start-point-clone-thresholds --start-point-reset]
        )
      end
    end

    describe "#regressed_alert_pairs" do
      it "returns deduped benchmark+measure pairs from active alerts, dropping nameless ones" do
        report = BencherReport.parse(
          JSON.generate(
            "results" => [[result("/x: Pro", [rps_measure])]],
            "alerts" => [
              active_alert(benchmark: "/x: Pro"),
              active_alert(benchmark: "/x: Pro"),
              { "threshold" => { "measure" => { "slug" => "rps" } }, "status" => "active" }
            ]
          )
        )
        expect(regressed_alert_pairs(report)).to eq([{ "benchmark" => "/x: Pro", "measure" => "rps" }])
      end

      it "preserves benchmark-only fallback pairs when Bencher omits the alert measure slug" do
        measureless_alert = active_alert(benchmark: "/x: Pro")
        measureless_alert["threshold"] = {}
        report = BencherReport.parse(
          JSON.generate(
            "results" => [[result("/x: Pro", [rps_measure])]],
            "alerts" => [measureless_alert]
          )
        )

        expect(regressed_alert_pairs(report)).to eq([{ "benchmark" => "/x: Pro", "measure" => nil }])
      end
    end

    describe "#load_candidate" do
      def write_candidate(dir, payload)
        artifact_dir = File.join(dir, "candidate")
        FileUtils.mkdir_p(artifact_dir)
        File.write(
          File.join(artifact_dir, RegressionReport::CANDIDATE_FILENAME),
          JSON.generate(payload)
        )
      end

      it "returns alerts and summary for a valid candidate" do
        Dir.mktmpdir do |dir|
          alerts = [{ "benchmark" => "/x: Pro", "measure" => "rps" }]
          write_candidate(dir, RegressionReport::ALERTS => alerts, RegressionReport::SUMMARY => "first run")

          expect(load_candidate(dir)).to eq([alerts, "first run"])
        end
      end

      it "treats a missing candidate as inconclusive" do
        Dir.mktmpdir do |dir|
          result = nil
          expect { result = load_candidate(dir) }
            .to output(/::error::No confirmation candidate/).to_stderr

          expect(result).to eq([nil, ""])
        end
      end

      it "treats multiple candidates as inconclusive instead of choosing one arbitrarily" do
        Dir.mktmpdir do |dir|
          first = File.join(dir, "first")
          second = File.join(dir, "second")
          FileUtils.mkdir_p(first)
          FileUtils.mkdir_p(second)
          File.write(
            File.join(first, RegressionReport::CANDIDATE_FILENAME),
            JSON.generate(RegressionReport::ALERTS => [])
          )
          File.write(
            File.join(second, RegressionReport::CANDIDATE_FILENAME),
            JSON.generate(RegressionReport::ALERTS => [{ "benchmark" => "/x: Pro", "measure" => "rps" }])
          )

          result = nil
          expect { result = load_candidate(dir) }
            .to output(/::error::Multiple confirmation candidates/).to_stderr

          expect(result).to eq([nil, ""])
        end
      end

      it "keeps the rescue message safe when candidate discovery fails before a path is selected" do
        allow(Dir).to receive(:glob).and_raise(Errno::EACCES)

        result = nil
        expect { result = load_candidate("candidate-dir") }
          .to output(%r{::error::Could not read confirmation candidate candidate-dir/\*\*/}).to_stderr

        expect(result).to eq([nil, ""])
      end

      it "treats missing alerts as inconclusive" do
        Dir.mktmpdir do |dir|
          write_candidate(dir, RegressionReport::SUMMARY => "first run")

          expect(load_candidate(dir)).to eq([nil, "first run"])
        end
      end

      it "treats non-array alerts as inconclusive" do
        Dir.mktmpdir do |dir|
          write_candidate(dir, RegressionReport::ALERTS => "not an array", RegressionReport::SUMMARY => "first run")

          expect(load_candidate(dir)).to eq([nil, "first run"])
        end
      end

      it "treats empty alerts as inconclusive" do
        Dir.mktmpdir do |dir|
          write_candidate(dir, RegressionReport::ALERTS => [], RegressionReport::SUMMARY => "first run")

          expect(load_candidate(dir)).to eq([nil, "first run"])
        end
      end
    end

    describe "#confirmation_outcome" do
      def pair(benchmark, measure)
        { "benchmark" => benchmark, "measure" => measure }
      end

      it "is inconclusive when there is no parseable report" do
        expect(confirmation_outcome(nil, 1, [pair("/x: Pro", "rps")])).to eq([:inconclusive, []])
      end

      it "is inconclusive on a non-zero exit with no alert (operational failure)" do
        expect(confirmation_outcome(report_without_alert, 1, [pair("/x: Pro", "rps")])).to eq([:inconclusive, []])
      end

      it "is confirmed when the same benchmark+measure re-alerts" do
        report = BencherReport.parse(
          JSON.generate(
            "results" => [[result("/x: Pro", [rps_measure])]],
            "alerts" => [active_alert(benchmark: "/x: Pro")]
          )
        )
        status, confirmed = confirmation_outcome(report, 1, [pair("/x: Pro", "rps")])
        expect(status).to eq(:confirmed)
        expect(confirmed).to eq([pair("/x: Pro", "rps")])
      end

      it "is cleared when a different benchmark/measure alerts than the candidate's" do
        report = BencherReport.parse(
          JSON.generate(
            "results" => [[result("/y: Pro", [rps_measure])]],
            "alerts" => [active_alert(benchmark: "/y: Pro")]
          )
        )
        expect(confirmation_outcome(report, 1, [pair("/x: Pro", "rps")])).to eq([:cleared, []])
      end

      it "ignores a candidate alert on a temporarily-ignored benchmark" do
        # The production list is empty (no active suppressions); stub a sample entry so
        # this example keeps pinning the ignore handling in the confirmation outcome.
        ignored = "/ignored: Pro"
        stub_const("RegressionReport::IGNORED_REGRESSION_BENCHMARKS", [ignored])
        report = BencherReport.parse(
          JSON.generate(
            "results" => [[result(ignored, [rps_measure])]],
            "alerts" => [active_alert(benchmark: ignored)]
          )
        )
        expect(confirmation_outcome(report, 1, [pair(ignored, "rps")])).to eq([:cleared, []])
      end
    end
  end

  describe "#normalized_bencher_exit_code" do
    it "normalizes an alert exit to success after retry handling when every active alert is stale" do
      report = BencherReport.parse(
        JSON.generate(
          "results" => [[result("/x", [rps_measure(value: 95.0)])]],
          "alerts" => [active_alert]
        )
      )

      exit_code = nil
      expect { exit_code = normalized_bencher_exit_code(1, report) }
        .to output(/::notice::Bencher reported only stale active alert/).to_stdout

      expect(exit_code).to eq(0)
    end
  end

  describe "GitHub warning annotations" do
    it "writes warning workflow commands to stdout, not stderr" do
      expect { Github.warning("benchmark annotation") }
        .to output("::warning::benchmark annotation\n").to_stdout
        .and output("").to_stderr
    end

    it "escapes workflow command data so multiline messages stay in one annotation" do
      expect { Github.warning("first line\n100% reproducible\r\nsecond line") }
        .to output("::warning::first line%0A100%25 reproducible%0D%0Asecond line\n").to_stdout
    end

    it "emits display sidecar warnings to stdout so GitHub Actions annotates them" do
      allow(File).to receive(:exist?).with(DISPLAY_JSON).and_return(true)
      allow(File).to receive(:read).with(DISPLAY_JSON).and_return(JSON.generate({ "not" => "an array" }))

      rows = nil
      warning_pattern = /::warning::#{Regexp.escape(DISPLAY_JSON)} is not a JSON array/o
      expect { rows = display_rows }
        .to output(warning_pattern).to_stdout

      expect(rows).to eq([])
    end
  end

  # On a main regression the rendered table feeds the report-regressions hand-off. If
  # the display sidecar was missing/corrupt the table is empty, and an empty-bodied
  # issue is useless — the hand-off must substitute a run-URL pointer instead.
  describe "#regression_handoff_summary" do
    it "returns the rendered table unchanged when it is non-empty" do
      expect(regression_handoff_summary("### Summary\n| a |")).to eq("### Summary\n| a |")
    end

    it "substitutes a run-URL pointer when the table is empty" do
      allow(Github).to receive(:run_url).and_return("https://github.test/run/1")
      summary = regression_handoff_summary("")
      expect(summary).not_to be_empty
      expect(summary).to include("https://github.test/run/1")
    end
  end

  # A threshold on a measure that no metric reports is a silent no-op, so every tracked
  # measure must be among what BmfCollector emits. The reverse is NOT exact equality:
  # BmfCollector also emits p90_latency boundary-less (recorded for a summary baseline but
  # deliberately absent from THRESHOLDS, so never alerted on).
  describe "tracked measures" do
    let(:emitted) do
      collector = BmfCollector.new
      collector.add(name: "x", rps: 1.0, p50: 1.0, p90: 1.0, status: "200=1")
      collector.to_bmf.fetch("x").keys
    end

    it "are all emitted by BmfCollector (so no threshold is a silent no-op)" do
      expect(emitted).to include(*BencherRunner::THRESHOLDS.map(&:first))
    end

    it "exclude p90_latency, which BmfCollector emits boundary-less (recorded but never alerted)" do
      expect(emitted).to include("p90_latency")
      expect(BencherRunner::THRESHOLDS.map(&:first)).not_to include("p90_latency")
    end
  end

  # The summary table's highlightable columns must stay in lockstep with the tracked
  # measures/sides Bencher is configured with, or a column would either be silently
  # un-highlightable or highlighted with the wrong direction. A column is "highlightable"
  # when it has a :direction; a column with a :measure but no :direction (p90_latency)
  # only shows a baseline delta and is never tagged.
  describe "summary table highlight columns" do
    # Tracked measures intentionally NOT shown as a table column: failed_pct is redundant
    # with the Status column (issue #3601 item 4) but stays in THRESHOLDS as an alerting
    # safety net. A measure listed here fires the build on a regression but renders only
    # via Status, not a highlighted cell — a deliberate trade, pinned so re-adding a column
    # (or dropping the threshold) is a conscious change.
    display_suppressed = %w[failed_pct].freeze

    it "use measures and directions that exist in THRESHOLDS" do
      thresholds = BencherRunner::THRESHOLDS.to_h { |measure, direction, _boundary| [measure, direction] }

      BenchmarkTable::COLUMNS.select { |col| col[:direction] }.each do |col|
        expect(thresholds).to include(col[:measure])
        expect(col[:direction]).to eq(thresholds[col[:measure]])
      end
    end

    # The reverse direction: every tracked measure must have a highlightable column —
    # except the deliberately display-suppressed ones — or an alert on it would fire but
    # render as an un-highlighted cell, invisible in the PR comment and regression hand-off.
    it "expose every tracked THRESHOLDS measure as a highlightable column, except suppressed ones" do
      highlightable = BenchmarkTable::COLUMNS.select { |col| col[:direction] }
                                             .to_h { |col| [col[:measure], col[:direction]] }

      BencherRunner::THRESHOLDS.each do |measure, direction, _boundary|
        if display_suppressed.include?(measure)
          expect(highlightable).not_to include(measure)
        else
          expect(highlightable).to include(measure)
          expect(highlightable[measure]).to eq(direction)
        end
      end
    end

    # p90_latency is a baseline-only column: it carries a :measure (so the table can show a
    # delta if Bencher supplies a baseline) but no :direction, and it must NOT be in
    # THRESHOLDS — it is sent boundary-less so it is recorded yet never alerted on.
    it "treat p90_latency as a baseline-only column, not a tracked threshold" do
      p90 = BenchmarkTable::COLUMNS.find { |col| col[:measure] == "p90_latency" }

      expect(p90).not_to be_nil
      expect(p90[:direction]).to be_nil
      expect(BencherRunner::THRESHOLDS.map(&:first)).not_to include("p90_latency")
    end
  end
end
