# rubocop:disable Naming/FileName
# frozen_string_literal: true

# Repeated A/B benchmark orchestrator for the local dedicated-hardware runner.
#
# This script does not benchmark directly. It creates temporary worktrees for two
# refs, waits for the machine to be quiet before each run, invokes
# run-local-benchmark.rb repeatedly in balanced A/B order, and writes a local
# aggregate summary. Upload is opt-in so exploratory repeats do not pollute the
# dedicated Bencher trend by default.

require "English"
require "fileutils"
require "json"
require "optparse"
require "shellwords"
require "time"

require_relative "lib/local_benchmark_runner/ab_run_plan"
require_relative "lib/local_benchmark_runner/comparison_summary"
require_relative "lib/local_benchmark_runner/machine_quiet"

REPO_ROOT = File.expand_path("..", __dir__)
RUNNER_SHIM_FILES = %w[
  benchmarks/generate_matrix.rb
  benchmarks/bench.rb
  benchmarks/bench-node-renderer.rb
  benchmarks/run-local-benchmark.rb
  benchmarks/lib/benchmark_config.rb
  benchmarks/lib/benchmark_helpers.rb
  benchmarks/lib/benchmark_target_monitor.rb
  benchmarks/lib/benchmark_routes.rb
  benchmarks/lib/bmf_helpers.rb
  benchmarks/lib/bencher_runner.rb
  benchmarks/lib/bencher_token.rb
  benchmarks/lib/bencher_report.rb
  benchmarks/lib/bencher_perf_url.rb
  benchmarks/lib/github.rb
  benchmarks/lib/local_benchmark_runner/process_wait.rb
].freeze

options = {
  repetitions: 3,
  testbed: "m1-bench",
  upload: false,
  setup_mode: "first",
  wait_for_quiet: true,
  quiet_thresholds: LocalBenchmarkRunner::MachineQuiet::Thresholds.new,
  duration: "30s",
  rate: "max",
  connections: "10",
  worktree_root: File.join(REPO_ROOT, "tmp", "local-benchmark-comparison"),
  artifact_root: nil,
  cleanup_worktrees: false,
  dry_run: false
}

# rubocop:disable Metrics/BlockLength
parser = OptionParser.new do |opts|
  opts.banner = [
    "Usage: ruby benchmarks/run-local-benchmark-comparison.rb SUITE",
    "--a-ref REF --b-ref REF [options]"
  ].join(" ")
  opts.on("--a-ref REF", "Git ref for scenario A") { |value| options[:a_ref] = value }
  opts.on("--b-ref REF", "Git ref for scenario B") { |value| options[:b_ref] = value }
  opts.on("--a-name NAME", "Scenario A label (default: sanitized --a-ref)") { |value| options[:a_name] = value }
  opts.on("--b-name NAME", "Scenario B label (default: sanitized --b-ref)") { |value| options[:b_name] = value }
  opts.on("--baseline NAME", "Baseline scenario for deltas (default: A)") { |value| options[:baseline] = value }
  opts.on("--candidate NAME", "Candidate scenario for deltas (default: B)") { |value| options[:candidate] = value }
  opts.on("--repetitions N", Integer, "A/B repetitions (default: 3)") { |value| options[:repetitions] = value }
  opts.on("--testbed NAME", "Bencher testbed for optional uploads (default: m1-bench)") do |value|
    options[:testbed] = value
  end
  opts.on("--[no-]upload", "Upload each run to Bencher (default: no)") { |value| options[:upload] = value }
  opts.on("--setup-mode MODE", "all | first | none (default: first)") { |value| options[:setup_mode] = value }
  opts.on("--[no-]wait-for-quiet", "Wait for a quiet machine window before each run (default: yes)") do |value|
    options[:wait_for_quiet] = value
  end
  opts.on("--quiet-load-per-core N", Float, "Max 1m load average per CPU (default: 0.25)") do |value|
    options[:quiet_thresholds].max_load_per_core = value
  end
  opts.on("--quiet-cpu-percent N", Float, "Max aggregate CPU percent of machine capacity (default: 20)") do |value|
    options[:quiet_thresholds].max_cpu_percent = value
  end
  opts.on("--quiet-top-process-percent N", Float, "Max single-process CPU percent (default: 75)") do |value|
    options[:quiet_thresholds].max_top_process_percent = value
  end
  opts.on("--quiet-samples N", Integer, "Consecutive quiet samples required (default: 6)") do |value|
    options[:quiet_thresholds].required_samples = value
  end
  opts.on("--quiet-interval SECONDS", Integer, "Quiet sample interval (default: 10)") do |value|
    options[:quiet_thresholds].sample_interval = value
  end
  opts.on("--quiet-timeout SECONDS", Integer, "Max wait for each quiet window (default: 21600)") do |value|
    options[:quiet_thresholds].timeout = value
  end
  opts.on("--duration D", "Per-route benchmark duration (default: 30s)") { |value| options[:duration] = value }
  opts.on("--rate R", "Requests per second, or 'max' (default: max)") { |value| options[:rate] = value }
  opts.on("--connections N", "Concurrent connections/VUs (default: 10)") { |value| options[:connections] = value }
  opts.on("--worktree-root PATH", "Temporary worktree parent") { |value| options[:worktree_root] = value }
  opts.on("--artifact-root PATH", "Comparison artifact directory") { |value| options[:artifact_root] = value }
  opts.on("--cleanup-worktrees", "Remove temporary worktrees after the run") { options[:cleanup_worktrees] = true }
  opts.on("--dry-run", "Print the plan without creating worktrees or running benchmarks") { options[:dry_run] = true }
  opts.on("-h", "--help") do
    puts opts
    exit 0
  end
