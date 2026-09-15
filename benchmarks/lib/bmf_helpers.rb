# frozen_string_literal: true

# Bencher Metric Format (BMF) helpers
# See: https://bencher.dev/docs/reference/bencher-metric-format/
#
# Output format:
#   {
#     "benchmark_name": {
#       "measure_name": { "value": 123.45 }
#     }
#   }
#
# Measures (snake_case for easy CLI usage with --threshold-measure):
#   - rps: Requests per second (higher is better - use Lower Boundary threshold)
#   - p50_latency: 50th-percentile latency in ms (lower is better - Upper Boundary)
#   - p90_latency: 90th-percentile latency in ms (sent boundary-less: recorded for a
#       summary-table baseline but NOT in THRESHOLDS, so never alerted on)
#   - failed_pct: Failed request percentage (lower is better - use Upper Boundary)

require "json"

# Collect benchmark results for BMF JSON output
class BmfCollector
  def initialize(prefix: "", suffix: "")
    @prefix = prefix
    @suffix = suffix
    @results = []
  end

  # Add a benchmark result
  # @param name [String] The benchmark name (e.g., route path or test name)
  # @param rps [Numeric, nil] Requests per second
  # @param p50 [Numeric, nil] 50th percentile latency in ms
  # @param status [String, nil] Status string like "200=100,5xx=2"
  # @param p90 [Numeric, nil] 90th percentile latency in ms (sent to Bencher
  #   boundary-less via to_bmf, and retained for the display sidecar so the table shows it)
  # @param samples [Hash, nil] Per-sample raw values keyed by Bencher measure name
  #   (e.g. {"rps" => [529.1, 533.0, 505.2]}) when the bench script ran repeated
  #   samples. Display-sidecar only (never part of the BMF payload): the relative
  #   comparison uses it to require a flagged change to reproduce across samples.
  def add(name:, rps:, p50:, status:, p90: nil, samples: nil)
    # Keep every row, including failures (rps "FAILED"/"MISSING"): the display sidecar
    # must still show a failed route/test rather than dropping it silently. The
    # numeric-rps filter lives in #to_bmf so only valid measures reach Bencher.
    @results << {
      name: "#{@prefix}#{name}#{@suffix}",
      rps:,
      p50: p50.is_a?(Numeric) ? p50 : nil,
      p90: p90.is_a?(Numeric) ? p90 : nil,
      status:,
      failed_pct: calculate_failed_percentage(status),
      samples: samples.is_a?(Hash) && !samples.empty? ? samples : nil
    }
  end

  # Convert results to BMF JSON hash
  def to_bmf
    output = {}

    @results.each do |r|
      # Only numeric-rps rows are valid Bencher measures; failed/MISSING rows are kept
      # for the display sidecar (see #add) but must not reach the BMF payload.
      next unless r[:rps].is_a?(Numeric)

      benchmark_entry = {}

      # RPS (higher is better) - use Lower Boundary threshold in Bencher
      add_measure(benchmark_entry, "rps", r[:rps])

      # Latency (lower is better) - use Upper Boundary threshold in Bencher
      # Units (ms) configured in Bencher measure settings
      add_measure(benchmark_entry, "p50_latency", r[:p50])

      # p90 latency (lower is better) - sent boundary-less: it is uploaded so Bencher
      # records its history and can supply a baseline for the summary table, but it is NOT
      # listed in track_benchmarks.rb THRESHOLDS, so it is never alerted on (its tail noise
      # can't meet the false-positive target at any usable boundary).
      add_measure(benchmark_entry, "p90_latency", r[:p90])

      # Failure percentage (lower is better) - use Upper Boundary threshold in Bencher
      add_measure(benchmark_entry, "failed_pct", r[:failed_pct])

      output[r[:name]] = benchmark_entry unless benchmark_entry.empty?
    end

    output
  end

  # Write BMF JSON to file, optionally appending to existing data
  def write_bmf_json(output_path, append: false)
    new_benchmarks = to_bmf

    if new_benchmarks.empty?
      warn "WARNING: No valid benchmark results to write"
      return false
    end

    # In append mode, merge with existing benchmarks
    if append && File.exist?(output_path)
      begin
        existing_benchmarks = JSON.parse(File.read(output_path))
        bmf_json = existing_benchmarks.merge(new_benchmarks)
        puts "Appended #{new_benchmarks.length} benchmarks to existing #{existing_benchmarks.length} benchmarks"
      rescue JSON::ParserError => e
        warn "WARNING: Existing #{output_path} contains invalid JSON (#{e.message}), overwriting"
        bmf_json = new_benchmarks
      end
    else
      bmf_json = new_benchmarks
      puts "Created #{bmf_json.length} new benchmarks"
    end

    File.write(output_path, JSON.pretty_generate(bmf_json))
    puts "Wrote #{bmf_json.length} total benchmarks to #{output_path}"
    true
  end

  # Rows for the Markdown summary table, joined with the Bencher report by name in
  # track_benchmarks.rb. Includes every row #add recorded — failed/MISSING rows too,
  # so a failed route/test stays visible in the summary even though it never reaches
  # Bencher (#to_bmf filters those out). rps may therefore be a non-numeric token like
  # "FAILED"/"MISSING"; BenchmarkTable renders it as text and never highlights a
  # non-numeric cell. The raw status string is summary-only (Bencher never sees it).
  # failed_pct is intentionally NOT carried: the Fail% column was dropped (redundant with
  # Status — issue #3601 item 4), so nothing reads it (it is still a tracked BMF measure).
  def display_rows
    @results.map do |r|
      row = { "name" => r[:name], "rps" => r[:rps], "p50" => r[:p50], "p90" => r[:p90], "status" => r[:status] }
      # Only multi-sample runs carry per-sample values; the key is absent otherwise so
      # single-sample consumers (and the sample-confirmation join) can treat "no key"
      # as "no repeated samples".
      row["samples"] = r[:samples] if r[:samples]
      row
    end
  end

  # Write the display sidecar (a JSON array of display_rows). Supports append: to
  # match write_bmf_json, so a job that runs more than one bench script keeps every
  # suite's rows (defensive; the current matrix runs one script per job).
  def write_display_json(output_path, append: false)
    rows = display_rows
    if rows.empty?
      warn "WARNING: No valid benchmark results for the display sidecar"
      return false
    end

    if append && File.exist?(output_path)
      begin
        existing = JSON.parse(File.read(output_path))
        if existing.is_a?(Array)
          rows = existing + rows
        else
          warn "WARNING: Existing #{output_path} is not a JSON array (#{existing.class}), overwriting"
        end
      rescue JSON::ParserError => e
        warn "WARNING: Existing #{output_path} contains invalid JSON (#{e.message}), overwriting"
      end
    end

    File.write(output_path, JSON.pretty_generate(rows))
    puts "Wrote #{rows.length} display rows to #{output_path}"
    true
  end

  def empty?
    @results.empty?
  end

  def length
    @results.length
  end

  private

  # Add a measure to the benchmark entry if the value is not nil
  def add_measure(benchmark_entry, measure_name, value)
    return if value.nil?

    benchmark_entry[measure_name] = { "value" => value }
  end

  # Calculate failed request percentage from status string
  # Status format: "200=7508,302=100,5xx=10" etc.
  def calculate_failed_percentage(status_str)
    return 0.0 unless valid_status_string?(status_str)

    total, failed = count_requests(status_str)
    return 0.0 if total.zero?

    (failed.to_f / total * 100).round(2)
  end

  def valid_status_string?(status_str)
    status_str.is_a?(String) && !%w[MISSING FAILED].include?(status_str)
  end

  def count_requests(status_str)
    total = 0
    failed = 0

    status_str.split(",").each do |part|
      code, count = part.split("=")
      count = count.to_i
      total += count
      # Consider 0 (for Vegeta), 4xx and 5xx as failures, also "other"
      failed += count if code.match?(/^[045]/) || code == "other"
    end

    [total, failed]
  end
end
