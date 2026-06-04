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
  # @param p90 [Numeric, nil] 90th percentile latency in ms (summary-only; not sent
  #   to Bencher, but retained for the display sidecar so the table can show it)
  def add(name:, rps:, p50:, status:, p90: nil)
    # Skip if RPS is not a valid number (FAILED, MISSING, etc.)
    return unless rps.is_a?(Numeric)

    @results << {
      name: "#{@prefix}#{name}#{@suffix}",
      rps: rps,
      p50: p50.is_a?(Numeric) ? p50 : nil,
      p90: p90.is_a?(Numeric) ? p90 : nil,
      status: status,
      failed_pct: calculate_failed_percentage(status)
    }
  end

  # Convert results to BMF JSON hash
  def to_bmf
    output = {}

    @results.each do |r|
      benchmark_entry = {}

      # RPS (higher is better) - use Lower Boundary threshold in Bencher
      add_measure(benchmark_entry, "rps", r[:rps])

      # Latency (lower is better) - use Upper Boundary threshold in Bencher
      # Units (ms) configured in Bencher measure settings
      add_measure(benchmark_entry, "p50_latency", r[:p50])

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
  # track_benchmarks.rb. Mirrors exactly the rows #add accepted (its numeric-rps
  # guard), so the set lines up with what the BMF/report can contain. p90 and the
  # raw status string are summary-only — they are absent from to_bmf.
  def display_rows
    @results.map do |r|
      { "name" => r[:name], "rps" => r[:rps], "p50" => r[:p50], "p90" => r[:p90], "status" => r[:status] }
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
