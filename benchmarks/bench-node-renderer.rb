#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark script for React on Rails Pro Node Renderer
# Uses Vegeta with HTTP/2 Cleartext (h2c) support

require "English"
require "open3"
require "socket"
require_relative "lib/benchmark_helpers"

# Read configuration from source files
def read_protocol_version
  package_json_path = File.expand_path(
    "../packages/react-on-rails-pro-node-renderer/package.json",
    __dir__
  )
  package_json = JSON.parse(File.read(package_json_path))
  package_json["protocolVersion"] || raise("protocolVersion not found in #{package_json_path}")
end

def read_password_from_config
  config_path = File.expand_path(
    "../react_on_rails_pro/spec/dummy/client/node-renderer.js",
    __dir__
  )
  config_content = File.read(config_path)
  match = config_content.match(/password:\s*['"]([^'"]+)['"]/)
  match ? match[1] : raise("password not found in #{config_path}")
end

# Benchmark parameters
BUNDLE_TIMESTAMP = env_or_default("BUNDLE_TIMESTAMP", nil)
PASSWORD = read_password_from_config
BASE_URL = env_or_default("BASE_URL", "localhost:3800")
PROTOCOL_VERSION = read_protocol_version

# Test cases: JavaScript expressions to evaluate
# Format: { name: "test_name", request: "javascript_code" }
TEST_CASES = [
  { name: "simple_eval", request: "2+2" },
  {
    name: "react_ssr",
    request: "ReactOnRails.serverRenderReactComponent(" \
             '{name:"HelloWorld",props:{helloWorldData:{name:"Benchmark"}},domNodeId:"app"})'
  }
].freeze

# Benchmark configuration
RATE = env_or_default("RATE", "max")
CONNECTIONS = env_or_default("CONNECTIONS", 10).to_i
MAX_CONNECTIONS = env_or_default("MAX_CONNECTIONS", CONNECTIONS).to_i
DURATION = env_or_default("DURATION", "30s")
REQUEST_TIMEOUT = env_or_default("REQUEST_TIMEOUT", "60s")

OUTDIR = "bench_results"
SUMMARY_TXT = "#{OUTDIR}/node_renderer_summary.txt".freeze

# Local wrapper for add_summary_line to use local constant
def add_to_summary(*parts)
  add_summary_line(SUMMARY_TXT, *parts)
end

# Find available bundle in the node-renderer bundles directory
def find_bundle_timestamp
  bundles_dir = File.expand_path(
    "../react_on_rails_pro/spec/dummy/.node-renderer-bundles",
    __dir__
  )

  unless Dir.exist?(bundles_dir)
    raise "Node renderer bundles directory not found: #{bundles_dir}\n" \
          "Make sure the Pro dummy app has been compiled with NODE_ENV=production"
  end

  # Bundle directories have format: <hash>-<environment> (e.g., 623229694671afc1ac9137f2715bb654-production)
  # Filter to only include production bundles with hash-like names
  bundles = Dir.children(bundles_dir).select do |entry|
    File.directory?(File.join(bundles_dir, entry)) &&
      entry.match?(/^[a-f0-9]+-production$/)
  end

  raise "No production bundles found in #{bundles_dir}" if bundles.empty?

  # Return the first production bundle
  bundles.first
end

# URL-encode special characters for form body
def url_encode(str)
  URI.encode_www_form_component(str)
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