end

# rubocop:enable Naming/FileName
# rubocop:enable Metrics/BlockLength
parser.parse!

suite = ARGV.shift
abort parser.help if suite.nil?
abort "--a-ref is required" if options[:a_ref].to_s.empty?
abort "--b-ref is required" if options[:b_ref].to_s.empty?
abort "--repetitions must be positive" unless options[:repetitions].positive?
abort "--setup-mode must be one of: all, first, none" unless %w[all first none].include?(options[:setup_mode])

def log(message)
  puts "\n=== #{message} ==="
end

def sanitize_name(value)
  value.to_s.downcase.gsub(/[^a-z0-9._-]+/, "-").gsub(/\A-+|-+\z/, "")
end

def validate_scenarios!(a_name:, b_name:, baseline:, candidate:)
  abort "--a-name resolved to an empty scenario name" if a_name.empty?
  abort "--b-name resolved to an empty scenario name" if b_name.empty?
  abort "A/B scenario names must be distinct after sanitizing refs or applying --a-name/--b-name" if a_name == b_name

  scenario_names = [a_name, b_name]
  return if scenario_names.include?(baseline) && scenario_names.include?(candidate)

  valid_names = scenario_names.join(", ")
  abort "--baseline and --candidate must match scenario names: #{valid_names}"
end

def run_command!(args, chdir:)
  puts "+ (#{chdir}) #{Shellwords.join(args)}"
  success = system(*args, chdir:)
  return if success

  status = $CHILD_STATUS&.exitstatus || "exec error"
  raise format(
    "command failed (exit %<status>s): %<command>s",
    status:,
    command: Shellwords.join(args)
  )
end

def ensure_worktree(ref, path)
  FileUtils.mkdir_p(File.dirname(path))
  run_command!(["git", "worktree", "add", "--detach", path, ref], chdir: REPO_ROOT)
end

def install_runner_shim(worktree)
  RUNNER_SHIM_FILES.each do |relative_path|
    source = File.join(REPO_ROOT, relative_path)
    destination = File.join(worktree, relative_path)
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp(source, destination)
  end
end

def copy_run_artifacts(worktree, destination)
  FileUtils.mkdir_p(destination)
  %w[benchmark.json benchmark_display.json summary.txt bencher_report.json].each do |filename|
    source = File.join(worktree, "bench_results", filename)
    FileUtils.cp(source, File.join(destination, filename)) if File.exist?(source)
  end
end

