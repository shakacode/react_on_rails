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
# Supports the rails/k6 suites (core, pro) and the Pro node-renderer/vegeta suite.

require "English"
require "fileutils"
require "optparse"
require "shellwords"

require_relative "generate_matrix"
require_relative "lib/bencher_runner"
require_relative "lib/bencher_token"
require_relative "lib/local_benchmark_runner/process_wait"

REPO_ROOT = File.expand_path("..", __dir__)
SERVER_PORT = 3001
# Pro renders via a node renderer; bin/prod (Procfile.prod) starts it on RENDERER_PORT and
# Rails reaches it at REACT_RENDERER_URL. Pin both so a local override/stale renderer can't
# desync them (see the pro server env + preflight below).
RENDERER_PORT = 3800
# How long to wait for the production server (and, for pro, the renderer) to bind. A cold
# production Puma boot eager-loads the whole app before listening, which is slow on the first
# run after a fresh build — observed ~83s on a 2021 M1 Max, vs ~2s warm. wait_for_port reaps
# an exited direct child each second, so a real crash fails fast; this generous ceiling only
# affects a slow-but-alive boot. Override with BENCHMARK_SERVER_BOOT_TIMEOUT if needed.
SERVER_BOOT_TIMEOUT = ENV.fetch("BENCHMARK_SERVER_BOOT_TIMEOUT", "240").then do |raw|
  seconds = Integer(raw, exception: false)
  next seconds if seconds&.positive?

  abort "BENCHMARK_SERVER_BOOT_TIMEOUT must be a positive integer (seconds); got #{raw.inspect}."
end

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
                "SUITE: core | pro | pro-node-renderer"
  opts.on("--testbed NAME", "Bencher testbed to report to (default: m1-bench)") { |v| options[:testbed] = v }
  opts.on("--branch NAME", "Bencher branch/series (default: the checked-out git ref)") { |v| options[:branch] = v }
  opts.on("--[no-]upload", "Upload results to Bencher (default: on; needs BENCHER_API_KEY or BENCHER_API_TOKEN)") do |v|
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
abort "Unknown suite #{suite_id.inspect}. Supported: core, pro, pro-node-renderer." if suite.nil?

upload_env = {}
# Fail fast on upload prerequisites BEFORE the long build + benchmark, so a missing credential or
# CLI doesn't waste a full dedicated-hardware run that can't be recorded. Treat an empty string
# as unset (BENCHER_API_KEY= would otherwise pass and only fail at upload).
if options[:upload]
  begin
    upload_env = BencherToken.upload_env(
      api_key: ENV.fetch("BENCHER_API_KEY", nil),
      api_token: ENV.fetch("BENCHER_API_TOKEN", nil)
    )
  rescue BencherToken::InvalidToken => e
    abort e.message
  end
  abort "bencher CLI not found on PATH; install it or pass --no-upload." if `command -v bencher`.strip.empty?
end

app_dir = File.join(REPO_ROOT, suite.fetch(:app_directory))
bench_script = File.join(REPO_ROOT, suite.fetch(:benchmark_script))
# bench.rb hardcodes OUTDIR="bench_results" relative to its CWD, and runs from the repo
# root (same as CI), so results land at REPO_ROOT/bench_results — not under the app dir.
results_dir = File.join(REPO_ROOT, "bench_results")
benchmark_json = File.join(results_dir, "benchmark.json")
display_json = File.join(results_dir, "benchmark_display.json")
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
# Clears Bencher upload credentials for the child: only the final in-process Bencher upload
# needs them, so setup/build/benchmark subprocesses (pnpm, Rails, the app) shouldn't see them.
# (`nil` in the env hash unsets the key for the child.)
def run!(command, chdir: REPO_ROOT, env: {})
  puts "+ (#{chdir}) #{command}"
  success = system(
    { "BENCHER_API_KEY" => nil, "BENCHER_API_TOKEN" => nil }.merge(env),
    "bash", "-lc", command, chdir:
  )
  # system returns nil (not false) when the command can't be exec'd at all; $CHILD_STATUS is
  # then nil too, so guard the exitstatus lookup to keep the real failure visible.
  raise "command failed (exit #{$CHILD_STATUS&.exitstatus || 'exec error'}): #{command}" unless success
end

def wait_for_port(pid, port, label)
  LocalBenchmarkRunner::ProcessWait.wait_for_port(pid, port, label, timeout: SERVER_BOOT_TIMEOUT)
end

def port_open?(port)
  LocalBenchmarkRunner::ProcessWait.port_open?(port)
end

web_concurrency = [cpu_count - 1, 1].max
pro = suite.fetch(:pro_env)
pro_app = suite.fetch(:app_directory).start_with?("react_on_rails_pro/")
node_renderer = suite.fetch(:server_kind) == "node-renderer"

# Fail fast (before the long build) if a Pro benchmark is missing its license: the app would
# otherwise boot with an empty license and die mid-startup with a cryptic error.
if pro_app && ENV["REACT_ON_RAILS_PRO_LICENSE"].to_s.empty?
  abort "REACT_ON_RAILS_PRO_LICENSE is required for Pro benchmark suites; export it first."