# Run Vegeta benchmark for a single test case
def run_vegeta_benchmark(test_case, bundle_timestamp)
  name = test_case[:name]
  request = test_case[:request]

  puts "\n===> Vegeta h2c: #{name}"

  # Create target URL
  target_url = "http://#{BASE_URL}/bundles/#{bundle_timestamp}/render/#{name}"

  # Create request body
  body = [
    "protocolVersion=#{url_encode(PROTOCOL_VERSION)}",
    "password=#{url_encode(PASSWORD)}",
    "renderingRequest=#{url_encode(request)}"
  ].join("&")

  # Create temp files for Vegeta
  targets_file = "#{OUTDIR}/#{name}_vegeta_targets.txt"
  body_file = "#{OUTDIR}/#{name}_vegeta_body.txt"
  vegeta_bin = "#{OUTDIR}/#{name}_vegeta.bin"
  vegeta_json = "#{OUTDIR}/#{name}_vegeta.json"
  vegeta_txt = "#{OUTDIR}/#{name}_vegeta.txt"

  # Write body file
  File.write(body_file, body)

  # Write targets file (Vegeta format with @body reference)
  File.write(targets_file, <<~TARGETS)
    POST #{target_url}
    Content-Type: application/x-www-form-urlencoded
    @#{body_file}
  TARGETS

  # Configure Vegeta arguments for max rate
  is_max_rate = RATE == "max"
  vegeta_args =
    if is_max_rate
      ["-rate=0", "-workers=#{CONNECTIONS}", "-max-workers=#{CONNECTIONS}"]
    else
      ["-rate=#{RATE}", "-workers=#{CONNECTIONS}", "-max-workers=#{MAX_CONNECTIONS}"]
    end

  # Run Vegeta attack with h2c
  vegeta_cmd = [
    "vegeta", "attack",
    "-targets=#{targets_file}",
    *vegeta_args,
    "-duration=#{DURATION}",
    "-timeout=#{REQUEST_TIMEOUT}",
    "-h2c", # HTTP/2 Cleartext (required for node renderer)
    "-max-body=0",
    "> #{vegeta_bin}"
  ].join(" ")

  raise "Vegeta attack failed for #{name}" unless system(vegeta_cmd)

  # Generate text report (display and save)
  raise "Vegeta text report failed" unless system("vegeta report #{vegeta_bin} | tee #{vegeta_txt}")

  # Generate JSON report
  raise "Vegeta JSON report failed" unless system("vegeta report -type=json #{vegeta_bin} > #{vegeta_json}")

  # Delete the large binary file to save disk space
  FileUtils.rm_f(vegeta_bin)

  # Parse results
  vegeta_data = parse_json_file(vegeta_json, "Vegeta")
  vegeta_rps = vegeta_data["throughput"]&.round(2) || "missing"
  vegeta_p50 = vegeta_data.dig("latencies", "50th")&./(1_000_000.0)&.round(2) || "missing"
  vegeta_p90 = vegeta_data.dig("latencies", "90th")&./(1_000_000.0)&.round(2) || "missing"
  vegeta_p99 = vegeta_data.dig("latencies", "99th")&./(1_000_000.0)&.round(2) || "missing"
  vegeta_max = vegeta_data.dig("latencies", "max")&./(1_000_000.0)&.round(2) || "missing"
  vegeta_status = vegeta_data["status_codes"]&.map { |k, v| "#{k}=#{v}" }&.join(",") || "missing"

  [vegeta_rps, vegeta_p50, vegeta_p90, vegeta_p99, vegeta_max, vegeta_status]
rescue StandardError => e
  puts "Error: #{e.message}"
  failure_metrics(e)
end

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

# Main execution
bundle_timestamp = BUNDLE_TIMESTAMP || find_bundle_timestamp

# Validate parameters
validate_rate(RATE)
validate_positive_integer(CONNECTIONS, "CONNECTIONS")
validate_positive_integer(MAX_CONNECTIONS, "MAX_CONNECTIONS")
validate_duration(DURATION, "DURATION")
validate_duration(REQUEST_TIMEOUT, "REQUEST_TIMEOUT")

if RATE == "max" && CONNECTIONS != MAX_CONNECTIONS
  raise "For RATE=max, CONNECTIONS must equal MAX_CONNECTIONS (got #{CONNECTIONS} and #{MAX_CONNECTIONS})"
end

# Check required tools
check_required_tools(%w[vegeta column tee])

# Print parameters
print_params(
  "BASE_URL" => BASE_URL,
  "BUNDLE_TIMESTAMP" => bundle_timestamp,
  "RATE" => RATE,
  "DURATION" => DURATION,
  "REQUEST_TIMEOUT" => REQUEST_TIMEOUT,
  "CONNECTIONS" => CONNECTIONS,
  "MAX_CONNECTIONS" => MAX_CONNECTIONS,
  "TEST_CASES" => TEST_CASES.map { |tc| tc[:name] }.join(", ")
)

# Wait for node renderer to be ready
# Note: Node renderer only speaks HTTP/2, but we can still check with a simple GET
# that will fail - we just check it doesn't refuse connection
puts "\nWaiting for node renderer at #{BASE_URL}..."
start_time = Time.now
timeout_sec = 60
loop do
  # Try a simple TCP connection to check if server is up

  Socket.tcp(BASE_URL.split(":").first, BASE_URL.split(":").last.to_i, connect_timeout: 5, &:close)
  puts "  Node renderer is accepting connections"
  break
rescue StandardError => e
  elapsed = Time.now - start_time
  puts "  Attempt at #{elapsed.round(2)}s: #{e.message}"
  raise "Node renderer at #{BASE_URL} not responding within #{timeout_sec}s" if elapsed > timeout_sec

  sleep 1
end

# Create output directory
FileUtils.mkdir_p(OUTDIR)

# Initialize summary file
File.write(SUMMARY_TXT, "")
add_to_summary("Test", "RPS", "p50(ms)", "p90(ms)", "p99(ms)", "max(ms)", "Status")

# Run benchmarks for each test case
TEST_CASES.each do |test_case|
  print_separator
  puts "Benchmarking: #{test_case[:name]}"
  puts "  Request: #{test_case[:request]}"
  print_separator

  metrics = run_vegeta_benchmark(test_case, bundle_timestamp)
  add_to_summary(test_case[:name], *metrics)
end

# Display summary
display_summary(SUMMARY_TXT)
