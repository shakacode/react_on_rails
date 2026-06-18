#!/usr/bin/env ruby
# frozen_string_literal: true

# Local dedicated-hardware benchmark runner (#4073).
#
# Builds, runs, and (optionally) uploads ONE benchmark suite to its own Bencher testbed
# entirely on this machine. Unlike a self-hosted GitHub Actions runner, nothing here is
# triggered by GitHub — there is no listener, no registration, and no way for a fork pull
# request to execute on the machine. It only ever runs the code already checked out in this
# repo. See benchmarks/LOCAL_BENCHMARK.md for usage, scheduling, and the rationale.
#
# It reuses the same building blocks as the CI suite (no duplicated benchmark logic):
#   - generate_matrix.rb SUITES  -> per-suite config (app dir, server kind, tool, ...)
#   - the dummy app's bin/prod*  -> production asset build + server
#   - bench.rb                   -> the actual benchmarking (k6)
#   - lib/bencher_runner.rb      -> upload with the tuned thresholds + the testbed override
#
# v1 supports the rails/k6 suites (core, pro). The node-renderer suite needs extra steps
# (renderer cache pre-seed, a different server + vegeta target) and is intentionally
# deferred; run it in CI for now.

require "English"
require "fileutils"
require "optparse"
require "shellwords"
require "socket"

require_relative "generate_matrix"
require_relative "lib/bencher_runner"

REPO_ROOT = File.expand_path("..", __dir__)
SERVER_PORT = 3001

# Match CI, which runs benchmarks on the MINIMUM supported Ruby ("Ruby stays on minimum to
# exercise gem compatibility"), not the repo's default. The default .tool-versions Ruby can
# be newer than the dummy app can boot — e.g. Ruby 4.0 trips net-imap's Ractor.make_shareable
# restriction and the server exits on startup. Setting MISE_RUBY_VERSION makes every
# `bash -lc` subcommand below resolve Ruby to the minimum via mise. Harmless if the machine
# doesn't use mise (see LOCAL_BENCHMARK.md for the manual fallback).
MIN_RUBY = File.read(File.join(REPO_ROOT, ".minimum.tool-versions"))[/^ruby\s+(\S+)/, 1]
ENV["MISE_RUBY_VERSION"] = MIN_RUBY if MIN_RUBY

