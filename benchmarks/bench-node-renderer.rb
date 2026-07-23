#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark script for React on Rails Pro Node Renderer.
#
# Uses Vegeta with HTTP/2 Cleartext (h2c) support. Set
# LOAD_GENERATOR_SHARDS=N to split each test across N Vegeta attack processes;
# the script passes every shard result file to one merged Vegeta report so
# percentiles are recomputed over the combined sample distribution.

require "English"
require "open3"
require "shellwords"
require "socket"
require_relative "lib/benchmark_config"
require_relative "lib/benchmark_helpers"
require_relative "lib/bmf_helpers"

# The monorepo checkout under test. These reads target the APP side (the phase's
# checked-out package/config/bundles), NOT the benchmark harness: CI stashes the
# head ref's benchmarks/ outside the workspace and runs both phases with it (one
# measuring instrument), so script-relative "../" would escape the stash instead
# of reaching the workspace. GITHUB_WORKSPACE points at the checkout in CI; local
# in-tree runs fall back to this script's parent directory as before.
def workspace_root
  ENV.fetch("GITHUB_WORKSPACE") { File.expand_path("..", __dir__) }
end

# Read configuration from source files
def read_protocol_version
  package_json_path = File.join(
    workspace_root,
    "packages/react-on-rails-pro-node-renderer/package.json"
  )
  package_json = JSON.parse(File.read(package_json_path))
  package_json["protocolVersion"] || raise("protocolVersion not found in #{package_json_path}")
end

def read_password_from_config
  config_path = File.join(
    workspace_root,
    "react_on_rails_pro/spec/dummy/renderer/node-renderer.js"
  )
  config_content = File.read(config_path)
  match = config_content.match(/password:\s*['"]([^'"]+)['"]/)
  match ? match[1] : raise("password not found in #{config_path}")
end

# Benchmark parameters
PASSWORD = read_password_from_config
BASE_URL = env_or_default("BASE_URL", "localhost:3800")
PROTOCOL_VERSION = read_protocol_version
LOAD_GENERATOR_SHARDS = env_or_default("LOAD_GENERATOR_SHARDS", 1).to_i
RAW_RENDER_CONTENT_TYPE = "application/vnd.react-on-rails.render-request+javascript"
RAW_RENDER_PROTOCOL_HEADER = "X-React-On-Rails-Pro-Protocol-Version"

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
BMF_PREFIX = "Pro Node Renderer: "
VEGETA_RATE_PRECISION = 6
VEGETA_RATE_SCALE = 10**VEGETA_RATE_PRECISION
VEGETA_DURATION_UNITS_IN_SECONDS = {
  "s" => 1,
  "m" => 60,
  "h" => 3600
}.freeze

# Local wrapper for add_summary_line to use local constant
def add_to_summary(*parts)
  add_summary_line(SUMMARY_TXT, *parts)
end

