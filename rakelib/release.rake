# frozen_string_literal: true

require "bundler"
require "json"
require "open3"
require "rubygems/version"
require "shellwords"
require "tempfile"
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

# Helper methods for release-specific tasks
# These are defined at the top level so they have access to Rake's sh method

def current_monorepo_root
  File.expand_path("..", __dir__)
end

def release_paths(monorepo_root)
  {
    monorepo_root: monorepo_root,
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

def prompt_for_otp(service_name)
  print "\n🔑 Enter OTP code for #{service_name}: "
  $stdout.flush
  otp = $stdin.gets&.strip
  abort "\n❌ No OTP provided. Aborting." if otp.nil? || otp.empty?
  normalize_otp_code(otp, service_name: service_name)
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

def capture_gh_output(*args)
  Open3.capture2e("gh", *args)
rescue Errno::ENOENT
  abort "❌ GitHub CLI (`gh`) is not installed. Install it from https://cli.github.com/ and retry."
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

def run_release_preflight_checks!(monorepo_root:, dry_run:)
  return if dry_run

  puts "\n#{'=' * 80}"
  puts "PRE-FLIGHT CHECKS"
  puts "=" * 80
  verify_npm_auth
  verify_gh_auth(monorepo_root: monorepo_root)
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
    "#{version[:major]}.#{version[:minor]}.#{version[:patch] + 1}"
  when "minor"
    "#{version[:major]}.#{version[:minor] + 1}.0"
  when "major"
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
  lines[(start_index + 1)...end_index].join.strip
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
def validate_release_version_policy!(monorepo_root:, target_gem_version:, allow_override:, fetch_tags: true)
  tagged_versions = tagged_release_gem_versions(monorepo_root, fetch_tags: fetch_tags)
  latest_tagged_version = tagged_versions.max_by { |version| Gem::Version.new(version) }

  if latest_tagged_version && Gem::Version.new(target_gem_version) <= Gem::Version.new(latest_tagged_version)
    handle_version_policy_violation!(
      message: "❌ Requested version #{target_gem_version} " \
               "must be greater than latest tagged version #{latest_tagged_version}.",
      allow_override: allow_override
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
                                       target_gem_version: target_gem_version)
  if actual_bump_type == :none
    handle_version_policy_violation!(
      message: "❌ Requested version #{target_gem_version} is not a major/minor/patch bump " \
               "over latest stable #{latest_stable_version}.",
      allow_override: allow_override
    )
    return if allow_override
  end

  if release_prerelease_version?(target_gem_version)
    puts "ℹ️ VERSION POLICY: Skipping changelog bump-consistency check for prerelease #{target_gem_version}."
    return
  end

  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  changelog_section = extract_changelog_section(changelog_path: changelog_path, version: target_gem_version)
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
    allow_override: allow_override
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

def warn_changelog_missing(monorepo_root:, version:)
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  section = extract_changelog_section(changelog_path: changelog_path, version: version)
  return if section

  puts "################################################################################"
  puts "WARNING: No CHANGELOG.md section found for #{version}."
  puts "Consider running /update-changelog to add entries before releasing."
  puts "sync_github_release will fail without a matching changelog section."
  puts "################################################################################"
end

def changelog_dirty?(monorepo_root:)
  changes_output, status = Open3.capture2e("git", "-C", monorepo_root, "status", "--porcelain", "--", "CHANGELOG.md")
  stripped = changes_output.strip
  abort "❌ Unable to check CHANGELOG.md status\n\n#{stripped}" unless status.success?
  !stripped.empty?
end

def ensure_changelog_committed!(monorepo_root:)
  return unless changelog_dirty?(monorepo_root: monorepo_root)

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
  notes = extract_changelog_section(changelog_path: changelog_path, version: gem_version)
  abort "❌ Could not find `### [#{gem_version}]` in CHANGELOG.md. Add that section and retry." unless notes

  {
    notes: notes,
    prerelease: prerelease,
    tag: "v#{gem_version}",
    title: "v#{gem_version}"
  }
end

# rubocop:disable Metrics/AbcSize
def publish_or_update_github_release(monorepo_root:, release_context:, dry_run:)
  ensure_git_tag_exists!(monorepo_root: monorepo_root, tag: release_context[:tag])

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
  section = extract_changelog_section(changelog_path: changelog_path, version: gem_version)
  unless section
    puts "################################################################################"
    puts "Skipping GitHub release: no CHANGELOG.md section for #{gem_version}."
    puts "After adding the changelog section, run:"
    puts "bundle exec rake \"sync_github_release[#{gem_version}]\""
    puts "################################################################################"
    return
  end

  verify_gh_auth(monorepo_root: monorepo_root)
  release_context = prepare_github_release_context(monorepo_root: monorepo_root, gem_version: gem_version)
  publish_or_update_github_release(monorepo_root: monorepo_root, release_context: release_context, dry_run: dry_run)
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

def resolve_version_input(version_input, monorepo_root)
  stripped = version_input.to_s.strip
  return stripped unless stripped.empty?

  changelog_version = extract_latest_changelog_version(monorepo_root: monorepo_root)
  current_version = current_gem_version(monorepo_root)

  if changelog_version && Gem::Version.new(changelog_version) > Gem::Version.new(current_version)
    puts "Found CHANGELOG.md version: #{changelog_version} (current: #{current_version})"
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

def publish_npm_with_retry(dir, package_name, base_args: [], otp: nil, max_retries: 3)
  puts "\nPublishing #{package_name}..."
  current_otp = normalize_otp_code(otp, service_name: "NPM")
  publish_args = Array(base_args)

  retry_count = 0
  success = false

  while retry_count < max_retries && !success
    begin
      command_args = ["pnpm", "publish", *publish_args]
      command_args += ["--otp", current_otp] if current_otp
      sh_args_in_dir_for_release(dir, *command_args)
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

Environment variables:
  VERBOSE=1                    # Enable verbose logging (shows all output)
  NPM_OTP=<code>               # Provide NPM one-time password (reused for all NPM publishes)
  RUBYGEMS_OTP=<code>          # Provide RubyGems one-time password (reused for both gems)
  RELEASE_VERSION_POLICY_OVERRIDE=true # Override release version policy checks
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
task :release, %i[version dry_run override_version_policy] do |_t, args|
  monorepo_root = current_monorepo_root

  args_hash = args.to_hash

  is_dry_run = ReactOnRails::Utils.object_to_boolean(args_hash[:dry_run])
  is_verbose = ENV["VERBOSE"] == "1"
  allow_version_policy_override = version_policy_override_enabled?(args_hash[:override_version_policy])
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

  run_release_preflight_checks!(monorepo_root: monorepo_root, dry_run: is_dry_run)

  released_gem_version = nil
  released_npm_version = nil

  with_release_checkout(monorepo_root: monorepo_root, dry_run: is_dry_run) do |release_root|
    release_paths_hash = release_paths(release_root)
    sh_in_dir_for_release(release_root, "git pull --rebase") unless is_dry_run

    version_input = resolve_version_input(args_hash.fetch(:version, ""), release_root)
    validate_requested_version_input!(version_input)

    current_checkout_version = current_gem_version(release_root)
    resolved_target_gem_version = compute_target_gem_version(
      current_gem_version: current_checkout_version,
      version_input: version_input
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

    warn_changelog_missing(monorepo_root: release_root, version: resolved_target_gem_version)
    validate_release_version_policy!(
      monorepo_root: release_root,
      target_gem_version: resolved_target_gem_version,
      allow_override: allow_version_policy_override,
      fetch_tags: true
    )

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

      tag_name = "v#{actual_gem_version}"
      tag_exists = system("git", "-C", release_root, "rev-parse", "--verify", "--quiet", "refs/tags/#{tag_name}",
                          out: File::NULL, err: File::NULL)
      if tag_exists
        puts "Git tag #{tag_name} already exists, skipping tag creation"
      else
        sh_in_dir_for_release(release_root, "git tag #{tag_name}")
      end

      sh_in_dir_for_release(release_root, "LEFTHOOK=0 git push")
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

      current_rubygems_otp = rubygems_otp
      if current_rubygems_otp
        puts "Using provided RubyGems OTP for gem publications..."
      else
        puts "\nNOTE: You will be prompted for RubyGems OTP code if needed."
        puts "TIP: Set RUBYGEMS_OTP environment variable to provide OTP upfront."
      end

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
    sync_github_release_after_publish(monorepo_root: monorepo_root, gem_version: released_gem_version, dry_run: false)

    changelog_path = File.join(monorepo_root, "CHANGELOG.md")
    has_changelog_section = extract_changelog_section(changelog_path: changelog_path, version: released_gem_version)

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
    if changelog_dirty?(monorepo_root: monorepo_root)
      abort "❌ DRY RUN: CHANGELOG.md has uncommitted changes. " \
            "Commit or stash CHANGELOG.md before running sync_github_release."
    end
    puts "DRY RUN: Validating CHANGELOG.md section exists for #{requested_gem_version}..."
  else
    ensure_changelog_committed!(monorepo_root: monorepo_root)
  end

  verify_gh_auth(monorepo_root: monorepo_root)
  release_context = prepare_github_release_context(monorepo_root: monorepo_root, gem_version: requested_gem_version)
  publish_or_update_github_release(monorepo_root: monorepo_root, release_context: release_context, dry_run: is_dry_run)
end
# rubocop:enable Metrics/BlockLength
