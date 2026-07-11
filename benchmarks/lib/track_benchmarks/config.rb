# frozen_string_literal: true

module TrackBenchmarks
  # Paths and required environment helpers for the benchmark tracking script.
  module Config
    module_function

    BENCHMARK_JSON = ENV.fetch("BENCHMARK_JSON", "bench_results/benchmark.json")
    REPORT_JSON = ENV.fetch("BENCHER_REPORT_JSON", "bench_results/bencher_report.json")
    # The base ref's results from this runner's base benchmark phase — the comparison
    # baseline for relative continuous benchmarking. The workflow stashes them outside
    # the workspace (the head phase git-cleans it) and points this env var there.
    BASELINE_BENCHMARK_JSON = ENV.fetch("BENCHMARK_BASELINE_JSON", "bench_results_base/benchmark.json")
    BASELINE_REPORT_JSON = ENV.fetch("BENCHER_BASELINE_REPORT_JSON", "bench_results_base/bencher_report.json")
    # Written by the bench scripts (BmfCollector#write_display_json); carries the
    # summary-table columns Bencher never sees (p90, raw Status), keyed by the same
    # canonical name as the report so the join is exact.
    # NOTE: benchmark_config.rb independently defines DISPLAY_JSON with the same default
    # path; the bench scripts and this tracker run as separate programs, so keep them in sync.
    DISPLAY_JSON = ENV.fetch("BENCHMARK_DISPLAY_JSON", "bench_results/benchmark_display.json")
    # Initial-run hand-off: a non-fatal candidate written when Bencher alerts on main.
    CANDIDATE_REPORT_JSON = File.join("bench_results", RegressionReport::CANDIDATE_FILENAME)
    # Confirmation-run hand-off: written only when the candidate's alert(s) re-alert.
    CONFIRMED_REPORT_JSON = File.join("bench_results", RegressionReport::CONFIRMED_FILENAME)
    # Directory the first-run candidate artifact was downloaded into (confirmation mode).
    # Read via a recursive glob, not a fixed path, so it works regardless of how
    # upload/download-artifact nests the single file under the download path.
    CANDIDATE_INPUT_DIR = ENV.fetch("BENCHMARK_CANDIDATE_DIR", "candidate")

    def env!(key)
      ENV.fetch(key) do
        warn "#{key} is required"
        exit 1
      end
    end
  end
end
