# frozen_string_literal: true

require "bundler"
require "English"
require "json"
require "open3"
require "rubygems/version"
require "shellwords"
require "tempfile"
require "time"
require "tmpdir"
require_relative "task_helpers"
require_relative "../react_on_rails/lib/react_on_rails/version_syntax_converter"
require_relative "../react_on_rails/lib/react_on_rails/git_utils"
require_relative "../react_on_rails/lib/react_on_rails/utils"

class RaisingMessageHandler
  def add_error(error)
    raise error
  end
end

NPM_REGISTRY_URL = "https://registry.npmjs.org/"
NPM_PUBLISH_VERIFY_ATTEMPTS = 6
NPM_PUBLISH_VERIFY_RETRY_DELAY_SECONDS = 5
NPM_INSTALL_DEPENDENCY_FIELDS = %w[dependencies optionalDependencies peerDependencies].freeze
SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE = "shakaperf-release-gates.yml"
SHAKAPERF_RELEASE_GATE_START_TIMEOUT_SECONDS = 600
SHAKAPERF_RELEASE_GATE_START_POLL_SECONDS = 5
SHAKAPERF_RELEASE_GATE_RUN_LIST_LIMIT = 100
SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS = 50 * 60

# Helper methods for release-specific tasks
# These are defined at the top level so they have access to Rake's sh method

def current_monorepo_root
  File.expand_path("..", __dir__)
end

def release_paths(monorepo_root)
  {
    monorepo_root:,
    gem_root: File.join(monorepo_root, "react_on_rails"),
    pro_gem_root: File.join(monorepo_root, "react_on_rails_pro"),
    dummy_app_dir: File.join(monorepo_root, "react_on_rails", "spec", "dummy"),
    pro_dummy_app_dir: File.join(monorepo_root, "react_on_rails_pro", "spec", "dummy"),
    pro_execjs_dummy_app_dir: File.join(monorepo_root, "react_on_rails_pro", "spec", "execjs-compatible-dummy")
  }
end

def sh_in_dir_for_release(dir, *shell_commands)
  Dir.chdir(dir) do
    shell_commands.flatten.each do |shell_command|
      sh(shell_command.strip)
    end
  end
end

def sh_args_in_dir_for_release(dir, *command_args, env: nil)
  Dir.chdir(dir) do
    env ? sh(env, *command_args) : sh(*command_args)
  end
end

def unbundled_sh_in_dir_for_release(dir, *shell_commands)
  Dir.chdir(dir) do
    Bundler.with_unbundled_env do
      shell_commands.flatten.each do |shell_command|
        sh(shell_command.strip)
      end
    end
  end
end

def prompt_for_otp(service_name, allow_blank: false, hint: nil)
  print "\n🔑 Enter OTP code for #{service_name}#{hint ? " (#{hint})" : ''}: "
  $stdout.flush
  otp = $stdin.gets&.strip
  if otp.nil? || otp.empty?
    return nil if allow_blank

    abort "\n❌ No OTP provided. Aborting."
  end
  normalize_otp_code(otp, service_name:)
end

# Resolve the RubyGems OTP to reuse for BOTH gem pushes (react_on_rails and
# react_on_rails_pro). When the operator does not supply RUBYGEMS_OTP, prompt
# once here and capture the code so it can be forwarded to both pushes via
# GEM_HOST_OTP_CODE. Without this up-front prompt, `gem push` prompts separately
# for each gem — the code typed into that subprocess is never captured by this
# script, so the operator ends up entering an OTP twice. RubyGems accepts the
# same TOTP for both pushes within its validity window; if it expires between
# gems, publish_gem_with_retry prompts for a fresh code.
def resolve_rubygems_otp_for_publish(provided_otp)
  normalized = normalize_otp_code(provided_otp, service_name: "RubyGems")
  if normalized
    puts "Using provided RubyGems OTP for gem publications..."
    return normalized
  end

  unless $stdin.tty?
    puts "\nNOTE: You will be prompted for RubyGems OTP code if needed."
    puts "TIP: Set RUBYGEMS_OTP environment variable to provide OTP upfront."
    return nil
  end

  # Pressing Enter without a code falls back to legacy per-gem prompting handled
  # by `gem push` itself (e.g. accounts without RubyGems 2FA enabled).
  puts "\nThe same RubyGems OTP is reused for both gems (react_on_rails and react_on_rails_pro)."
  prompt_for_otp("RubyGems", allow_blank: true, hint: "press Enter to be prompted per gem")
end

def normalize_otp_code(otp, service_name:)
  return nil if otp.nil?

  normalized = otp.to_s.strip
  abort "❌ Invalid OTP for #{service_name}. Expected digits only." unless normalized.match?(/\A\d+\z/)

  normalized
end

def verify_npm_auth(registry_url = "https://registry.npmjs.org/")
  result, status = Open3.capture2e("npm", "whoami", "--registry", registry_url)
  unless status.success?
    puts <<~MESSAGE
      ⚠️  NPM authentication required!

      You are not logged in to NPM. Running 'npm login' now...

    MESSAGE

    # Run npm login interactively
    system("npm", "login", "--registry", registry_url)

    # Verify login succeeded
    result, status = Open3.capture2e("npm", "whoami", "--registry", registry_url)
    unless status.success?
      abort <<~ERROR
        ❌ NPM login failed!

        Please manually run 'npm login' and retry the release.

        Technical details:
          Registry: #{registry_url}
          Error: #{result.strip}
      ERROR
    end
  end
  puts "✓ Logged in to NPM as: #{result.strip}"
end

def github_repo_slug(monorepo_root)
  origin_url, status = Open3.capture2e("git", "-C", monorepo_root, "remote", "get-url", "origin")
  abort "❌ Unable to determine git origin URL.\n\n#{origin_url}" unless status.success?

  match = origin_url.strip.match(%r{github\.com[:/](?<repo>[^/]+/[^/]+?)(?:\.git)?\z})
  abort "❌ Unable to determine GitHub repository from origin URL #{origin_url.inspect}" unless match

  match[:repo]
end

def capture_gh_output(*)
  Open3.capture2e("gh", *)
rescue Errno::ENOENT
  abort "❌ GitHub CLI (`gh`) is not installed. Install it from https://cli.github.com/ and retry."
end

def read_output_from_io(reader)
  Thread.new do
    reader.read
  rescue IOError
    ""
  end
end

def stop_output_reader(output_reader)
  return unless output_reader&.alive?

  output_reader.join(0.5)
  output_reader.kill if output_reader.alive?
end

def capture_gh_output_with_timeout(*, timeout_seconds:)
  reader, writer = IO.pipe
  pid = Process.spawn("gh", *, out: writer, err: writer)
  writer.close
  output_reader = read_output_from_io(reader)
  status = nil
  timed_out = false
  deadline = Time.now + timeout_seconds

  loop do
    waited_pid, status = Process.waitpid2(pid, Process::WNOHANG)
    break if waited_pid

    if Time.now >= deadline
      timed_out = true
      status = terminate_process(pid)
      break
    end

    sleep 0.2
  end

  [output_reader.value, status, timed_out]
rescue Errno::ENOENT
  abort "❌ GitHub CLI (`gh`) is not installed. Install it from https://cli.github.com/ and retry."
ensure
  writer&.close unless writer&.closed?
  stop_output_reader(output_reader)
  reader&.close unless reader&.closed?
end

def terminate_process(pid)
  Process.kill("TERM", pid)
  deadline = Time.now + 5

  loop do
    waited_pid, status = Process.waitpid2(pid, Process::WNOHANG)
    return status if waited_pid
    break if Time.now >= deadline

    sleep 0.1
  end

  Process.kill("KILL", pid)
  _waited_pid, status = Process.waitpid2(pid)
  status
rescue Errno::ESRCH
  nil
end

def verify_gh_auth(monorepo_root:)
  result, status = capture_gh_output("auth", "status")
  abort "❌ GitHub CLI authentication required! Run `gh auth login` and retry.\n\n#{result}" unless status.success?

  repo_slug = github_repo_slug(monorepo_root)
  permission_result, permission_status = capture_gh_output("api", "repos/#{repo_slug}", "--jq", ".permissions.push")

  unless permission_status.success?
    abort "❌ GitHub CLI authenticated, but failed to verify write access to #{repo_slug}.\n\n#{permission_result}"
  end

  unless permission_result.strip == "true"
    abort "❌ GitHub CLI authenticated, but your account/token does not have write access to #{repo_slug}."
  end

  puts "✓ GitHub CLI authenticated with write access to #{repo_slug}"
end

def current_git_sha!(monorepo_root)
  output, status = Open3.capture2e("git", "-C", monorepo_root, "rev-parse", "HEAD")
  abort "❌ Unable to resolve current git SHA.\n\n#{output}" unless status.success?

  output.strip
end

def handle_shakaperf_release_gate_violation!(message:)
  abort <<~ERROR
    #{message}

    The version-bump commit may already be pushed to the remote without a tag or published packages.
    For a transient gate failure, retry the release from that same commit; the version bump is already present.
    If the gate should not be retried, push a revert commit before retrying the release.

    To override this release gate (use only for an urgent release when ShakaPerf is known-unrelated):
      RELEASE_CI_STATUS_OVERRIDE=true bundle exec rake release[...]
      # or pass override_ci_status as the 4th positional argument:
      bundle exec rake "release[VERSION,false,false,true]"
  ERROR
end

def fetch_shakaperf_release_gate_runs(repo_slug:, ref:)
  output, status = capture_gh_output(
    "run", "list",
    "--repo", repo_slug,
    "--workflow", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
    "--branch", ref,
    "--event", "workflow_dispatch",
    "--json", "createdAt,databaseId,headSha,status,conclusion,url",
    "--limit", SHAKAPERF_RELEASE_GATE_RUN_LIST_LIMIT.to_s
  )

  unless status.success?
    handle_shakaperf_release_gate_violation!(
      message: "❌ Unable to list ShakaPerf release gate workflow runs.\n\n#{output}"
    )
  end

  JSON.parse(output)
rescue JSON::ParserError => e
  handle_shakaperf_release_gate_violation!(
    message: "❌ Failed to parse ShakaPerf release gate workflow runs: #{e.message}\n\nOutput:\n#{output}"
  )
end

def shakaperf_release_gate_dispatch_started_at
  Time.at(Time.now.to_i).utc
end

def shakaperf_release_gate_run_created_after?(run, earliest_created_at)
  return true unless earliest_created_at

  created_at = run["createdAt"]
  return false unless created_at

  Time.iso8601(created_at) >= earliest_created_at
rescue ArgumentError
  false
end

def wait_for_shakaperf_release_gate_run!(repo_slug:, ref:, head_sha:, ignored_run_ids: [], earliest_created_at: nil)
  deadline = Time.now + SHAKAPERF_RELEASE_GATE_START_TIMEOUT_SECONDS
  ignored_run_ids = ignored_run_ids.map(&:to_s)

  loop do
    runs = fetch_shakaperf_release_gate_runs(repo_slug:, ref:)
    matching_run = runs.find do |run|
      run["headSha"] == head_sha &&
        !ignored_run_ids.include?(run["databaseId"].to_s) &&
        shakaperf_release_gate_run_created_after?(run, earliest_created_at)
    end
    return matching_run if matching_run

    break if Time.now >= deadline

    sleep SHAKAPERF_RELEASE_GATE_START_POLL_SECONDS
  end

  handle_shakaperf_release_gate_violation!(
    message: "❌ Timed out waiting for ShakaPerf release gate workflow to start for #{head_sha[0, 8]}."
  )
end

def watch_shakaperf_release_gate_run!(repo_slug:, run:)
  run_id = run.fetch("databaseId").to_s
  run_url = run["url"] || "https://github.com/#{repo_slug}/actions/runs/#{run_id}"

  output, status, timed_out = capture_gh_output_with_timeout(
    "run", "watch", run_id, "--repo", repo_slug, "--exit-status",
    timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
  )

  if timed_out
    handle_shakaperf_release_gate_violation!(
      message: "❌ Timed out watching ShakaPerf release gate run #{run_id}.\n\nRun: #{run_url}"
    )
  end

  return if status.success?

  handle_shakaperf_release_gate_violation!(
    message: "❌ ShakaPerf release gate failed.\n\nRun: #{run_url}\n\n#{output}"
  )
end

def run_shakaperf_release_gate!(monorepo_root:, ref:, head_sha:, allow_override:, dry_run:)
  if dry_run
    puts "⚠️ DRY RUN: Would run ShakaPerf release gate on #{ref} at #{head_sha[0, 8]} before publishing."
    return
  end

  if allow_override
    puts "⚠️ CI STATUS OVERRIDE enabled — skipping ShakaPerf release gate."
    return
  end

  repo_slug = github_repo_slug(monorepo_root)
  puts "\nRunning ShakaPerf release gate on #{ref} at #{head_sha[0, 8]} before tagging and publishing..."
  existing_run_ids = fetch_shakaperf_release_gate_runs(repo_slug:, ref:).map do |run|
    run["databaseId"].to_s
  end
  dispatch_started_at = shakaperf_release_gate_dispatch_started_at
  output, status = capture_gh_output(
    "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE, "--repo", repo_slug, "--ref", ref
  )

  unless status.success?
    handle_shakaperf_release_gate_violation!(
      message: "❌ Unable to dispatch ShakaPerf release gate workflow.\n\n#{output}"
    )
  end

  run = wait_for_shakaperf_release_gate_run!(
    repo_slug:,
    ref:,
    head_sha:,
    ignored_run_ids: existing_run_ids,
    earliest_created_at: dispatch_started_at
  )
  watch_shakaperf_release_gate_run!(repo_slug:, run:)

  puts "✓ ShakaPerf release gate passed: #{run['url'] || "GitHub Actions run #{run.fetch('databaseId')}"}"
end

def run_release_preflight_checks!(monorepo_root:, dry_run:)
  # The main-CI status check (`validate_main_ci_status!`) is intentionally
  # NOT in this function — it runs inside `with_release_checkout` (after
  # `git pull --rebase` but before tagging) so it still fires under
  # `dry_run: true` and surfaces the warning operators need to see.
  return if dry_run

  puts "\n#{'=' * 80}"
  puts "PRE-FLIGHT CHECKS"
  puts "=" * 80
  verify_npm_auth
  verify_gh_auth(monorepo_root:)
end

def current_gem_version(monorepo_root)
  version_file = File.join(monorepo_root, "react_on_rails", "lib", "react_on_rails", "version.rb")
  content = File.read(version_file)
  match = content.match(/VERSION = "([^"]+)"/)
  abort "❌ Unable to read current gem version from #{version_file}" unless match

  match[1]
