#!/usr/bin/env ruby
# frozen_string_literal: true

# Converts benchmark summary files to JSON format for github-action-benchmark
# Outputs two files:
#   - benchmark_rps.json (customBiggerIsBetter)
#   - benchmark_latency.json (customSmallerIsBetter)
#
# Usage: ruby convert_to_benchmark_json.rb [prefix]
#   prefix: Optional prefix for benchmark names (e.g., "Core: " or "Pro: ")

require "json"

BENCH_RESULTS_DIR = "bench_results"
PREFIX = ARGV[0] || ""

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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

    # Skip if we got FAILED values
    next if row["RPS"] == "FAILED"

    # Parse numeric values
    rps = row["RPS"]&.to_f
    p50 = row["p50(ms)"]&.to_f
    p90 = row["p90(ms)"]&.to_f
    p99 = row["p99(ms)"]&.to_f

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

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# Calculate failed request percentage from status string
# Status format: "200=7508,302=100,5xx=10" etc.
def calculate_failed_percentage(status_str)
  return 0.0 if status_str.nil? || status_str == "missing"

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

# Convert results to customBiggerIsBetter format (for RPS)
def to_rps_json(results)
  results.map do |r|
    {
      name: "#{r[:name]} - RPS",
      unit: "requests/sec",
      value: r[:rps]
    }
  end
end

# Convert results to customSmallerIsBetter format (for latencies and failure rate)
def to_latency_json(results)
  output = []

  results.each do |r|
    output << {
      name: "#{r[:name]} - p50 latency",
      unit: "ms",
      value: r[:p50]
    }
    output << {
      name: "#{r[:name]} - p90 latency",
      unit: "ms",
      value: r[:p90]
    }
    output << {
      name: "#{r[:name]} - p99 latency",
      unit: "ms",
      value: r[:p99]
    }
    output << {
      name: "#{r[:name]} - failed requests",
      unit: "%",
      value: r[:failed_pct]
    }
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
  puts "No benchmark results found to convert"
  exit 0
end

# Write RPS JSON (bigger is better)
rps_json = to_rps_json(all_results)
File.write(File.join(BENCH_RESULTS_DIR, "benchmark_rps.json"), JSON.pretty_generate(rps_json))
puts "Wrote #{rps_json.length} RPS metrics to benchmark_rps.json"

# Write latency/failure JSON (smaller is better)
latency_json = to_latency_json(all_results)
File.write(File.join(BENCH_RESULTS_DIR, "benchmark_latency.json"), JSON.pretty_generate(latency_json))
puts "Wrote #{latency_json.length} latency/failure metrics to benchmark_latency.json"
