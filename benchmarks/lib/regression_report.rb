# frozen_string_literal: true

# The filename contract for benchmark regression hand-off between two jobs:
# the writer (track_benchmarks.rb) drops one into each matrix job's bench_results/,
# and the reader (report_regressions.rb) finds them by globbing this exact basename
# under the downloaded artifacts. They run in different jobs, so the name must match.
module RegressionReport
  FILENAME = "regression.json"
end
