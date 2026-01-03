#!/usr/bin/env ruby
# frozen_string_literal: true

# Converts benchmark summary files to Bencher Metric Format (BMF) JSON
# See: https://bencher.dev/docs/reference/bencher-metric-format/
#
# Output format (BMF):
#   {
#     "benchmark_name": {
#       "measure_name": { "value": 123.45 }
#     }
#   }
#
# Measures (snake_case for easy CLI usage with --threshold-measure):
#   - rps: Requests per second (higher is better - use Lower Boundary threshold)
#   - p50_latency_ms, p90_latency_ms, p99_latency_ms: Latencies (lower is better - Upper Boundary)
#   - failed_pct: Failed request percentage (lower is better - use Upper Boundary)
#
# Usage: ruby convert-to-bmf.rb [prefix] [--append]
#   prefix: Optional prefix for benchmark names (e.g., "Core: " or "Pro: ")
#   --append: Append to existing benchmark.json instead of overwriting

require "json"

BENCH_RESULTS_DIR = "bench_results"
PREFIX = ARGV[0] || ""
APPEND_MODE = ARGV.include?("--append")

# Try to parse a string as a float, return nil if not a valid number
def parse_float(str)
  return nil if str.nil? || str.empty? || str == "MISSING" || str == "FAILED"

  Float(str)
rescue ArgumentError, TypeError
  nil
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity

# Parse a summary file and return array of hashes with metrics
# Expected format (tab-separated):
#   Route  RPS  p50(ms)  p90(ms)  p99(ms)  max(ms)  Status
#   or for node renderer:
#   Test  Bundle  RPS  p50(ms)  p90(ms)  p99(ms)  max(ms)  Status
def parse_summary_file(file_path, prefix: "")
  return [] unless File.exist?(file_path)

  lines = File.readlines(file_path).map(&:strip).reject(&:empty?)
  return [] if lines.length < 2

  header = lines.first.split("\t")
  results = []

  lines[1..].each do |line|
    cols = line.split("\t")
    row = header.zip(cols).to_h

    # Determine the name based on available columns
    name = row["Route"] || row["Test"] || "unknown"
    bundle_suffix = row["Bundle"] ? " (#{row['Bundle']})" : ""
    full_name = "#{prefix}#{name}#{bundle_suffix}"

    # Parse numeric values, skip row if RPS can't be parsed (FAILED, MISSING, etc.)
    rps = parse_float(row["RPS"])
    next if rps.nil?

    p50 = parse_float(row["p50(ms)"])
    p90 = parse_float(row["p90(ms)"])
    p99 = parse_float(row["p99(ms)"])

    # Calculate failed percentage from Status column
    failed_pct = calculate_failed_percentage(row["Status"])

    results << {
      name: full_name,
      rps: rps,
      p50: p50,
      p90: p90,
      p99: p99,
      failed_pct: failed_pct
    }
  end

  results
end

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

# Calculate failed request percentage from status string
# Status format: "200=7508,302=100,5xx=10" etc.
def calculate_failed_percentage(status_str)
  return 0.0 if status_str.nil? || status_str == "MISSING" || status_str == "FAILED"

  total = 0
  failed = 0

  status_str.split(",").each do |part|
    code, count = part.split("=")
    count = count.to_i
    total += count

    # Consider 0 (for Vegeta), 4xx and 5xx as failures, also "other"
    failed += count if code.match?(/^[045]/) || code == "other"
  end

  return 0.0 if total.zero?

  (failed.to_f / total * 100).round(2)
end

# Add a measure to the benchmark entry if the value is not nil
# BMF format: { "measure_name": { "value": 123.45 } }
def add_measure(benchmark_entry, measure_name:, value:)
  return if value.nil?

  benchmark_entry[measure_name] = { "value" => value }
end

# Convert all results to Bencher Metric Format (BMF)
# See: https://bencher.dev/docs/reference/bencher-metric-format/
#
# Output structure:
#   {
#     "benchmark_name": {
#       "rps": { "value": 5000.0 },
#       "p50_latency_ms": { "value": 45.2 },
#       ...
#     }
#   }
def to_bmf_json(results)
  output = {}

  results.each do |r|
    benchmark_name = r[:name]
    benchmark_entry = {}

    # RPS (higher is better) - use Lower Boundary threshold in Bencher
    add_measure(benchmark_entry, measure_name: "rps", value: r[:rps])

    # Latencies in ms (lower is better) - use Upper Boundary threshold in Bencher
    add_measure(benchmark_entry, measure_name: "p50_latency_ms", value: r[:p50])
    add_measure(benchmark_entry, measure_name: "p90_latency_ms", value: r[:p90])
    add_measure(benchmark_entry, measure_name: "p99_latency_ms", value: r[:p99])

    # Failure percentage (lower is better) - use Upper Boundary threshold in Bencher
    add_measure(benchmark_entry, measure_name: "failed_pct", value: r[:failed_pct])

    output[benchmark_name] = benchmark_entry unless benchmark_entry.empty?
  end

  output
end

# Main execution
all_results = []

# Parse Rails benchmark
rails_summary = File.join(BENCH_RESULTS_DIR, "summary.txt")
all_results.concat(parse_summary_file(rails_summary, prefix: PREFIX)) if File.exist?(rails_summary)

# Parse Node Renderer benchmark
node_renderer_summary = File.join(BENCH_RESULTS_DIR, "node_renderer_summary.txt")
if File.exist?(node_renderer_summary)
  all_results.concat(parse_summary_file(node_renderer_summary, prefix: "#{PREFIX}NodeRenderer: "))
end

if all_results.empty?
  warn "ERROR: All benchmarks failed - no valid results to convert"
  exit 1
end

# Convert current results to BMF JSON
new_benchmarks = to_bmf_json(all_results)
output_path = File.join(BENCH_RESULTS_DIR, "benchmark.json")

# In append mode, merge with existing benchmarks
if APPEND_MODE && File.exist?(output_path)
  existing_benchmarks = JSON.parse(File.read(output_path))
  bmf_json = existing_benchmarks.merge(new_benchmarks)
  puts "Appended #{new_benchmarks.length} benchmarks to existing #{existing_benchmarks.length} benchmarks"
else
  bmf_json = new_benchmarks
  puts "Created #{bmf_json.length} new benchmarks"
end

# Write BMF JSON
# See: https://bencher.dev/docs/reference/bencher-metric-format/
File.write(output_path, JSON.pretty_generate(bmf_json))
puts "Wrote #{bmf_json.length} total benchmarks to benchmark.json (from #{all_results.length} parsed results)"
puts "Bencher threshold configuration (--threshold-measure):"
puts "  - rps: Higher is better (use --threshold-lower-boundary)"
puts "  - p50/p90/p99_latency_ms: Lower is better (use --threshold-upper-boundary)"
puts "  - failed_pct: Lower is better (use --threshold-upper-boundary)"
