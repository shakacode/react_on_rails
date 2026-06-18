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
# Pro renders via a node renderer; bin/prod (Procfile.prod) starts it on RENDERER_PORT and
# Rails reaches it at REACT_RENDERER_URL. Pin both so a local override/stale renderer can't
# desync them (see the pro server env + preflight below).
RENDERER_PORT = 3800

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
  opts.on("--branch NAME", "Bencher branch/series (default: the checked-out git ref)") { |v| options[:branch] = v }
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

# Fail fast on upload prerequisites BEFORE the long build + benchmark, so a missing token or
# CLI doesn't waste a full dedicated-hardware run that can't be recorded.
if options[:upload]
  abort "BENCHER_API_TOKEN is not set; export it or pass --no-upload." unless ENV["BENCHER_API_TOKEN"]
  abort "bencher CLI not found on PATH; install it or pass --no-upload." if `command -v bencher`.strip.empty?
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

# The git ref being benchmarked, used as the Bencher branch/series so a non-main checkout
# (an RC tag, a feature branch) never lands in — and pollutes — the dedicated main baseline.
# Branch name when on a branch; tag name for a detached tag checkout; short SHA otherwise.
def git_ref
  branch = `git -C #{Shellwords.escape(REPO_ROOT)} symbolic-ref --short -q HEAD`.strip
  return branch unless branch.empty?

  tag = `git -C #{Shellwords.escape(REPO_ROOT)} describe --tags --exact-match 2>/dev/null`.strip
  return tag unless tag.empty?

  `git -C #{Shellwords.escape(REPO_ROOT)} rev-parse --short HEAD`.strip
end

# Run a command, streaming output, raising on failure. Returns nothing.
# Clears BENCHER_API_TOKEN for the child: only the final in-process Bencher upload needs it,
# so setup/build/benchmark subprocesses (pnpm, Rails, the app) shouldn't see the upload token.
# (`nil` in the env hash unsets the key for the child.)
def run!(command, chdir: REPO_ROOT, env: {})
  puts "+ (#{chdir}) #{command}"
  success = system({ "BENCHER_API_TOKEN" => nil }.merge(env), "bash", "-lc", command, chdir:)
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
    prod = { "RAILS_ENV" => "production" }
    log "Prepare + seed benchmark database"
    run!("bundle exec rails db:prepare", chdir: app_dir, env: prod)
    # db:prepare only seeds when it CREATES the database, so on a persistent host the DB can
    # carry stale/old rows from a previous seed version or manual experimentation — which the
    # benchmark would then measure. Reseed every run: db/seeds.rb clears and recreates
    # deterministic, faker-free data and is designed to be re-run under production, so this is
    # idempotent and keeps /posts_page benchmarking the current dataset.
    run!("bundle exec rails db:seed", chdir: app_dir, env: prod)
    # Confirm the reseed populated the tables the DB-backed routes read (same shape as the CI
    # guard) — a fail-loud backstop so an empty DB can't pass as a healthy "No posts found" 200.
    db_guard = <<~'RUBY'
      counts = { posts: Post.count, users: User.count, comments: Comment.count }
      empty = counts.select { |_, count| count.zero? }.keys
      abort("Benchmark DB still empty after db:seed (#{empty.join(', ')})") if empty.any?
      puts "DB seeded (#{counts.map { |table, count| "#{count} #{table}" }.join(', ')})"
    RUBY
    run!("bundle exec rails runner #{Shellwords.escape(db_guard)}", chdir: app_dir, env: prod)
  end
else
  log "Skipping setup (--no-setup); reusing the existing build"
end

# Server env mirrors the CI suite. No taskset: it's Linux-only and absent on macOS, so the
# server runs unpinned (the dedicated machine has no competing load anyway). PORT is pinned to
# SERVER_PORT (bin/prod honors an ambient PORT/RAILS_PORT) so the server can't land on a
# different port than the one this runner probes and benchmarks.
server_env = {
  "WEB_CONCURRENCY" => web_concurrency.to_s,
  "RAILS_MAX_THREADS" => "3",
  "RAILS_MIN_THREADS" => "3",
  "PORT" => SERVER_PORT.to_s,
  "RAILS_PORT" => SERVER_PORT.to_s
}
if pro
  server_env["REACT_ON_RAILS_PRO_LICENSE"] = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE", "")
  # Pin the renderer port AND the URL Rails uses to reach it to the same value, so an ambient
  # RENDERER_PORT override (or a default-vs-override split) can't make Rails talk to the wrong
  # renderer.
  server_env["RENDERER_PORT"] = RENDERER_PORT.to_s
  server_env["REACT_RENDERER_URL"] = "http://localhost:#{RENDERER_PORT}"