def write_quiet_samples(path, result)
  payload = {
    quiet: result.quiet?,
    reason: result.reason,
    samples: result.samples.map do |sample|
      {
        timestamp: sample.timestamp.iso8601,
        load_per_core: sample.load_per_core,
        cpu_percent: sample.cpu_percent,
        top_process_percent: sample.top_process_percent,
        quiet: sample.quiet?,
        reason: sample.reason
      }
    end
  }
  File.write(path, JSON.pretty_generate(payload))
end

def setup_arg_for(setup_mode, scenario_seen)
  case setup_mode
  when "all"
    nil
  when "first"
    scenario_seen ? "--no-setup" : nil
  when "none"
    "--no-setup"
  end
end

def run_artifact_dir(artifact_root, step)
  File.join(
    artifact_root,
    format(
      "%<index>02d-%<scenario>s-run-%<repetition>02d",
      index: step.sequence_index,
      scenario: step.scenario,
      repetition: step.repetition
    )
  )
end

def wait_for_quiet!(step, destination, thresholds)
  log "Wait for quiet machine before #{step.scenario} repetition #{step.repetition}"
  quiet_result = LocalBenchmarkRunner::MachineQuiet.new(thresholds:).wait
  write_quiet_samples(File.join(destination, "quiet_samples.json"), quiet_result)
  abort quiet_result.reason unless quiet_result.quiet?

  puts quiet_result.samples.last.summary
end

def benchmark_json_path!(step, destination)
  benchmark_json = File.join(destination, "benchmark.json")
  return benchmark_json if File.exist?(benchmark_json)

  abort format(
    "Benchmark JSON missing after %<scenario>s repetition %<repetition>d",
    scenario: step.scenario,
    repetition: step.repetition
  )
end

def benchmark_command(suite, branch, options, setup_arg)
  command = [
    "ruby", "benchmarks/run-local-benchmark.rb", suite,
    "--branch", branch,
    "--testbed", options[:testbed],
    "--duration", options[:duration],
    "--rate", options[:rate],
    "--connections", options[:connections],
    options[:upload] ? "--upload" : "--no-upload"
  ]
  command << setup_arg if setup_arg
  command
end

def run_benchmark_step(step:, scenarios:, suite:, options:, artifact_root:, seen_scenarios:)
  scenario = scenarios.fetch(step.scenario)
  destination = run_artifact_dir(artifact_root, step)
  FileUtils.mkdir_p(destination)

  wait_for_quiet!(step, destination, options[:quiet_thresholds]) if options[:wait_for_quiet]

  setup_arg = setup_arg_for(options[:setup_mode], seen_scenarios[step.scenario])
  log "Run #{step.scenario} repetition #{step.repetition}"
  run_command!(
    benchmark_command(suite, step.scenario, options, setup_arg),
    chdir: scenario.fetch(:worktree)
  )
  seen_scenarios[step.scenario] = true

  copy_run_artifacts(scenario.fetch(:worktree), destination)
  LocalBenchmarkRunner::ComparisonSummary::Run.new(
    scenario: step.scenario,
    repetition: step.repetition,
    benchmark_json: benchmark_json_path!(step, destination)
  )
end

def top_route_groups(summary)
  routes = summary.route_summaries.values
  {
    improvements: routes.select { |route| route.rps_delta_percent&.positive? }
                        .sort_by { |route| -route.rps_delta_percent }
                        .first(10),
    regressions: routes.select { |route| route.rps_delta_percent&.negative? }
                       .sort_by(&:rps_delta_percent)
                       .first(10)
  }
end

def write_markdown_summary(path, summary)
  route_groups = top_route_groups(summary)

  File.open(path, "w") do |file|
    write_markdown_metadata(file, summary)
    write_markdown_section(file, "Largest Candidate RPS Improvements", route_groups.fetch(:improvements))
    write_markdown_section(file, "Largest Candidate RPS Regressions", route_groups.fetch(:regressions))
  end
end