end

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

  if node_renderer
    prod = { "RAILS_ENV" => "production", "NODE_ENV" => "production" }
    log "Pre-seed node renderer bundle cache"
    run!("bundle exec rake react_on_rails_pro:pre_seed_renderer_cache MODE=symlink", chdir: app_dir, env: prod)
  end

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
  "RAILS_PORT" => SERVER_PORT.to_s,
  # The benchmarked app (Rails + Pro node renderer) is checked-out code; keep Bencher upload
  # credentials out of it — only the final in-process upload needs them.
  "BENCHER_API_KEY" => nil,
  "BENCHER_API_TOKEN" => nil
}
server_env["REACT_ON_RAILS_PRO_LICENSE"] = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE", "") if pro_app
if pro
  # Pin the renderer port AND the URL Rails uses to reach it to the same value, so an ambient
  # RENDERER_PORT override (or a default-vs-override split) can't make Rails talk to the wrong
  # renderer.
  server_env["RENDERER_PORT"] = RENDERER_PORT.to_s
  server_env["REACT_RENDERER_URL"] = "http://localhost:#{RENDERER_PORT}"
end
if node_renderer
  server_env["RAILS_ENV"] = "production"
  server_env["NODE_ENV"] = "production"
  server_env["RENDERER_LOG_LEVEL"] = "error"
  server_env["RENDERER_PORT"] = RENDERER_PORT.to_s
end

# Reject a pre-existing listener BEFORE spawning: otherwise wait_for_port's check
# could pass against a stale server/dev process and the benchmark would measure (and upload)
# the wrong app. On a persistent host this is a real hazard. Pro also needs the renderer port.
if !node_renderer && port_open?(SERVER_PORT)
  abort "Port #{SERVER_PORT} is already in use — stop the other server/dev process first."
end
if (pro || node_renderer) && port_open?(RENDERER_PORT)
  abort "Renderer port #{RENDERER_PORT} is already in use — stop the other process first."
end

server_pid = nil
begin
  start_label = node_renderer ? "#{suite[:suite_name]} node renderer" : "#{suite[:suite_name]} production server"
  log "Start #{start_label} (WEB_CONCURRENCY=#{web_concurrency})"
  # Own process group (pgroup: true) so cleanup can terminate the whole tree: bin/prod runs
  # `rails server` as a child (core) or starts overmind/foreman managing rails + node-renderer
  # (pro), so a TERM to the leader alone would orphan those children or block.
  FileUtils.mkdir_p(results_dir)
  renderer_log = File.join(results_dir, "node-renderer.log")
  spawn_options = { chdir: app_dir, pgroup: true }
  if node_renderer
    spawn_options[:out] = [renderer_log, "w"]
    spawn_options[:err] = %i[child out]
  end
  server_command = node_renderer ? ["node", "renderer/node-renderer.js"] : ["bin/prod"]
  server_pid = Process.spawn(server_env, *server_command, **spawn_options)
  wait_for_port(
    server_pid,
    node_renderer ? RENDERER_PORT : SERVER_PORT,
    node_renderer ? "node renderer" : "Rails server"
  )
  # Pro starts the node renderer concurrently; wait for it too so the benchmark doesn't hit a
  # not-yet-ready renderer and record skewed (cold/erroring) numbers.
  wait_for_port(server_pid, RENDERER_PORT, "node renderer") if pro
  puts "✅ server ready (pid #{server_pid})"

  log "Run #{suite[:suite_name]} benchmark"
  FileUtils.mkdir_p(results_dir)
  # Drop prior payloads so the post-run checks and summary tables cannot pass on stale files if
  # this run exits 0 without writing fresh metrics (e.g. k6 metrics MISSING -> no BMF written).
  FileUtils.rm_f([benchmark_json, display_json])
  bench_env = {
    "PRO" => pro.to_s,
    "BASE_URL" => "localhost:#{node_renderer ? RENDERER_PORT : SERVER_PORT}",
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
  bench_env["TARGET_LOG"] = renderer_log if node_renderer
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
    # Bound the reap: a server that ignores TERM (or a wedged child holding the group open)
    # would otherwise hang Process.wait forever and leave the runner stuck after the
    # benchmark. Poll for the child against a deadline, then escalate to KILL and reap so no
    # zombie is left behind.
    reaped = false
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
    until reaped || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      begin
        reaped = !Process.wait(server_pid, Process::WNOHANG).nil?
      rescue Errno::ECHILD
        reaped = true # Already reaped (or never a child) — nothing left to wait on.
      end
      sleep 0.2 unless reaped
    end
    unless reaped
      warn "Server (pid #{server_pid}) did not exit within 10s of TERM; sending KILL."
      begin
        Process.kill("KILL", -server_pid)
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
upload_env.each do |key, value|
  value.nil? ? ENV.delete(key) : ENV[key] = value
end
# BencherRunner#run already echoes the CLI's stderr, so don't print it again here.
result = BencherRunner.new(benchmark_json:, report_json:).run(branch:, start_point_args:)

if result.report&.regression?
  # A regression means the measurement worked, not that the run failed. BencherRunner passes
  # --err, so result.exit_code is non-zero on any alert — but the default (trend) mode should
  # still succeed and just record the point. Only the explicit --fail-on-alert gate fails.
  # (Plain message, not a ::warning:: workflow command — this is a local script.)
  warn "⚠️  Bencher flagged a performance regression for #{suite[:suite_name]}."
  exit(options[:fail_on_alert] ? 1 : 0)
end

# Bencher also exits non-zero on a stale/filtered alert (one it still lists but that is not a
# current regression). That is not a failure — match track_benchmarks.rb and treat it as
# success. The `!regression?` guard mirrors track_benchmarks.rb's normalized_bencher_exit_code
# and keeps the --fail-on-alert gate above authoritative: a real regression already exited
# (honoring --fail-on-alert), so this branch can never swallow one. A non-zero exit with NO
# alert at all is a genuine operational failure (auth/CLI) and propagates unchanged.
exit 0 if result.exit_code != 0 && result.report&.filtered_alert? && !result.report.regression?
exit result.exit_code
