#!/usr/bin/env ruby
# frozen_string_literal: true

# Recover historical benchmark data from GH Actions artifacts and submit to Bencher.
#
# The Bencher integration was broken from ~Jan 2026: push-to-main runs passed
# --start-point-hash pointing to commits not in Bencher, causing a 404 that
# silently dropped the report. This script backfills the gap.
#
# Two-phase workflow:
#   1. `download` — fetch all missing benchmark.json artifacts into WORK_DIR
#   2. `push`     — submit each to Bencher, deleting the artifact on success
#
# Requires: gh CLI (authenticated), bencher CLI (for push), ruby json/open-uri
#
# Usage:
#   ruby scripts/recover-bencher-data.rb download [--work-dir=DIR]
#   BENCHER_API_TOKEN=... ruby scripts/recover-bencher-data.rb push [--work-dir=DIR] [--dry-run]

# rubocop:disable Metrics

require "json"
require "net/http"
require "uri"
require "fileutils"
require "open3"
require "set"
require "parallel"

REPO = "shakacode/react_on_rails"
PROJECT = "react-on-rails-t8a9ncxo"
TESTBED = "github-actions"
BENCHER_API = "https://api.bencher.dev/v0"

def main
  command = ARGV.find { |a| !a.start_with?("--") } || abort(usage)
  work_dir = extract_opt("--work-dir") || ".bencher-recovery"
  dry_run = ARGV.include?("--dry-run")

  case command
  when "download" then cmd_download(work_dir)
  when "push"     then cmd_push(work_dir, dry_run: dry_run)
  when "delete"   then cmd_delete(dry_run: dry_run)
  else abort "Unknown command: #{command}\n\n#{usage}"
  end
end

def usage
  <<~TEXT
    Usage:
      ruby #{$PROGRAM_NAME} download [--work-dir=DIR]
      ruby #{$PROGRAM_NAME} push [--work-dir=DIR] [--dry-run]
      ruby #{$PROGRAM_NAME} delete [--dry-run]              # delete today's bad backfill reports
  TEXT
end

def extract_opt(prefix)
  arg = ARGV.find { |a| a.start_with?("#{prefix}=") }
  arg&.split("=", 2)&.last
end

# ── Phase 1: Download ────────────────────────────────────────────────────

def cmd_download(work_dir)
  ensure_cmd!("gh")
  artifacts_dir = File.join(work_dir, "artifacts")
  FileUtils.mkdir_p(artifacts_dir)

  existing = Set.new(load_cached(work_dir, "bencher_hashes.json") { fetch_bencher_hashes })
  puts "  #{existing.size} hashes in Bencher (cached)"

  runs = load_cached(work_dir, "successful_runs.json") { fetch_successful_runs }
  puts "  #{runs.size} successful runs from GH Actions (cached)"

  # Artifacts have 30-day retention — skip runs older than that
  cutoff = (Time.now - (30 * 24 * 3600)).strftime("%Y-%m-%d")
  recent, too_old = runs.partition { |r| r[:date] >= cutoff }

  # Partition recent runs into buckets
  in_bencher, not_in_bencher = recent.partition { |r| existing.include?(r[:sha]) }
  already_downloaded, to_download = not_in_bencher.partition do |r|
    File.exist?(File.join(artifacts_dir, r[:sha], "benchmark.json"))
  end

  puts "\n  Artifacts expired (>30d): #{too_old.size}"
  puts "  Already in Bencher:       #{in_bencher.size}"
  puts "  Already downloaded:       #{already_downloaded.size}"
  puts "  To download:              #{to_download.size}"

  if to_download.empty?
    puts "\nNothing to download!"
    return
  end

  results = Parallel.map(to_download, in_threads: 4, progress: "Downloading") do |run|
    dest = File.join(artifacts_dir, run[:sha])
    FileUtils.mkdir_p(dest)

    if download_artifact(run[:id], dest)
      :ok
    else
      FileUtils.rm_rf(dest) if Dir.exist?(dest) && Dir.empty?(dest)
      artifact_expired?(run[:id]) ? :expired : :failed
    end
  end

  downloaded = results.count(:ok)
  expired = results.count(:expired)
  failed = results.count(:failed)

  puts("=" * 40)
  puts "Downloaded: #{downloaded}  Expired: #{expired}  Failed: #{failed}"
  puts "\nRun 'push' to submit to Bencher." if downloaded.positive?
end

# ── Phase 2: Push ────────────────────────────────────────────────────────