# Find all production bundles in the node-renderer bundles directory
def find_all_production_bundles
  bundles_dir = File.join(
    workspace_root,
    "react_on_rails_pro/spec/dummy/.node-renderer-bundles"
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
    "-H", "Content-Type: #{RAW_RENDER_CONTENT_TYPE}",
    "-H", "#{RAW_RENDER_PROTOCOL_HEADER}: #{PROTOCOL_VERSION}",
    "-H", "Authorization: Bearer #{PASSWORD}",
    "--data-binary", body,
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

# Build render URL for a bundle and render name
def render_url(bundle_timestamp, render_name)
  "http://#{BASE_URL}/bundles/#{bundle_timestamp}/render/#{render_name}"
end

# Build request body for a rendering request
def render_body(rendering_request)
  rendering_request
end

def validate_node_renderer_benchmark_config!
  validate_benchmark_config!
  validate_positive_integer(LOAD_GENERATOR_SHARDS, "LOAD_GENERATOR_SHARDS")

  unless LOAD_GENERATOR_SHARDS <= CONNECTIONS && LOAD_GENERATOR_SHARDS <= MAX_CONNECTIONS
    raise "LOAD_GENERATOR_SHARDS must be no greater than CONNECTIONS and MAX_CONNECTIONS " \
          "(got shards=#{LOAD_GENERATOR_SHARDS}, connections=#{CONNECTIONS}, max_connections=#{MAX_CONNECTIONS})"
  end

  validate_fixed_rate_shards!(LOAD_GENERATOR_SHARDS)
end

def distribute_integer(total, shard_count)
  base, remainder = total.divmod(shard_count)
  Array.new(shard_count) { |index| base + (index < remainder ? 1 : 0) }
end

def duration_seconds(duration)
  duration.scan(/(\d+(?:\.\d+)?)([smh])/).sum(Rational(0)) do |number, unit|
    Rational(number) * VEGETA_DURATION_UNITS_IN_SECONDS.fetch(unit)
  end
end

def minimum_scaled_rate_for_duration(duration)
  seconds = duration_seconds(duration)
  raise "DURATION must be greater than 0 for fixed RATE" if seconds.zero?

  (VEGETA_RATE_SCALE / seconds).ceil
end

def scaled_vegeta_rate
  whole, fractional = RATE.split(".", 2)
  fractional_digits = (fractional || "").ljust(VEGETA_RATE_PRECISION + 1, "0")
  scaled = (whole.to_i * VEGETA_RATE_SCALE) + fractional_digits[0, VEGETA_RATE_PRECISION].to_i
  scaled += 1 if fractional_digits[VEGETA_RATE_PRECISION].to_i >= 5
  scaled
end

def validate_fixed_rate_shards!(shard_count)
  return if RATE == "max"

  shard_rates = distribute_integer(scaled_vegeta_rate, shard_count)
  minimum_rate_for_shards = shard_count
  if shard_rates.min.zero?
    minimum_rate = format_scaled_vegeta_rate_for_message(minimum_rate_for_shards)
    raise "RATE must be at least #{minimum_rate} when LOAD_GENERATOR_SHARDS=#{shard_count}"
  end

  minimum_rate_per_shard = minimum_scaled_rate_for_duration(DURATION)
  return if shard_rates.min >= minimum_rate_per_shard

  minimum_rate = format_scaled_vegeta_rate_for_message(minimum_rate_per_shard * shard_count)
  raise "RATE must be at least #{minimum_rate} when LOAD_GENERATOR_SHARDS=#{shard_count} and DURATION=#{DURATION}"
end

def format_scaled_vegeta_rate_for_message(scaled_rate)
  whole, fractional = scaled_rate.divmod(VEGETA_RATE_SCALE)
  return whole.to_s if fractional.zero?

  "#{whole}.#{fractional.to_s.rjust(VEGETA_RATE_PRECISION, '0').sub(/0+\z/, '')}"
end

def format_vegeta_attack_rate(scaled_rate)
  whole, fractional = scaled_rate.divmod(VEGETA_RATE_SCALE)
  return whole.to_s if fractional.zero?

  # Vegeta accepts integer rates or integer-frequency duration syntax, but not
  # bare decimals like "0.333333".
  "#{scaled_rate}/#{VEGETA_RATE_SCALE}s"
end

def vegeta_rates_for_shards(shard_count)
  return Array.new(shard_count, "0") if RATE == "max"

  distribute_integer(scaled_vegeta_rate, shard_count).map { |rate| format_vegeta_attack_rate(rate) }
end

def vegeta_result_file(name, shard_number, shard_count)
  return "#{OUTDIR}/#{name}_vegeta.bin" if shard_count == 1

  "#{OUTDIR}/#{name}_vegeta_shard_#{shard_number}_of_#{shard_count}.bin"
end

def vegeta_result_files(name, shard_count)
  Array.new(shard_count) { |index| vegeta_result_file(name, index + 1, shard_count) }
end

def vegeta_attack_shard_specs(targets_file, result_files)
  shard_count = result_files.length
  worker_counts = distribute_integer(CONNECTIONS, shard_count)
  max_worker_counts = distribute_integer(MAX_CONNECTIONS, shard_count)
  rates = vegeta_rates_for_shards(shard_count)

  result_files.map.with_index do |result_file, index|
    shard_number = index + 1
    vegeta_args = [
      "-rate=#{rates.fetch(index)}",
      "-workers=#{worker_counts.fetch(index)}",
      "-max-workers=#{max_worker_counts.fetch(index)}"
    ]

    puts "  Shard #{shard_number}/#{shard_count}: #{vegeta_args.join(' ')}" if shard_count > 1

    vegeta_cmd = [
      "vegeta", "attack",
      "-targets=#{Shellwords.escape(targets_file)}",
      *vegeta_args,
      "-duration=#{DURATION}",
      "-timeout=#{REQUEST_TIMEOUT}",
      "-h2c", # HTTP/2 Cleartext (required for node renderer)
      "-max-body=0",
      "> #{Shellwords.escape(result_file)}"
    ].join(" ")

    { command: vegeta_cmd, result_file:, shard_count:, shard_number: }
  end
end

def vegeta_shard_label(shard_spec)
  "shard #{shard_spec.fetch(:shard_number)}/#{shard_spec.fetch(:shard_count)}"
end

def process_status_description(status)
  return "exited with status #{status.exitstatus}" if status.exitstatus
  return "terminated by signal #{status.termsig}" if status.termsig

  "finished unsuccessfully"
end

def wait_for_vegeta_attack_shards(running_shards)
  running_shards.filter_map do |shard_spec|
    _pid, status = Process.wait2(shard_spec.fetch(:pid))
    next if status.success?

    "#{vegeta_shard_label(shard_spec)} #{process_status_description(status)}"
  rescue Errno::ECHILD
    "#{vegeta_shard_label(shard_spec)} could not be waited on"
  end
end

def stop_vegeta_attack_shards(running_shards)
  running_shards.each do |shard_spec|
    Process.kill("TERM", shard_spec.fetch(:pid))
  rescue Errno::ESRCH
    nil
  end
end

def run_vegeta_attack_shards(name, targets_file, result_files)
  running_shards = []
  current_spec = nil

  vegeta_attack_shard_specs(targets_file, result_files).each do |shard_spec|
    current_spec = shard_spec
    running_shards << shard_spec.merge(pid: Process.spawn(shard_spec.fetch(:command)))
  end

  failures = wait_for_vegeta_attack_shards(running_shards)
  raise "Vegeta attack failed for #{name}: #{failures.join(', ')}" if failures.any?

  result_files
rescue SystemCallError => e
  stop_vegeta_attack_shards(running_shards)
  wait_for_vegeta_attack_shards(running_shards)
  raise "Vegeta attack failed for #{name} #{vegeta_shard_label(current_spec)}: #{e.message}"
end

def vegeta_report_command(result_files, *args)
  ["vegeta", "report", *args, *result_files].map { |part| Shellwords.escape(part) }.join(" ")
end

def run_vegeta_report_command!(command, failure_message)
  return if system("bash", "-c", "set -o pipefail; #{command}")

  raise failure_message
end

def run_vegeta_reports(result_files, vegeta_txt, vegeta_json)
  # Pass multiple gob files to one report; naive `cat` concatenation fails with
  # duplicate gob type declarations on Vegeta 12.13.
  run_vegeta_report_command!(
    "#{vegeta_report_command(result_files)} | tee #{Shellwords.escape(vegeta_txt)}",
    "Vegeta text report failed"
  )
  run_vegeta_report_command!(
    "#{vegeta_report_command(result_files, '-type=json')} > #{Shellwords.escape(vegeta_json)}",
    "Vegeta JSON report failed"
  )
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# Run Vegeta benchmark for a single test case. Returns [rps, p50, p90, status]
# on success and RAISES on any Vegeta/parse failure so the suite can record the
# failure and exit non-zero instead of shipping fabricated metrics to Bencher.
def run_vegeta_benchmark(test_case, bundle_timestamp, shard_count: LOAD_GENERATOR_SHARDS)
  name = test_case[:name]
  request = test_case[:request]

  puts "\n===> Vegeta h2c: #{name}"

  target_url = render_url(bundle_timestamp, name)
  body = render_body(request)

  # Create temp files for Vegeta
  targets_file = "#{OUTDIR}/#{name}_vegeta_targets.txt"
  body_file = "#{OUTDIR}/#{name}_vegeta_body.txt"
  vegeta_json = "#{OUTDIR}/#{name}_vegeta.json"
  vegeta_txt = "#{OUTDIR}/#{name}_vegeta.txt"

  # Write body file
  File.write(body_file, body)

  # Write targets file (Vegeta format with @body reference)
  File.write(targets_file, <<~TARGETS)
    POST #{target_url}
    Content-Type: #{RAW_RENDER_CONTENT_TYPE}
    #{RAW_RENDER_PROTOCOL_HEADER}: #{PROTOCOL_VERSION}
    Authorization: Bearer #{PASSWORD}
    @#{body_file}
  TARGETS

  result_files = vegeta_result_files(name, shard_count)
  begin
    run_vegeta_attack_shards(name, targets_file, result_files)
    run_vegeta_reports(result_files, vegeta_txt, vegeta_json)

    # Parse results
    vegeta_data = parse_json_file(vegeta_json, "Vegeta")
    vegeta_rps = vegeta_data["throughput"]&.round(2) || "MISSING"
    vegeta_p50 = vegeta_data.dig("latencies", "50th")&./(1_000_000.0)&.round(2) || "MISSING"
    vegeta_p90 = vegeta_data.dig("latencies", "90th")&./(1_000_000.0)&.round(2) || "MISSING"
    vegeta_status = vegeta_data["status_codes"]&.map { |k, v| "#{k}=#{v}" }&.join(",") || "MISSING"

    [vegeta_rps, vegeta_p50, vegeta_p90, vegeta_status]
  ensure
    # Delete the large binary files to save disk space, including failed partial runs.
    FileUtils.rm_f(result_files)
  end
end

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# Run a batch of test cases against a bundle, collecting per-test failures
# instead of aborting on the first. A failed test is recorded as FAILED in the
# human-readable summary but is NOT added to the BMF collector, so fabricated
# metrics never ship to Bencher. Returns the labels of tests that failed (caller
# exits non-zero when any failed). `runner` is injected so the failure-collection
# control flow can be unit-tested without a live node renderer or Vegeta.
def run_vegeta_suite(test_cases, bundle, label, bmf_collector, runner: method(:run_vegeta_benchmark))
  failed = []

  test_cases.each do |test_case|
    print_separator
    puts "Benchmarking (#{label}): #{test_case[:name]}"
    puts "  Bundle: #{bundle}"
    puts "  Request: #{test_case[:request]}"
    print_separator

    test_label = "#{test_case[:name]} (#{label})"
    begin
      rps, p50, p90, status = runner.call(test_case, bundle)
      add_to_summary(test_case[:name], label, rps, p50, p90, status)
      # Add to BMF collector for Bencher output. p90 is sent to Bencher boundary-less
      # (recorded for a summary-table baseline but never thresholded) and also kept in the
      # display sidecar so the summary table can show it; see BmfCollector.
      bmf_collector.add(name: test_label, rps:, p50:, p90:, status:)
    rescue StandardError => e
      # ::error:: must go to stdout — GitHub Actions only parses workflow commands
      # from stdout, not stderr, so writing here is what renders the UI annotation.
      # Newlines are collapsed so a multiline message can't truncate the
      # annotation (Actions treats a newline as the command terminator).
      $stdout.puts "::error::Vegeta benchmark failed for #{test_label}: #{e.message.to_s.tr("\n", ' ')}"
      failed << test_label
      add_to_summary(test_case[:name], label, *failure_metrics(e))
    end
  end

  failed
end

# Main execution

if __FILE__ == $PROGRAM_NAME
  validate_node_renderer_benchmark_config!

  # Check required tools
  check_required_tools(%w[vegeta curl column tee bash])

  # Wait for node renderer to be ready
  # Note: Node renderer only speaks HTTP/2, but we can still check with a simple GET
  # that will fail - we just check it doesn't refuse connection
  puts "\nWaiting for node renderer at #{BASE_URL}..."
  base_uri = URI.parse("http://#{BASE_URL}")
  start_time = Time.now
  timeout_sec = 60
  loop do
    # Try a simple TCP connection to check if server is up
    Socket.tcp(base_uri.host, base_uri.port, connect_timeout: 5, &:close)
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
    skipped = rsc_tests.map { |tc| tc[:name] }.join(", ")
    puts "Warning: RSC tests requested but no RSC bundle found, skipping: #{skipped}"
    rsc_tests = []
  end

  if non_rsc_tests.any? && non_rsc_bundle.nil?
    skipped = non_rsc_tests.map { |tc| tc[:name] }.join(", ")
    puts "Warning: Non-RSC tests requested but no non-RSC bundle found, skipping: #{skipped}"
    non_rsc_tests = []
  end

  # Fail fast if bundle discovery/categorization left nothing to benchmark.
  # Otherwise failed_tests stays empty and the script exits 0 after producing
  # only an empty summary — turning a broken discovery run into a false green,
  # exactly the silent-success class this script is meant to prevent. Mirrors
  # bench.rb's `raise "No routes to benchmark"` guard.
  if rsc_tests.empty? && non_rsc_tests.empty?
    raise "No benchmarkable test cases found for the discovered bundles " \
          "(RSC bundle: #{rsc_bundle || 'none'}, non-RSC bundle: #{non_rsc_bundle || 'none'})"
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
    "LOAD_GENERATOR_SHARDS" => LOAD_GENERATOR_SHARDS,
    "RSC_TESTS" => rsc_tests.map { |tc| tc[:name] }.join(", ").then { |s| s.empty? ? "none" : s },
    "NON_RSC_TESTS" => non_rsc_tests.map { |tc| tc[:name] }.join(", ").then { |s| s.empty? ? "none" : s }
  )

  # Create output directory
  FileUtils.mkdir_p(OUTDIR)
  target_monitor = BenchmarkTargetMonitor.from_env(output_dir: OUTDIR)
  target_monitor.start_measurement!

  # Initialize BMF collector for Bencher output
  bmf_collector = BmfCollector.new(prefix: BMF_PREFIX)

  # Initialize summary file
  File.write(SUMMARY_TXT, "")
  add_to_summary("Test", "Bundle", "RPS", "p50(ms)", "p90(ms)", "Status")

  failed_tests = []
  failed_tests.concat(run_vegeta_suite(non_rsc_tests, non_rsc_bundle, "non-RSC", bmf_collector))
  failed_tests.concat(run_vegeta_suite(rsc_tests, rsc_bundle, "RSC", bmf_collector))

  # Display summary
  display_summary(SUMMARY_TXT)

  # Write the Bencher payload only on a fully green run against a healthy target.
  # Guarding the write here makes the "never upload partial metrics" invariant
  # self-enforcing instead of relying on later workflow steps to discard data.
  if failed_tests.empty?
    begin
      # Append to existing Pro results and display sidecar rows.
      write_benchmark_payload(bmf_collector, target_monitor:, append: true)
    rescue BenchmarkTargetMonitor::MonitorFailure => e
      $stdout.puts "::error::#{e.message}"
      exit 1
    end
  else
    $stdout.puts "::error::#{failed_tests.length} node renderer benchmark(s) failed: #{failed_tests.join(', ')}"
    exit 1
  end
end
