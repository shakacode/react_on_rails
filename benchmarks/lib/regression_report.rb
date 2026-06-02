# frozen_string_literal: true

# Shared constants between track_benchmarks.rb and report_regressions.rb.
module RegressionReport
  # The contract for the benchmark regression hand-off between two jobs: the writer
  # (track_benchmarks.rb) drops a regression.json into each matrix job's bench_results/,
  # and the reader (report_regressions.rb) globs this basename under the downloaded
  # artifacts and reads these keys.
  FILENAME = "regression.json"

  # Payload keys
  SUITE_NAME = "suite_name"
  SHARD_LABEL = "shard_label"
  SUMMARY = "summary"
end