def cmd_push(work_dir, dry_run:)
  token = ENV["BENCHER_API_TOKEN"] || extract_opt("--token")
  abort "Error: BENCHER_API_TOKEN env var required" unless token
  ensure_cmd!("bencher") unless dry_run

  artifacts_dir = File.join(work_dir, "artifacts")
  abort "No artifacts directory found at #{artifacts_dir}. Run 'download' first." unless Dir.exist?(artifacts_dir)

  puts "Fetching current Bencher hashes..."
  existing = Set.new(fetch_bencher_hashes(token: token))
  puts "  #{existing.size} hashes in Bencher"

  # Build SHA → original timestamp mapping from cached runs
  runs_cache = File.join(work_dir, "successful_runs.json")
  sha_to_time = {}
  if File.exist?(runs_cache)
    JSON.parse(File.read(runs_cache), symbolize_names: true).each do |r|
      sha_to_time[r[:sha]] = r[:created]
    end
  end

  # Find all downloaded artifacts with benchmark.json
  entries = Dir.glob(File.join(artifacts_dir, "*", "benchmark.json")).map do |path|
    sha = File.basename(File.dirname(path))
    { sha: sha, path: path, dir: File.dirname(path), created: sha_to_time[sha] }
  end

  # Filter out already-pushed
  to_push = entries.reject { |e| existing.include?(e[:sha]) }
  puts "  Already pushed: #{entries.size - to_push.size}"
  puts "  To push:        #{to_push.size}"

  if to_push.empty?
    puts "\nNothing to push!"
    return
  end

  # Sort by original GH Actions run timestamp — git-based sorting fails in shallow CI clones
  to_push.sort_by! { |e| e[:created] || "" }

  if dry_run
    puts "\nDry-run — would push:"
    to_push.each { |e| puts "  #{e[:sha][0, 10]}" }
    return
  end

  puts "\nPushing #{to_push.size} reports to Bencher (branch: main)..."
  success = 0
  failed = 0

  to_push.each_with_index do |entry, idx|
    sha = entry[:sha]
    puts "\n[#{idx + 1}/#{to_push.size}] #{sha[0, 10]}"

    benchmarks = JSON.parse(File.read(entry[:path]))
    puts "  #{benchmarks.size} benchmarks"

    ok = run_bencher(token: token, sha: sha, file: entry[:path], created: entry[:created])
    if ok
      success += 1
      puts "  Submitted — removing artifact"
      FileUtils.rm_rf(entry[:dir])
    else
      failed += 1
      puts "  FAILED — artifact kept for retry"
    end
  end

  puts "\n#{'=' * 40}"
  puts "Submitted: #{success}  Failed: #{failed}"
  return unless failed.positive?

  puts "Re-run 'push' to retry failures."
  exit 1
end

# ── Phase 3: Delete bad backfill reports ─────────────────────────────────

def cmd_delete(dry_run:)
  token = ENV["BENCHER_API_TOKEN"] || extract_opt("--token")
  abort "Error: BENCHER_API_TOKEN env var required" unless token

  puts "Fetching all reports on main branch..."
  uri = URI("#{BENCHER_API}/projects/#{PROJECT}/reports?branch=main&per_page=250&direction=desc")
  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer #{token}"
  resp = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  abort "Failed to fetch reports: #{resp.code}" unless resp.is_a?(Net::HTTPSuccess)

  reports = JSON.parse(resp.body)
  # Delete all reports so we can resubmit in correct chronological order
  bad_reports = reports

  puts "  #{bad_reports.size} reports to delete"

  if bad_reports.empty?
    puts "Nothing to delete."
    return
  end

  if dry_run
    puts "\nDry-run — would delete:"
    bad_reports.each { |r| puts "  #{r['uuid']}  #{r['start_time']}" }
    return
  end

  puts "\nDeleting #{bad_reports.size} reports..."
  deleted = 0
  bad_reports.each do |report|
    uri = URI("#{BENCHER_API}/projects/#{PROJECT}/reports/#{report['uuid']}")
    req = Net::HTTP::Delete.new(uri)
    req["Authorization"] = "Bearer #{token}"
    resp = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    if resp.is_a?(Net::HTTPSuccess)
      deleted += 1
      print "."
    else
      puts "\n  Failed to delete #{report['uuid']}: #{resp.code} #{resp.body[0, 100]}"
    end
  end
  puts "\nDeleted #{deleted}/#{bad_reports.size} reports."
end

# ── Helpers ──────────────────────────────────────────────────────────────