def write_markdown_metadata(file, summary)
  file.puts "# Local Benchmark Comparison"
  file.puts
  file.puts "- Baseline: `#{summary.baseline}`"
  file.puts "- Candidate: `#{summary.candidate}`"
  file.puts "- Common routes: #{summary.to_h.fetch(:common_route_count)}"
  unless summary.only_baseline_routes.empty?
    file.puts "- Baseline-only routes: #{summary.only_baseline_routes.join(', ')}"
  end
  unless summary.only_candidate_routes.empty?
    file.puts "- Candidate-only routes: #{summary.only_candidate_routes.join(', ')}"
  end
  file.puts
end

def write_markdown_section(file, title, rows)
  file.puts "## #{title}"
  file.puts
  write_markdown_rows(file, rows)
  file.puts
end

def write_markdown_rows(file, rows)
  if rows.empty?
    file.puts "_None._"
    return
  end

  file.puts "| Route | Delta | Baseline median RPS | Candidate median RPS | Baseline CV | Candidate CV |"
  file.puts "| --- | ---: | ---: | ---: | ---: | ---: |"
  format_string = "| `%<route>s` | %<delta>+.1f%% | %<baseline>.2f | %<candidate>.2f | " \
                  "%<baseline_cv>.1f%% | %<candidate_cv>.1f%% |"
  rows.each do |row|
    file.puts format(
      format_string,
      route: row.route,
      delta: row.rps_delta_percent,
      baseline: row.baseline_median_rps,
      candidate: row.candidate_median_rps,
      baseline_cv: row.baseline_cv_percent || 0.0,
      candidate_cv: row.candidate_cv_percent || 0.0
    )
  end
end

timestamp = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
a_name = options[:a_name] || sanitize_name(options[:a_ref])
b_name = options[:b_name] || sanitize_name(options[:b_ref])
baseline = options[:baseline] || a_name
candidate = options[:candidate] || b_name
validate_scenarios!(a_name:, b_name:, baseline:, candidate:)
run_root = File.join(options[:worktree_root], timestamp)
artifact_root = options[:artifact_root] || File.join(REPO_ROOT, "bench_results", "local_comparison", timestamp)
scenarios = {
  a_name => { ref: options[:a_ref], worktree: File.join(run_root, a_name) },
  b_name => { ref: options[:b_ref], worktree: File.join(run_root, b_name) }
}
plan = LocalBenchmarkRunner::AbRunPlan.new(a_name:, b_name:, repetitions: options[:repetitions])

log "Plan"
puts "Suite: #{suite}"
puts "A: #{a_name} (#{options[:a_ref]})"
puts "B: #{b_name} (#{options[:b_ref]})"
puts "Baseline -> candidate: #{baseline} -> #{candidate}"
plan_order = plan.steps.map { |step| "#{step.scenario}[#{step.repetition}]" }.join(" -> ")
puts "Order: #{plan_order}"
puts "Artifacts: #{artifact_root}"
puts "Upload: #{options[:upload]}"
puts "Quiet gate: #{options[:wait_for_quiet]}"
exit 0 if options[:dry_run]

begin
  log "Create temporary worktrees"
  scenarios.each_value do |scenario|
    ensure_worktree(scenario.fetch(:ref), scenario.fetch(:worktree))
    install_runner_shim(scenario.fetch(:worktree))
  end

  runs = []
  seen_scenarios = {}
  FileUtils.mkdir_p(artifact_root)

  plan.steps.each do |step|
    runs << run_benchmark_step(
      step:,
      scenarios:,
      suite:,
      options:,
      artifact_root:,
      seen_scenarios:
    )
  end

  summary = LocalBenchmarkRunner::ComparisonSummary.new(runs:, baseline:, candidate:)
  File.write(File.join(artifact_root, "comparison_summary.json"), JSON.pretty_generate(summary.to_h))
  write_markdown_summary(File.join(artifact_root, "comparison_summary.md"), summary)
  log "Done"
  puts "Summary: #{File.join(artifact_root, 'comparison_summary.md')}"
ensure
  if options[:cleanup_worktrees]
    scenarios.each_value do |scenario|
      worktree = scenario.fetch(:worktree)
      run_command!(["git", "worktree", "remove", "--force", worktree], chdir: REPO_ROOT) if Dir.exist?(worktree)
    end
  end
end
