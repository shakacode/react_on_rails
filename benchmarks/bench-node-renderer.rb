#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark script for React on Rails Pro Node Renderer
# Uses Vegeta with HTTP/2 Cleartext (h2c) support

require "English"
require "open3"
require "socket"
require_relative "lib/benchmark_config"
require_relative "lib/benchmark_helpers"
require_relative "lib/bmf_helpers"

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
PASSWORD = read_password_from_config
BASE_URL = env_or_default("BASE_URL", "localhost:3800")
PROTOCOL_VERSION = read_protocol_version

# Test cases: JavaScript expressions to evaluate
# Format: { name: "test_name", request: "javascript_code", rsc: true/false }
# rsc: true means the test requires an RSC bundle, false means non-RSC bundle
TEST_CASES = [
  { name: "simple_eval", rsc: false, request: "2+2" },
  {
    name: "react_ssr",
    rsc: false,
    request: "ReactOnRails.serverRenderReactComponent(" \
             '{name:"HelloWorld",props:{helloWorldData:{name:"Benchmark"}},domNodeId:"app"})'
  }
].freeze

# Script-specific configuration (common params from benchmark_config.rb)
SUMMARY_TXT = "#{OUTDIR}/node_renderer_summary.txt".freeze
BMF_PREFIX = "Pro: NodeRenderer: "

# Local wrapper for add_summary_line to use local constant
def add_to_summary(*parts)
  add_summary_line(SUMMARY_TXT, *parts)
end

# Find all production bundles in the node-renderer bundles directory
def find_all_production_bundles
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

  bundles
end

# Check if a bundle is an RSC bundle by evaluating ReactOnRails.isRSCBundle
# Returns true/false/nil (nil means couldn't determine)
# rubocop:disable Style/ReturnNilInPredicateMethodDefinition
def rsc_bundle?(bundle_timestamp)
  url = render_url(bundle_timestamp, "rsc_check")
  body = render_body("ReactOnRails.isRSCBundle")

  # Use curl with h2c since Net::HTTP doesn't support HTTP/2
  result, status = Open3.capture2(
    "curl", "-s", "--http2-prior-knowledge", "-X", "POST",
    "-H", "Content-Type: application/x-www-form-urlencoded",
    "-d", body,
    url
  )
  return nil unless status.success?

  # The response should be "true" or "false"
  result.strip == "true"
rescue StandardError => e
  puts "  Warning: Could not determine RSC status for #{bundle_timestamp}: #{e.message}"
  nil
end
# rubocop:enable Style/ReturnNilInPredicateMethodDefinition

# Categorize bundles into RSC and non-RSC
# Stops early once we find one of each type
def categorize_bundles(bundles)
  rsc_bundle = nil
  non_rsc_bundle = nil

  bundles.each do |bundle|
    # Stop if we already have both types
    break if rsc_bundle && non_rsc_bundle

    puts "  Checking bundle #{bundle}..."
    is_rsc = rsc_bundle?(bundle)
    if is_rsc.nil?
      puts "    Could not determine bundle type, skipping"
    elsif is_rsc
      puts "    RSC bundle"
      rsc_bundle ||= bundle
    else
      puts "    Non-RSC bundle"
      non_rsc_bundle ||= bundle
    end
  end

  [rsc_bundle, non_rsc_bundle]
end

# URL-encode special characters for form body
def url_encode(str)
  URI.encode_www_form_component(str)
end

# Build render URL for a bundle and render name
def render_url(bundle_timestamp, render_name)
  "http://#{BASE_URL}/bundles/#{bundle_timestamp}/render/#{render_name}"
end

# Build request body for a rendering request
def render_body(rendering_request)
  [
    "protocolVersion=#{url_encode(PROTOCOL_VERSION)}",
    "password=#{url_encode(PASSWORD)}",
    "renderingRequest=#{url_encode(rendering_request)}"
  ].join("&")
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

# Run Vegeta benchmark for a single test case
def run_vegeta_benchmark(test_case, bundle_timestamp)
  name = test_case[:name]
  request = test_case[:request]

  puts "\n===> Vegeta h2c: #{name}"

  target_url = render_url(bundle_timestamp, name)
  body = render_body(request)

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
  vegeta_rps = vegeta_data["throughput"]&.round(2) || "MISSING"
  vegeta_p50 = vegeta_data.dig("latencies", "50th")&./(1_000_000.0)&.round(2) || "MISSING"
  vegeta_p90 = vegeta_data.dig("latencies", "90th")&./(1_000_000.0)&.round(2) || "MISSING"
  vegeta_p99 = vegeta_data.dig("latencies", "99th")&./(1_000_000.0)&.round(2) || "MISSING"
  vegeta_max = vegeta_data.dig("latencies", "max")&./(1_000_000.0)&.round(2) || "MISSING"
  vegeta_status = vegeta_data["status_codes"]&.map { |k, v| "#{k}=#{v}" }&.join(",") || "MISSING"

  [vegeta_rps, vegeta_p50, vegeta_p90, vegeta_p99, vegeta_max, vegeta_status]