options = {
  testbed: "m1-bench",
  upload: true,
  fail_on_alert: false,
  setup: true,
  duration: "30s",
  rate: "max",
  connections: "10"
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby benchmarks/run-local-benchmark.rb SUITE [options]\n  " \
                "SUITE: core | pro   (node-renderer is deferred; run it in CI)"
  opts.on("--testbed NAME", "Bencher testbed to report to (default: m1-bench)") { |v| options[:testbed] = v }
  opts.on("--[no-]upload", "Upload results to Bencher (default: on; needs BENCHER_API_TOKEN)") do |v|
    options[:upload] = v
  end
  opts.on("--fail-on-alert", "Exit non-zero if Bencher flags a regression") { options[:fail_on_alert] = true }
  opts.on("--[no-]setup", "Run the build/setup steps (default: on; skip to reuse a prior build)") do |v|
    options[:setup] = v
  end
  opts.on("--duration D", "Per-route benchmark duration (default: 30s)") { |v| options[:duration] = v }
  opts.on("--rate R", "Requests per second, or 'max' (default: max)") { |v| options[:rate] = v }
  opts.on("--connections N", "Concurrent connections/VUs (default: 10)") { |v| options[:connections] = v }
  opts.on("-h", "--help") do
    puts opts
    exit 0
  end
end
parser.parse!

suite_id = ARGV.shift
abort parser.help if suite_id.nil?

suite = SUITES.find { |s| s[:id] == suite_id }
abort "Unknown suite #{suite_id.inspect}. Supported: core, pro." if suite.nil?
if suite[:server_kind] != "rails"
  abort "Suite #{suite_id.inspect} (#{suite[:server_kind]}) is not supported by the local runner yet; run it in CI."
end

app_dir = File.join(REPO_ROOT, suite.fetch(:app_directory))
bench_script = File.join(REPO_ROOT, suite.fetch(:benchmark_script))
# bench.rb hardcodes OUTDIR="bench_results" relative to its CWD, and runs from the repo
# root (same as CI), so results land at REPO_ROOT/bench_results — not under the app dir.
results_dir = File.join(REPO_ROOT, "bench_results")
benchmark_json = File.join(results_dir, "benchmark.json")
report_json = File.join(results_dir, "bencher_report.json")

# Cross-platform CPU count: works on macOS (sysctl-backed) and Linux. Used to size Puma
# workers the same way the CI "Configure benchmark commands" step does.
def cpu_count
  Integer(`getconf _NPROCESSORS_ONLN`.strip)
rescue StandardError
  1
end

def log(message)
  puts "\n=== #{message} ==="
end

# Run a command, streaming output, raising on failure. Returns nothing.
def run!(command, chdir: REPO_ROOT, env: {})
  puts "+ (#{chdir}) #{command}"
  success = system(env, "bash", "-lc", command, chdir:)
  raise "command failed (#{$CHILD_STATUS.exitstatus}): #{command}" unless success
end

def wait_for_server(pid)
  attempt = 0
  while attempt < 30
    raise "server (pid #{pid}) exited during startup" unless process_alive?(pid)
    return if port_open?(SERVER_PORT)

    attempt += 1
    puts "  attempt #{attempt}/30: server not ready yet..."
    sleep 1
  end
  raise "server failed to start within 30s"
end

def port_open?(port)
  TCPSocket.new("localhost", port).close
  true
rescue StandardError
  false
end

def process_alive?(pid)
  Process.kill(0, pid)
  true
rescue Errno::ESRCH
  false
end

web_concurrency = [cpu_count - 1, 1].max
pro = suite.fetch(:pro_env)

puts "Suite: #{suite[:suite_name]} | Ruby (app): #{MIN_RUBY || 'ambient'} | " \
     "testbed: #{options[:testbed]} | upload: #{options[:upload]}"

if options[:setup]
  log "Install JS deps + build workspace packages"
  run!("pnpm install --frozen-lockfile")
  run!("pnpm run build")

  log "Install Ruby gems for #{suite[:suite_name]}"
  run!("bundle install", chdir: app_dir)

  if suite.fetch(:generate_packs)
    log "Generate file-system based entrypoints"
    run!("bundle exec rake react_on_rails:generate_packs", chdir: app_dir)
  end

  log "Build production assets"
  run!("bin/prod-assets", chdir: app_dir)

  if pro
    log "Prepare + seed benchmark database"
    run!("bundle exec rails db:prepare", chdir: app_dir, env: { "RAILS_ENV" => "production" })
  end
else
  log "Skipping setup (--no-setup); reusing the existing build"
end

# Server env mirrors the CI suite. No taskset: it's Linux-only and absent on macOS, so the
# server runs unpinned (the dedicated machine has no competing load anyway).
server_env = {
  "WEB_CONCURRENCY" => web_concurrency.to_s,
  "RAILS_MAX_THREADS" => "3",
  "RAILS_MIN_THREADS" => "3"
}
server_env["REACT_ON_RAILS_PRO_LICENSE"] = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE", "") if pro

server_pid = nil
begin
  log "Start #{suite[:suite_name]} production server (WEB_CONCURRENCY=#{web_concurrency})"
  server_pid = Process.spawn(server_env, "bin/prod", chdir: app_dir)
  wait_for_server(server_pid)
  puts "✅ server ready (pid #{server_pid})"

  log "Run #{suite[:suite_name]} benchmark"
  FileUtils.mkdir_p(results_dir)
  bench_env = {
    "PRO" => pro.to_s,
    "BASE_URL" => "localhost:#{SERVER_PORT}",
    "BENCHMARK_TOOL" => suite.fetch(:benchmark_tool),
    "RATE" => options[:rate],
    "DURATION" => options[:duration],
    "CONNECTIONS" => options[:connections],
    "MAX_CONNECTIONS" => options[:connections],
    "REQUEST_TIMEOUT" => "60s"
  }
  run!("ruby #{Shellwords.escape(bench_script)}", chdir: REPO_ROOT, env: bench_env)
ensure
  if server_pid && process_alive?(server_pid)
    log "Stop server (pid #{server_pid})"
    Process.kill("TERM", server_pid)
    begin
      Process.wait(server_pid)
    rescue Errno::ECHILD
      nil
    end
  end
end

unless File.exist?(benchmark_json)
  abort "Benchmark JSON not found at #{benchmark_json} — the benchmark did not produce results."
end

unless options[:upload]
  log "Done (--no-upload). Results: #{benchmark_json}"
  exit 0
end

log "Upload to Bencher (testbed #{options[:testbed]})"
ENV.fetch("BENCHER_API_TOKEN") do
  abort "BENCHER_API_TOKEN is not set; export it or pass --no-upload."
end
# The local runner always reports to the testbed's own `main` series (no PR/branch logic):
# this machine benchmarks merged main, so its history is a single dedicated-hardware trend.
ENV["BENCHER_TESTBED"] = options[:testbed]
result = BencherRunner.new(benchmark_json:, report_json:).run(branch: "main", start_point_args: [])
warn result.stderr unless result.stderr.empty?

if result.report&.regression?
  warn "::warning:: Bencher flagged a performance regression for #{suite[:suite_name]}."
  exit 1 if options[:fail_on_alert]
end

exit result.exit_code