def load_cached(work_dir, filename)
  path = File.join(work_dir, filename)
  return JSON.parse(File.read(path), symbolize_names: true) if File.exist?(path)

  data = yield
  File.write(path, JSON.pretty_generate(data))
  data
end

def ensure_cmd!(cmd)
  return if system("command -v #{cmd} > /dev/null 2>&1")

  abort "Error: #{cmd} not found in PATH"
end

def fetch_bencher_hashes(token: nil)
  uri = URI("#{BENCHER_API}/projects/#{PROJECT}/reports?branch=main&per_page=250&direction=asc")
  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer #{token}" if token

  resp = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  return [] unless resp.is_a?(Net::HTTPSuccess)

  reports = JSON.parse(resp.body)
  reports.filter_map { |r| r.dig("branch", "head", "version", "hash") }.uniq
rescue StandardError => e
  warn "  Warning: could not fetch Bencher hashes: #{e.message}"
  []
end

def fetch_successful_runs
  runs = []
  %w[master main].each do |branch|
    output, status = Open3.capture2(
      "gh", "api", "--paginate",
      "repos/#{REPO}/actions/workflows/benchmark.yml/runs?branch=#{branch}&status=success&per_page=100",
      "--jq", '.workflow_runs[] | "\(.id)\t\(.head_sha)\t\(.created_at)"'
    )
    next unless status.success?

    output.each_line do |line|
      id, sha, created = line.strip.split("\t")
      runs << { id: id, sha: sha, created: created, date: created&.slice(0, 10) }
    end
  end
  runs.sort_by { |r| r[:created] }
end

def download_artifact(run_id, dest)
  # Prefer pro artifact (has combined core+pro benchmark.json)
  artifact_name = gh_api_jq(
    "repos/#{REPO}/actions/runs/#{run_id}/artifacts",
    '[.artifacts[] | select(.name | startswith("benchmark-pro-results"))][0].name // empty'
  )

  if artifact_name && !artifact_name.empty?
    _, status = Open3.capture2("gh", "run", "download", run_id.to_s, "-R", REPO, "-n", artifact_name, "-D", dest)
    return true if status.success? && File.exist?(File.join(dest, "benchmark.json"))
  end

  # Fall back to core
  artifact_name = gh_api_jq(
    "repos/#{REPO}/actions/runs/#{run_id}/artifacts",
    '[.artifacts[] | select(.name | startswith("benchmark-core-results"))][0].name // empty'
  )

  if artifact_name && !artifact_name.empty?
    _, status = Open3.capture2("gh", "run", "download", run_id.to_s, "-R", REPO, "-n", artifact_name, "-D", dest)
    return true if status.success? && File.exist?(File.join(dest, "benchmark.json"))
  end

  false
end

def artifact_expired?(run_id)
  expires = gh_api_jq(
    "repos/#{REPO}/actions/runs/#{run_id}/artifacts",
    '[.artifacts[] | select(.name | startswith("benchmark-"))][0].expires_at // empty'
  )
  return true if expires.nil? || expires.empty?

  require "time"
  Time.parse(expires) <= Time.now
rescue StandardError
  true
end

def gh_api_jq(endpoint, jq_expr)
  output, status = Open3.capture2("gh", "api", endpoint, "--jq", jq_expr)
  return nil unless status.success?

  output.strip
end

def run_bencher(token:, sha:, file:, created: nil)
  args = [
    "bencher", "run",
    "--project", PROJECT,
    "--token", token,
    "--branch", "main",
    "--hash", sha,
    "--testbed", TESTBED,
    "--adapter", "json",
    "--file", file
  ]
  # Backdate to original run time so Bencher plots show correct timeline
  if created
    require "time"
    epoch = Time.parse(created).to_i
    args.push("--backdate", epoch.to_s)
  end
  # No --err: alerts are expected during backfill and should not block submission
  _output, status = Open3.capture2(*args)
  status.success?
end

def sort_by_commit_date(entries)
  # Try to sort by commit date using git log
  sha_to_entry = entries.to_h { |e| [e[:sha], e] }
  shas = entries.map { |e| e[:sha] }

  # git log can sort multiple commits chronologically
  output, status = Open3.capture2(
    "git", "log", "--format=%H", "--no-walk", "--date-order", *shas
  )

  if status.success?
    sorted_shas = output.lines.map(&:strip).select { |s| sha_to_entry.key?(s) }
    # Reverse because git log shows newest first
    sorted_shas.reverse.map { |s| sha_to_entry[s] }
  else
    # Fall back to original order
    entries
  end
rescue StandardError
  entries
end

main
# rubocop:enable Metrics