rescue StandardError => e
  puts "Error: #{e.message}"
  failure_metrics(e)
end

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

# Main execution

validate_benchmark_config!

# Check required tools
check_required_tools(%w[vegeta curl column tee])

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

# Find and categorize bundles
puts "\nDiscovering and categorizing bundles..."
all_bundles = find_all_production_bundles
puts "Found #{all_bundles.length} production bundle(s)"
rsc_bundle, non_rsc_bundle = categorize_bundles(all_bundles)

rsc_tests = TEST_CASES.select { |tc| tc[:rsc] }
non_rsc_tests = TEST_CASES.reject { |tc| tc[:rsc] }

if rsc_tests.any? && rsc_bundle.nil?
  puts "Warning: RSC tests requested but no RSC bundle found, skipping: #{rsc_tests.map { |tc| tc[:name] }.join(', ')}"
  rsc_tests = []
end

if non_rsc_tests.any? && non_rsc_bundle.nil?
  skipped = non_rsc_tests.map { |tc| tc[:name] }.join(", ")
  puts "Warning: Non-RSC tests requested but no non-RSC bundle found, skipping: #{skipped}"
  non_rsc_tests = []
end

# Print parameters
print_params(
  "BASE_URL" => BASE_URL,
  "RSC_BUNDLE" => rsc_bundle || "none",
  "NON_RSC_BUNDLE" => non_rsc_bundle || "none",
  "RATE" => RATE,
  "DURATION" => DURATION,
  "REQUEST_TIMEOUT" => REQUEST_TIMEOUT,
  "CONNECTIONS" => CONNECTIONS,
  "MAX_CONNECTIONS" => MAX_CONNECTIONS,
  "RSC_TESTS" => rsc_tests.map { |tc| tc[:name] }.join(", ").then { |s| s.empty? ? "none" : s },
  "NON_RSC_TESTS" => non_rsc_tests.map { |tc| tc[:name] }.join(", ").then { |s| s.empty? ? "none" : s }
)

# Create output directory
FileUtils.mkdir_p(OUTDIR)

# Initialize BMF collector for Bencher output
bmf_collector = BmfCollector.new(prefix: BMF_PREFIX)

# Initialize summary file
File.write(SUMMARY_TXT, "")
add_to_summary("Test", "Bundle", "RPS", "p50(ms)", "p90(ms)", "p99(ms)", "max(ms)", "Status")

# Run non-RSC benchmarks
non_rsc_tests.each do |test_case|
  print_separator
  puts "Benchmarking (non-RSC): #{test_case[:name]}"
  puts "  Bundle: #{non_rsc_bundle}"
  puts "  Request: #{test_case[:request]}"
  print_separator

  rps, p50, p90, p99, max_latency, status = run_vegeta_benchmark(test_case, non_rsc_bundle)
  add_to_summary(test_case[:name], "non-RSC", rps, p50, p90, p99, max_latency, status)

  # Add to BMF collector for Bencher output
  bmf_collector.add(name: test_case[:name], rps: rps, p50: p50, p90: p90, p99: p99, status: status,
                    suffix: " (non-RSC)")
end

# Run RSC benchmarks
rsc_tests.each do |test_case|
  print_separator
  puts "Benchmarking (RSC): #{test_case[:name]}"
  puts "  Bundle: #{rsc_bundle}"
  puts "  Request: #{test_case[:request]}"
  print_separator

  rps, p50, p90, p99, max_latency, status = run_vegeta_benchmark(test_case, rsc_bundle)
  add_to_summary(test_case[:name], "RSC", rps, p50, p90, p99, max_latency, status)

  # Add to BMF collector for Bencher output
  bmf_collector.add(name: test_case[:name], rps: rps, p50: p50, p90: p90, p99: p99, status: status,
                    suffix: " (RSC)")
end

# Display summary
display_summary(SUMMARY_TXT)

# Write BMF JSON for Bencher (append to existing Pro results)
bmf_collector.write_bmf_json(BENCHMARK_JSON, append: true)