end

def semver_keyword?(value)
  %w[patch minor major].include?(value.to_s.strip.downcase)
end

def release_prerelease_version?(version)
  version.to_s.match?(/\.(test|beta|alpha|rc|pre)\./i)
end

def npm_dist_tag_for_version(npm_version)
  prerelease_part = npm_version.to_s.split("-", 2)[1]
  return "latest" if prerelease_part.nil? || prerelease_part.empty?

  prerelease_part.split(".", 2).first
end

def validate_requested_version_input!(version_input)
  return if semver_keyword?(version_input)
  return if version_input.match?(/\A\d+\.\d+\.\d+(\.(test|beta|alpha|rc|pre)\.\d+)?\z/i)

  abort <<~ERROR
    ❌ Invalid version argument: #{version_input.inspect}

    Use:
      - Semver bump keyword: patch, minor, or major
      - Explicit version: 16.2.0
      - Explicit prerelease: 16.2.0.rc.1 (RubyGems format with dots)
  ERROR
end

def parse_gem_version_components(gem_version)
  match = gem_version.to_s.strip.match(/\A(\d+)\.(\d+)\.(\d+)(?:\.(test|beta|alpha|rc|pre)\.(\d+))?\z/i)
  abort "❌ Unsupported gem version format: #{gem_version.inspect}" unless match

  {
    major: match[1].to_i,
    minor: match[2].to_i,
    patch: match[3].to_i,
    prerelease_type: match[4]&.downcase,
    prerelease_index: match[5]&.to_i
  }
end

def compute_target_gem_version(current_gem_version:, version_input:)
  return version_input unless semver_keyword?(version_input)

  version = parse_gem_version_components(current_gem_version)
  case version_input.to_s.strip.downcase
  when "patch"
    if version[:prerelease_type]
      # Pre-release → stable: strip the pre-release suffix (e.g., 16.5.0.rc.0 → 16.5.0).
      # This matches `gem bump --version patch` behavior from the gem-release gem.
      "#{version[:major]}.#{version[:minor]}.#{version[:patch]}"
    else
      "#{version[:major]}.#{version[:minor]}.#{version[:patch] + 1}"
    end
  when "minor"
    # NOTE: From a pre-release (e.g., 16.5.0.rc.0), this produces 16.6.0, not 16.5.0.
    # To promote a pre-release to its stable version, use "patch" instead.
    # This matches `gem bump --version minor` behavior from the gem-release gem.
    "#{version[:major]}.#{version[:minor] + 1}.0"
  when "major"
    # NOTE: From a pre-release (e.g., 16.5.0.rc.0), this produces 17.0.0.
    # To promote a pre-release to its stable version, use "patch" instead.
    "#{version[:major] + 1}.0.0"
  else
    abort "❌ Unsupported semver bump keyword #{version_input.inspect}"
  end
end

def parse_release_tag_to_gem_version(tag)
  stable_match = tag.match(/\Av(\d+\.\d+\.\d+)\z/)
  return stable_match[1] if stable_match

  prerelease_with_dot = tag.match(/\Av(\d+\.\d+\.\d+)\.(test|beta|alpha|rc|pre)\.(\d+)\z/i)
  return "#{prerelease_with_dot[1]}.#{prerelease_with_dot[2].downcase}.#{prerelease_with_dot[3]}" if prerelease_with_dot

  prerelease_with_dash = tag.match(/\Av(\d+\.\d+\.\d+)-(test|beta|alpha|rc|pre)\.(\d+)\z/i)
  if prerelease_with_dash
    return "#{prerelease_with_dash[1]}.#{prerelease_with_dash[2].downcase}.#{prerelease_with_dash[3]}"
  end

  nil
end

def tagged_release_gem_versions(monorepo_root, fetch_tags: true)
  if fetch_tags
    fetch_output, fetch_status = Open3.capture2e("git", "-C", monorepo_root, "fetch", "--tags", "--quiet")
    abort "❌ Unable to fetch tags for version policy validation.\n\n#{fetch_output.strip}" unless fetch_status.success?
  end

  tags_output, tags_status = Open3.capture2e("git", "-C", monorepo_root, "tag", "-l", "v*")
  abort "❌ Unable to list git tags for version policy validation.\n\n#{tags_output.strip}" unless tags_status.success?

  tags_output.lines.map(&:strip).filter_map { |tag| parse_release_tag_to_gem_version(tag) }.uniq
end

def version_bump_type(previous_stable_gem_version:, target_gem_version:)
  previous = parse_gem_version_components(previous_stable_gem_version)
  target = parse_gem_version_components(target_gem_version)

  return :major if target[:major] > previous[:major]
  return :minor if target[:major] == previous[:major] && target[:minor] > previous[:minor]
  if target[:major] == previous[:major] && target[:minor] == previous[:minor] && target[:patch] > previous[:patch]
    return :patch
  end

  :none