end

# Reject a pre-existing listener BEFORE spawning: otherwise wait_for_server's port check
# could pass against a stale server/dev process and the benchmark would measure (and upload)
# the wrong app. On a persistent host this is a real hazard. Pro also needs the renderer port.
abort "Port #{SERVER_PORT} is already in use — stop the other server/dev process first." if port_open?(SERVER_PORT)
if pro && port_open?(RENDERER_PORT)
  abort "Renderer port #{RENDERER_PORT} is already in use — stop the other process first."
end

server_pid = nil
begin
  log "Start #{suite[:suite_name]} production server (WEB_CONCURRENCY=#{web_concurrency})"
  # Own process group (pgroup: true) so cleanup can terminate the whole tree: bin/prod runs
  # `rails server` as a child (core) or starts overmind/foreman managing rails + node-renderer
  # (pro), so a TERM to the leader alone would orphan those children or block.
  server_pid = Process.spawn(server_env, "bin/prod", chdir: app_dir, pgroup: true)
  wait_for_server(server_pid)
  puts "✅ server ready (pid #{server_pid})"

  log "Run #{suite[:suite_name]} benchmark"
  FileUtils.mkdir_p(results_dir)
  # Drop any prior payload so the post-run existence check can't pass on a stale file if this
  # run exits 0 without writing fresh metrics (e.g. k6 metrics MISSING -> no BMF written).
  FileUtils.rm_f(benchmark_json)
  bench_env = {
    "PRO" => pro.to_s,
    "BASE_URL" => "localhost:#{SERVER_PORT}",
    # Lets bench.rb's BenchmarkTargetMonitor discard metrics if the server dies mid-run
    # instead of uploading numbers from a dead/restarting target (same as the CI suite).
    "TARGET_PID" => server_pid.to_s,
    "BENCHMARK_TOOL" => suite.fetch(:benchmark_tool),
    "RATE" => options[:rate],
    "DURATION" => options[:duration],
    "CONNECTIONS" => options[:connections],
    "MAX_CONNECTIONS" => options[:connections],
    "REQUEST_TIMEOUT" => "60s"
  }
  run!("ruby #{Shellwords.escape(bench_script)}", chdir: REPO_ROOT, env: bench_env)
ensure
  if server_pid
    log "Stop server (pid #{server_pid})"
    # Negative pid = the whole process group, so rails/overmind/foreman children all stop.
    begin
      Process.kill("TERM", -server_pid)
    rescue Errno::ESRCH
      nil
    end
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

branch = options[:branch] || git_ref
log "Upload to Bencher (testbed #{options[:testbed]}, branch #{branch})"
# Report under the checked-out ref so a nightly main run feeds the dedicated main trend while
# an RC/feature run forms its own series instead of polluting that baseline. (Token + CLI were
# already verified up front.) A non-main branch clones main's thresholds (same args as the CI
# tracker's PR path) so --fail-on-alert actually compares against the baseline instead of
# starting an empty series that can never alert.
start_point_args = if branch == "main"
                     []
                   else
                     ["--start-point", "main", "--start-point-clone-thresholds", "--start-point-reset"]
                   end
ENV["BENCHER_TESTBED"] = options[:testbed]
result = BencherRunner.new(benchmark_json:, report_json:).run(branch:, start_point_args:)
warn result.stderr unless result.stderr.empty?

if result.report&.regression?
  # A regression means the measurement worked, not that the run failed. BencherRunner passes
  # --err, so result.exit_code is non-zero on any alert — but the default (trend) mode should
  # still succeed and just record the point. Only the explicit --fail-on-alert gate fails.
  warn "::warning:: Bencher flagged a performance regression for #{suite[:suite_name]}."
  exit(options[:fail_on_alert] ? 1 : 0)
end

# Bencher also exits non-zero on a stale/filtered alert (one it still lists but that is not a
# current regression). That is not a failure — match track_benchmarks.rb and treat it as
# success. A non-zero exit with NO alert at all is a genuine operational failure (auth/CLI).
exit 0 if result.exit_code != 0 && result.report&.filtered_alert?
exit result.exit_code