end

def expected_bump_type_from_changelog_section(changelog_section)
  section = changelog_section.to_s
  return :major if section.match?(/^####?\s+(?:⚠️\s*)?Breaking(?:\s+Changes?)?\b/i)
  return :minor if section.match?(/^####?\s+(Added|New\s+Features?|Features?|Enhancements?)\b/i)
  return :patch if section.match?(/^####?\s+(Fixed|Fixes|Bug\s+Fixes?|Security|Improved|Changed|Deprecated|Removed)\b/i)

  nil
end

def version_policy_override_enabled?(override_flag)
  ReactOnRails::Utils.object_to_boolean(override_flag) ||
    ReactOnRails::Utils.object_to_boolean(ENV.fetch("RELEASE_VERSION_POLICY_OVERRIDE", nil))
end

def ci_status_override_enabled?(override_flag)
  ReactOnRails::Utils.object_to_boolean(override_flag) ||
    ReactOnRails::Utils.object_to_boolean(ENV.fetch("RELEASE_CI_STATUS_OVERRIDE", nil))
end

# Statuses considered "incomplete" — anything not yet a finalized conclusion.
CI_INCOMPLETE_STATUSES = %w[in_progress queued waiting requested pending].freeze
# Conclusions considered acceptable. `skipped`/`neutral` are not failures (e.g. docs-only
# paths-ignore skips, or workflows that intentionally short-circuit).
CI_PASSING_CONCLUSIONS = %w[success skipped neutral].freeze

# rubocop:disable Metrics/MethodLength
def fetch_main_ci_checks(monorepo_root:, allow_override: false, dry_run: false)
  fetch_output, fetch_status = Open3.capture2e(
    "git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet"
  )
  unless fetch_status.success?
    handle_main_ci_status_violation!(
      message: "❌ Unable to fetch origin/main for CI status check.\n\n#{fetch_output}",
      allow_override:,
      dry_run:
    )
    return nil
  end

  sha_output, sha_status = Open3.capture2e("git", "-C", monorepo_root, "rev-parse", "origin/main")
  unless sha_status.success?
    handle_main_ci_status_violation!(
      message: "❌ Unable to resolve origin/main HEAD.\n\n#{sha_output}",
      allow_override:,
      dry_run:
    )
    return nil
  end
  sha = sha_output.strip

  repo_slug = github_repo_slug(monorepo_root)
  api_path = "repos/#{repo_slug}/commits/#{sha}/check-runs"

  # `--paginate --jq '.check_runs[]'` flattens paginated responses into JSONL.
  # Each non-empty line is one check_run object. We invoke `gh` directly here
  # (rather than via `capture_gh_output`) so that a missing binary routes
  # through `handle_main_ci_status_violation!` — same as a git fetch failure —
  # instead of aborting unconditionally. This keeps `dry_run` / `allow_override`
  # symmetric across every fetch step.
  begin
    output, status = Open3.capture2e(
      "gh", "api", "--paginate", "--jq", ".check_runs[]", api_path
    )
  rescue Errno::ENOENT
    # validate_main_ci_status! normally checks `gh` first, but keep this helper
    # defensive for direct calls and focused tests.
    handle_main_ci_status_violation!(
      message: "❌ GitHub CLI (`gh`) is not installed. Install it from https://cli.github.com/ and retry.",
      allow_override:,
      dry_run:
    )
    # Only reached in override/dry-run mode; strict mode aborts above.
    return nil
  end

  unless status.success?
    handle_main_ci_status_violation!(
      message: "❌ Unable to query GitHub Checks API for #{sha}.\n\n#{output}",
      allow_override:,
      dry_run:
    )
    # Only reached in override/dry-run mode; strict mode aborts above.
    return nil
  end

  begin
    check_runs = parse_gh_jsonl(output)
  rescue JSON::ParserError => e
    handle_main_ci_status_violation!(
      message: "❌ Failed to parse check_runs response from gh: #{e.message}\n\nOutput:\n#{output}",
      allow_override:,
      dry_run:
    )
    return nil
  end

  { sha:, repo_slug:, check_runs: }
end
# rubocop:enable Metrics/MethodLength

def parse_gh_jsonl(output)
  output.lines.reject { |line| line.strip.empty? }.map do |line|
    JSON.parse(line)
  end
end

def fetch_main_commit_statuses(repo_slug:, sha:, allow_override:, dry_run:)
  api_path = "repos/#{repo_slug}/commits/#{sha}/statuses"

  begin
    output, status = Open3.capture2e(
      "gh", "api", "--paginate", "--jq", ".[]", api_path
    )
  rescue Errno::ENOENT
    handle_main_ci_status_violation!(
      message: "❌ GitHub CLI (`gh`) is not installed. Install it from https://cli.github.com/ and retry.",
      allow_override:,
      dry_run:
    )
    return nil
  end

  unless status.success?
    handle_main_ci_status_violation!(
      message: "❌ Unable to query GitHub Statuses API for #{sha}.\n\n#{output}",
      allow_override:,
      dry_run:
    )
    return nil
  end

  begin
    parse_gh_jsonl(output)
  rescue JSON::ParserError => e
    handle_main_ci_status_violation!(
      message: "❌ Failed to parse statuses response from gh: #{e.message}\n\nOutput:\n#{output}",
      allow_override:,
      dry_run:
    )
    # Only reached in override/dry-run mode; strict mode aborts above.
    nil
  end
end

def normalize_status_as_check_run(status)
  state = status["state"]
  conclusion = normalize_status_conclusion(state)
  {
    "id" => status["id"],
    "name" => status["context"],
    "status" => conclusion.nil? ? "pending" : "completed",
    "conclusion" => conclusion,
    "html_url" => status["target_url"]
  }
end

def normalize_status_conclusion(state)
  case state
  when "success"
    "success"
  when "pending"
    nil
  when "failure", "error"
    state
  else
    # GitHub documents error/failure/pending/success; unknown values should block.
    "error"
  end
end

def latest_commit_statuses(statuses)
  statuses
    .group_by { |status| status["context"] }
    .map do |_context, context_statuses|
      context_statuses.max_by { |status| [status["id"].to_i, status["created_at"].to_s] }
    end
end

def normalize_required_check_entries(checks)
  Array(checks).filter_map do |check|
    context = check["context"].to_s
    next if context.empty?

    { context:, app_id: check["app_id"]&.to_i }
  end.uniq
end

def normalize_required_checks_payload(parsed)
  return nil unless parsed.is_a?(Hash)

  checks = normalize_required_check_entries(parsed["checks"])
  check_contexts = checks.map { |check| check[:context] }
  # GitHub mirrors required status-check names into both `contexts` and `checks`.
  # Keep the modern `checks` entry when names overlap so one required gate is
  # evaluated once, with its app pin preserved.
  contexts = Array(parsed["contexts"]).map(&:to_s).reject(&:empty?).uniq - check_contexts

  # No required names parseable is treated the same as "no branch protection
  # visible" — fail-safe to evaluating every check run.
  contexts.empty? && checks.empty? ? nil : { contexts:, checks: }
end

def required_check_names_for_main(monorepo_root:, repo_slug: nil)
  repo_slug ||= github_repo_slug(monorepo_root)
  api_path = "repos/#{repo_slug}/branches/main/protection/required_status_checks"
  # Keep legacy `contexts` separate from modern `checks` entries. Modern
  # required checks can be pinned to a GitHub App via `app_id`; legacy contexts
  # may be satisfied by either a Checks API run or a commit-status context.
  jq_query = "{contexts: (.contexts // []), checks: (.checks // [] | map({context, app_id}))}"
  # Precondition: `fetch_main_ci_checks` already verified `gh` is installed
  # before `validate_main_ci_status!` calls this helper. The remaining failure
  # mode here is "branch protection unknown", which returns nil so the caller
  # fail-safes to evaluating every visible check_run.
  output, status = capture_gh_output("api", "--jq", jq_query, api_path)
  # If branch protection isn't configured, isn't queryable with current token scope, or the
  # endpoint returns 404, fall through to nil so the caller treats all checks as required
  # (fail-safe).
  return nil unless status.success?

  begin
    parsed = JSON.parse(output)
    normalize_required_checks_payload(parsed)
  rescue JSON::ParserError
    nil
  end
end

def check_run_app_id(run)
  app_id = run.dig("app", "id")
  app_id&.to_i
end

def required_check_app_wildcard?(app_id)
  app_id.nil? || app_id == -1
end

def required_check_matches_run?(required_check, run)
  required_check[:context] == run["name"] &&
    (required_check_app_wildcard?(required_check[:app_id]) || required_check[:app_id] == check_run_app_id(run))
end

def required_check_present?(required_check:, check_runs:, legacy_status_runs:)
  check_runs.any? { |run| required_check_matches_run?(required_check, run) } ||
    (required_check_app_wildcard?(required_check[:app_id]) &&
      legacy_status_runs.any? { |run| run["name"] == required_check[:context] })
end

def context_name_matches?(context:, run:)
  run["name"] == context
end

def legacy_context_present?(context:, check_runs:, legacy_status_runs:)
  matching_check_run = check_runs.any? do |run|
    context_name_matches?(context:, run:)
  end

  matching_check_run || legacy_status_runs.any? { |run| context_name_matches?(context:, run:) }
end

def required_check_label(required_check)
  return required_check[:context] if required_check_app_wildcard?(required_check[:app_id])

  "#{required_check[:context]} (app_id: #{required_check[:app_id]})"
end

def format_required_check_labels(labels)
  labels.tally.map { |label, count| count > 1 ? "#{label} (#{count} gates)" : label }
end

def required_check_labels(required_checks)
  labels = required_checks[:contexts] + required_checks[:checks].map { |check| required_check_label(check) }
  format_required_check_labels(labels)
end

def required_check_count(required_checks)
  required_checks[:contexts].length + required_checks[:checks].length
end

def missing_required_checks(required_checks:, check_runs:, legacy_status_runs:)
  missing_modern = required_checks[:checks].reject do |required_check|
    required_check_present?(
      required_check:,
      check_runs:,
      legacy_status_runs:
    )
  end
  missing_legacy = required_checks[:contexts].reject do |context|
    legacy_context_present?(
      context:,
      check_runs:,
      legacy_status_runs:
    )
  end

  # Keep the raw count separate from display labels for deliberately duplicated
  # names; mirrored branch-protection contexts are removed during normalization.
  {
    count: missing_legacy.length + missing_modern.length,
    labels: format_required_check_labels(missing_legacy + missing_modern.map { |check| required_check_label(check) })
  }
end

def legacy_status_contexts_for_required_checks(required_checks)
  wildcard_check_contexts = required_checks[:checks]
                            .select { |check| required_check_app_wildcard?(check[:app_id]) }
                            .map { |check| check[:context] }

  (
    required_checks[:contexts] +
    wildcard_check_contexts
  ).uniq
end

def legacy_status_runs_for_required_contexts(required_checks:, statuses:)
  status_contexts = legacy_status_contexts_for_required_checks(required_checks)

  # App-wildcard required checks can be satisfied by either Checks API runs or
  # legacy commit statuses. App-pinned checks still require a matching check run.
  latest_commit_statuses(statuses)
    .select { |status| status_contexts.include?(status["context"]) }
    .map { |status| normalize_status_as_check_run(status) }
end

def format_ci_status_run_line(run, kind:)
  icon = kind == :in_progress ? "⏳" : "❌"
  detail = kind == :in_progress ? (run["status"] || "in_progress") : (run["conclusion"] || "incomplete")
  url = run["html_url"].to_s
  url.strip.empty? ? "  #{icon} #{detail}: #{run['name']}" : "  #{icon} #{detail}: #{run['name']}\n      #{url}"
end

def format_main_ci_status_violation(kind:, short_sha:, runs:) # rubocop:disable Metrics/CyclomaticComplexity
  header = case kind
           when :in_progress
             "⏳ CI is still in progress on origin/main (commit #{short_sha})."
           when :no_checks
             "❌ No CI check runs visible on origin/main (commit #{short_sha}). " \
             "CI may not have started yet, or the GitHub Checks API is unavailable."
           when :no_required_checks
             "❌ No required CI check runs found on origin/main (commit #{short_sha})."
           when :missing_required_checks
             "❌ Some required CI checks are missing on origin/main (commit #{short_sha}). " \
             "Branch protection would refuse this merge."
           when :failed
             "❌ CI on origin/main is not healthy (commit #{short_sha})."
           when :unknown_status
             "❌ Check run(s) with unrecognized status on origin/main (commit #{short_sha})."
           else
             raise ArgumentError, "Unknown CI violation kind: #{kind.inspect}"
           end
  return header if runs.nil? || runs.empty?

  lines = runs.map { |run| format_ci_status_run_line(run, kind:) }
  "#{header}\n\n#{lines.join("\n")}"
end

def handle_main_ci_status_violation!(message:, allow_override:, dry_run:)
  if dry_run
    puts message.lines.map { |line| "⚠️ DRY RUN: #{line}" }.join
    puts "⚠️ DRY RUN: Real release would block. Use RELEASE_CI_STATUS_OVERRIDE=true to bypass."
    return
  end

  if allow_override
    puts "⚠️ CI STATUS OVERRIDE enabled — proceeding despite the following:"
    puts message.lines.map { |line| "  #{line}" }.join
    return
  end

  abort <<~ERROR
    #{message}

    To override (use only if the failures are known-unrelated to this release):
      RELEASE_CI_STATUS_OVERRIDE=true bundle exec rake release[...]
      # or pass override_ci_status as the 4th positional argument:
      bundle exec rake "release[VERSION,false,false,true]"
  ERROR
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
def validate_main_ci_status!(monorepo_root:, is_prerelease:, allow_override:, dry_run:)
  puts "\nChecking CI status on origin/main..."

  data = fetch_main_ci_checks(monorepo_root:, allow_override:, dry_run:)
  # `fetch_main_ci_checks` returns nil when it surfaced a violation through
  # `handle_main_ci_status_violation!` (dry-run or override path). In that case
  # the warning has already been printed and we should not continue.
  return if data.nil?

  sha = data[:sha]
  short_sha = sha[0, 8]
  repo_slug = data[:repo_slug]
  check_runs = data[:check_runs]

  # Collapse multiple runs per (check_suite_id, name) to the most recent
  # attempt (highest check_run id). The key intentionally includes
  # check_suite_id so we only collapse *true* reruns (same workflow run,
  # same job name) and not unrelated workflows that happen to share a job
  # name. For example, this repo has multiple workflows that each define a
  # `detect-changes` job; without the suite_id in the key, a passing run
  # from one workflow could mask a failing run from another. `id` is
  # monotonically increasing per check run, so `max_by { id }` reliably
  # selects the latest attempt within a suite.
  # When `check_suite` is absent (rare — third-party integrations that don't
  # attach to a suite), fall back to the run's own `id` for the group key so
  # each nil-suite run sits in its own group and is never collapsed with
  # another. The GitHub Actions Checks API always populates `check_suite`,
  # so this only matters for external check integrations.
  check_runs = check_runs
               .group_by { |run| [run.dig("check_suite", "id") || run["id"], run["name"], check_run_app_id(run)] }
               .map { |_key, runs| runs.max_by { |run| run["id"].to_i } }

  # Always query branch-protection required checks (when configured) so the
  # missing-required-check gate applies to both stable and prerelease.
  # `evaluated` then differs by mode:
  #   - prerelease: only the required subset (narrower filter; non-required failures are advisory)
  #   - stable:     every check_run on the commit (broader filter; any failure blocks)
  required_args = { monorepo_root: }
  required_args[:repo_slug] = repo_slug if repo_slug
  required_names = required_check_names_for_main(**required_args)
  required_status_contexts = required_names ? legacy_status_contexts_for_required_checks(required_names) : []
  legacy_status_runs = []
  if required_status_contexts.any?
    statuses = fetch_main_commit_statuses(
      repo_slug: repo_slug || github_repo_slug(monorepo_root),
      sha:,
      allow_override:,
      dry_run:
    )
    if statuses.nil?
      unless allow_override || dry_run
        handle_main_ci_status_violation!(
          message: "❌ Internal error: legacy status fetch returned nil unexpectedly in strict mode.",
          allow_override:,
          dry_run:
        )
        return
      end

      # Only dry-run/override mode reaches the fallback; strict mode aborts inside
      # the fetch helper after surfacing the violation.
      statuses = []
    end

    legacy_status_runs = legacy_status_runs_for_required_contexts(
      required_checks: required_names,
      statuses:
    )
  end

  if check_runs.empty? && legacy_status_runs.empty?
    handle_main_ci_status_violation!(
      message: format_main_ci_status_violation(kind: :no_checks, short_sha:, runs: nil),
      allow_override:,
      dry_run:
    )
    return
  end

  evaluated = if is_prerelease && required_names
                check_runs.select do |run|
                  required_names[:contexts].any? do |context|
                    context_name_matches?(context:, run:)
                  end ||
                    required_names[:checks].any? { |required_check| required_check_matches_run?(required_check, run) }
                end + legacy_status_runs
              else
                check_runs + legacy_status_runs
              end

  # Report visible failures before missing/in-progress runs. If both are
  # present, the operator needs to know about the failure right away; this also
  # prevents same-label legacy/modern required checks from hiding a failed
  # legacy status behind a "missing required" message.
  failed = evaluated.select do |run|
    run["status"] == "completed" && !CI_PASSING_CONCLUSIONS.include?(run["conclusion"])
  end
  if failed.any?
    handle_main_ci_status_violation!(
      message: format_main_ci_status_violation(kind: :failed, short_sha:, runs: failed),
      allow_override:,
      dry_run:
    )
    return
  end

  # When branch protection lists required checks, treat any missing required
  # check as blocking — for stable AND prerelease. Branch protection would
  # refuse the merge in this state, so a release that ignored the gap would
  # ship against a commit GitHub itself considers unverified.
  # `:no_required_checks` covers the all-missing case (typically: CI hasn't
  # started yet); `:missing_required_checks` covers the partial case (some
  # required workflows ran, others never registered — usually a renamed or
  # deleted workflow that branch protection still requires).
  unless required_names.nil?
    required_labels = required_check_labels(required_names)
    missing_required = missing_required_checks(
      required_checks: required_names,
      check_runs:,
      legacy_status_runs:
    )
    missing_names = missing_required[:labels]
    if missing_required[:count] == required_check_count(required_names)
      handle_main_ci_status_violation!(
        message: format_main_ci_status_violation(kind: :no_required_checks, short_sha:, runs: nil) +
                 "\nRequired: #{required_labels.join(', ')}",
        allow_override:,
        dry_run:
      )
      return
    elsif missing_names.any?
      handle_main_ci_status_violation!(
        message: format_main_ci_status_violation(kind: :missing_required_checks, short_sha:, runs: nil) +
                 "\nRequired: #{required_labels.join(', ')}\nMissing: #{missing_names.join(', ')}",
        allow_override:,
        dry_run:
      )
      return
    end
  end

  in_progress = evaluated.select { |run| CI_INCOMPLETE_STATUSES.include?(run["status"]) }
  if in_progress.any?
    handle_main_ci_status_violation!(
      message: format_main_ci_status_violation(kind: :in_progress, short_sha:, runs: in_progress),
      allow_override:,
      dry_run:
    )
    return
  end

  # Catch any run whose status falls outside both the "completed" and
  # `CI_INCOMPLETE_STATUSES` buckets — e.g. a new GitHub status value we
  # don't yet know about, or a `nil` from a malformed response. Treat the
  # ambiguity as a failure rather than letting it slip through as green;
  # the release gate is supposed to be the last-line check.
  unknown = evaluated.reject do |run|
    run["status"] == "completed" || CI_INCOMPLETE_STATUSES.include?(run["status"])
  end
  if unknown.any?
    handle_main_ci_status_violation!(
      message: format_main_ci_status_violation(kind: :unknown_status, short_sha:, runs: unknown),
      allow_override:,
      dry_run:
    )
    return
  end

  # Only label the count "required" when `evaluated` was actually filtered to
  # the required subset (prerelease + branch protection visible). On stable
  # releases we keep evaluating every check_run, so the count includes
  # non-required runs and labelling them "required" would misrepresent the
  # gate.
  qualifier = is_prerelease && required_names ? "required " : ""
  healthy_count = is_prerelease && required_names ? required_check_count(required_names) : evaluated.length
  noun = healthy_count == 1 ? "check" : "checks"
  puts "✓ Main CI is healthy on #{short_sha} (#{healthy_count} #{qualifier}#{noun})"
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

def handle_version_policy_violation!(message:, allow_override:)
  if allow_override
    normalized = message.sub(/\A❌\s*/, "")
    puts "⚠️ VERSION POLICY OVERRIDE enabled: #{normalized}"
    return
  end

  abort message
end

def extract_changelog_section(changelog_path:, version:)
  lines = File.readlines(changelog_path)
  section_header = /^### \[#{Regexp.escape(version)}\]/
  start_index = lines.index { |line| line.match?(section_header) }
  return nil unless start_index

  end_index = ((start_index + 1)...lines.length).find { |idx| lines[idx].start_with?("### [") } || lines.length
  # Skip the version header line itself; GitHub release title already contains the version.
  content = lines[(start_index + 1)...end_index].join.strip
  return nil if content.empty?

  content
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
def validate_release_version_policy!(monorepo_root:, target_gem_version:, allow_override:, fetch_tags: true)
  tagged_versions = tagged_release_gem_versions(monorepo_root, fetch_tags:)
  latest_tagged_version = tagged_versions.max_by { |version| Gem::Version.new(version) }

  if latest_tagged_version && Gem::Version.new(target_gem_version) <= Gem::Version.new(latest_tagged_version)
    handle_version_policy_violation!(
      message: "❌ Requested version #{target_gem_version} " \
               "must be greater than latest tagged version #{latest_tagged_version}.",
      allow_override:
    )
  end

  if release_prerelease_version?(target_gem_version) && latest_tagged_version
    target_components = parse_gem_version_components(target_gem_version)
    latest_components = parse_gem_version_components(latest_tagged_version)

    same_release_base = target_components[:major] == latest_components[:major] &&
                        target_components[:minor] == latest_components[:minor] &&
                        target_components[:patch] == latest_components[:patch]

    if same_release_base && release_prerelease_version?(latest_tagged_version)
      puts "ℹ️ VERSION POLICY: Skipping all downstream checks for same-base prerelease bump " \
           "(#{latest_tagged_version} → #{target_gem_version})."
      return
    end
  end

  latest_stable_version = tagged_versions.reject { |version| release_prerelease_version?(version) }
                                         .max_by { |version| Gem::Version.new(version) }
  return unless latest_stable_version

  actual_bump_type = version_bump_type(previous_stable_gem_version: latest_stable_version,
                                       target_gem_version:)
  if actual_bump_type == :none
    handle_version_policy_violation!(
      message: "❌ Requested version #{target_gem_version} is not a major/minor/patch bump " \
               "over latest stable #{latest_stable_version}.",
      allow_override:
    )
    return if allow_override
  end

  if release_prerelease_version?(target_gem_version)
    puts "ℹ️ VERSION POLICY: Skipping changelog bump-consistency check for prerelease #{target_gem_version}."
    return
  end

  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  changelog_section = extract_changelog_section(changelog_path:, version: target_gem_version)
  unless changelog_section
    puts "ℹ️ VERSION POLICY: No changelog content found for #{target_gem_version}; " \
         "skipping changelog bump-consistency check."
    return
  end

  expected_bump_type = expected_bump_type_from_changelog_section(changelog_section)
  unless expected_bump_type
    puts "ℹ️ VERSION POLICY: CHANGELOG section #{target_gem_version} does not declare bump level; skipping check."
    return
  end
  return if actual_bump_type == expected_bump_type

  handle_version_policy_violation!(
    message: "❌ Version bump mismatch for #{target_gem_version}: CHANGELOG implies #{expected_bump_type}, " \
             "but version bump is #{actual_bump_type} from #{latest_stable_version}.",
    allow_override:
  )
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

def extract_latest_changelog_version(monorepo_root:)
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  return nil unless File.exist?(changelog_path)

  File.readlines(changelog_path).each do |line|
    match = line.match(/^### \[([^\]]+)\]/)
    next unless match

    version = match[1].strip
    next if version == "Unreleased"

    return version if version.match?(/\A\d+\.\d+\.\d+(\.(test|beta|alpha|rc|pre)\.\d+)?\z/i)
  end

  nil
end

def confirm_release!(version:, monorepo_root:)
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  has_changelog = extract_changelog_section(changelog_path:, version:)

  puts ""
  puts "################################################################################"
  puts "RELEASE CONFIRMATION"
  puts "################################################################################"
  puts "  Version:   #{version}"
  if has_changelog
    puts "  Changelog: ✓ section found"
  else
    puts "  Changelog: ✗ MISSING — no GitHub release will be created"
    puts "             Run /update-changelog to add entries before releasing."
  end
  puts "################################################################################"
  print "Proceed with release? [y/N] "
  $stdout.flush
  answer = $stdin.gets&.strip&.downcase
  abort "Release aborted." unless answer == "y"
end

def changelog_dirty?(monorepo_root:)
  changes_output, status = Open3.capture2e("git", "-C", monorepo_root, "status", "--porcelain", "--", "CHANGELOG.md")
  stripped = changes_output.strip
  abort "❌ Unable to check CHANGELOG.md status\n\n#{stripped}" unless status.success?
  !stripped.empty?
end

def ensure_changelog_committed!(monorepo_root:)
  return unless changelog_dirty?(monorepo_root:)

  abort "❌ CHANGELOG.md has uncommitted changes. Commit or stash CHANGELOG.md before running sync_github_release."
end

def ensure_git_tag_exists!(monorepo_root:, tag:)
  fetch_output, fetch_status = Open3.capture2e("git", "-C", monorepo_root, "fetch", "--tags", "--quiet")
  unless fetch_status.success?
    abort "❌ Unable to fetch git tags before verifying #{tag.inspect}.\n\n#{fetch_output.strip}"
  end

  tag_ref = "refs/tags/#{tag}"
  tag_exists = system("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", tag_ref, out: File::NULL,
                                                                                               err: File::NULL)
  abort "❌ Unable to run git to verify tag #{tag.inspect}." if tag_exists.nil?
  return if tag_exists

  abort "❌ Git tag #{tag.inspect} was not found locally or remotely."
end

def prepare_github_release_context(monorepo_root:, gem_version:)
  prerelease = release_prerelease_version?(gem_version)
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  notes = extract_changelog_section(changelog_path:, version: gem_version)
  abort "❌ Could not find `### [#{gem_version}]` in CHANGELOG.md. Add that section and retry." unless notes

  {
    notes:,
    prerelease:,
    tag: "v#{gem_version}",
    title: "v#{gem_version}"
  }
end

# rubocop:disable Metrics/AbcSize
def publish_or_update_github_release(monorepo_root:, release_context:, dry_run:)
  ensure_git_tag_exists!(monorepo_root:, tag: release_context[:tag])

  if dry_run
    puts "DRY RUN: Would create or update GitHub release #{release_context[:tag]}" \
         "#{release_context[:prerelease] ? ' (prerelease)' : ''}"
    return
  end

  Tempfile.create(["react-on-rails-release-notes-", ".md"]) do |tmp|
    tmp.write(release_context[:notes])
    tmp.flush

    release_exists = system("gh", "release", "view", release_context[:tag], chdir: monorepo_root, out: File::NULL,
                                                                            err: File::NULL)
    abort "❌ Unable to run `gh`. Ensure GitHub CLI is installed and on PATH." if release_exists.nil?

    release_command = if release_exists
                        ["gh", "release", "edit", release_context[:tag], "--title", release_context[:title],
                         "--notes-file", tmp.path,
                         "--prerelease=#{release_context[:prerelease]}"]
                      else
                        command = ["gh", "release", "create", release_context[:tag], "--verify-tag", "--title",
                                   release_context[:title],
                                   "--notes-file", tmp.path]
                        command << "--prerelease" if release_context[:prerelease]
                        command
                      end

    puts "Publishing GitHub release #{release_context[:tag]}#{release_context[:prerelease] ? ' (prerelease)' : ''}"
    success = system(*release_command, chdir: monorepo_root)
    abort "❌ Failed to publish GitHub release #{release_context[:tag]}." unless success
  end
end
# rubocop:enable Metrics/AbcSize

def sync_github_release_after_publish(monorepo_root:, gem_version:, dry_run:)
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  section = extract_changelog_section(changelog_path:, version: gem_version)
  unless section
    puts "################################################################################"
    puts "Skipping GitHub release: no CHANGELOG.md section for #{gem_version}."
    puts "After adding the changelog section, run:"
    puts "bundle exec rake \"sync_github_release[#{gem_version}]\""
    puts "################################################################################"
    return
  end

  verify_gh_auth(monorepo_root:)
  release_context = prepare_github_release_context(monorepo_root:, gem_version:)
  publish_or_update_github_release(monorepo_root:, release_context:, dry_run:)
end

def with_release_checkout(monorepo_root:, dry_run:)
  return yield(monorepo_root) unless dry_run

  Dir.mktmpdir("react-on-rails-release-dry-run") do |tmpdir|
    worktree_dir = File.join(tmpdir, "worktree")
    escaped_worktree_dir = Shellwords.escape(worktree_dir)
    sh_in_dir_for_release(monorepo_root, "git worktree add --detach #{escaped_worktree_dir} HEAD")
    begin
      yield(worktree_dir)
    ensure
      original_error = $ERROR_INFO
      begin
        sh_in_dir_for_release(monorepo_root, "git worktree remove --force #{escaped_worktree_dir}")
      rescue StandardError => e
        warn "⚠️  Failed to clean up worktree #{worktree_dir}: #{e.message}"
        raise e if original_error.nil?
      end
    end
  end
end

def version_tagged?(monorepo_root, version)
  tagged_versions = tagged_release_gem_versions(monorepo_root, fetch_tags: true)
  tagged_versions.include?(version)
end

def resolve_version_input(version_input, monorepo_root)
  stripped = version_input.to_s.strip
  return stripped unless stripped.empty?

  changelog_version = extract_latest_changelog_version(monorepo_root:)
  current_version = current_gem_version(monorepo_root)

  if changelog_version && Gem::Version.new(changelog_version) > Gem::Version.new(current_version)
    puts "Found CHANGELOG.md version: #{changelog_version} (current: #{current_version})"
    return changelog_version
  end

  # If the latest changelog version matches the current version but hasn't been
  # tagged yet, use it. This handles the case where the changelog was updated
  # and the version bumped in a prior step (e.g., RC → stable promotion).
  if changelog_version &&
     Gem::Version.new(changelog_version) == Gem::Version.new(current_version) &&
     !version_tagged?(monorepo_root, changelog_version)
    puts "Found untagged CHANGELOG.md version: #{changelog_version} (current: #{current_version})"
    return changelog_version
  end

  puts "No new version found in CHANGELOG.md (latest: #{changelog_version || 'none'}, current: #{current_version})."
  puts "Falling back to patch bump."
  "patch"
end

def publish_gem_with_retry(dir, gem_name, otp: nil, max_retries: ENV.fetch("GEM_RELEASE_MAX_RETRIES", "3").to_i)
  puts "\nPublishing #{gem_name} gem to RubyGems.org..."
  current_otp = normalize_otp_code(otp, service_name: "RubyGems")

  if current_otp
    puts "Using provided OTP code..."
  else
    puts "Carefully add your OTP for Rubygems when prompted."
    puts "NOTE: OTP codes expire quickly (typically 30 seconds). Generate a fresh code when prompted."
  end

  retry_count = 0
  success = false

  while retry_count < max_retries && !success
    begin
      # Use GEM_HOST_OTP_CODE environment variable instead of --otp flag
      # because `gem release` (gem-release gem) doesn't support --otp,
      # but the underlying `gem push` reads OTP from this env var
      gem_release_env = current_otp ? { "GEM_HOST_OTP_CODE" => current_otp } : nil
      sh_args_in_dir_for_release(dir, "gem", "release", env: gem_release_env)
      success = true
    # Rake's sh method raises RuntimeError (not Gem exceptions) when commands fail
    rescue RuntimeError, IOError => e
      retry_count += 1
      if retry_count < max_retries
        puts "\n⚠️  #{gem_name} release failed (attempt #{retry_count}/#{max_retries})"
        puts "Error: #{e.class}: #{e.message}"
        puts "Common causes:"
        puts "  - OTP code expired or already used"
        puts "  - Network timeout"
        puts "\nPlease enter a FRESH OTP code to retry..."
        current_otp = prompt_for_otp("RubyGems")
      else
        puts "\n❌ Failed to publish #{gem_name} after #{max_retries} attempts"
        raise e
      end
    end
  end

  # Return the last successful OTP so it can potentially be reused
  current_otp
end

def parse_npm_package_ref(package_ref)
  match = package_ref.to_s.match(%r{\A(?<name>@[^/]+/[^@]+|[^@]+)@(?<version>.+)\z})
  abort "❌ Invalid npm package ref for release verification: #{package_ref.inspect}" unless match

  [match[:name], match[:version]]
end

def workspace_protocol_dependencies(metadata)
  return [] unless metadata.is_a?(Hash)

  NPM_INSTALL_DEPENDENCY_FIELDS.flat_map do |field|
    dependencies = metadata[field]
    next [] unless dependencies.is_a?(Hash)

    dependencies.filter_map do |dependency_name, dependency_version|
      next unless dependency_version.to_s.start_with?("workspace:")

      "#{field}.#{dependency_name}=#{dependency_version}"
    end
  end
end

def publish_dependency_version_for_workspace_protocol(dependency_version, package_version)
  workspace_range = dependency_version.to_s.delete_prefix("workspace:")

  case workspace_range
  when "*", ""
    package_version
  when "^", "~"
    "#{workspace_range}#{package_version}"
  else
    workspace_range
  end
end

def replace_workspace_protocol_dependencies_for_publish!(package_json, package_version)
  changed = false

  NPM_INSTALL_DEPENDENCY_FIELDS.each do |field|
    dependencies = package_json[field]
    next unless dependencies.is_a?(Hash)

    dependencies.each do |dependency_name, dependency_version|
      next unless dependency_version.to_s.start_with?("workspace:")

      dependencies[dependency_name] =
        publish_dependency_version_for_workspace_protocol(dependency_version, package_version)
      changed = true
    end
  end

  changed
end

def write_publishable_package_json(package_json_path, package_json)
  tmp = Tempfile.create(["package-json-", ".json"], File.dirname(package_json_path))
  tmp_path = tmp.path
  renamed = false

  begin
    tmp.write("#{JSON.pretty_generate(package_json)}\n")
    tmp.chmod(File.stat(package_json_path).mode & 0o777)
    tmp.close
    File.rename(tmp_path, package_json_path)
    renamed = true
  ensure
    tmp.close unless tmp.closed?
    File.unlink(tmp_path) if !renamed && File.exist?(tmp_path)
  end
end

def with_publishable_package_json(dir, package_version)
  package_json_path = File.join(dir, "package.json")
  changed = false
  original_content = File.read(package_json_path)
  package_json = JSON.parse(original_content)

  if replace_workspace_protocol_dependencies_for_publish!(package_json, package_version)
    write_publishable_package_json(package_json_path, package_json)
    # Only flip `changed` after the atomic same-directory rename succeeds so the `ensure`
    # restore runs only after package.json was actually replaced.
    changed = true
  end

  yield
ensure
  original_error = $ERROR_INFO

  begin
    File.write(package_json_path, original_content) if changed
  rescue StandardError => e
    warn "⚠️  Failed to restore #{package_json_path}: #{e.message}"
    raise e unless original_error
  end
end

def fetch_npm_package_metadata(package_ref, registry_url:)
  output, status = Open3.capture2e(
    "npm",
    "view",
    package_ref,
    "version",
    "dependencies",
    "optionalDependencies",
    "peerDependencies",
    "--json",
    "--registry",
    registry_url
  )
  [output, status]
end

def fetch_npm_package_metadata_with_retries(package_ref, registry_url:, attempts:, retry_delay_seconds:)
  last_output = nil
  last_status = nil

  attempts.times do |attempt|
    output, status = fetch_npm_package_metadata(package_ref, registry_url:)
    return [output, status] if status.success?

    last_output = output
    last_status = status
    unless attempt == attempts - 1
      puts "npm did not return #{package_ref} yet; retrying in #{retry_delay_seconds} seconds..."
      sleep retry_delay_seconds
    end
  end

  [last_output, last_status]
end

def parse_npm_package_metadata(package_ref, output)
  JSON.parse(output)
rescue JSON::ParserError => e
  abort <<~ERROR
    ❌ Unable to parse npm metadata for #{package_ref}.

    Error: #{e.message}
    Output:
    #{output}
  ERROR
end

def verify_npm_package_published!(
  package_name,
  expected_version,
  registry_url: NPM_REGISTRY_URL,
  attempts: NPM_PUBLISH_VERIFY_ATTEMPTS,
  retry_delay_seconds: NPM_PUBLISH_VERIFY_RETRY_DELAY_SECONDS
)
  package_ref = "#{package_name}@#{expected_version}"
  output, status = fetch_npm_package_metadata_with_retries(
    package_ref,
    registry_url:,
    attempts:,
    retry_delay_seconds:
  )
  unless status.success?
    abort <<~ERROR
      ❌ #{package_ref} is not visible on npm after publish.

      The release cannot continue because npm did not confirm the published package.

      Technical details:
      #{output.strip}
    ERROR
  end

  metadata = parse_npm_package_metadata(package_ref, output)
  actual_version = metadata.is_a?(Hash) ? metadata["version"] : metadata.to_s
  unless actual_version == expected_version
    abort <<~ERROR
      ❌ npm returned #{actual_version.inspect} for #{package_ref}; expected #{expected_version.inspect}.

      The release cannot continue because npm did not confirm the exact published version.
    ERROR
  end

  workspace_dependencies = workspace_protocol_dependencies(metadata)
  unless workspace_dependencies.empty?
    abort <<~ERROR
      ❌ #{package_ref} was published with workspace protocol dependencies.

      Published packages must not contain workspace:* install-time dependencies because external package managers
      cannot resolve them from npm.

      Offending dependencies:
      #{workspace_dependencies.map { |dependency| "  - #{dependency}" }.join("\n")}
    ERROR
  end

  puts "✓ Verified npm package #{package_ref}"
end

def publish_npm_with_retry(dir, package_name, base_args: [], otp: nil, max_retries: 3)
  puts "\nPublishing #{package_name}..."
  current_otp = normalize_otp_code(otp, service_name: "NPM")
  publish_args = Array(base_args)
  npm_package_name, npm_package_version = parse_npm_package_ref(package_name)

  retry_count = 0
  success = false

  while retry_count < max_retries && !success
    begin
      command_args = ["pnpm", "publish", *publish_args]
      command_args += ["--otp", current_otp] if current_otp
      with_publishable_package_json(dir, npm_package_version) do
        sh_args_in_dir_for_release(dir, *command_args)
      end
      verify_npm_package_published!(npm_package_name, npm_package_version)
      success = true
    rescue RuntimeError => e
      retry_count += 1
      if retry_count < max_retries
        puts "\n⚠️  #{package_name} publish failed (attempt #{retry_count}/#{max_retries})"
        puts "Error: #{e.message}"
        puts "Common causes:"
        puts "  - OTP code expired or incorrect"
        puts "  - Network timeout"
        puts "\nPlease enter a FRESH OTP code to retry..."
        current_otp = prompt_for_otp("NPM")
      else
        puts "\n❌ Failed to publish #{package_name} after #{max_retries} attempts"
        raise e
      end
    end
  end

  # Return the last successful OTP so it can be reused for subsequent packages
  current_otp
end

# rubocop:disable Metrics/BlockLength

desc("Unified release script for all React on Rails packages and gems.

IMPORTANT: This script uses UNIFIED VERSIONING - all packages (core + pro) will be
updated to the same version number and released together.

Version argument can be:
  - Semver bump type: 'patch', 'minor', or 'major' (e.g., 16.1.1 → 16.1.2, 16.2.0, or 17.0.0)
  - Explicit version: '16.2.0'
  - Pre-release version: '16.2.0.beta.1' (rubygem format with dots, converted to 16.2.0-beta.1 for NPM)

Note: Pre-release versions (containing .test., .beta., .alpha., .rc., or .pre.) automatically
skip git branch checks, allowing releases from non-main branches.

This will update and release:
  PUBLIC (npmjs.org + rubygems.org):
    - react-on-rails NPM package
    - react-on-rails-pro NPM package
    - react-on-rails-pro-node-renderer NPM package
    - create-react-on-rails-app NPM package
    - react_on_rails RubyGem
    - react_on_rails_pro RubyGem

1st argument: Version (optional). Supported values:
  - patch/minor/major
  - explicit version like 16.2.0
  - explicit prerelease like 16.2.0.rc.1
  - empty (auto): use latest CHANGELOG.md version if newer, else patch bump
2nd argument: Dry run (true/false, default: false)
3rd argument: Override version policy checks (true/false, default: false)
4th argument: Override release CI gates (true/false, default: false)

Release CI policy:
  Before releasing, the script checks CI status on origin/main HEAD.
  - Stable releases require every check run on the commit to have succeeded.
  - Pre-releases require only the GitHub-branch-protection-required checks
    to have succeeded.
  After pushing the version bump commit, the script runs the ShakaPerf RSC FOUC
  workflow_dispatch gate and waits for it before creating/pushing the tag and
  publishing npm packages or Ruby gems.
  If that gate fails, the remote branch has the version-bump commit but no release
  tag or published packages; retry from that commit or push a revert commit first.
  In-progress checks and failing gates block the release until they pass, or until you
  explicitly override via the 4th argument or RELEASE_CI_STATUS_OVERRIDE=true.

Environment variables:
  VERBOSE=1                    # Enable verbose logging (shows all output)
  NPM_OTP=<code>               # Provide NPM one-time password (reused for all NPM publishes)
  RUBYGEMS_OTP=<code>          # Provide RubyGems one-time password (reused for both gems)
  RELEASE_VERSION_POLICY_OVERRIDE=true # Override release version policy checks
  RELEASE_CI_STATUS_OVERRIDE=true      # Override release CI gates
  GEM_RELEASE_MAX_RETRIES=<n>  # Override max retry attempts (default: 3)

Examples:
  rake release                                  # Use CHANGELOG.md version or patch bump
  rake release[patch]                           # Bump patch version (16.1.1 → 16.1.2)
  rake release[minor]                           # Bump minor version (16.1.1 → 16.2.0)
  rake release[major]                           # Bump major version (16.1.1 → 17.0.0)
  rake release[16.2.0]                          # Set explicit version
  rake release[16.2.0.beta.1]                   # Set pre-release version (→ 16.2.0-beta.1 for NPM)
  rake release[patch,true]                      # Dry run
  VERBOSE=1 rake release[patch]                 # Release with verbose logging
  NPM_OTP=123456 RUBYGEMS_OTP=789012 rake release[patch]  # Skip OTP prompts")
task :release, %i[version dry_run override_version_policy override_ci_status] do |_t, args|
  monorepo_root = current_monorepo_root

  args_hash = args.to_hash

  is_dry_run = ReactOnRails::Utils.object_to_boolean(args_hash[:dry_run])
  is_verbose = ENV["VERBOSE"] == "1"
  allow_version_policy_override = version_policy_override_enabled?(args_hash[:override_version_policy])
  allow_ci_status_override = ci_status_override_enabled?(args_hash[:override_ci_status])
  npm_otp = ENV.fetch("NPM_OTP", nil)
  rubygems_otp = ENV.fetch("RUBYGEMS_OTP", nil)

  current_branch_output, current_branch_status = Open3.capture2e(
    "git", "-C", monorepo_root, "rev-parse", "--abbrev-ref", "HEAD"
  )
  abort "❌ Failed to determine current git branch.\n\n#{current_branch_output}" unless current_branch_status.success?
  current_branch = current_branch_output.strip

  # Check if there are uncommitted changes
  ReactOnRails::GitUtils.uncommitted_changes?(RaisingMessageHandler.new)

  # Configure output verbosity
  verbose(is_verbose)

  run_release_preflight_checks!(monorepo_root:, dry_run: is_dry_run)

  released_gem_version = nil
  released_npm_version = nil

  with_release_checkout(monorepo_root:, dry_run: is_dry_run) do |release_root|
    release_paths_hash = release_paths(release_root)
    sh_in_dir_for_release(release_root, "git pull --rebase") unless is_dry_run

    version_input = resolve_version_input(args_hash.fetch(:version, ""), release_root)
    validate_requested_version_input!(version_input)

    current_checkout_version = current_gem_version(release_root)
    resolved_target_gem_version = compute_target_gem_version(
      current_gem_version: current_checkout_version,
      version_input:
    )
    is_prerelease = release_prerelease_version?(resolved_target_gem_version)

    unless is_prerelease || current_branch == "main"
      abort <<~ERROR
        ❌ Release must be run from the main branch!

        Current branch: #{current_branch}

        To release a stable version, please switch to main:
          git checkout main && git pull --rebase

        For pre-release versions (beta, alpha, rc, etc.), you can release from any branch:
          rake release[#{resolved_target_gem_version.sub(/(\d+\.\d+\.\d+)/, '\\1.beta.1')}]
      ERROR
    end

    validate_main_ci_status!(
      monorepo_root: release_root,
      is_prerelease:,
      allow_override: allow_ci_status_override,
      dry_run: is_dry_run
    )

    validate_release_version_policy!(
      monorepo_root: release_root,
      target_gem_version: resolved_target_gem_version,
      allow_override: allow_version_policy_override,
      fetch_tags: true
    )

    confirm_release!(version: resolved_target_gem_version, monorepo_root: release_root) unless is_dry_run

    # Having generated examples in-tree can interfere with publishing.
    sh_in_dir_for_release(release_root, "rm -rf gen-examples/examples")
    # Delete any react_on_rails.gemspec except the root one.
    sh_in_dir_for_release(release_paths_hash[:gem_root], "find . -mindepth 2 -name 'react_on_rails.gemspec' -delete")
    # Delete any react_on_rails_pro.gemspec except the one in react_on_rails_pro directory.
    sh_in_dir_for_release(release_paths_hash[:gem_root],
                          "find . -mindepth 3 -name 'react_on_rails_pro.gemspec' -delete")

    if semver_keyword?(version_input)
      puts "Bumping #{version_input} version for react_on_rails gem..."
    else
      puts "Setting react_on_rails gem version to #{version_input}..."
    end
    sh_in_dir_for_release(release_paths_hash[:gem_root], "gem bump --no-commit --version #{version_input}")

    actual_gem_version = current_gem_version(release_root)
    actual_npm_version = ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(actual_gem_version)

    puts "\n#{'=' * 80}"
    puts "UNIFIED VERSION: #{actual_gem_version} (gem) / #{actual_npm_version} (npm)"
    puts "=" * 80

    # Update react_on_rails_pro gem version to match.
    puts "\nUpdating react_on_rails_pro gem version to #{actual_gem_version}..."
    pro_version_file = File.join(release_paths_hash[:pro_gem_root], "lib", "react_on_rails_pro", "version.rb")
    pro_version_content = File.read(pro_version_file)
    # Use word boundary \b to match VERSION and avoid PROTOCOL_VERSION.
    pro_version_content.gsub!(/\bVERSION = ".+"/, "VERSION = \"#{actual_gem_version}\"")
    File.write(pro_version_file, pro_version_content)
    puts "  Updated #{pro_version_file}"
    puts "  Note: react_on_rails_pro.gemspec will automatically use ReactOnRails::VERSION"

    puts "\nUpdating package.json files to version #{actual_npm_version}..."
    package_json_files = [
      File.join(release_root, "package.json"),
      File.join(release_root, "packages", "react-on-rails", "package.json"),
      File.join(release_root, "packages", "react-on-rails-pro", "package.json"),
      File.join(release_root, "packages", "react-on-rails-pro-node-renderer", "package.json"),
      File.join(release_root, "packages", "create-react-on-rails-app", "package.json")
    ]

    package_json_files.each do |file|
      content = JSON.parse(File.read(file))
      content["version"] = actual_npm_version
      File.write(file, "#{JSON.pretty_generate(content)}\n")
      puts "  Updated #{file}"
    end

    puts "\nUpdating Gemfile.lock files..."
    bundle_quiet_flag = is_verbose ? "" : " --quiet"
    unbundled_sh_in_dir_for_release(release_paths_hash[:gem_root], "bundle install#{bundle_quiet_flag}")
    unbundled_sh_in_dir_for_release(release_paths_hash[:dummy_app_dir], "bundle install#{bundle_quiet_flag}")

    if Dir.exist?(release_paths_hash[:pro_dummy_app_dir])
      unbundled_sh_in_dir_for_release(release_paths_hash[:pro_dummy_app_dir], "bundle install#{bundle_quiet_flag}")
    end

    if Dir.exist?(release_paths_hash[:pro_execjs_dummy_app_dir])
      unbundled_sh_in_dir_for_release(
        release_paths_hash[:pro_execjs_dummy_app_dir],
        "bundle install#{bundle_quiet_flag}"
      )
    end

    unbundled_sh_in_dir_for_release(release_paths_hash[:pro_gem_root], "bundle install#{bundle_quiet_flag}")

    released_gem_version = actual_gem_version
    released_npm_version = actual_npm_version

    unless is_dry_run
      sh_in_dir_for_release(release_root, "LEFTHOOK=0 git add -A")

      _git_diff_output, git_diff_status = Open3.capture2e("git", "-C", release_root, "diff", "--cached", "--quiet")
      if git_diff_status.success?
        puts "No version changes to commit (version already set to #{actual_gem_version})"
      else
        sh_in_dir_for_release(release_root, "LEFTHOOK=0 git commit -m 'Bump version to #{actual_gem_version}'")
      end

      # Push the version-bump commit first so the workflow_dispatch run can be matched by headSha.
      sh_in_dir_for_release(release_root, "LEFTHOOK=0 git push")
      run_shakaperf_release_gate!(
        monorepo_root: release_root,
        ref: current_branch,
        head_sha: current_git_sha!(release_root),
        allow_override: allow_ci_status_override,
        dry_run: is_dry_run
      )

      tag_name = "v#{actual_gem_version}"
      tag_exists = system("git", "-C", release_root, "rev-parse", "--verify", "--quiet", "refs/tags/#{tag_name}",
                          out: File::NULL, err: File::NULL)
      if tag_exists
        puts "Git tag #{tag_name} already exists, skipping tag creation"
      else
        sh_in_dir_for_release(release_root, "git tag #{tag_name}")
      end

      sh_in_dir_for_release(release_root, "LEFTHOOK=0 git push --tags")

      puts "\n#{'=' * 80}"
      puts "Publishing PUBLIC packages to npmjs.org..."
      puts "=" * 80

      npm_base_args = []
      current_npm_otp = npm_otp

      if current_npm_otp
        puts "Using provided NPM OTP for NPM package publications..."
      else
        puts "\nNOTE: You will be prompted for NPM OTP code if needed."
        puts "TIP: Set NPM_OTP environment variable to provide OTP upfront."
      end

      npm_dist_tag = npm_dist_tag_for_version(actual_npm_version)
      puts "NPM target: #{actual_npm_version} (dist-tag: #{npm_dist_tag})"
      npm_base_args += ["--tag", npm_dist_tag] unless npm_dist_tag == "latest"

      if release_prerelease_version?(actual_gem_version)
        npm_base_args << "--no-git-checks"
        puts "Pre-release version detected - skipping git branch checks for NPM publish"
      end

      current_npm_otp = publish_npm_with_retry(
        File.join(release_root, "packages", "react-on-rails"),
        "react-on-rails@#{actual_npm_version}",
        base_args: npm_base_args,
        otp: current_npm_otp
      )

      current_npm_otp = publish_npm_with_retry(
        File.join(release_root, "packages", "react-on-rails-pro"),
        "react-on-rails-pro@#{actual_npm_version}",
        base_args: npm_base_args,
        otp: current_npm_otp
      )

      puts "\n#{'=' * 80}"
      puts "Publishing PUBLIC node-renderer to npmjs.org..."
      puts "=" * 80

      current_npm_otp = publish_npm_with_retry(
        File.join(release_root, "packages", "react-on-rails-pro-node-renderer"),
        "react-on-rails-pro-node-renderer@#{actual_npm_version}",
        base_args: npm_base_args,
        otp: current_npm_otp
      )

      publish_npm_with_retry(
        File.join(release_root, "packages", "create-react-on-rails-app"),
        "create-react-on-rails-app@#{actual_npm_version}",
        base_args: npm_base_args,
        otp: current_npm_otp
      )

      puts "\n#{'=' * 80}"
      puts "Publishing PUBLIC Ruby gems..."
      puts "=" * 80

      current_rubygems_otp = resolve_rubygems_otp_for_publish(rubygems_otp)

      current_rubygems_otp = publish_gem_with_retry(
        release_paths_hash[:gem_root],
        "react_on_rails",
        otp: current_rubygems_otp
      )

      publish_gem_with_retry(
        release_paths_hash[:pro_gem_root],
        "react_on_rails_pro",
        otp: current_rubygems_otp
      )
    end
  end

  if is_dry_run
    puts "\n#{'=' * 80}"
    puts "DRY RUN COMPLETE"
    puts "=" * 80
    puts "Version would be bumped to: #{released_gem_version} (gem) / #{released_npm_version} (npm)"
    puts "\nFiles that would be updated:"
    puts "  - react_on_rails/lib/react_on_rails/version.rb"
    puts "  - react_on_rails_pro/lib/react_on_rails_pro/version.rb"
    puts "  - package.json (root)"
    puts "  - packages/react-on-rails/package.json"
    puts "  - packages/react-on-rails-pro/package.json (version only; workspace:* converted by pnpm)"
    puts "  - packages/react-on-rails-pro-node-renderer/package.json"
    puts "  - packages/create-react-on-rails-app/package.json"
    puts "  - Gemfile.lock files (root, dummy apps, pro)"
    puts "\nAuto-synced (no write needed):"
    puts "  - react_on_rails_pro/react_on_rails_pro.gemspec (uses ReactOnRails::VERSION)"
    puts "\nTo actually release, run: rake release[#{released_gem_version}]"
  else
    sync_github_release_after_publish(monorepo_root:, gem_version: released_gem_version, dry_run: false)

    changelog_path = File.join(monorepo_root, "CHANGELOG.md")
    has_changelog_section = extract_changelog_section(changelog_path:, version: released_gem_version)

    puts "\n#{'=' * 80}"
    puts "RELEASE COMPLETE!"
    puts "=" * 80
    puts ""
    puts "Published to npmjs.org:"
    puts "  - react-on-rails@#{released_npm_version}"
    puts "  - react-on-rails-pro@#{released_npm_version}"
    puts "  - react-on-rails-pro-node-renderer@#{released_npm_version}"
    puts "  - create-react-on-rails-app@#{released_npm_version}"
    puts ""
    puts "Ruby Gems (RubyGems.org):"
    puts "  - react_on_rails #{released_gem_version}"
    puts "  - react_on_rails_pro #{released_gem_version}"
    puts ""

    if has_changelog_section
      puts "Changelog: ✓ CHANGELOG.md section found for #{released_gem_version}"
    else
      puts "Next steps:"
      puts "  Option A - Use Claude Code (recommended):"
      puts "    Run /update-changelog to analyze commits, write entries, and create a PR"
      puts ""
      puts "  Option B - Manual:"
      puts "    1. Ensure CHANGELOG.md entries are complete"
      puts "    2. Push any follow-up changelog fixes if needed"
    end
    puts ""
  end
end

desc("Creates or updates a GitHub release from CHANGELOG.md for an already-published version.

Arguments:
1st argument: Gem version in RubyGems format (required), e.g. 16.4.0 or 16.4.0.rc.1
2nd argument: Dry run (true/false, default: false)

Examples:
  rake \"sync_github_release[16.4.0]\"
  rake \"sync_github_release[16.4.0.rc.1]\"
  rake \"sync_github_release[16.4.0.rc.1,true]\"
")
task :sync_github_release, %i[gem_version dry_run] do |_t, args|
  monorepo_root = current_monorepo_root
  args_hash = args.to_hash
  is_dry_run = ReactOnRails::Utils.object_to_boolean(args_hash[:dry_run])

  requested_gem_version = args_hash[:gem_version].to_s.strip
  if requested_gem_version.empty?
    abort "❌ gem_version is required. Usage: " \
          "rake \"sync_github_release[16.4.0]\" or rake \"sync_github_release[16.4.0.rc.1]\""
  end
  validate_requested_version_input!(requested_gem_version)

  puts "ℹ️ sync_github_release reads local committed CHANGELOG.md; " \
       "run `git pull --rebase` first for latest remote notes."
  if is_dry_run
    if changelog_dirty?(monorepo_root:)
      abort "❌ DRY RUN: CHANGELOG.md has uncommitted changes. " \
            "Commit or stash CHANGELOG.md before running sync_github_release."
    end
    puts "DRY RUN: Validating CHANGELOG.md section exists for #{requested_gem_version}..."
  else
    ensure_changelog_committed!(monorepo_root:)
  end

  verify_gh_auth(monorepo_root:)
  release_context = prepare_github_release_context(monorepo_root:, gem_version: requested_gem_version)
  publish_or_update_github_release(monorepo_root:, release_context:, dry_run: is_dry_run)
end
# rubocop:enable Metrics/BlockLength
