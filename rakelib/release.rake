# frozen_string_literal: true

require "bundler"
require "cgi"
require "digest"
require "English"
require "json"
require "net/http"
require "open3"
require "rubygems/version"
require "shellwords"
require "tempfile"
require "time"
require "tmpdir"
require "uri"
require_relative "release_changelog_selector"
require_relative "release_lease_guard"
require_relative "task_helpers"
require_relative "../react_on_rails/lib/react_on_rails/version_syntax_converter"
require_relative "../react_on_rails/lib/react_on_rails/git_utils"

class RaisingMessageHandler
  def add_error(error)
    raise error
  end
end

class UnhandledReleaseFinalizationMetadataPathError < StandardError; end

NPM_REGISTRY_URL = "https://registry.npmjs.org/"
RUBYGEMS_VERSIONS_API_URL = "https://rubygems.org/api/v1/versions"
RUBYGEMS_VERSIONS_OPEN_TIMEOUT_SECONDS = 10
RUBYGEMS_VERSIONS_READ_TIMEOUT_SECONDS = 15
GITHUB_RELEASE_BODY_MAX_LENGTH = 125_000
NPM_PUBLISH_VERIFY_ATTEMPTS = 6
NPM_PUBLISH_VERIFY_RETRY_DELAY_SECONDS = 5
NPM_PUBLISH_MAX_BACKOFF_SECONDS = 30
NPM_PUBLISH_HARD_FAILURE_CATEGORIES = %i[
  authentication_failure
  local_lifecycle
  registry_rejection
  unknown
].freeze
NPM_PUBLISH_UNCERTAIN_RECOVERY_CATEGORIES = %i[transient registry_rejection].freeze
NPM_PUBLISH_TRANSIENT_PATTERN = %r{
  \b(?:
    EAI_AGAIN | ECONNRESET | ETIMEDOUT | ENETUNREACH | ECONNREFUSED |
    ERR_SOCKET_TIMEOUT | E429 | E5\d\d | ERR_PNPM_FETCH_(?:429|5\d\d)
  )\b |
  socket\ hang\ up | network\ (?:timeout|error) | too\ many\ requests |
  \bHTTP(?:/1\.\d)?\s+(?:429|5\d\d)\b |
  \b(?:response(?:\s+status)?|status(?:\s+code)?)\s*(?::|=)?\s*(?:429|5\d\d)\b
}ix
NPM_PUBLISH_LOCAL_LIFECYCLE_HARD_PATTERN = /
  \b(?:ELIFECYCLE|ERR_PNPM_RECURSIVE_RUN_FIRST_FAIL|ERR_PNPM_EXEC_FIRST_FAIL|ERR_PNPM_NO_SCRIPT)\b |
  Cannot\ find\ module
/ix
NPM_PUBLISH_LOCAL_LIFECYCLE_BANNER_PATTERN = /\b(?:prepublishOnly|lifecycle(?:\s+script)?|tsc|TypeScript)\b/i
NPM_PUBLISH_LOCAL_LIFECYCLE_FAILURE_CONTEXT_PATTERN = /
  \b(?:failed|failure|not\ found|not\ recognized)\b | \berror\s+TS\d+\b
/ix
NPM_PUBLISH_REGISTRY_REJECTION_PATTERN = /
  \b(?:EPUBLISHCONFLICT|E403|E400)\b | cannot\ publish\ over | previously\ published | forbidden |
  invalid\ package | invalid\ semver | access\ denied
/ix
NPM_INSTALL_DEPENDENCY_FIELDS = %w[dependencies optionalDependencies peerDependencies].freeze
NPM_RELEASE_PACKAGE_NAMES = %w[
  react-on-rails
  react-on-rails-pro
  react-on-rails-pro-node-renderer
  create-react-on-rails-app
].freeze
RUBYGEMS_RELEASE_GEM_NAMES = %w[
  react_on_rails
  react_on_rails_pro
].freeze
SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE = "shakaperf-release-gates.yml"
SHAKAPERF_RELEASE_GATE_START_TIMEOUT_SECONDS = 600
SHAKAPERF_RELEASE_GATE_START_POLL_SECONDS = 5
SHAKAPERF_RELEASE_GATE_RUN_LIST_LIMIT = 100
SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS = 65 * 60
# Keep in sync with the sum of timeout-minutes in .github/workflows/shakaperf-release-gates.yml.
SHAKAPERF_RELEASE_GATE_WORKFLOW_TIMEOUT_MINUTES = 60
SHAKAPERF_RELEASE_GATE_EVIDENCE_ARTIFACT = "shakaperf-release-evidence"
SHAKAPERF_RELEASE_GATE_EVIDENCE_FILE = "shakaperf-release-evidence.json"
SHAKAPERF_RELEASE_GATE_EVIDENCE_MAX_AGE_SECONDS = 7 * 24 * 60 * 60
SHAKAPERF_RELEASE_GATE_EVIDENCE_SCHEMA_VERSION = 2
SHAKAPERF_GIT_TREE_METADATA_PATTERN = /\A\d{6} (?:blob|commit) [0-9a-f]{40}(?:[0-9a-f]{24})?\z/
SHAKAPERF_GIT_NAME_STATUS_PATTERN = /\A(?:[ADMTUXB]|[CR]\d{1,3})\z/
ACCELERATED_RC_RECORD_SCHEMA_VERSION = 1
ACCELERATED_RC_RECORD_MARKER = "react-on-rails-accelerated-rc"
ACCELERATED_RC_RECORD_MARKER_OPENER = "<!-- #{ACCELERATED_RC_RECORD_MARKER} ".freeze
ACCELERATED_RC_TAG_PROVENANCE_MARKER = "react-on-rails-accelerated-rc-provenance"
ACCELERATED_RC_REPOSITORY_COMMENT_PAGE_SIZE = 100
ACCELERATED_RC_REPOSITORY_COMMENT_MAX_PAGES = 250
ACCELERATED_RC_REPOSITORY_MARKER_COMMENT_LIMIT = 1_000
ACCELERATED_RC_CANONICAL_TARGET_PATTERN =
  /\A(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.rc\.(?:0|[1-9]\d*)\z/
ACCELERATED_RC_CANONICAL_TARGET_CASE_INSENSITIVE_PATTERN =
  /\A(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.rc\.(?:0|[1-9]\d*)\z/i
ACCELERATED_RC_LOOSE_TARGET_PATTERN = /\A\d+\.\d+\.\d+\.rc\.\d+\z/i
ACCELERATED_RC_RECORD_IDENTITY_FIELDS = %w[status target_version candidate_sha].freeze
ACCELERATED_RC_PENDING_STATUSES = %w[publication-authorized published-awaiting-gates].freeze
ACCELERATED_RC_TERMINAL_STATUSES = %w[candidate-accepted candidate-rejected].freeze
ACCELERATED_RC_RECORD_STATUSES = (ACCELERATED_RC_PENDING_STATUSES + ACCELERATED_RC_TERMINAL_STATUSES).freeze
ACCELERATED_RC_LEGACY_PUBLICATION_FOLLOW_UP =
  "Run release:reconcile_accelerated_rc before promoting this RC to final."
ACCELERATED_RC_PUBLICATION_FOLLOW_UP_CANONICAL_VALUE = "reconcile-accelerated-rc-before-final"
ACCELERATED_RC_REQUIRED_EVIDENCE = %w[demo_fleet behavioral artifacts].freeze
ACCELERATED_RC_RECORD_FIELDS = %w[
  schema_version status target_version candidate_sha runtime_tree_fingerprint release_branch release_tracker ci
  shakaperf reason approved_by recorded_at required_follow_up evidence
].freeze
ACCELERATED_RC_CI_FIELDS = %w[status sha checks_url non_success].freeze
ACCELERATED_RC_CI_CHECK_FIELDS = %w[name state url].freeze
ACCELERATED_RC_SHAKAPERF_FIELDS = %w[
  status run_id attempt run_url candidate_sha target_version release_started_at
].freeze
ACCELERATED_RC_TAG_PROVENANCE_FIELDS = %w[
  schema_version target_version candidate_sha release_tracker authorization_digest
].freeze
ACCELERATED_RC_AUTHORIZATION_BOUND_FIELDS = %w[
  schema_version target_version candidate_sha runtime_tree_fingerprint release_branch release_tracker
].freeze
ACCELERATED_RC_CI_BOUND_FIELDS = %w[sha checks_url].freeze
ACCELERATED_RC_SHAKAPERF_BOUND_FIELDS = %w[
  run_id attempt candidate_sha target_version release_started_at
].freeze
ACCELERATED_RC_MAINTAINER_PERMISSIONS = %w[write maintain admin].freeze
ACCELERATED_RC_NON_MAINTAINER_PERMISSIONS = %w[none read triage].freeze
FINAL_PROMOTION_SHAKAPERF_ACCEPTED_RC_MODE = "accepted-rc-reuse"
FINAL_PROMOTION_SHAKAPERF_STRICT_FINAL_MODE = "strict-final"
FINAL_PROMOTION_SHAKAPERF_OBSERVATION_WAIVER_MODE = "strict-final-observation-waiver"
FINAL_PROMOTION_SHAKAPERF_OBSERVATION_WAIVER_FIELDS = %w[
  status run_id attempt run_url candidate_sha target_version release_started_at observed_status observed_conclusion
  release_tracker waiver_digest
].freeze
SHAKAPERF_RELEASE_GATE_TERMINAL_CONCLUSIONS = %w[
  action_required cancelled failure neutral skipped stale startup_failure success timed_out
].freeze
SHAKAPERF_RELEASE_GATE_ACTIVE_STATUSES = %w[queued in_progress requested waiting pending].freeze
SHAKAPERF_RELEASE_GATE_CANONICAL_VERSION_PATTERN =
  /\A(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:\.(?:test|beta|alpha|rc|pre)\.(?:0|[1-9]\d*))?\z/
SHAKAPERF_RELEASE_GATE_DISPLAY_TITLE_PATTERN =
  /\AShakaPerf Release Gates — (?<target_version>.+) on (?<ref>.+) @ (?<head_sha>[0-9a-f]{40})\z/
SHAKAPERF_RELEASE_GATE_EVIDENCE_KEYS = %w[
  branch
  candidate_sha
  completed_at
  conclusion
  run_attempt
  run_id
  run_url
  runtime_tree_fingerprint
  schema_version
  target_version
].freeze
SHAKAPERF_RELEASE_TRACKER_EVIDENCE_MARKER = "<!-- shakaperf-release-evidence v1\n"
SHAKAPERF_RELEASE_TRACKER_EVIDENCE_FIELDS = %w[
  repository release branch head_sha workflow run_id run_attempt event status conclusion started_at completed_at
  run_url report_digest server_logs_digest
].freeze
SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_SCHEMA_VERSION = 1
SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_MARKER = "react-on-rails-shakaperf-release-evidence"
SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_MARKER_OPENER =
  "<!-- #{SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_MARKER} ".freeze
SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_FIELDS = %w[
  schema_version repository release_tracker branch candidate_sha target_version workflow run_id run_attempt run_url
  runtime_tree_fingerprint evidence_digest approved_by recorded_at
].freeze
SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_IDENTITY_FIELDS = %w[
  repository release_tracker branch candidate_sha target_version workflow run_id run_attempt run_url
  runtime_tree_fingerprint evidence_digest
].freeze
SHAKAPERF_APPROVER_BOUND_ENTRY_KINDS = %i[association waiver legacy_waiver].freeze
SHAKAPERF_FINAL_OBSERVATION_WAIVER_SCHEMA_VERSION = 2
SHAKAPERF_FINAL_OBSERVATION_WAIVER_MARKER = "react-on-rails-final-shakaperf-waiver"
SHAKAPERF_FINAL_OBSERVATION_WAIVER_MARKER_OPENER =
  "<!-- #{SHAKAPERF_FINAL_OBSERVATION_WAIVER_MARKER} ".freeze
SHAKAPERF_FINAL_OBSERVATION_WAIVER_FIELDS = %w[
  schema_version repository release_tracker branch candidate_sha target_version workflow run_id run_attempt run_url
  failure_kind reason observation_digest approved_by recorded_at
].freeze
SHAKAPERF_FINAL_OBSERVATION_WAIVER_IDENTITY_FIELDS = %w[
  repository release_tracker branch candidate_sha target_version workflow run_id run_attempt run_url failure_kind
  reason observation_digest approved_by
].freeze
SHAKAPERF_FINAL_OBSERVATION_WAIVER_LEGACY_V1_FIELDS = %w[
  schema_version repository release_tracker branch candidate_sha target_version workflow run_id run_url failure_kind
  reason observation_digest approved_by recorded_at
].freeze

class ShakaperfGateObservationError < StandardError
  attr_reader :run, :tracker_entry

  def initialize(message, run: nil, tracker_entry: nil)
    super(message)
    @run = run
    @tracker_entry = tracker_entry
  end
end

class ShakaperfGateMissingRunError < ShakaperfGateObservationError; end
class ShakaperfGateMissingArtifactError < ShakaperfGateObservationError; end

class ShakaperfAssociationBackedRun < Hash
  attr_reader :association_identity

  def self.from_verified_association(run:, association:)
    identity = SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_IDENTITY_FIELDS.to_h do |field|
      value = association.fetch(field)
      [field, value.is_a?(String) ? value.dup.freeze : value]
    end.freeze
    new(run:, association_identity: identity)
  end

  def initialize(run:, association_identity:)
    super()
    run.each do |key, value|
      self[key] = value.is_a?(String) ? value.dup.freeze : value
    end
    @association_identity = association_identity
    freeze
  end

  private_class_method :new
end

class ShakaperfVerificationResult
  attr_reader :status, :value, :details

  def self.verified(value)
    new(status: :verified, value:)
  end

  def self.not_ancestor
    new(status: :not_ancestor)
  end

  def self.unknown(details)
    new(status: :unknown, details:)
  end

  def initialize(status:, value: nil, details: nil)
    @status = status
    @value = value
    @details = details
  end

  def verified?
    status == :verified
  end
end

class ShakaperfEvidenceRejection
  NATURAL_INVALIDATION_KINDS = %i[
    missing_artifact
    missing_run
    not_ancestor
    runtime_bearing_commits
    runtime_diverged
    stale
    workflow_cancelled
    workflow_failed
  ].freeze

  attr_reader :kind, :message

  def initialize(kind:, message:)
    @kind = kind
    @message = message
  end

  def natural_invalidation?
    NATURAL_INVALIDATION_KINDS.include?(kind)
  end

  def to_s
    message
  end
end

class NpmPublishAttemptError < StandardError
  attr_reader :category

  def initialize(category:, details:)
    @category = category
    super("npm publish #{category.to_s.tr('_', ' ')}: #{details}")
  end
end
# Keep in sync with every package.json, Gemfile.lock, and version file that the
# release task rewrites while promoting an RC to a final release.
# CHANGELOG.md is intentionally excluded. main_ci_walkback_commit? classifies
# changelog-only release commits through commit_non_runtime_only?; adding
# Markdown here would need a content handler.
RELEASE_FINALIZATION_METADATA_PATHS = [
  "Gemfile.lock",
  "package.json",
  "packages/create-react-on-rails-app/package.json",
  "packages/react-on-rails/package.json",
  "packages/react-on-rails-pro/package.json",
  "packages/react-on-rails-pro-node-renderer/package.json",
  "react_on_rails/Gemfile.lock",
  "react_on_rails/lib/react_on_rails/version.rb",
  "react_on_rails/spec/dummy/Gemfile.lock",
  "react_on_rails_pro/Gemfile.lock",
  "react_on_rails_pro/lib/react_on_rails_pro/version.rb",
  "react_on_rails_pro/spec/dummy/Gemfile.lock",
  "react_on_rails_pro/spec/execjs-compatible-dummy/Gemfile.lock"
].freeze
SHAKAPERF_RUNTIME_TREE_IGNORED_PATHS = (RELEASE_FINALIZATION_METADATA_PATHS + ["CHANGELOG.md"]).freeze

# Helper methods for release-specific tasks
# These are defined at the top level so they have access to Rake's sh method

def current_monorepo_root
  File.expand_path("..", __dir__)
end

def release_truthy?(value)
  # Includes "t" to preserve the former ReactOnRails::Utils.object_to_boolean contract.
  [true, "true", "yes", 1, "1", "t"].include?(value.instance_of?(String) ? value.downcase : value)
end

def activate_release_lease_guard!(dry_run:)
  return if dry_run

  ReleaseLeaseGuard.activate!(dry_run: false)
rescue ReleaseLeaseGuard::LeaseError => e
  abort "❌ Live release requires the supervised `script/release` wrapper: #{e.message}"
end

def release_write_fence!(operation)
  ReleaseLeaseGuard.fence!
rescue ReleaseLeaseGuard::LeaseError => e
  abort "❌ Release lease fence failed before #{operation}: #{e.message}"
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

def push_release_version_commit!(release_root)
  release_write_fence!("push version commit")
  sh_in_dir_for_release(release_root, "LEFTHOOK=0 git push")
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

def capture_gh_stdout_and_stderr(*)
  Open3.capture3("gh", *)
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

def current_git_sha!(monorepo_root, context: nil)
  output, status = Open3.capture2e("git", "-C", monorepo_root, "rev-parse", "HEAD")
  abort "❌ Unable to resolve local HEAD before #{context}.\n\n#{output.strip}" if !status.success? && context
  abort "❌ Unable to resolve current git SHA.\n\n#{output}" unless status.success?

  output.strip
end

def shakaperf_runtime_tree_entry(entry)
  metadata, path = entry.split("\t", 2)
  return nil unless metadata&.match?(SHAKAPERF_GIT_TREE_METADATA_PATTERN) && !path.to_s.empty?

  [metadata, path]
end

def shakaperf_runtime_tree_entries_verdict(output)
  entries = output.split("\0")
  return ShakaperfVerificationResult.unknown("git ls-tree returned no entries") if entries.empty?

  parsed_entries = entries.map { |entry| shakaperf_runtime_tree_entry(entry) }
  return ShakaperfVerificationResult.unknown("git ls-tree returned malformed entry data") if parsed_entries.any?(&:nil?)

  runtime_pairs = parsed_entries.reject do |_metadata, path|
    SHAKAPERF_RUNTIME_TREE_IGNORED_PATHS.include?(path)
  end
  runtime_entries = runtime_pairs.map { |metadata, path| "#{metadata}\t#{path}" }
  return ShakaperfVerificationResult.unknown("git ls-tree returned no runtime entries") if runtime_entries.empty?

  ShakaperfVerificationResult.verified(Digest::SHA256.hexdigest(runtime_entries.sort.join("\0")))
end

def shakaperf_runtime_tree_fingerprint_verdict(monorepo_root:, sha:)
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "ls-tree", "-r", "-z", "--full-tree", sha
  )
  unless status.success?
    return ShakaperfVerificationResult.unknown(
      "git ls-tree exited #{status.exitstatus}: #{output.to_s.strip}"
    )
  end

  shakaperf_runtime_tree_entries_verdict(output)
rescue StandardError => e
  ShakaperfVerificationResult.unknown("git ls-tree raised #{e.class}: #{e.message}")
end

def shakaperf_runtime_tree_fingerprint(monorepo_root:, sha:)
  verdict = shakaperf_runtime_tree_fingerprint_verdict(monorepo_root:, sha:)
  verdict.value if verdict.verified?
end

def shakaperf_prerun_candidate(monorepo_root:, ref:, head_sha:)
  target_version = extract_latest_changelog_version(monorepo_root:)
  return nil unless target_version
  return nil unless target_version.match?(/\A\d+\.\d+\.\d+(\.(test|beta|alpha|rc|pre)\.\d+)?\z/i)
  return nil unless ref == "release/#{release_base_version(target_version)}"

  current_version = current_gem_version(monorepo_root)
  return nil unless Gem::Version.new(target_version) > Gem::Version.new(current_version)

  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  return nil unless extract_changelog_section(changelog_path:, version: target_version)

  runtime_tree_fingerprint = shakaperf_runtime_tree_fingerprint(monorepo_root:, sha: head_sha)
  return nil unless runtime_tree_fingerprint

  {
    branch: ref,
    candidate_sha: head_sha,
    target_version:,
    runtime_tree_fingerprint:
  }
rescue ArgumentError
  nil
end

def shakaperf_release_gate_evidence_rejection(monorepo_root:, ref:, head_sha:, target_version:, run:, evidence:,
                                              release_started_at:, validation_time:, require_prerun:,
                                              allow_prerun_completion_after_release_start: false)
  rejection = shakaperf_release_gate_evidence_schema_rejection(evidence)
  return rejection if rejection

  rejection = shakaperf_release_gate_evidence_run_rejection(run:, evidence:)
  return rejection if rejection

  rejection = shakaperf_release_gate_evidence_candidate_rejection(ref:, target_version:, run:, evidence:)
  return rejection if rejection

  rejection = shakaperf_release_gate_evidence_time_rejection(
    run:, evidence:, release_started_at:, validation_time:, require_prerun:,
    allow_prerun_completion_after_release_start:
  )
  return rejection if rejection

  shakaperf_release_gate_evidence_runtime_rejection(monorepo_root:, head_sha:, evidence:)
rescue StandardError => e
  "evidence verification failed: #{e.class}: #{e.message}"
end

def shakaperf_release_gate_evidence_schema_rejection(evidence)
  return "evidence payload is not an object" unless evidence.is_a?(Hash)
  unless evidence.keys.sort == SHAKAPERF_RELEASE_GATE_EVIDENCE_KEYS
    return "evidence schema fields are incomplete or unknown"
  end
  unless evidence["schema_version"] == SHAKAPERF_RELEASE_GATE_EVIDENCE_SCHEMA_VERSION
    return "evidence schema version is unsupported"
  end

  nil
end

def shakaperf_release_gate_evidence_run_rejection(run:, evidence:)
  unless run["status"] == "completed" && run["conclusion"] == "success"
    return "workflow run did not complete successfully"
  end
  return "evidence conclusion is not success" unless evidence["conclusion"] == "success"

  identity_rejection = shakaperf_release_gate_evidence_run_identity_rejection(run:, evidence:)
  return identity_rejection if identity_rejection

  run_url = run["url"]
  return "workflow run URL is missing" unless run_url.is_a?(String) && !run_url.empty?
  return "evidence run URL does not match the workflow run" unless evidence["run_url"] == run_url

  nil
end

def shakaperf_release_gate_evidence_run_identity_rejection(run:, evidence:)
  unless shakaperf_release_gate_run_id_matches?(run:, evidence:)
    return "evidence run ID does not match the workflow run"
  end
  unless shakaperf_release_gate_run_attempt_matches?(run:, evidence:)
    return "evidence run attempt does not match the workflow run"
  end

  nil
end

def shakaperf_release_gate_run_id_matches?(run:, evidence:)
  run_id = evidence["run_id"]
  run_id.is_a?(Integer) && run_id.positive? && run_id == run["databaseId"]
end

def shakaperf_release_gate_run_attempt_matches?(run:, evidence:)
  run_attempt = evidence["run_attempt"]
  run_attempt.is_a?(Integer) && run_attempt.positive? && run_attempt == run["attempt"]
end

def shakaperf_release_gate_evidence_candidate_rejection(ref:, target_version:, run:, evidence:)
  return "evidence branch does not match the release branch" unless evidence["branch"] == ref
  return "evidence target version does not match the release" unless evidence["target_version"] == target_version

  candidate_sha = evidence["candidate_sha"]
  return "evidence candidate SHA does not match the workflow run" unless candidate_sha == run["headSha"]

  fingerprint = evidence["runtime_tree_fingerprint"]
  return "evidence runtime fingerprint is malformed" unless fingerprint.to_s.match?(/\A[0-9a-f]{64}\z/)

  nil
end

def shakaperf_release_gate_evidence_time_rejection(run:, evidence:, release_started_at:, validation_time:,
                                                   require_prerun:,
                                                   allow_prerun_completion_after_release_start: false)
  times, rejection = shakaperf_release_gate_evidence_times(run:, evidence:)
  return rejection if rejection

  completed_at, updated_at = times
  return "evidence completion time is after the workflow update" if completed_at > updated_at
  return "evidence completion time is in the future" if completed_at > validation_time
  if validation_time - completed_at > SHAKAPERF_RELEASE_GATE_EVIDENCE_MAX_AGE_SECONDS
    return ShakaperfEvidenceRejection.new(kind: :stale, message: "evidence is stale")
  end
  return nil unless require_prerun

  shakaperf_prerun_release_order_rejection(
    run:, completed_at:, updated_at:, release_started_at:, allow_completion_after_release_start:
      allow_prerun_completion_after_release_start
  )
end

def shakaperf_prerun_release_order_rejection(run:, completed_at:, updated_at:, release_started_at:,
                                             allow_completion_after_release_start:)
  release_start_second = Time.at(release_started_at.to_i).utc
  unless allow_completion_after_release_start
    return "evidence was not complete before the release run started" if
      completed_at >= release_start_second || updated_at >= release_start_second

    return nil
  end

  started_at = shakaperf_release_gate_time(run["startedAt"])
  return "workflow start time is invalid" unless started_at
  return "pre-run did not start before the release run" if started_at >= release_start_second

  nil
end

def shakaperf_release_gate_evidence_times(run:, evidence:)
  completed_at = shakaperf_release_gate_time(evidence["completed_at"])
  return [nil, "evidence completion time is invalid"] unless completed_at

  updated_at = shakaperf_release_gate_time(run["updatedAt"])
  return [nil, "workflow completion time is invalid"] unless updated_at

  [[completed_at, updated_at], nil]
end

def shakaperf_runtime_fingerprint_rejection(verdict:, fingerprint:, unknown_message:, mismatch_kind:,
                                            mismatch_message:)
  unless verdict.verified?
    return ShakaperfEvidenceRejection.new(
      kind: :git_unknown,
      message: "#{unknown_message} (#{verdict.details})"
    )
  end
  return nil if verdict.value == fingerprint

  ShakaperfEvidenceRejection.new(kind: mismatch_kind, message: mismatch_message)
end

def shakaperf_intervening_commits_rejection(monorepo_root:, commits:)
  commits.each do |sha|
    verdict = shakaperf_prerun_metadata_commit_verdict(monorepo_root:, sha:)
    unless verdict.verified?
      return ShakaperfEvidenceRejection.new(
        kind: :git_unknown,
        message: "intervening commit classification cannot be verified for #{sha} (#{verdict.details})"
      )
    end
    next if verdict.value == :metadata_only

    return ShakaperfEvidenceRejection.new(
      kind: :runtime_bearing_commits,
      message: "release commits after the tested candidate are not metadata-only"
    )
  end

  nil
end

def shakaperf_candidate_commits_rejection(monorepo_root:, candidate_sha:, head_sha:)
  verdict = shakaperf_candidate_commit_shas(monorepo_root:, candidate_sha:, head_sha:)
  if verdict.status == :not_ancestor
    return ShakaperfEvidenceRejection.new(
      kind: :not_ancestor,
      message: "tested candidate is not an ancestor of the release head"
    )
  end
  unless verdict.verified?
    return ShakaperfEvidenceRejection.new(
      kind: :git_unknown,
      message: "tested candidate ancestry or intervening commits cannot be verified"
    )
  end

  shakaperf_intervening_commits_rejection(monorepo_root:, commits: verdict.value)
end

def shakaperf_release_gate_evidence_runtime_rejection(monorepo_root:, head_sha:, evidence:)
  candidate_sha = evidence["candidate_sha"]
  fingerprint = evidence["runtime_tree_fingerprint"]
  candidate_verdict = shakaperf_runtime_tree_fingerprint_verdict(monorepo_root:, sha: candidate_sha)
  rejection = shakaperf_runtime_fingerprint_rejection(
    verdict: candidate_verdict,
    fingerprint:,
    unknown_message: "candidate runtime tree cannot be verified",
    mismatch_kind: :candidate_runtime_mismatch,
    mismatch_message: "candidate runtime tree does not match the recorded evidence"
  )
  return rejection if rejection

  head_verdict = shakaperf_runtime_tree_fingerprint_verdict(monorepo_root:, sha: head_sha)
  rejection = shakaperf_runtime_fingerprint_rejection(
    verdict: head_verdict,
    fingerprint:,
    unknown_message: "release-head runtime tree cannot be verified",
    mismatch_kind: :runtime_diverged,
    mismatch_message: "release runtime tree differs from the tested candidate"
  )
  return rejection if rejection
  return nil if candidate_sha == head_sha

  shakaperf_candidate_commits_rejection(monorepo_root:, candidate_sha:, head_sha:)
end

def shakaperf_release_gate_time(value)
  return value if value.is_a?(Time)
  return nil unless value.is_a?(String) && !value.empty?

  Time.iso8601(value)
rescue ArgumentError
  nil
end

def shakaperf_candidate_ancestry_verdict(monorepo_root:, candidate_sha:, head_sha:)
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "merge-base", "--is-ancestor", candidate_sha, head_sha
  )
  return ShakaperfVerificationResult.verified(true) if status.success?
  return ShakaperfVerificationResult.not_ancestor if status.exitstatus == 1

  ShakaperfVerificationResult.unknown("git merge-base exited #{status.exitstatus}: #{output.to_s.strip}")
rescue StandardError => e
  ShakaperfVerificationResult.unknown("git merge-base raised #{e.class}: #{e.message}")
end

def shakaperf_candidate_rev_list_verdict(monorepo_root:, candidate_sha:, head_sha:)
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "rev-list", "--reverse", "#{candidate_sha}..#{head_sha}"
  )
  unless status.success?
    return ShakaperfVerificationResult.unknown(
      "git rev-list exited #{status.exitstatus}: #{output.to_s.strip}"
    )
  end

  commits = output.lines.map(&:strip).reject(&:empty?)
  unless commits.any? && commits.all? { |sha| sha.match?(/\A[0-9a-f]{40}\z/) }
    return ShakaperfVerificationResult.unknown("git rev-list returned malformed or empty commit data")
  end

  ShakaperfVerificationResult.verified(commits)
rescue StandardError => e
  ShakaperfVerificationResult.unknown("git rev-list raised #{e.class}: #{e.message}")
end

def shakaperf_candidate_commit_shas(monorepo_root:, candidate_sha:, head_sha:)
  ancestry = shakaperf_candidate_ancestry_verdict(monorepo_root:, candidate_sha:, head_sha:)
  return ancestry unless ancestry.verified?

  shakaperf_candidate_rev_list_verdict(monorepo_root:, candidate_sha:, head_sha:)
end

def shakaperf_detector_flag_verdict(output_file)
  flag = File.read(output_file).lines.reverse.find { |line| line.start_with?("non_runtime_only=") }
  return ShakaperfVerificationResult.unknown("ci-changes-detector omitted non_runtime_only") if flag.nil?

  value = flag.split("=", 2).last.strip
  unless %w[true false].include?(value)
    return ShakaperfVerificationResult.unknown("ci-changes-detector returned an invalid non_runtime_only value")
  end

  ShakaperfVerificationResult.verified(value == "true")
end

def shakaperf_run_detector_verdict(detector:, output_file:, monorepo_root:, sha:)
  output, status = Open3.capture2e(
    { "GITHUB_OUTPUT" => output_file }, detector, "#{sha}^", sha, chdir: monorepo_root
  )
  unless status.success?
    return ShakaperfVerificationResult.unknown(
      "ci-changes-detector exited #{status.exitstatus}: #{output.to_s.strip}"
    )
  end

  shakaperf_detector_flag_verdict(output_file)
rescue StandardError => e
  ShakaperfVerificationResult.unknown("ci-changes-detector raised #{e.class}: #{e.message}")
end

def shakaperf_commit_non_runtime_only_verdict(monorepo_root:, sha:)
  detector = File.join(monorepo_root, "script", "ci-changes-detector")
  return ShakaperfVerificationResult.unknown("ci-changes-detector is not executable") unless File.executable?(detector)

  Dir.mktmpdir("ror-ci-detector") do |dir|
    output_file = File.join(dir, "github_output")
    File.write(output_file, "")
    shakaperf_run_detector_verdict(detector:, output_file:, monorepo_root:, sha:)
  end
rescue StandardError => e
  ShakaperfVerificationResult.unknown("ci-changes-detector setup raised #{e.class}: #{e.message}")
end

def shakaperf_git_file_at_commit_verdict(monorepo_root:, ref:, path:)
  output, status = Open3.capture2e("git", "-C", monorepo_root, "show", "#{ref}:#{path}")
  unless status.success?
    return ShakaperfVerificationResult.unknown(
      "git show exited #{status.exitstatus} for #{path}: #{output.to_s.strip}"
    )
  end

  ShakaperfVerificationResult.verified(output)
rescue StandardError => e
  ShakaperfVerificationResult.unknown("git show raised #{e.class} for #{path}: #{e.message}")
end

def shakaperf_name_status_change(line)
  fields = line.split("\t", -1)
  status_code = fields.shift
  path_count = status_code&.match?(/\A[CR]\d{1,3}\z/) ? 2 : 1
  return nil unless status_code&.match?(SHAKAPERF_GIT_NAME_STATUS_PATTERN)
  return nil unless fields.length == path_count && fields.none?(&:empty?)

  { status: status_code, paths: fields }
end

def shakaperf_commit_name_status_verdict(monorepo_root:, sha:)
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "diff-tree", "--no-commit-id", "--name-status", "-r", "#{sha}^", sha
  )
  unless status.success?
    return ShakaperfVerificationResult.unknown(
      "git diff-tree exited #{status.exitstatus}: #{output.to_s.strip}"
    )
  end

  changes = output.lines.map { |line| shakaperf_name_status_change(line.chomp) }
  return ShakaperfVerificationResult.unknown("git diff-tree returned malformed name-status data") if
    changes.any?(&:nil?)

  ShakaperfVerificationResult.verified(changes)
rescue StandardError => e
  ShakaperfVerificationResult.unknown("git diff-tree raised #{e.class}: #{e.message}")
end

def shakaperf_release_metadata_path_verdict(monorepo_root:, sha:, path:)
  before = shakaperf_git_file_at_commit_verdict(monorepo_root:, ref: "#{sha}^", path:)
  return before unless before.verified?

  after = shakaperf_git_file_at_commit_verdict(monorepo_root:, ref: sha, path:)
  return after unless after.verified?

  metadata_only = release_finalization_metadata_contents_only?(before: before.value, after: after.value, path:)
  ShakaperfVerificationResult.verified(metadata_only)
end

def shakaperf_release_metadata_paths_verdict(monorepo_root:, sha:, paths:)
  paths.each do |path|
    verdict = shakaperf_release_metadata_path_verdict(monorepo_root:, sha:, path:)
    return verdict unless verdict.verified? && verdict.value
  end

  ShakaperfVerificationResult.verified(true)
end

def shakaperf_release_finalization_metadata_commit_verdict(monorepo_root:, sha:)
  changes = shakaperf_commit_name_status_verdict(monorepo_root:, sha:)
  return changes unless changes.verified?
  return ShakaperfVerificationResult.verified(false) if changes.value.empty?

  paths = changes.value.filter_map do |change|
    path = change[:paths].first
    path if change[:status] == "M" && RELEASE_FINALIZATION_METADATA_PATHS.include?(path)
  end
  return ShakaperfVerificationResult.verified(false) unless paths.length == changes.value.length

  shakaperf_release_metadata_paths_verdict(monorepo_root:, sha:, paths:)
rescue StandardError => e
  ShakaperfVerificationResult.unknown("release metadata inspection raised #{e.class}: #{e.message}")
end

def shakaperf_prerun_metadata_commit_verdict(monorepo_root:, sha:)
  finalization_verdict = shakaperf_release_finalization_metadata_commit_verdict(monorepo_root:, sha:)
  return finalization_verdict unless finalization_verdict.verified?
  return ShakaperfVerificationResult.verified(:metadata_only) if finalization_verdict.value

  detector_verdict = shakaperf_commit_non_runtime_only_verdict(monorepo_root:, sha:)
  return detector_verdict unless detector_verdict.verified?
  return ShakaperfVerificationResult.verified(:runtime_bearing) unless detector_verdict.value

  changelog_verdict = shakaperf_changelog_only_commit_verdict(monorepo_root:, sha:)
  return changelog_verdict unless changelog_verdict.verified?

  classification = changelog_verdict.value ? :metadata_only : :runtime_bearing
  ShakaperfVerificationResult.verified(classification)
end

def shakaperf_changelog_only_commit_verdict(monorepo_root:, sha:)
  changes_verdict = shakaperf_commit_name_status_verdict(monorepo_root:, sha:)
  return changes_verdict unless changes_verdict.verified?

  changes = changes_verdict.value
  changelog_only = changes.any? && changes.all?({ status: "M", paths: ["CHANGELOG.md"] })
  ShakaperfVerificationResult.verified(changelog_only)
end

def handle_shakaperf_release_gate_violation!(message:)
  abort <<~ERROR
    #{message}

    The version-bump commit may already be pushed to the remote without a tag or published packages.
    Preserve the failure evidence; do not rerun or revert this partial release.
    Follow the partial-publication recovery procedure in the release-train runbook.

    Preview an explicitly approved prerelease override only (when ShakaPerf is known-unrelated):
      RELEASE_CI_STATUS_OVERRIDE=true bundle exec rake "release[VERSION,true]"
      # or pass override_ci_status as the 4th positional argument:
      bundle exec rake "release[VERSION,true,false,true]"
    #{release_version_placeholder_guidance}

    #{release_compound_live_boundary_guidance}
  ERROR
end

def fetch_shakaperf_release_tracker_comments!(repo_slug:, tracker:)
  comments = []
  state = { seen_ids: {}, last_created_at: nil }
  1.upto(ACCELERATED_RC_REPOSITORY_COMMENT_MAX_PAGES) do |page|
    page_comments = fetch_accelerated_rc_comment_page!(repo_slug:, tracker:, page:, state:)
    comments.concat(page_comments.select { |comment| shakaperf_release_tracker_machine_marker_comment?(comment) })
    if comments.length > ACCELERATED_RC_REPOSITORY_MARKER_COMMENT_LIMIT
      abort "❌ Bounded release tracker ShakaPerf-marker limit was exceeded; durable evidence is unknown."
    end

    return comments if page_comments.length < ACCELERATED_RC_REPOSITORY_COMMENT_PAGE_SIZE
  end

  abort "❌ Bounded release tracker issue-comment page limit was reached; durable ShakaPerf evidence is unknown."
end

def shakaperf_release_tracker_machine_marker_comment?(comment)
  return false unless comment.is_a?(Hash) && comment["body"].is_a?(String)

  body = comment.fetch("body")
  body.include?(SHAKAPERF_RELEASE_TRACKER_EVIDENCE_MARKER) ||
    body.include?(SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_MARKER_OPENER) ||
    body.include?(SHAKAPERF_FINAL_OBSERVATION_WAIVER_MARKER_OPENER)
end

def shakaperf_release_tracker_v1_record_from_comment!(comment)
  body = comment.fetch("body")
  marker_count = body.scan(SHAKAPERF_RELEASE_TRACKER_EVIDENCE_MARKER).length
  matches = body.scan(/#{Regexp.escape(SHAKAPERF_RELEASE_TRACKER_EVIDENCE_MARKER)}(.*?)\n-->/mo)
  abort "❌ Release tracker contains malformed ShakaPerf evidence." unless marker_count == 1 && matches.one?

  seen_fields = {}
  fields = matches.first.first.lines.to_h do |line|
    key, value = line.chomp.split(": ", 2)
    abort "❌ Release tracker contains malformed ShakaPerf evidence." unless key && value
    abort "❌ Release tracker contains duplicate ShakaPerf evidence fields." if seen_fields.key?(key)

    seen_fields[key] = true
    [key, value]
  end
  unless fields.keys == SHAKAPERF_RELEASE_TRACKER_EVIDENCE_FIELDS
    abort "❌ Release tracker contains incomplete or unknown ShakaPerf evidence fields."
  end
  fields
end

def validate_approver_bound_shakaperf_tracker_entry!(entry:, tracker:, login:)
  return unless SHAKAPERF_APPROVER_BOUND_ENTRY_KINDS.include?(entry[:kind])

  if entry.dig(:record, "release_tracker") != tracker
    abort "❌ ShakaPerf record's embedded release tracker does not match its containing issue."
  end
  return if entry.dig(:record, "approved_by") == login

  abort "❌ ShakaPerf tracker record approver does not match its trusted comment author."
end

def trusted_shakaperf_release_tracker_records!(repo_slug:, tracker:)
  permissions = {}
  fetch_shakaperf_release_tracker_comments!(repo_slug:, tracker:).filter_map do |comment|
    login = accelerated_rc_comment_author_login!(comment)
    permission = accelerated_rc_repository_comment_permission!(repo_slug:, login:, permissions:)
    permission_class = accelerated_rc_repository_permission_class!(permission:, login:)
    next if permission_class == :non_maintainer

    created_at, updated_at = accelerated_rc_comment_timestamps!(comment)
    if created_at != updated_at
      abort "❌ Edited ShakaPerf evidence comment detected; durable evidence must remain append-only."
    end

    issue_tracker = release_tracker_number_from_repository_comment_issue_url!(
      issue_url: comment.fetch("issue_url", nil), repo_slug:
    )
    abort "❌ ShakaPerf evidence is bound to a different release tracker." unless issue_tracker == tracker

    entry = shakaperf_release_tracker_entry_from_comment!(comment)
    validate_approver_bound_shakaperf_tracker_entry!(entry:, tracker:, login:)

    entry.merge(author: login, comment:)
  end
end

def shakaperf_release_tracker_entry_from_comment!(comment)
  body = comment.fetch("body")
  marker_family_count = [
    SHAKAPERF_FINAL_OBSERVATION_WAIVER_MARKER_OPENER,
    SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_MARKER_OPENER,
    SHAKAPERF_RELEASE_TRACKER_EVIDENCE_MARKER
  ].count { |marker| body.include?(marker) }
  abort "❌ Release tracker comment contains more than one ShakaPerf marker family." if marker_family_count > 1

  if body.include?(SHAKAPERF_FINAL_OBSERVATION_WAIVER_MARKER_OPENER)
    record = final_shakaperf_observation_waiver_record_from_comment!(comment)
    current_schema = record.fetch("schema_version") == SHAKAPERF_FINAL_OBSERVATION_WAIVER_SCHEMA_VERSION
    kind = current_schema ? :waiver : :legacy_waiver
    { kind:, record: }
  elsif body.include?(SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_MARKER_OPENER)
    { kind: :association, record: verified_shakaperf_release_tracker_record_from_comment!(comment) }
  else
    { kind: :legacy, record: shakaperf_release_tracker_v1_record_from_comment!(comment) }
  end
end

def final_shakaperf_observation_waiver_record_from_comment!(comment)
  body = comment.fetch("body")
  marker_count = body.scan(SHAKAPERF_FINAL_OBSERVATION_WAIVER_MARKER_OPENER).length
  opener = Regexp.escape(SHAKAPERF_FINAL_OBSERVATION_WAIVER_MARKER_OPENER)
  matches = body.scan(/#{opener}v(\d+) ([0-9a-fA-F]+) -->/)
  unless marker_count == 1 && matches.one?
    abort "❌ Release tracker contains a malformed final ShakaPerf observation waiver."
  end

  schema_version, encoded_payload = matches.first
  unless %w[1 2].include?(schema_version) && encoded_payload.length.even?
    abort "❌ Release tracker contains an unsupported final ShakaPerf observation waiver."
  end

  record = JSON.parse([encoded_payload].pack("H*"))
  if schema_version == SHAKAPERF_FINAL_OBSERVATION_WAIVER_SCHEMA_VERSION.to_s
    validate_final_shakaperf_observation_waiver_record!(record)
  else
    validate_legacy_final_shakaperf_observation_waiver_record!(record)
  end
  canonical_encoded = canonical_accelerated_rc_json(record).unpack1("H*")
  unless encoded_payload == canonical_encoded
    abort "❌ Release tracker contains a non-canonical final ShakaPerf observation waiver."
  end

  record
rescue ArgumentError, JSON::ParserError
  abort "❌ Release tracker contains a malformed final ShakaPerf observation waiver."
end

def verified_shakaperf_release_tracker_record_from_comment!(comment)
  body = comment.fetch("body")
  marker_count = body.scan(SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_MARKER_OPENER).length
  opener = Regexp.escape(SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_MARKER_OPENER)
  matches = body.scan(/#{opener}v(\d+) ([0-9a-fA-F]+) -->/)
  unless marker_count == 1 && matches.one?
    abort "❌ Release tracker contains a malformed verified ShakaPerf association."
  end

  schema_version, encoded_payload = matches.first
  unless schema_version == SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_SCHEMA_VERSION.to_s && encoded_payload.length.even?
    abort "❌ Release tracker contains an unsupported verified ShakaPerf association."
  end

  record = JSON.parse([encoded_payload].pack("H*"))
  validate_verified_shakaperf_release_tracker_record!(record)
  canonical_encoded = canonical_accelerated_rc_json(record).unpack1("H*")
  unless encoded_payload == canonical_encoded
    abort "❌ Release tracker contains a non-canonical verified ShakaPerf association."
  end

  record
rescue ArgumentError, JSON::ParserError
  abort "❌ Release tracker contains a malformed verified ShakaPerf association."
end

def shakaperf_release_tracker_entry_candidate_sha(entry)
  field = entry[:kind] == :association ? "candidate_sha" : "head_sha"
  entry.dig(:record, field)
end

def shakaperf_release_tracker_entry_matches?(entry:, repo_slug:, ref:, head_sha:, target_version:, run_id:)
  record = entry.fetch(:record)
  version_field = entry[:kind] == :association ? "target_version" : "release"
  identity_matches = record.values_at("repository", version_field, "branch") == [repo_slug, target_version, ref]
  selected_run_matches = run_id.nil? || record["run_id"].to_i == run_id
  candidate_matches = entry[:kind] == :association || record["head_sha"] == head_sha
  identity_matches && selected_run_matches && candidate_matches
end

def preferred_shakaperf_release_tracker_candidates(matches, head_sha:)
  exact_matches = matches.select { |entry| shakaperf_release_tracker_entry_candidate_sha(entry) == head_sha }
  exact_associations = exact_matches.select { |entry| entry[:kind] == :association }
  return exact_associations if exact_associations.any?
  return exact_matches if exact_matches.any?

  matches.select { |entry| entry[:kind] == :association }
end

def shakaperf_release_tracker_candidate_run_ids(candidates)
  candidates.map { |entry| entry.dig(:record, "run_id").to_i }.uniq
end

def latest_shakaperf_release_tracker_candidates(candidates)
  latest_recorded_at = candidates.map { |entry| entry.dig(:record, "recorded_at") }.max
  candidates.select { |entry| entry.dig(:record, "recorded_at") == latest_recorded_at }
end

def reject_conflicting_same_run_shakaperf_associations!(candidates)
  association_identities_by_run_id = {}
  candidates.each do |entry|
    next unless entry[:kind] == :association

    record = entry.fetch(:record)
    run_id = record.fetch("run_id").to_i
    identity = SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_IDENTITY_FIELDS.map { |field| record[field] }
    existing_identity = association_identities_by_run_id[run_id]
    if existing_identity && existing_identity != identity
      abort "❌ Release tracker contains conflicting ShakaPerf associations for the same run."
    end

    association_identities_by_run_id[run_id] = identity
  end
end

def resolve_shakaperf_release_tracker_candidate_conflict!(candidates)
  reject_conflicting_same_run_shakaperf_associations!(candidates)

  run_ids = shakaperf_release_tracker_candidate_run_ids(candidates)
  return candidates unless run_ids.length > 1

  unless candidates.all? { |entry| entry[:kind] == :association }
    abort "❌ Release tracker contains conflicting ShakaPerf evidence for this candidate; select one exact run."
  end

  latest = latest_shakaperf_release_tracker_candidates(candidates)
  unless shakaperf_release_tracker_candidate_run_ids(latest).one?
    abort "❌ Release tracker contains conflicting latest ShakaPerf associations; select one exact run."
  end

  latest
end

def selected_shakaperf_release_tracker_record!(repo_slug:, tracker:, ref:, head_sha:, target_version:, run_id: nil)
  entries = trusted_shakaperf_release_tracker_records!(repo_slug:, tracker:)
  reject_conflicting_same_run_shakaperf_associations!(entries)
  matches = entries.select do |entry|
    shakaperf_release_tracker_entry_matches?(entry:, repo_slug:, ref:, head_sha:, target_version:, run_id:)
  end
  return nil if matches.empty?

  candidates = preferred_shakaperf_release_tracker_candidates(matches, head_sha:)
  candidates = resolve_shakaperf_release_tracker_candidate_conflict!(candidates)
  candidates.find { |entry| entry[:kind] == :association } || candidates.first
end

def fetch_selected_shakaperf_release_gate_run!(repo_slug:, run_id:)
  output, status = capture_gh_output("api", "repos/#{repo_slug}/actions/runs/#{run_id}")
  unless status.success?
    error_class = if output.match?(%r{\bHTTP(?:/\d(?:\.\d)?)?\s+404\b|\b404\s+Not Found\b}i)
                    ShakaperfGateMissingRunError
                  else
                    ShakaperfGateObservationError
                  end
    raise error_class, "Unable to inspect selected ShakaPerf release gate run #{run_id}.\n\n#{output}"
  end

  JSON.parse(output)
rescue JSON::ParserError => e
  raise ShakaperfGateObservationError,
        "Selected ShakaPerf release gate run returned invalid JSON: #{e.message}"
end

def canonical_shakaperf_release_gate_run_id(value:, repo_slug:)
  uri = URI.parse(value)
  expected_path = %r{\A/#{Regexp.escape(repo_slug)}/actions/runs/([1-9]\d*)\z}
  run_id = uri.path.match(expected_path)&.captures&.first
  expected_url = "https://github.com/#{repo_slug}/actions/runs/#{run_id}"
  canonical = [
    uri.is_a?(URI::HTTPS), uri.host == "github.com", uri.userinfo.nil?, uri.query.nil?, uri.fragment.nil?, run_id,
    value == expected_url
  ].all?
  run_id.to_i if canonical
rescue URI::InvalidURIError
  nil
end

def selected_shakaperf_release_gate_run_id!(selector:, repo_slug:)
  value = selector.to_s.strip
  return value.to_i if value.match?(/\A[1-9]\d*\z/)

  run_id = canonical_shakaperf_release_gate_run_id(value:, repo_slug:)
  return run_id if run_id

  abort "❌ RELEASE_SHAKAPERF_RUN must be a positive run ID or canonical run URL for #{repo_slug}."
end

def normalized_optional_release_value(value)
  return nil if value.nil? || value.strip.empty?

  value
end

def validated_shakaperf_release_tracker!(monorepo_root:, tracker_input:, required:, target_version:)
  if tracker_input.to_s.empty?
    if required
      abort "❌ RELEASE_SHAKAPERF_RUN or RELEASE_FINAL_SHAKAPERF_WAIVER_REASON requires " \
            "RELEASE_TRACKER=<issue>."
    end

    return nil
  end
  unless tracker_input.to_s.match?(/\A[1-9]\d*\z/)
    abort "❌ RELEASE_TRACKER must be a positive issue number when used for ShakaPerf evidence."
  end

  tracker = tracker_input.to_i
  fetch_release_tracker_issue!(repo_slug: github_repo_slug(monorepo_root), tracker:, target_version:)
  tracker
end

def normalized_selected_shakaperf_release_gate_run(run)
  return run if run.key?("databaseId")

  {
    "databaseId" => run["id"],
    "attempt" => run["run_attempt"],
    "displayTitle" => run["display_title"],
    "headSha" => run["head_sha"],
    "headBranch" => run["head_branch"],
    "workflowPath" => run["path"],
    "event" => run["event"],
    "status" => run["status"],
    "conclusion" => run["conclusion"],
    "createdAt" => run["created_at"],
    "startedAt" => run["run_started_at"],
    "updatedAt" => run["updated_at"],
    "url" => run["html_url"],
    "repository" => run.dig("repository", "full_name")
  }
end

def selected_shakaperf_release_gate_run_identity_rejection(run:, repo_slug:, ref:)
  expected_workflow_path = ".github/workflows/#{SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE}"
  return "repository does not match" unless run["repository"] == repo_slug
  unless run["workflowPath"].to_s.split("@", 2).first == expected_workflow_path
    return "workflowPath does not match the canonical ShakaPerf workflow"
  end
  return "event is not workflow_dispatch" unless run["event"] == "workflow_dispatch"
  return "headBranch does not match the release branch" unless run["headBranch"] == ref

  nil
end

def shakaperf_release_tracker_identity_rejection(record:, run:, repo_slug:, ref:, head_sha:, target_version:)
  return "repository does not match" unless record["repository"] == repo_slug && run["repository"] == repo_slug
  return "release does not match" unless record["release"] == target_version
  return "branch does not match" unless record["branch"] == ref && run["headBranch"] == ref
  return "candidate SHA does not match" unless record["head_sha"] == head_sha && run["headSha"] == head_sha

  nil
end

def shakaperf_release_tracker_workflow_rejection(record:, run:)
  expected_workflow = ".github/workflows/#{SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE}"
  return "workflow does not match" unless record["workflow"] == SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE &&
                                          run["workflowPath"].to_s.split("@", 2).first == expected_workflow
  return "workflow event does not match" unless record["event"] == "workflow_dispatch" &&
                                                run["event"] == "workflow_dispatch"

  shakaperf_release_tracker_run_reference_rejection(record:, run:)
end

def shakaperf_release_tracker_run_reference_rejection(record:, run:)
  return "workflow run ID does not match" unless record["run_id"].match?(/\A[1-9]\d*\z/) &&
                                                 record["run_id"].to_i == run["databaseId"]
  return "workflow run attempt does not match" unless record["run_attempt"].match?(/\A[1-9]\d*\z/) &&
                                                      record["run_attempt"].to_i == run["attempt"]

  nil
end

def shakaperf_release_tracker_result_rejection(record:, run:)
  return "workflow run did not complete successfully" unless record.values_at("status", "conclusion") ==
                                                             %w[completed success] &&
                                                             run.values_at("status", "conclusion") ==
                                                             %w[completed success]
  return "workflow run URL does not match" unless record["run_url"] == run["url"]
  return "workflow start time does not match" unless record["started_at"] == run["startedAt"]
  return "workflow completion time does not match" unless record["completed_at"] == run["updatedAt"]
  unless %w[report_digest server_logs_digest].all? { |field| record[field].match?(/\Asha256:[0-9a-f]{64}\z/) }
    return "artifact digest is malformed"
  end

  nil
end

def shakaperf_release_tracker_freshness_rejection(record:, validation_time:)
  completed_at = shakaperf_release_gate_time(record["completed_at"])
  return "workflow completion time is invalid" unless completed_at
  return "evidence completion time is in the future" if completed_at > validation_time
  return "evidence is stale" if validation_time - completed_at > SHAKAPERF_RELEASE_GATE_EVIDENCE_MAX_AGE_SECONDS

  nil
end

def shakaperf_release_tracker_record_rejection(record:, run:, repo_slug:, ref:, head_sha:, target_version:,
                                               validation_time:)
  rejection = shakaperf_release_tracker_identity_rejection(
    record:, run:, repo_slug:, ref:, head_sha:, target_version:
  )
  return rejection if rejection

  rejection = shakaperf_release_tracker_workflow_rejection(record:, run:)
  return rejection if rejection

  rejection = shakaperf_release_tracker_result_rejection(record:, run:)
  return rejection if rejection

  shakaperf_release_tracker_freshness_rejection(record:, validation_time:)
end

def naturally_invalidated_shakaperf_association_rejection?(rejection)
  rejection.is_a?(ShakaperfEvidenceRejection) && rejection.natural_invalidation?
end

def continue_after_naturally_invalidated_shakaperf_association(rejection:, run_url:)
  puts "Saved ShakaPerf association is no longer reusable (#{rejection}); " \
       "continuing with normal discovery: #{run_url}"
  nil
end

def automatic_shakaperf_association_reuse?(entry:, run_id:)
  entry[:kind] == :association && run_id.nil?
end

def reusable_saved_shakaperf_evidence?(entry:, run_id:, rejection:, run_url:)
  return true unless rejection

  if automatic_shakaperf_association_reuse?(entry:, run_id:) &&
     naturally_invalidated_shakaperf_association_rejection?(rejection)
    continue_after_naturally_invalidated_shakaperf_association(rejection:, run_url:)
    return false
  end

  abort "❌ Saved ShakaPerf release tracker evidence is invalid: #{rejection}."
end

def saved_shakaperf_observation_error_run(record:, entry:, ref:, target_version:)
  candidate_sha = entry[:kind] == :association ? record.fetch("candidate_sha") : record.fetch("head_sha")
  {
    "databaseId" => record.fetch("run_id").to_i,
    "attempt" => record.fetch("run_attempt").to_i,
    "displayTitle" => shakaperf_release_gate_display_title(ref:, head_sha: candidate_sha, target_version:),
    "headSha" => candidate_sha,
    "headBranch" => ref,
    "workflowPath" => ".github/workflows/#{SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE}",
    "event" => "workflow_dispatch",
    "repository" => record.fetch("repository"),
    "status" => "unknown",
    "conclusion" => nil,
    "url" => record.fetch("run_url")
  }
end

def fetch_saved_shakaperf_release_gate_run(repo_slug:, record:, entry:, ref:, target_version:, run_id:)
  normalized_selected_shakaperf_release_gate_run(
    fetch_selected_shakaperf_release_gate_run!(repo_slug:, run_id: record.fetch("run_id").to_i)
  )
rescue ShakaperfGateMissingRunError
  reusable_saved_shakaperf_evidence?(
    entry:,
    run_id:,
    rejection: ShakaperfEvidenceRejection.new(
      kind: :missing_run,
      message: "saved workflow run is authoritatively missing"
    ),
    run_url: record.fetch("run_url")
  )
  nil
rescue ShakaperfGateObservationError => e
  tracked_run = saved_shakaperf_observation_error_run(record:, entry:, ref:, target_version:)
  raise ShakaperfGateObservationError.new(e.message, run: tracked_run, tracker_entry: entry)
end

def saved_shakaperf_release_tracker_rejection(entry:, record:, run:, repo_slug:, monorepo_root:, ref:,
                                              head_sha:, target_version:, release_started_at:)
  if entry[:kind] == :association
    verified_shakaperf_release_tracker_association_rejection(
      record:, run:, repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, release_started_at:
    )
  else
    shakaperf_release_tracker_record_rejection(
      record:, run:, repo_slug:, ref:, head_sha:, target_version:, validation_time: release_started_at
    )
  end
rescue ShakaperfGateMissingArtifactError
  ShakaperfEvidenceRejection.new(
    kind: :missing_artifact,
    message: "saved evidence artifact is authoritatively missing"
  )
rescue ShakaperfGateObservationError => e
  abort "❌ Saved ShakaPerf release tracker evidence could not be re-observed; refusing dispatch.\n\n#{e.message}"
end

def shakaperf_association_backed_run(run:, entry:, record:)
  return run unless entry[:kind] == :association

  ShakaperfAssociationBackedRun.from_verified_association(run:, association: record)
end

def reuse_shakaperf_release_tracker_evidence(repo_slug:, monorepo_root:, tracker:, ref:, head_sha:, target_version:,
                                             release_started_at:, run_id: nil, expected_association_identity: nil)
  entry = selected_shakaperf_release_tracker_record!(
    repo_slug:, tracker:, ref:, head_sha:, target_version:, run_id:
  )
  return nil unless entry

  record = entry.fetch(:record)
  if expected_association_identity
    current_identity = SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_IDENTITY_FIELDS.to_h do |field|
      [field, record[field]]
    end
    unless entry[:kind] == :association && current_identity == expected_association_identity
      abort "❌ Saved ShakaPerf release tracker association changed before publication."
    end
  end
  run = fetch_saved_shakaperf_release_gate_run(repo_slug:, record:, entry:, ref:, target_version:, run_id:)
  return nil unless run

  rejection = saved_shakaperf_release_tracker_rejection(
    entry:, record:, run:, repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, release_started_at:
  )
  return nil unless reusable_saved_shakaperf_evidence?(entry:, run_id:, rejection:, run_url: run.fetch("url"))

  run = shakaperf_association_backed_run(run:, entry:, record:)
  tracker_url = "https://github.com/#{repo_slug}/issues/#{tracker}"
  puts "✓ Reusing verified ShakaPerf release tracker evidence from #{tracker_url}: #{run.fetch('url')}"
  run
end

def verified_shakaperf_release_tracker_association_identity_rejection(record:, run:, repo_slug:, ref:, target_version:)
  return "repository does not match" unless record["repository"] == repo_slug
  return "release tracker association branch does not match" unless record["branch"] == ref
  unless record["candidate_sha"] == run["headSha"]
    return "release tracker association candidate SHA does not match the selected workflow run"
  end
  return "release tracker association target version does not match" unless record["target_version"] == target_version
  return "release tracker association run ID does not match" unless record["run_id"] == run["databaseId"]
  return "release tracker association run attempt does not match" unless record["run_attempt"] == run["attempt"]
  return "release tracker association run URL does not match" unless record["run_url"] == run["url"]

  nil
end

def verified_shakaperf_release_tracker_artifact_rejection(record:, evidence:)
  return "schema-v2 evidence artifact is missing or unreadable" unless evidence

  evidence_digest = Digest::SHA256.hexdigest(canonical_accelerated_rc_json(evidence))
  return "schema-v2 evidence digest changed" unless record["evidence_digest"] == evidence_digest
  return "runtime tree fingerprint changed" unless
    record["runtime_tree_fingerprint"] == evidence["runtime_tree_fingerprint"]

  nil
end

def verified_shakaperf_release_tracker_association_rejection(record:, run:, repo_slug:, monorepo_root:, ref:,
                                                             head_sha:, target_version:, release_started_at:)
  rejection = selected_shakaperf_release_gate_run_identity_rejection(run:, repo_slug:, ref:)
  return rejection if rejection

  rejection = verified_shakaperf_release_tracker_association_identity_rejection(
    record:, run:, repo_slug:, ref:, target_version:
  )
  return rejection if rejection

  if run["status"] == "completed" && %w[failure cancelled].include?(run["conclusion"])
    conclusion = run.fetch("conclusion")
    return ShakaperfEvidenceRejection.new(
      kind: conclusion == "failure" ? :workflow_failed : :workflow_cancelled,
      message: "workflow run completed with #{conclusion}"
    )
  end

  evidence = fetch_shakaperf_release_gate_evidence_for_association!(repo_slug:, run:)
  rejection = verified_shakaperf_release_tracker_artifact_rejection(record:, evidence:)
  return rejection if rejection

  shakaperf_release_gate_evidence_rejection(
    monorepo_root:,
    ref:,
    head_sha:,
    target_version:,
    run:,
    evidence:,
    release_started_at:,
    validation_time: Time.now.utc,
    require_prerun: false
  )
end

def shakaperf_release_tracker_records_for_kind(entries, kind:)
  entries.filter_map { |entry| entry[:record] if entry[:kind] == kind }
end

def matching_shakaperf_release_tracker_identity(records, record:, identity_fields:)
  records.find do |existing|
    identity_fields.all? { |field| existing[field] == record[field] }
  end
end

def matching_shakaperf_release_tracker_digest(records, record:)
  digest = Digest::SHA256.hexdigest(canonical_accelerated_rc_json(record))
  records.find do |existing|
    Digest::SHA256.hexdigest(canonical_accelerated_rc_json(existing)) == digest
  end
end

def persist_verified_shakaperf_release_tracker_evidence!(repo_slug:, tracker:, ref:, head_sha:, target_version:,
                                                         run:, evidence:)
  approved_by = current_release_approver!(repo_slug:)
  record = build_verified_shakaperf_release_tracker_record(
    repo_slug:, tracker:, ref:, head_sha:, target_version:, run:, evidence:, approved_by:, recorded_at: Time.now.utc
  )
  entries = trusted_shakaperf_release_tracker_records!(repo_slug:, tracker:)
  association_records = shakaperf_release_tracker_records_for_kind(entries, kind: :association)
  duplicate = matching_shakaperf_release_tracker_identity(
    association_records, record:, identity_fields: SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_IDENTITY_FIELDS
  )
  return duplicate if duplicate

  post_release_tracker_comment!(
    repo_slug:, tracker:, body: verified_shakaperf_release_tracker_comment(record)
  )
  refreshed = trusted_shakaperf_release_tracker_records!(repo_slug:, tracker:)
  refreshed_records = shakaperf_release_tracker_records_for_kind(refreshed, kind: :association)
  persisted = matching_shakaperf_release_tracker_digest(refreshed_records, record:)
  abort "❌ ShakaPerf tracker association could not be verified after posting; refusing to continue." unless persisted

  persisted
end

def build_verified_shakaperf_release_tracker_record(repo_slug:, tracker:, ref:, head_sha:, target_version:, run:,
                                                    evidence:, approved_by:, recorded_at:)
  normalized_run = normalized_selected_shakaperf_release_gate_run(run)
  record = {
    "schema_version" => SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_SCHEMA_VERSION,
    "repository" => repo_slug,
    "release_tracker" => tracker,
    "branch" => ref,
    "candidate_sha" => head_sha,
    "target_version" => target_version,
    "workflow" => SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
    "run_id" => normalized_run.fetch("databaseId"),
    "run_attempt" => normalized_run.fetch("attempt"),
    "run_url" => normalized_run.fetch("url"),
    "runtime_tree_fingerprint" => evidence.fetch("runtime_tree_fingerprint"),
    "evidence_digest" => Digest::SHA256.hexdigest(canonical_accelerated_rc_json(evidence)),
    "approved_by" => approved_by,
    "recorded_at" => recorded_at.utc.iso8601
  }
  validate_verified_shakaperf_release_tracker_record!(record)
end

def valid_verified_shakaperf_release_tracker_identity?(record)
  return false unless accelerated_rc_exact_keys?(record, SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_FIELDS)

  [
    record["schema_version"] == SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_SCHEMA_VERSION,
    valid_accelerated_rc_nonempty_string?(record["repository"]),
    valid_accelerated_rc_tracker_number?(record["release_tracker"]),
    valid_accelerated_rc_nonempty_string?(record["branch"]),
    record["candidate_sha"].to_s.match?(/\A[0-9a-f]{40}\z/),
    record["target_version"].to_s.match?(SHAKAPERF_RELEASE_GATE_CANONICAL_VERSION_PATTERN),
    record["workflow"] == SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE
  ].all?
end

def valid_verified_shakaperf_release_tracker_evidence?(record)
  [
    positive_github_id?(record["run_id"]),
    positive_github_id?(record["run_attempt"]),
    valid_accelerated_rc_https_url?(record["run_url"]),
    record["runtime_tree_fingerprint"].to_s.match?(/\A[0-9a-f]{64}\z/),
    record["evidence_digest"].to_s.match?(/\A[0-9a-f]{64}\z/)
  ].all?
end

def valid_verified_shakaperf_release_tracker_approval?(record)
  valid_accelerated_rc_nonempty_string?(record["approved_by"]) &&
    !shakaperf_release_gate_time(record["recorded_at"]).nil?
end

def validate_verified_shakaperf_release_tracker_record!(record)
  valid = valid_verified_shakaperf_release_tracker_identity?(record) &&
          valid_verified_shakaperf_release_tracker_evidence?(record) &&
          valid_verified_shakaperf_release_tracker_approval?(record)
  abort "❌ Release tracker contains a malformed verified ShakaPerf association." unless valid

  record
end

def verified_shakaperf_release_tracker_comment(record)
  encoded = canonical_accelerated_rc_json(record).unpack1("H*")
  marker = "#{SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_MARKER_OPENER}" \
           "v#{SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_SCHEMA_VERSION} #{encoded} -->"
  <<~MARKDOWN
    #{marker}
    ### Verified ShakaPerf release evidence

    - Release: `#{record.fetch('target_version')}` at `#{record.fetch('candidate_sha')}`
    - Run: #{record.fetch('run_url')} (attempt #{record.fetch('run_attempt')})
    - Maintainer: `#{record.fetch('approved_by')}` at `#{record.fetch('recorded_at')}`
  MARKDOWN
end

def validate_final_shakaperf_observation_waiver_reason!(reason)
  valid = reason.is_a?(String) && reason == reason.strip && reason.length.between?(1, 500) &&
          !reason.match?(/[\r\n[:cntrl:]]/) && !reason.include?("<!--") && !reason.include?("-->")
  unless valid
    abort "❌ RELEASE_FINAL_SHAKAPERF_WAIVER_REASON must be non-empty single-line plain text " \
          "(maximum 500 characters)."
  end

  reason
end

def valid_final_shakaperf_observation_waiver_identity?(record)
  return false unless accelerated_rc_exact_keys?(record, SHAKAPERF_FINAL_OBSERVATION_WAIVER_FIELDS)

  [
    record["schema_version"] == SHAKAPERF_FINAL_OBSERVATION_WAIVER_SCHEMA_VERSION,
    valid_accelerated_rc_nonempty_string?(record["repository"]),
    valid_accelerated_rc_tracker_number?(record["release_tracker"]),
    valid_accelerated_rc_nonempty_string?(record["branch"]),
    record["candidate_sha"].to_s.match?(/\A[0-9a-f]{40}\z/),
    record["target_version"].to_s.match?(SHAKAPERF_RELEASE_GATE_CANONICAL_VERSION_PATTERN),
    !release_prerelease_version?(record["target_version"]),
    record["workflow"] == SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE
  ].all?
end

def valid_final_shakaperf_observation_waiver_evidence?(record)
  [
    positive_github_id?(record["run_id"]),
    positive_github_id?(record["run_attempt"]),
    valid_accelerated_rc_https_url?(record["run_url"]),
    record["failure_kind"] == "gate_observation_failed",
    record["observation_digest"].to_s.match?(/\A[0-9a-f]{64}\z/),
    valid_accelerated_rc_nonempty_string?(record["approved_by"]),
    !shakaperf_release_gate_time(record["recorded_at"]).nil?
  ].all?
end

def valid_legacy_final_shakaperf_observation_waiver_identity?(record)
  return false unless accelerated_rc_exact_keys?(record, SHAKAPERF_FINAL_OBSERVATION_WAIVER_LEGACY_V1_FIELDS)

  [
    record["schema_version"] == 1,
    valid_accelerated_rc_nonempty_string?(record["repository"]),
    valid_accelerated_rc_tracker_number?(record["release_tracker"]),
    valid_accelerated_rc_nonempty_string?(record["branch"]),
    record["candidate_sha"].to_s.match?(/\A[0-9a-f]{40}\z/),
    record["target_version"].to_s.match?(SHAKAPERF_RELEASE_GATE_CANONICAL_VERSION_PATTERN),
    !release_prerelease_version?(record["target_version"]),
    record["workflow"] == SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE
  ].all?
end

def valid_legacy_final_shakaperf_observation_waiver_evidence?(record)
  [
    positive_github_id?(record["run_id"]),
    valid_accelerated_rc_https_url?(record["run_url"]),
    record["failure_kind"] == "gate_observation_failed",
    record["observation_digest"].to_s.match?(/\A[0-9a-f]{64}\z/),
    valid_accelerated_rc_nonempty_string?(record["approved_by"]),
    !shakaperf_release_gate_time(record["recorded_at"]).nil?
  ].all?
end

def validate_legacy_final_shakaperf_observation_waiver_record!(record)
  valid = valid_legacy_final_shakaperf_observation_waiver_identity?(record) &&
          valid_legacy_final_shakaperf_observation_waiver_evidence?(record)
  validate_final_shakaperf_observation_waiver_reason!(record["reason"]) if valid
  abort "❌ Release tracker contains a malformed final ShakaPerf observation waiver." unless valid

  record
end

def validate_final_shakaperf_observation_waiver_record!(record)
  valid = valid_final_shakaperf_observation_waiver_identity?(record) &&
          valid_final_shakaperf_observation_waiver_evidence?(record)
  validate_final_shakaperf_observation_waiver_reason!(record["reason"]) if valid
  abort "❌ Release tracker contains a malformed final ShakaPerf observation waiver." unless valid

  record
end

def final_shakaperf_observation_waiver_comment(record)
  encoded = canonical_accelerated_rc_json(record).unpack1("H*")
  marker = "#{SHAKAPERF_FINAL_OBSERVATION_WAIVER_MARKER_OPENER}" \
           "v#{SHAKAPERF_FINAL_OBSERVATION_WAIVER_SCHEMA_VERSION} #{encoded} -->"
  <<~MARKDOWN
    #{marker}
    ### Final ShakaPerf observation waiver

    - Release: `#{record.fetch('target_version')}` at `#{record.fetch('candidate_sha')}`
    - Run: #{record.fetch('run_url')} (attempt #{record.fetch('run_attempt')})
    - Failure kind: `gate_observation_failed`
    - Maintainer: `#{record.fetch('approved_by')}` at `#{record.fetch('recorded_at')}`
    - Reason: #{record.fetch('reason')}
  MARKDOWN
end

def exact_final_shakaperf_waiver_run!(repo_slug:, ref:, head_sha:, target_version:, run:)
  normalized = normalized_selected_shakaperf_release_gate_run(run)
  run_id = normalized["databaseId"]
  expected_url = "https://github.com/#{repo_slug}/actions/runs/#{run_id}"
  expected_title = shakaperf_release_gate_display_title(ref:, head_sha:, target_version:)
  identity_rejection = selected_shakaperf_release_gate_run_identity_rejection(
    run: normalized, repo_slug:, ref:
  )
  valid = identity_rejection.nil? && positive_github_id?(run_id) && positive_github_id?(normalized["attempt"]) &&
          normalized["headSha"] == head_sha &&
          normalized["displayTitle"] == expected_title && normalized["url"] == expected_url
  unless valid
    abort "❌ Final ShakaPerf observation waiver requires an exact repository/branch/version/SHA run identity."
  end

  normalized
end

def selected_final_shakaperf_observation_waiver(entries:, repo_slug:, tracker:, ref:, head_sha:, target_version:)
  matches = entries.filter_map do |entry|
    next unless entry[:kind] == :waiver

    record = entry.fetch(:record)
    record if record.values_at("repository", "release_tracker", "branch", "candidate_sha", "target_version") ==
              [repo_slug, tracker, ref, head_sha, target_version]
  end
  return nil if matches.empty?

  identities = matches.map do |record|
    SHAKAPERF_FINAL_OBSERVATION_WAIVER_IDENTITY_FIELDS.map { |field| record[field] }
  end.uniq
  abort "❌ Conflicting final ShakaPerf observation waivers exist for this exact candidate." unless identities.one?

  matches.first
end

def build_final_shakaperf_observation_waiver_record(repo_slug:, tracker:, ref:, head_sha:, target_version:, run:,
                                                    reason:, observation:, approved_by:, recorded_at:)
  normalized_run = exact_final_shakaperf_waiver_run!(
    repo_slug:, ref:, head_sha:, target_version:, run:
  )
  record = {
    "schema_version" => SHAKAPERF_FINAL_OBSERVATION_WAIVER_SCHEMA_VERSION,
    "repository" => repo_slug,
    "release_tracker" => tracker,
    "branch" => ref,
    "candidate_sha" => head_sha,
    "target_version" => target_version,
    "workflow" => SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
    "run_id" => normalized_run.fetch("databaseId"),
    "run_attempt" => normalized_run.fetch("attempt"),
    "run_url" => normalized_run.fetch("url"),
    "failure_kind" => "gate_observation_failed",
    "reason" => validate_final_shakaperf_observation_waiver_reason!(reason),
    "observation_digest" => Digest::SHA256.hexdigest(observation),
    "approved_by" => approved_by,
    "recorded_at" => recorded_at.utc.iso8601
  }
  validate_final_shakaperf_observation_waiver_record!(record)
end

def persist_final_shakaperf_observation_waiver!(repo_slug:, tracker:, ref:, head_sha:, target_version:, run:, reason:,
                                                observation:)
  approved_by = current_release_approver!(repo_slug:)
  record = build_final_shakaperf_observation_waiver_record(
    repo_slug:, tracker:, ref:, head_sha:, target_version:, run:, reason:, observation:, approved_by:,
    recorded_at: Time.now.utc
  )
  entries = trusted_shakaperf_release_tracker_records!(repo_slug:, tracker:)
  duplicate = selected_final_shakaperf_observation_waiver(
    entries:, repo_slug:, tracker:, ref:, head_sha:, target_version:
  )
  matching_duplicate = duplicate && matching_shakaperf_release_tracker_identity(
    [duplicate], record:, identity_fields: SHAKAPERF_FINAL_OBSERVATION_WAIVER_IDENTITY_FIELDS
  )
  return duplicate if matching_duplicate

  abort "❌ Conflicting final ShakaPerf observation waiver exists for this exact candidate." if duplicate

  post_release_tracker_comment!(repo_slug:, tracker:, body: final_shakaperf_observation_waiver_comment(record))
  refreshed = trusted_shakaperf_release_tracker_records!(repo_slug:, tracker:)
  refreshed_records = shakaperf_release_tracker_records_for_kind(refreshed, kind: :waiver)
  persisted = matching_shakaperf_release_tracker_digest(refreshed_records, record:)
  abort "❌ Final ShakaPerf observation waiver append could not be verified; refusing to continue." unless persisted

  persisted
end

def waived_final_shakaperf_run(record, observed_run: nil)
  normalized_run = normalized_selected_shakaperf_release_gate_run(observed_run || {})
  if observed_run && normalized_run["attempt"] != record.fetch("run_attempt")
    abort "❌ Observed run attempt does not match the final ShakaPerf observation waiver."
  end
  {
    "databaseId" => record.fetch("run_id"),
    "attempt" => record.fetch("run_attempt"),
    "displayTitle" => shakaperf_release_gate_display_title(
      ref: record.fetch("branch"),
      head_sha: record.fetch("candidate_sha"),
      target_version: record.fetch("target_version")
    ),
    "headSha" => record.fetch("candidate_sha"),
    "status" => normalized_run["status"] || "unknown",
    "conclusion" => normalized_run["conclusion"],
    "url" => record.fetch("run_url"),
    "observationWaived" => true,
    "waiverRecord" => record
  }
end

def ensure_final_shakaperf_observation_waiver_run!(error)
  return if error.run.is_a?(Hash)

  abort "❌ Final ShakaPerf observation waiver cannot waive a gate observation failure before an exact " \
        "ShakaPerf run is identified.\n\n#{error.message}"
end

def apply_final_shakaperf_observation_waiver!(error:, repo_slug:, tracker:, ref:, head_sha:, target_version:, reason:)
  abort "❌ Final ShakaPerf observation waiver requires RELEASE_TRACKER=<issue>." unless tracker
  if release_prerelease_version?(target_version)
    abort "❌ RELEASE_FINAL_SHAKAPERF_WAIVER_REASON is allowed for stable releases only."
  end
  validate_final_shakaperf_observation_waiver_reason!(reason)
  ensure_final_shakaperf_observation_waiver_run!(error)
  observed_run = exact_final_shakaperf_waiver_run!(
    repo_slug:, ref:, head_sha:, target_version:, run: error.run
  )
  if observed_run["status"] == "completed" || !observed_run["conclusion"].to_s.empty?
    abort "❌ A terminal ShakaPerf result cannot be treated as gate_observation_failed."
  end

  entries = trusted_shakaperf_release_tracker_records!(repo_slug:, tracker:)
  existing = selected_final_shakaperf_observation_waiver(
    entries:, repo_slug:, tracker:, ref:, head_sha:, target_version:
  )
  if existing && (existing.values_at("run_id", "run_attempt", "run_url", "reason") !=
                  [observed_run["databaseId"], observed_run["attempt"], observed_run["url"], reason])
    abort "❌ Existing final ShakaPerf observation waiver does not match the current exact run and reason."
  end
  record = existing || persist_final_shakaperf_observation_waiver!(
    repo_slug:, tracker:, ref:, head_sha:, target_version:, run: observed_run, reason:,
    observation: error.message
  )
  tracker_url = "https://github.com/#{repo_slug}/issues/#{tracker}"
  puts "⚠️ Using tracked stable ShakaPerf observation waiver from #{tracker_url}: #{record.fetch('run_url')}"
  waived_final_shakaperf_run(record, observed_run: error.run)
end

def select_and_verify_shakaperf_release_gate_run!(repo_slug:, monorepo_root:, tracker:, selector:, ref:, head_sha:,
                                                  target_version:, release_started_at:)
  abort "❌ RELEASE_SHAKAPERF_RUN requires a canonical release tracker." unless tracker

  run_id = selected_shakaperf_release_gate_run_id!(selector:, repo_slug:)
  tracker_run = reuse_shakaperf_release_tracker_evidence(
    repo_slug:, monorepo_root:, tracker:, ref:, head_sha:, target_version:, release_started_at:, run_id:
  )
  return tracker_run if tracker_run

  run = normalized_selected_shakaperf_release_gate_run(
    fetch_selected_shakaperf_release_gate_run!(repo_slug:, run_id:)
  )
  identity_rejection = selected_shakaperf_release_gate_run_identity_rejection(run:, repo_slug:, ref:)
  abort "❌ Selected ShakaPerf run is not reusable: #{identity_rejection}." if identity_rejection

  evidence = fetch_shakaperf_release_gate_evidence(repo_slug:, run:)
  abort "❌ Selected ShakaPerf run has no readable schema-v2 evidence artifact." unless evidence

  rejection = shakaperf_release_gate_evidence_rejection(
    monorepo_root:, ref:, head_sha:, target_version:, run:, evidence:, release_started_at:,
    validation_time: Time.now.utc, require_prerun: false
  )
  abort "❌ Selected ShakaPerf run is not reusable: #{rejection}." if rejection

  association = persist_verified_shakaperf_release_tracker_evidence!(
    repo_slug:, tracker:, ref:, head_sha: evidence.fetch("candidate_sha"), target_version:, run:, evidence:
  )
  puts "✓ Selected ShakaPerf run passed schema-v2 verification: #{run.fetch('url')}"
  ShakaperfAssociationBackedRun.from_verified_association(run:, association:)
end

def fetch_shakaperf_release_gate_runs(repo_slug:, ref:)
  output, status = capture_gh_output(
    "run", "list",
    "--repo", repo_slug,
    "--workflow", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
    "--branch", ref,
    "--event", "workflow_dispatch",
    "--json", "attempt,createdAt,databaseId,displayTitle,headSha,startedAt,status,conclusion,updatedAt,url",
    "--limit", SHAKAPERF_RELEASE_GATE_RUN_LIST_LIMIT.to_s
  )

  unless status.success?
    raise ShakaperfGateObservationError, "Unable to list ShakaPerf release gate workflow runs.\n\n#{output}"
  end

  JSON.parse(output).map do |run|
    run.merge(
      "repository" => repo_slug,
      "workflowPath" => ".github/workflows/#{SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE}",
      "event" => "workflow_dispatch",
      "headBranch" => ref
    )
  end
rescue JSON::ParserError => e
  raise ShakaperfGateObservationError,
        "Failed to parse ShakaPerf release gate workflow runs: #{e.message}\n\nOutput:\n#{output}"
end

def fetch_shakaperf_release_gate_evidence(repo_slug:, run:)
  Dir.mktmpdir("shakaperf-release-evidence") do |dir|
    output, status = capture_gh_output(
      "run", "download", run.fetch("databaseId").to_s,
      "--repo", repo_slug,
      "--name", SHAKAPERF_RELEASE_GATE_EVIDENCE_ARTIFACT,
      "--dir", dir
    )
    unless status.success?
      warn "⚠️ Unable to download ShakaPerf pre-run evidence; dispatching an exact-head gate.\n#{output}"
      return nil
    end

    evidence_paths = Dir.glob(File.join(dir, "**", SHAKAPERF_RELEASE_GATE_EVIDENCE_FILE))
    unless evidence_paths.one?
      warn "⚠️ ShakaPerf pre-run evidence artifact did not contain exactly one " \
           "#{SHAKAPERF_RELEASE_GATE_EVIDENCE_FILE}; dispatching an exact-head gate."
      return nil
    end

    JSON.parse(File.read(evidence_paths.first))
  end
rescue JSON::ParserError => e
  warn "⚠️ Unable to parse ShakaPerf pre-run evidence: #{e.message}; dispatching an exact-head gate."
  nil
rescue StandardError => e
  warn "⚠️ Unable to inspect ShakaPerf pre-run evidence: #{e.class}: #{e.message}; " \
       "dispatching an exact-head gate."
  nil
end

def authoritative_shakaperf_artifact_absence?(output)
  output.to_s.match?(%r{
    \bHTTP(?:/\d(?:\.\d)?)?\s+404\b |
    \b404\s+Not\ Found\b |
    \bno\ artifacts?\ found\b |
    \bno\ valid\ artifacts\ found\ to\ download\b
  }ix)
end

def download_saved_shakaperf_release_gate_evidence!(repo_slug:, run:, dir:)
  output, status = capture_gh_output(
    "run", "download", run.fetch("databaseId").to_s,
    "--repo", repo_slug,
    "--name", SHAKAPERF_RELEASE_GATE_EVIDENCE_ARTIFACT,
    "--dir", dir
  )
  return if status.success?

  error_class = if authoritative_shakaperf_artifact_absence?(output)
                  ShakaperfGateMissingArtifactError
                else
                  ShakaperfGateObservationError
                end
  raise error_class.new("Unable to download saved ShakaPerf evidence artifact.\n\n#{output}", run:)
end

def saved_shakaperf_release_gate_evidence_path!(dir:, run:)
  evidence_paths = Dir.glob(File.join(dir, "**", SHAKAPERF_RELEASE_GATE_EVIDENCE_FILE))
  if evidence_paths.empty?
    raise ShakaperfGateMissingArtifactError.new(
      "Saved ShakaPerf evidence artifact no longer contains #{SHAKAPERF_RELEASE_GATE_EVIDENCE_FILE}.", run:
    )
  end
  unless evidence_paths.one?
    raise ShakaperfGateObservationError.new(
      "Saved ShakaPerf evidence artifact contains multiple evidence files.", run:
    )
  end

  evidence_paths.first
end

def fetch_shakaperf_release_gate_evidence_for_association!(repo_slug:, run:)
  Dir.mktmpdir("shakaperf-release-evidence") do |dir|
    download_saved_shakaperf_release_gate_evidence!(repo_slug:, run:, dir:)
    JSON.parse(File.read(saved_shakaperf_release_gate_evidence_path!(dir:, run:)))
  end
rescue ShakaperfGateObservationError
  raise
rescue JSON::ParserError => e
  raise ShakaperfGateObservationError.new(
    "Saved ShakaPerf evidence artifact returned invalid JSON: #{e.message}", run:
  )
rescue StandardError => e
  raise ShakaperfGateObservationError.new(
    "Unable to inspect saved ShakaPerf evidence artifact: #{e.class}: #{e.message}", run:
  )
end

def refresh_shakaperf_release_gate_run!(repo_slug:, run:)
  output, status = capture_gh_output(
    "run", "view", run.fetch("databaseId").to_s,
    "--repo", repo_slug,
    "--json", "attempt,createdAt,databaseId,displayTitle,headSha,startedAt,status,conclusion,updatedAt,url"
  )
  unless status.success?
    raise ShakaperfGateObservationError.new(
      "Unable to refresh ShakaPerf release gate workflow evidence.\n\n#{output}", run:
    )
  end

  JSON.parse(output).merge(
    "repository" => run["repository"],
    "workflowPath" => run["workflowPath"],
    "event" => run["event"],
    "headBranch" => run["headBranch"]
  )
rescue JSON::ParserError => e
  raise ShakaperfGateObservationError.new(
    "Failed to parse refreshed ShakaPerf release gate workflow evidence: #{e.message}", run:
  )
end

def shakaperf_release_gate_run_evidence_rejection(repo_slug:, monorepo_root:, ref:, head_sha:, target_version:,
                                                  run:, release_started_at:, require_prerun:)
  evidence = fetch_shakaperf_release_gate_evidence(repo_slug:, run:)
  return "evidence artifact is missing or unreadable" unless evidence

  shakaperf_release_gate_evidence_rejection(
    monorepo_root:,
    ref:,
    head_sha:,
    target_version:,
    run:,
    evidence:,
    release_started_at:,
    validation_time: Time.now.utc,
    require_prerun:
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

def wait_for_shakaperf_release_gate_run!(repo_slug:, ref:, head_sha:, target_version:, ignored_run_ids: [],
                                         earliest_created_at: nil)
  deadline = Time.now + SHAKAPERF_RELEASE_GATE_START_TIMEOUT_SECONDS
  ignored_run_ids = ignored_run_ids.map(&:to_s)

  loop do
    runs = fetch_shakaperf_release_gate_runs(repo_slug:, ref:)
    matching_run = runs.find do |run|
      shakaperf_release_gate_run_matches_target?(run:, ref:, head_sha:, target_version:) &&
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

def accelerated_shakaperf_polling_target_runs!(runs:, ref:, target_version:)
  collapse_accelerated_shakaperf_run_duplicates!(runs).filter_map do |run|
    case accelerated_shakaperf_run_target_classification(run:, ref:, target_version:)
    when :target
      run
    when :unrelated
      nil
    else
      abort "❌ Accelerated RC ShakaPerf polling target identity is unknown or malformed; " \
            "refusing unaudited publication."
    end
  end
end

def accelerated_shakaperf_fresh_polling_run!(
  runs:, repo_slug:, ref:, head_sha:, target_version:, ignored_run_ids:, earliest_created_at:
)
  unless runs.is_a?(Array)
    abort "❌ Accelerated RC ShakaPerf polling collection is unknown or malformed; " \
          "refusing unaudited publication."
  end

  runs.each { |run| validate_accelerated_shakaperf_run_metadata!(repo_slug:, run:) }
  target_runs = accelerated_shakaperf_polling_target_runs!(runs:, ref:, target_version:)
  fresh_runs = target_runs.select do |run|
    shakaperf_release_gate_run_matches_target?(run:, ref:, head_sha:, target_version:) &&
      !ignored_run_ids.include?(run["databaseId"].to_s) &&
      shakaperf_release_gate_run_created_after?(run, earliest_created_at)
  end
  if fresh_runs.length > 1
    abort "❌ Accelerated RC ShakaPerf polling returned ambiguous concurrent fresh runs; " \
          "refusing unaudited publication."
  end

  fresh_runs.first
end

def wait_for_accelerated_shakaperf_release_gate_run!(repo_slug:, ref:, head_sha:, target_version:,
                                                     ignored_run_ids: [], earliest_created_at: nil)
  deadline = Time.now + SHAKAPERF_RELEASE_GATE_START_TIMEOUT_SECONDS
  ignored_run_ids = ignored_run_ids.map(&:to_s)

  loop do
    runs = fetch_shakaperf_release_gate_runs(repo_slug:, ref:)
    fresh_run = accelerated_shakaperf_fresh_polling_run!(
      runs:, repo_slug:, ref:, head_sha:, target_version:, ignored_run_ids:, earliest_created_at:
    )
    return fresh_run if fresh_run

    break if Time.now >= deadline

    sleep SHAKAPERF_RELEASE_GATE_START_POLL_SECONDS
  end

  handle_shakaperf_release_gate_violation!(
    message: "❌ Timed out waiting for accelerated ShakaPerf release gate workflow to start for #{head_sha[0, 8]}."
  )
end

def shakaperf_release_gate_display_title(ref:, head_sha:, target_version:)
  "ShakaPerf Release Gates — #{target_version} on #{ref} @ #{head_sha}"
end

def shakaperf_release_gate_run_matches_target?(run:, ref:, head_sha:, target_version:)
  run["headSha"] == head_sha && positive_github_id?(run["attempt"]) &&
    run["displayTitle"] == shakaperf_release_gate_display_title(ref:, head_sha:, target_version:)
end

def shakaperf_release_gate_canonical_title_identity(run)
  return nil unless run.is_a?(Hash) && run["headSha"].is_a?(String)

  match = SHAKAPERF_RELEASE_GATE_DISPLAY_TITLE_PATTERN.match(run["displayTitle"].to_s)
  return nil unless match && match[:head_sha] == run["headSha"]

  title_target = match[:target_version]
  title_ref = match[:ref]
  return nil unless title_target.match?(SHAKAPERF_RELEASE_GATE_CANONICAL_VERSION_PATTERN)

  target_base = title_target.split(".").first(3).join(".")
  return nil unless title_ref == "release/#{target_base}"

  { target_version: title_target, ref: title_ref, head_sha: match[:head_sha] }
end

def accelerated_shakaperf_run_target_classification(run:, ref:, target_version:)
  identity = shakaperf_release_gate_canonical_title_identity(run)
  return :unknown unless identity

  if identity.fetch(:ref) == ref && identity.fetch(:target_version) == target_version
    :target
  else
    :unrelated
  end
end

def active_shakaperf_release_gate_run?(run)
  return false unless SHAKAPERF_RELEASE_GATE_ACTIVE_STATUSES.include?(run["status"].to_s)

  unless run["conclusion"].nil?
    abort "❌ Active ShakaPerf run has a terminal conclusion; refusing contradictory gate evidence."
  end

  true
end

def same_shakaperf_release_gate_run_identity?(original_run:, refreshed_run:)
  return false unless refreshed_run.is_a?(Hash)

  head_sha = refreshed_run["headSha"]
  positive_github_id?(refreshed_run["databaseId"]) &&
    refreshed_run.values_at("databaseId", "headSha", "attempt", "displayTitle") ==
      original_run.values_at("databaseId", "headSha", "attempt", "displayTitle") &&
    head_sha.is_a?(String) && !head_sha.empty?
end

def trustworthy_terminal_shakaperf_release_gate_run?(original_run:, refreshed_run:)
  same_shakaperf_release_gate_run_identity?(original_run:, refreshed_run:) &&
    positive_github_id?(refreshed_run["attempt"]) &&
    refreshed_run["status"] == "completed" &&
    SHAKAPERF_RELEASE_GATE_TERMINAL_CONCLUSIONS.include?(refreshed_run["conclusion"])
end

def trustworthy_terminal_shakaperf_workflow_run?(original_run:, refreshed_run:)
  return false unless refreshed_run.is_a?(Hash)

  refreshed_run.values_at("databaseId", "headSha", "displayTitle") ==
    original_run.values_at("databaseId", "headSha", "displayTitle") &&
    positive_github_id?(refreshed_run["attempt"]) &&
    refreshed_run["status"] == "completed" &&
    SHAKAPERF_RELEASE_GATE_TERMINAL_CONCLUSIONS.include?(refreshed_run["conclusion"])
end

def find_latest_shakaperf_release_gate_run(runs, head_sha, ref: nil, target_version: nil)
  matching_runs = runs.select do |run|
    run["headSha"] == head_sha &&
      (!target_version || shakaperf_release_gate_run_matches_target?(run:, ref:, head_sha:, target_version:))
  end
  matching_runs.max_by { |run| shakaperf_release_gate_run_sort_key(run) }
end

def shakaperf_prerun_candidates(runs, head_sha, ref: nil, target_version: nil)
  candidates = runs.reject { |run| run["headSha"] == head_sha }
  if target_version
    candidates = candidates.select do |run|
      shakaperf_release_gate_run_matches_target?(
        run:, ref:, head_sha: run["headSha"], target_version:
      )
    end
  end

  candidates
end

def find_latest_shakaperf_prerun(runs, head_sha, ref: nil, target_version: nil)
  candidates = shakaperf_prerun_candidates(runs, head_sha, ref:, target_version:)
  return nil unless candidates.all? { |run| valid_shakaperf_prerun_ordering_metadata?(run) }

  candidates.max_by { |run| shakaperf_prerun_candidate_sort_key(run) }
end

def collapse_accelerated_shakaperf_run_duplicates!(runs)
  identities = {}
  runs.each_with_object([]) do |run, unique_runs|
    abort "❌ Accelerated RC ShakaPerf run identity is unknown or malformed." unless run.is_a?(Hash)

    identity = [run["databaseId"], run["attempt"]]
    unless identity.all? { |value| positive_github_id?(value) }
      unique_runs << run
      next
    end

    existing = identities[identity]
    if existing
      unless existing == run
        abort "❌ Accelerated RC ShakaPerf duplicate run identity is conflicting; refusing unaudited publication."
      end
      next
    end

    identities[identity] = run
    unique_runs << run
  end
end

def valid_shakaperf_release_gate_ordering_metadata?(run)
  valid_identity_and_times = positive_github_id?(run["databaseId"]) &&
                             positive_github_id?(run["attempt"]) &&
                             !shakaperf_release_gate_time(run["createdAt"]).nil? &&
                             !shakaperf_release_gate_time(run["updatedAt"]).nil?
  return false unless valid_identity_and_times

  if SHAKAPERF_RELEASE_GATE_ACTIVE_STATUSES.include?(run["status"])
    run["startedAt"].nil? || !shakaperf_release_gate_time(run["startedAt"]).nil?
  else
    !shakaperf_release_gate_time(run["startedAt"]).nil?
  end
end

def accelerated_shakaperf_candidate_selection!(runs, exact_head:)
  if exact_head
    ordering_validator = method(:valid_shakaperf_release_gate_ordering_metadata?)
    sort_key = method(:shakaperf_release_gate_run_sort_key)
  else
    ordering_validator = method(:valid_accelerated_shakaperf_prerun_ordering_metadata?)
    sort_key = method(:shakaperf_prerun_candidate_sort_key)
  end
  ordered, unordered = runs.partition { |run| ordering_validator.call(run) }
  ordered.group_by { |run| sort_key.call(run) }.each_value do |same_key_runs|
    next if same_key_runs.one?

    abort "❌ Accelerated RC ShakaPerf equal ordering keys are conflicting; refusing unaudited publication."
  end

  { run: ordered.max_by { |run| sort_key.call(run) }, unordered_runs: unordered }
end

def accelerated_shakaperf_run_selection!(runs, head_sha, repo_slug:, ref:, target_version:)
  unless runs.is_a?(Array)
    abort "❌ Accelerated RC ShakaPerf run collection is unknown or malformed; refusing unaudited publication."
  end

  runs.each { |run| validate_accelerated_shakaperf_run_metadata!(repo_slug:, run:) }
  unique_runs = collapse_accelerated_shakaperf_run_duplicates!(runs)
  relevant_runs = unique_runs.filter_map do |run|
    case accelerated_shakaperf_run_target_classification(run:, ref:, target_version:)
    when :target
      run
    when :unrelated
      nil
    else
      abort "❌ Accelerated RC ShakaPerf target identity is unknown or malformed; refusing unaudited publication."
    end
  end
  exact_runs, preruns = relevant_runs.partition { |run| run["headSha"] == head_sha }
  exact_selection = accelerated_shakaperf_candidate_selection!(exact_runs, exact_head: true)
  prerun_selection = accelerated_shakaperf_candidate_selection!(preruns, exact_head: false)
  {
    exact_run: exact_selection.fetch(:run),
    prerun: prerun_selection.fetch(:run),
    unordered_runs: exact_selection.fetch(:unordered_runs) + prerun_selection.fetch(:unordered_runs)
  }
end

def valid_shakaperf_prerun_ordering_metadata?(run)
  positive_github_id?(run["databaseId"]) &&
    positive_github_id?(run["attempt"]) &&
    !shakaperf_release_gate_time(run["createdAt"]).nil? &&
    !shakaperf_release_gate_time(run["startedAt"]).nil?
end

def valid_accelerated_shakaperf_prerun_ordering_metadata?(run)
  valid_shakaperf_prerun_ordering_metadata?(run) &&
    !shakaperf_release_gate_time(run["updatedAt"]).nil?
end

def shakaperf_prerun_candidate_sort_key(run)
  created_at = shakaperf_release_gate_run_timestamp(run, "createdAt")
  updated_at = shakaperf_release_gate_run_timestamp(run, "updatedAt")

  [created_at, run["databaseId"].to_i, run["attempt"].to_i, updated_at]
end

def shakaperf_release_gate_run_sort_key(run)
  updated_at = shakaperf_release_gate_run_timestamp(run, "updatedAt")
  created_at = shakaperf_release_gate_run_timestamp(run, "createdAt")

  [updated_at, run["attempt"].to_i, created_at, run["databaseId"].to_i]
end

def shakaperf_release_gate_run_timestamp(run, field_name)
  Time.iso8601(run[field_name]).to_i
rescue ArgumentError, TypeError
  0
end

def shakaperf_release_gate_run_url(repo_slug:, run:)
  run["url"] || "https://github.com/#{repo_slug}/actions/runs/#{run.fetch('databaseId')}"
end

def print_shakaperf_release_gate_notice(ref:, head_sha:)
  start_timeout_minutes = SHAKAPERF_RELEASE_GATE_START_TIMEOUT_SECONDS / 60
  watch_timeout_minutes = SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS / 60
  fresh_dispatch_timeout_minutes = start_timeout_minutes + watch_timeout_minutes

  puts <<~NOTICE

    Running ShakaPerf release gate on #{ref} at #{head_sha[0, 8]} before tagging and publishing...
    This first checks for verified same-version pre-run evidence from this branch, then for an exact-head run.
    If neither is reusable, it dispatches a new exact-head workflow run and blocks until verified evidence exists.
    Warm-cache waits usually take a few minutes.
    The workflow can run up to #{SHAKAPERF_RELEASE_GATE_WORKFLOW_TIMEOUT_MINUTES} minutes.
    Fresh dispatches can take up to #{start_timeout_minutes} minutes to appear before watching starts.
    Once a run is found, this release task will watch it for up to #{watch_timeout_minutes} minutes.
    A fresh dispatch can therefore block for up to about #{fresh_dispatch_timeout_minutes} minutes total.
    To preview the skip only for an explicitly approved prerelease where ShakaPerf is known-unrelated:
      RELEASE_CI_STATUS_OVERRIDE=true bundle exec rake "release[VERSION,true]"
      # or pass override_ci_status as the 4th positional argument:
      bundle exec rake "release[VERSION,true,false,true]"
    #{release_version_placeholder_guidance}

    #{release_compound_live_boundary_guidance}
  NOTICE
end

def dispatch_shakaperf_release_gate_workflow!(repo_slug:, ref:, target_version:, candidate_sha:)
  release_write_fence!("dispatch ShakaPerf release gate")
  output, status = capture_gh_output(
    "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
    "--repo", repo_slug,
    "--ref", ref,
    "-f", "target_version=#{target_version}",
    "-f", "candidate_sha=#{candidate_sha}"
  )

  return if status.success?

  handle_shakaperf_release_gate_violation!(
    message: "❌ Unable to dispatch ShakaPerf release gate workflow.\n\n#{output}"
  )
end

def watch_shakaperf_release_gate_run!(repo_slug:, run:)
  run_id = run.fetch("databaseId").to_s
  run_url = shakaperf_release_gate_run_url(repo_slug:, run:)

  output, status, timed_out = capture_gh_output_with_timeout(
    "run", "watch", run_id, "--repo", repo_slug, "--exit-status",
    timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
  )

  if timed_out
    raise ShakaperfGateObservationError.new(
      "Timed out watching ShakaPerf release gate run #{run_id}.\n\nRun: #{run_url}", run:
    )
  end

  return if status.success?

  begin
    refreshed_run = refresh_shakaperf_release_gate_run!(repo_slug:, run:)
  rescue ShakaperfGateObservationError => e
    handle_shakaperf_release_gate_violation!(
      message: "❌ ShakaPerf release gate watcher returned nonzero and its terminal result could not be " \
               "refreshed; this failure is non-waivable.\n\nRun: #{run_url}\n\n#{output}\n\n#{e.message}"
    )
  end
  if refreshed_run["status"] == "completed" && refreshed_run["conclusion"] != "success"
    handle_shakaperf_release_gate_violation!(
      message: "❌ ShakaPerf release gate failed.\n\nRun: #{run_url}\n\n#{output}"
    )
  end
  return if refreshed_run["status"] == "completed" && refreshed_run["conclusion"] == "success"

  raise ShakaperfGateObservationError.new(
    "Unable to observe a terminal ShakaPerf release gate result for run #{run_id}.\n\n" \
    "Run: #{run_url}\n\n#{output}",
    run: refreshed_run
  )
end

def watch_existing_shakaperf_release_gate_run!(repo_slug:, run:)
  run_id = run.fetch("databaseId").to_s
  run_url = shakaperf_release_gate_run_url(repo_slug:, run:)
  output, status, timed_out = capture_gh_output_with_timeout(
    "run", "watch", run_id, "--repo", repo_slug,
    timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
  )

  if timed_out
    raise ShakaperfGateObservationError.new(
      "Timed out watching ShakaPerf release gate run #{run_id}.\n\nRun: #{run_url}", run:
    )
  end

  unless status.success?
    raise ShakaperfGateObservationError.new(
      "Unable to watch existing ShakaPerf release gate run #{run_id}." \
      "\n\nRun: #{run_url}\n\n#{output}",
      run:
    )
  end

  refreshed_run = refresh_shakaperf_release_gate_run!(repo_slug:, run:)
  return refreshed_run if trustworthy_terminal_shakaperf_workflow_run?(original_run: run, refreshed_run:)

  raise ShakaperfGateObservationError.new(
    "Unable to establish the terminal result of existing ShakaPerf release gate run #{run_id}." \
    "\n\nRun: #{run_url}\n\n#{output}",
    run: refreshed_run
  )
end

def handle_existing_shakaperf_release_gate_run!(repo_slug:, monorepo_root:, ref:, run:, head_sha:, target_version:,
                                                release_started_at:)
  return false unless run

  if run["status"].to_s == "completed"
    return handle_completed_shakaperf_release_gate_run(
      repo_slug:, monorepo_root:, ref:, run:, head_sha:, target_version:, release_started_at:
    )
  end
  return false unless active_shakaperf_release_gate_run?(run)

  handle_active_shakaperf_release_gate_run(
    repo_slug:, monorepo_root:, ref:, run:, head_sha:, target_version:, release_started_at:
  )
end

def handle_completed_shakaperf_release_gate_run(repo_slug:, monorepo_root:, ref:, run:, head_sha:, target_version:,
                                                release_started_at:)
  run_id = run.fetch("databaseId").to_s
  run_url = shakaperf_release_gate_run_url(repo_slug:, run:)
  conclusion = run["conclusion"].to_s
  unless conclusion == "success"
    puts "Latest ShakaPerf release gate run #{run_id} completed with conclusion " \
         "#{conclusion.empty? ? 'unknown' : conclusion}; dispatching a fresh gate run: #{run_url}"
    return false
  end

  rejection = shakaperf_release_gate_run_evidence_rejection(
    repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run:, release_started_at:, require_prerun: false
  )
  unless rejection
    puts "✓ ShakaPerf release gate already passed with verified evidence: #{run_url}"
    return run
  end

  puts "Successful ShakaPerf release gate evidence is not reusable (#{rejection}); " \
       "dispatching a fresh exact-head gate: #{run_url}"
  false
end

def handle_active_shakaperf_release_gate_run(repo_slug:, monorepo_root:, ref:, run:, head_sha:, target_version:,
                                             release_started_at:)
  run_url = shakaperf_release_gate_run_url(repo_slug:, run:)
  puts "Found an existing ShakaPerf release gate run for #{head_sha[0, 8]}; watching it instead: #{run_url}"
  refreshed_run = watch_existing_shakaperf_release_gate_run!(repo_slug:, run:)
  unless refreshed_run["conclusion"].to_s == "success"
    return handle_completed_shakaperf_release_gate_run(
      repo_slug:, monorepo_root:, ref:, run: refreshed_run, head_sha:, target_version:, release_started_at:
    )
  end

  rejection = shakaperf_release_gate_run_evidence_rejection(
    repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run: refreshed_run, release_started_at:,
    require_prerun: false
  )
  unless rejection
    puts "✓ ShakaPerf release gate passed with verified evidence: #{run_url}"
    return refreshed_run
  end

  puts "Completed ShakaPerf release gate evidence is not reusable (#{rejection}); " \
       "dispatching a fresh exact-head gate: #{run_url}"
  false
end

def reuse_shakaperf_prerun?(repo_slug:, monorepo_root:, ref:, existing_runs:, head_sha:, target_version:,
                            release_started_at:)
  prerun = find_latest_shakaperf_prerun(existing_runs, head_sha, ref:, target_version:)
  return false unless prerun

  waited_for_active_prerun = active_shakaperf_release_gate_run?(prerun)
  if waited_for_active_prerun
    watched_attempt = prerun["attempt"]
    watched_started_at = prerun["startedAt"]
    run_url = shakaperf_release_gate_run_url(repo_slug:, run: prerun)
    puts "Found an in-progress ShakaPerf pre-run; watching it before deciding whether to dispatch: #{run_url}"
    prerun = watch_existing_shakaperf_release_gate_run!(repo_slug:, run: prerun)
    unless prerun["attempt"] == watched_attempt
      puts "ShakaPerf pre-run attempt changed while the release task waited; " \
           "dispatching an exact-head gate: #{run_url}"
      return false
    end
    unless prerun["startedAt"] == watched_started_at
      puts "ShakaPerf pre-run provenance changed while the release task waited; " \
           "dispatching an exact-head gate: #{run_url}"
      return false
    end
    conclusion = prerun["conclusion"].to_s
    unless conclusion == "success"
      puts "Latest ShakaPerf pre-run completed with conclusion #{conclusion}; " \
           "dispatching an exact-head gate: #{run_url}"
      return false
    end
  end

  evidence = fetch_shakaperf_release_gate_evidence(repo_slug:, run: prerun)
  return false unless evidence

  rejection = shakaperf_release_gate_evidence_rejection(
    monorepo_root:, ref:, head_sha:, target_version:, run: prerun, evidence:, release_started_at:,
    validation_time: Time.now.utc, require_prerun: true,
    allow_prerun_completion_after_release_start: waited_for_active_prerun
  )
  run_url = shakaperf_release_gate_run_url(repo_slug:, run: prerun)
  unless rejection
    puts "✓ Reusing successful ShakaPerf pre-run: #{run_url}"
    return prerun
  end

  puts "Latest ShakaPerf pre-run is not reusable (#{rejection}); dispatching an exact-head gate: #{run_url}"
  false
end

def dispatch_and_validate_shakaperf_release_gate!(repo_slug:, monorepo_root:, ref:, existing_runs:, head_sha:,
                                                  target_version:, release_started_at:)
  existing_run_ids = existing_runs.map { |run| run["databaseId"].to_s }
  dispatch_started_at = shakaperf_release_gate_dispatch_started_at
  dispatch_shakaperf_release_gate_workflow!(repo_slug:, ref:, target_version:, candidate_sha: head_sha)
  run = wait_for_shakaperf_release_gate_run!(
    repo_slug:, ref:, head_sha:, target_version:, ignored_run_ids: existing_run_ids,
    earliest_created_at: dispatch_started_at
  )
  watch_shakaperf_release_gate_run!(repo_slug:, run:)

  refreshed_run = refresh_shakaperf_release_gate_run!(repo_slug:, run:)
  unless trustworthy_terminal_shakaperf_release_gate_run?(original_run: run, refreshed_run:)
    run_id = run.fetch("databaseId")
    run_url = shakaperf_release_gate_run_url(repo_slug:, run:)
    handle_shakaperf_release_gate_violation!(
      message: "❌ Unable to establish the terminal result of freshly dispatched " \
               "ShakaPerf release gate run #{run_id}.\n\nRun: #{run_url}"
    )
  end
  verify_fresh_shakaperf_release_gate_evidence!(
    repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run: refreshed_run, release_started_at:
  )
  refreshed_run
end

def verify_fresh_shakaperf_release_gate_evidence!(repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run:,
                                                  release_started_at:)
  rejection = shakaperf_release_gate_run_evidence_rejection(
    repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run:, release_started_at:, require_prerun: false
  )
  run_url = shakaperf_release_gate_run_url(repo_slug:, run:)
  if rejection
    handle_shakaperf_release_gate_violation!(
      message: "❌ Fresh ShakaPerf release gate evidence is invalid: #{rejection}.\n\nRun: #{run_url}"
    )
  end

  puts "✓ ShakaPerf release gate passed with verified evidence: #{run_url}"
end

def validate_final_shakaperf_waiver_request!(target_version:, tracker:, waiver_reason:)
  return unless waiver_reason

  if release_prerelease_version?(target_version)
    abort "❌ RELEASE_FINAL_SHAKAPERF_WAIVER_REASON is allowed for stable releases only."
  end
  abort "❌ Final ShakaPerf observation waiver requires RELEASE_TRACKER=<issue>." unless tracker

  validate_final_shakaperf_observation_waiver_reason!(waiver_reason)
end

def skip_shakaperf_release_gate?(ref:, head_sha:, dry_run:, allow_override:)
  if dry_run
    puts "⚠️ DRY RUN: Would run ShakaPerf release gate on #{ref} at #{head_sha[0, 8]} before publishing."
    return true
  end

  if allow_override
    puts "⚠️ CI STATUS OVERRIDE enabled — skipping ShakaPerf release gate."
    return true
  end

  false
end

def discover_and_run_shakaperf_release_gate!(repo_slug:, monorepo_root:, ref:, head_sha:, target_version:,
                                             release_started_at:)
  existing_runs = fetch_shakaperf_release_gate_runs(repo_slug:, ref:)
  existing_run = find_latest_shakaperf_release_gate_run(existing_runs, head_sha, ref:, target_version:)
  validated_run = handle_existing_shakaperf_release_gate_run!(
    repo_slug:, monorepo_root:, ref:, run: existing_run, head_sha:, target_version:, release_started_at:
  )
  return validated_run if validated_run

  validated_run = reuse_shakaperf_prerun?(
    repo_slug:, monorepo_root:, ref:, existing_runs:, head_sha:, target_version:, release_started_at:
  )
  return validated_run if validated_run

  dispatch_and_validate_shakaperf_release_gate!(
    repo_slug:, monorepo_root:, ref:, existing_runs:, head_sha:, target_version:, release_started_at:
  )
end

def observe_shakaperf_release_gate!(repo_slug:, monorepo_root:, tracker:, run_selector:, ref:, head_sha:,
                                    target_version:, release_started_at:)
  if run_selector
    return select_and_verify_shakaperf_release_gate_run!(
      repo_slug:, monorepo_root:, tracker:, selector: run_selector, ref:, head_sha:, target_version:,
      release_started_at:
    )
  end

  if tracker
    tracker_run = reuse_shakaperf_release_tracker_evidence(
      repo_slug:, monorepo_root:, tracker:, ref:, head_sha:, target_version:, release_started_at:
    )
    return tracker_run if tracker_run
  end

  discover_and_run_shakaperf_release_gate!(
    repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, release_started_at:
  )
end

def run_shakaperf_release_gate!(monorepo_root:, ref:, head_sha:, target_version:, release_started_at:,
                                allow_override:, dry_run:, tracker: nil, run_selector: nil, waiver_reason: nil)
  validate_final_shakaperf_waiver_request!(target_version:, tracker:, waiver_reason:)
  return if skip_shakaperf_release_gate?(ref:, head_sha:, dry_run:, allow_override:)

  repo_slug = github_repo_slug(monorepo_root)
  print_shakaperf_release_gate_notice(ref:, head_sha:)
  observe_shakaperf_release_gate!(
    repo_slug:, monorepo_root:, tracker:, run_selector:, ref:, head_sha:, target_version:, release_started_at:
  )
rescue ShakaperfGateObservationError => e
  if waiver_reason
    apply_final_shakaperf_observation_waiver!(
      error: e, repo_slug:, tracker:, ref:, head_sha:, target_version:, reason: waiver_reason
    )
  else
    handle_shakaperf_release_gate_violation!(
      message: "❌ ShakaPerf gate observation failed.\n\n#{e.message}"
    )
  end
end

def run_accelerated_shakaperf_release_gate!(monorepo_root:, ref:, head_sha:, target_version:, release_started_at:)
  repo_slug = github_repo_slug(monorepo_root)
  existing_runs = fetch_shakaperf_release_gate_runs(repo_slug:, ref:)
  selection = accelerated_shakaperf_run_selection!(existing_runs, head_sha, repo_slug:, ref:, target_version:)
  unordered_states = selection.fetch(:unordered_runs).map do |unordered_run|
    accelerated_shakaperf_run_state!(repo_slug:, run: unordered_run, unordered: true)
  end
  force_exact_head_dispatch = unordered_states.include?(:dispatch)
  existing_snapshot = selected_accelerated_shakaperf_snapshot(
    repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, release_started_at:, selection:,
    force_exact_head_dispatch:
  )
  return existing_snapshot if existing_snapshot.is_a?(Hash)

  dispatch_accelerated_shakaperf_release_gate!(
    repo_slug:, monorepo_root:, ref:, existing_runs:, head_sha:, target_version:, release_started_at:
  )
end

def selected_accelerated_shakaperf_snapshot(repo_slug:, monorepo_root:, ref:, head_sha:, target_version:,
                                            release_started_at:, selection:, force_exact_head_dispatch:)
  existing_run = selection.fetch(:exact_run)
  prerun = selection.fetch(:prerun)
  exact_state = accelerated_shakaperf_run_state!(repo_slug:, run: existing_run, unordered: false)
  prerun_state = accelerated_shakaperf_run_state!(repo_slug:, run: prerun, unordered: false)
  return nil if force_exact_head_dispatch && exact_state != :none

  if exact_state == :active
    return accelerated_shakaperf_snapshot(
      repo_slug:, run: existing_run, ref:, candidate_sha: head_sha, target_version:, release_started_at:,
      status: "pending"
    )
  end
  if exact_state == :success
    exact_snapshot = verified_accelerated_shakaperf_snapshot(
      repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run: existing_run,
      release_started_at:, require_prerun: false, candidate_sha: head_sha
    )
    return exact_snapshot if exact_snapshot
  end

  return nil if force_exact_head_dispatch
  return unless prerun_state == :success

  verified_accelerated_shakaperf_snapshot(
    repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run: prerun,
    release_started_at:, require_prerun: true, candidate_sha: prerun.fetch("headSha")
  )
end

def dispatch_accelerated_shakaperf_release_gate!(repo_slug:, monorepo_root:, ref:, existing_runs:, head_sha:,
                                                 target_version:, release_started_at:)
  existing_run_ids = existing_runs.map { |run| run["databaseId"].to_s }
  dispatch_started_at = shakaperf_release_gate_dispatch_started_at
  dispatch_shakaperf_release_gate_workflow!(repo_slug:, ref:, target_version:, candidate_sha: head_sha)
  run = wait_for_accelerated_shakaperf_release_gate_run!(
    repo_slug:,
    ref:,
    head_sha:,
    target_version:,
    ignored_run_ids: existing_run_ids,
    earliest_created_at: dispatch_started_at
  )
  validate_accelerated_shakaperf_run_metadata!(repo_slug:, run:)

  if run["status"] == "completed"
    reject_known_accelerated_shakaperf_failure!(repo_slug:, run:)
    snapshot = verified_accelerated_shakaperf_snapshot(
      repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run:,
      release_started_at:, require_prerun: false, candidate_sha: head_sha
    )
    return snapshot if snapshot

    abort "❌ Freshly dispatched ShakaPerf run completed without trustworthy evidence; " \
          "refusing unaudited publication."
  end
  unless active_shakaperf_release_gate_run?(run)
    abort "❌ Freshly dispatched ShakaPerf run state is unknown; refusing unaudited publication."
  end

  accelerated_shakaperf_snapshot(
    repo_slug:, run:, ref:, candidate_sha: head_sha, target_version:, release_started_at:, status: "pending"
  )
end

def verified_accelerated_shakaperf_snapshot(repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run:,
                                            release_started_at:, require_prerun:, candidate_sha:)
  return nil unless run&.fetch("status", nil) == "completed" && run["conclusion"] == "success"

  rejection = shakaperf_release_gate_run_evidence_rejection(
    repo_slug:, monorepo_root:, ref:, head_sha:, target_version:, run:, release_started_at:, require_prerun:
  )
  return nil if rejection

  accelerated_shakaperf_snapshot(
    repo_slug:, run:, ref:, candidate_sha:, target_version:, release_started_at:, status: "success"
  )
end

def accelerated_shakaperf_snapshot(repo_slug:, run:, ref:, candidate_sha:, target_version:, release_started_at:,
                                   status:)
  validate_accelerated_shakaperf_run_metadata!(repo_slug:, run:)
  run_url = run.fetch("url")
  started_at = shakaperf_release_gate_time(release_started_at)
  unless run["headSha"] == candidate_sha &&
         shakaperf_release_gate_run_matches_target?(run:, ref:, head_sha: candidate_sha, target_version:) &&
         %w[pending success].include?(status) && started_at
    abort "❌ Accelerated RC ShakaPerf run identity is unknown or malformed; refusing unaudited publication."
  end

  {
    status:,
    run_id: run.fetch("databaseId"),
    attempt: run.fetch("attempt"),
    run_url:,
    candidate_sha:,
    target_version:,
    release_started_at: started_at.iso8601
  }
end

def reject_known_accelerated_shakaperf_failure!(repo_slug:, run:)
  return unless run.is_a?(Hash) && run["status"] == "completed" && run["conclusion"] != "success"

  validate_accelerated_shakaperf_run_metadata!(repo_slug:, run:)
  run_url = run.fetch("url")
  unless SHAKAPERF_RELEASE_GATE_TERMINAL_CONCLUSIONS.include?(run["conclusion"])
    abort "❌ Accelerated RC ShakaPerf result is unknown; refusing unaudited publication: #{run_url}"
  end

  abort "❌ Accelerated RC publication found a known ShakaPerf failure (#{run['conclusion']}): #{run_url}"
end

def accelerated_shakaperf_run_state!(repo_slug:, run:, unordered:)
  return :none unless run

  validate_accelerated_shakaperf_run_metadata!(repo_slug:, run:)

  status = run["status"]
  conclusion = run["conclusion"]
  if status == "completed"
    return unordered ? :ignore : :success if conclusion == "success"

    reject_known_accelerated_shakaperf_failure!(repo_slug:, run:)
  elsif SHAKAPERF_RELEASE_GATE_ACTIVE_STATUSES.include?(status)
    active_shakaperf_release_gate_run?(run)
    return unordered ? :dispatch : :active
  end

  abort "❌ Accelerated RC ShakaPerf run state is unknown or malformed; refusing unaudited publication."
end

def validate_accelerated_shakaperf_run_metadata!(repo_slug:, run:)
  return run if valid_accelerated_shakaperf_run_metadata?(repo_slug:, run:)

  abort "❌ Accelerated RC ShakaPerf run identity, URL, state, or timestamp metadata is malformed; " \
        "refusing unaudited publication."
end

def valid_accelerated_shakaperf_run_metadata?(repo_slug:, run:)
  return false unless run.is_a?(Hash)

  valid_accelerated_shakaperf_run_identity_metadata?(repo_slug:, run:) &&
    valid_accelerated_shakaperf_run_state_metadata?(run) &&
    valid_accelerated_shakaperf_run_timestamp_metadata?(run)
end

def valid_accelerated_shakaperf_run_identity_metadata?(repo_slug:, run:)
  run_id = run["databaseId"]
  positive_github_id?(run_id) && positive_github_id?(run["attempt"]) &&
    valid_accelerated_shakaperf_run_url?(repo_slug:, run_id:, url: run["url"])
end

def valid_accelerated_shakaperf_run_state_metadata?(run)
  status = run["status"]
  conclusion = run["conclusion"]
  return SHAKAPERF_RELEASE_GATE_TERMINAL_CONCLUSIONS.include?(conclusion) if status == "completed"

  SHAKAPERF_RELEASE_GATE_ACTIVE_STATUSES.include?(status) && conclusion.nil?
end

def valid_accelerated_shakaperf_run_timestamp_metadata?(run)
  created_at = accelerated_shakaperf_api_timestamp(run["createdAt"])
  updated_at = accelerated_shakaperf_api_timestamp(run["updatedAt"])
  return false unless created_at && updated_at && created_at <= updated_at

  started_at_value = run["startedAt"]
  return run["status"] == "queued" if started_at_value.nil?

  started_at = accelerated_shakaperf_api_timestamp(started_at_value)
  started_at && created_at <= started_at && started_at <= updated_at
end

def accelerated_shakaperf_api_timestamp(value)
  return nil unless value.is_a?(String)

  shakaperf_release_gate_time(value)
end

def valid_accelerated_shakaperf_run_url?(repo_slug:, run_id:, url:)
  repo_slug.is_a?(String) && repo_slug.match?(%r{\A[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\z}) &&
    positive_github_id?(run_id) &&
    url == "https://github.com/#{repo_slug}/actions/runs/#{run_id}"
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

def resolve_release_version_before_auth!(version_input:, monorepo_root:, dry_run:, current_version: nil)
  resolved_version_input = resolve_version_input(
    version_input,
    monorepo_root,
    argumentless_starting_prerelease_version: current_version
  )
  validate_requested_version_input!(resolved_version_input)
  run_release_preflight_checks!(monorepo_root:, dry_run:)
  resolved_version_input
end

def validate_supervised_release_version_after_pull!(monorepo_root:, selected_version:, dry_run:)
  return if dry_run
  return if ENV.fetch(ReleaseLeaseGuard::CONTRACT_ENV, nil).to_s.empty?

  refreshed_version = prepared_release_version_from_changelog(monorepo_root:)
  return if refreshed_version == selected_version

  abort <<~ERROR
    ❌ The prepared CHANGELOG.md release changed from #{selected_version} to #{refreshed_version || 'none'}
    after `git pull --rebase`, or its selected section is now empty.

    No publication has started. Review the refreshed changelog and rerun `script/release`
    so its release-line claim and supervised contract bind the refreshed version.
  ERROR
end

def prepared_release_version_from_changelog(monorepo_root:)
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  lines = File.readlines(changelog_path)
  ReleaseChangelogSelector.prepared_version(
    lines,
    version_pattern: ReleaseLeaseGuard::RELEASE_VERSION_PATTERN
  )
rescue Errno::ENOENT, Errno::EACCES
  nil
end

def prepared_release_version_from_changelog_at_revision(monorepo_root:, revision:)
  changelog, status = Open3.capture2e(
    "git", "-C", monorepo_root, "show", "#{revision}:CHANGELOG.md"
  )
  return nil unless status.success?

  ReleaseChangelogSelector.prepared_version(
    changelog.lines,
    version_pattern: ReleaseLeaseGuard::RELEASE_VERSION_PATTERN
  )
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

# Whether a *stable* (non-prerelease) release may run from `current_branch`.
# Stable releases are allowed from `main` (the standard path) or from the
# ephemeral `release/X.Y.Z` promotion branch whose name matches the target
# version exactly — that is how the release train promotes the last good RC to
# its final tag in place, without re-cutting from `main` (see
# internal/contributor-info/release-train-runbook.md). The exact-version match
# prevents promoting, say, `17.0.0` from `release/16.7.1`. Prereleases use the
# target-base release branch guard below so feature-branch prereleases remain
# allowed, but `release/X.Y.Z` branches cannot cut another release line.
def stable_release_branch_allowed?(current_branch:, target_gem_version:)
  ["main", "release/#{target_gem_version}"].include?(current_branch)
end

def supervised_release_branch_allowed?(current_branch:, target_gem_version:)
  return false if current_branch.to_s.empty? || target_gem_version.to_s.empty?

  if release_prerelease_version?(target_gem_version)
    current_branch == "release/#{release_base_version(target_gem_version)}"
  else
    stable_release_branch_allowed?(current_branch:, target_gem_version:)
  end
end

def release_base_version(gem_version)
  version = parse_gem_version_components(gem_version)

  "#{version[:major]}.#{version[:minor]}.#{version[:patch]}"
end

def ensure_release_branch_matches_target_base!(current_branch:, target_gem_version:)
  return unless current_branch.start_with?("release/")

  expected_release_branch = "release/#{release_base_version(target_gem_version)}"
  return if current_branch == expected_release_branch

  abort <<~ERROR
    ❌ Release branch must match the target release line.

    Current branch: #{current_branch}
    Target version: #{target_gem_version}
    Expected branch: #{expected_release_branch}

    Use the matching release branch for this target version, or run prereleases from a non-release branch.
  ERROR
end

def ensure_accelerated_rc_release_branch!(current_branch:, target_gem_version:)
  expected_release_branch = "release/#{release_base_version(target_gem_version)}"
  return if current_branch == expected_release_branch

  abort <<~ERROR
    ❌ Accelerated RC publication must run from the matching release branch.

    Current branch: #{current_branch}
    Target version: #{target_gem_version}
    Expected branch: #{expected_release_branch}

    Switch to the matching release branch before requesting or retrying accelerated RC publication.
    Ordinary non-accelerated prereleases may still run from non-release branches.
  ERROR
end

def same_release_base?(first_version, second_version)
  first_components = parse_gem_version_components(first_version)
  second_components = parse_gem_version_components(second_version)

  %i[major minor patch].all? do |component|
    first_components[component] == second_components[component]
  end
end

# True only for `rc` prereleases (e.g. 17.0.0.rc.0). beta/alpha/pre/test and
# stable versions are false. Used to gate the `release start` auto-offer to the
# rc-cut path the release train cares about.
def rc_prerelease_version?(gem_version)
  parse_gem_version_components(gem_version)[:prerelease_type] == "rc"
end

# Whether `branch` exists either locally or on `origin`. The remote check mirrors
# the abort-on-unexpected-git-error contract of `remote_git_tag_exists?` so a
# transient transport failure is never silently treated as "branch absent" — that
# would let `release start` create a branch that already exists.
#
# The two git commands signal "absent" differently:
# - `git rev-parse --verify --quiet refs/heads/<b>` exits 1 (not 2) for a
#   well-formed missing ref; `--quiet` exists precisely to collapse that into a
#   clean non-success, so (as in `peeled_git_tag_sha`) any non-success local
#   result means "not a local branch" and falls through to the remote check.
# - `git ls-remote --exit-code --heads origin refs/heads/<b>` exits 2 for "no
#   matching refs" and 0 for a hit; any other status (e.g. 128 transport error)
#   is a real failure and aborts.
def local_or_remote_branch_exists?(monorepo_root:, branch:)
  _local_output, local_status = Open3.capture2e(
    "git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/heads/#{branch}"
  )
  return true if local_status.success?

  remote_output, remote_status = Open3.capture2e(
    "git", "-C", monorepo_root, "ls-remote", "--exit-code", "--heads", "origin", "refs/heads/#{branch}"
  )
  return true if remote_status.success?
  return false if remote_status.exitstatus == 2

  abort_unexpected_branch_existence_error!(branch:, details: remote_output)
end

def abort_unexpected_branch_existence_error!(branch:, details: nil)
  message = "❌ Unable to verify whether branch #{branch.inspect} exists before starting the release line."
  message += "\n\n#{details.strip}" if details && !details.strip.empty?
  abort message
end

# Shared by `rake "release:start"` and the in-`rake release` offer: create and
# publish the `release/X.Y.Z` line off `origin/main`, then stop so CI can run on
# the fresh branch tip before rc.0 is cut. Cut + tag-rc.0 cannot be one atomic
# command — the release CI gate evaluates the branch tip, and a just-pushed
# branch has no checks yet. See internal/contributor-info/release-train-runbook.md.
def start_release_line!(monorepo_root:, release_branch:, dry_run:)
  if dry_run
    puts "ℹ️ DRY RUN: would create #{release_branch} from origin/main, push, and stop for CI"
    return
  end

  sh_in_dir_for_release(monorepo_root, "git fetch origin")

  if local_or_remote_branch_exists?(monorepo_root:, branch: release_branch)
    abort release_branch_already_exists_message(release_branch:)
  end

  sh_in_dir_for_release(monorepo_root, "git checkout -b #{release_branch} origin/main")
  sh_in_dir_for_release(monorepo_root, "git push -u origin #{release_branch}")

  puts release_line_started_next_steps(release_branch:)
end

def release_branch_already_exists_message(release_branch:)
  <<~MESSAGE.chomp
    ❌ #{release_branch} already exists.

    Preview the existing release line after selecting #{release_branch} through the guarded runbook procedure:
      bundle exec rake "release[VERSION,true]"
    #{release_version_placeholder_guidance}

    #{release_compound_live_boundary_guidance}
  MESSAGE
end

def release_line_started_next_steps(release_branch:)
  <<~MESSAGE.chomp

    ✅ Started #{release_branch} (created from origin/main and pushed).

    Next steps:
      1. Wait for at least one CI run to finish on the #{release_branch} tip
         (the release gate evaluates the branch tip; a just-pushed branch has no checks yet).
      2. Ensure the rc changelog header is present on the branch: /update-changelog rc
      3. Preview the exact CHANGELOG.md version from the branch: bundle exec rake "release[VERSION,true]"
    #{release_version_placeholder_guidance}

    #{release_compound_live_boundary_guidance}
  MESSAGE
end

# Pointer-only guidance printed when the offer cannot run interactively
# (non-TTY). It names what the guarded runbook procedure would do without
# emitting live branch-creation or push commands.
def release_branch_manual_cut_recipe(release_branch:)
  <<~MESSAGE.chomp
    The guarded runbook procedure would create #{release_branch} from origin/main and push it.
  MESSAGE
end

# The main-only / rc-only decision matrix for the in-`rake release` offer. A
# no-op unless we are on `main` cutting an `rc` — feature-branch prerelease cuts
# (the existing escape hatch) and rc.1+ cut from the release branch are
# untouched. When it does fire it either creates the release line (after a
# prompt) and exits before any tagging, or aborts with guidance.
def maybe_offer_release_branch_cut!(monorepo_root:, current_branch:, target_gem_version:, dry_run:)
  return unless current_branch == "main"
  return unless rc_prerelease_version?(target_gem_version)

  release_branch = "release/#{release_base_version(target_gem_version)}"

  case release_branch_cut_offer_decision(monorepo_root:, release_branch:, dry_run:)
  when :dry_run_branch_exists
    # Mirror the real existence-guard outcome in dry-run, so the plan is honest:
    # an existing branch would stop the offer, not create a new line.
    puts "⚠️ DRY RUN: would stop — #{release_branch_already_exists_message(release_branch:).sub(/\A❌\s*/, '')}"
  when :dry_run_create
    puts "ℹ️ DRY RUN: would offer to create #{release_branch} from origin/main and stop for CI " \
         "(rc cut detected on main)."
  when :branch_exists
    abort release_branch_already_exists_message(release_branch:)
  when :non_interactive
    abort release_branch_cut_offer_non_interactive_message(release_branch:)
  when :prompt
    prompt_and_start_release_line!(monorepo_root:, release_branch:)
  end
end

# Pure decision step so the matrix is unit-testable without exit/abort/prompt
# side effects. The existence guard is evaluated FIRST in every mode (including
# dry-run) so the dry-run plan reflects the real outcome; only after that does
# dry-run short-circuit (it must not prompt, abort, or touch the working tree).
# Then the TTY check, else prompt.
def release_branch_cut_offer_decision(monorepo_root:, release_branch:, dry_run:)
  branch_exists = local_or_remote_branch_exists?(monorepo_root:, branch: release_branch)
  return branch_exists ? :dry_run_branch_exists : :dry_run_create if dry_run
  return :branch_exists if branch_exists
  return :non_interactive unless $stdin.tty?

  :prompt
end

def release_branch_cut_offer_non_interactive_message(release_branch:)
  <<~MESSAGE.chomp
    ❌ Refusing to auto-create #{release_branch} without a terminal (non-interactive shell).

    Use the guarded runbook procedure to start the release line, then preview the release:
    #{release_branch_manual_cut_recipe(release_branch:)}
    bundle exec rake "release[VERSION,true]"
    #{release_version_placeholder_guidance}

    #{release_compound_live_boundary_guidance}
  MESSAGE
end

def release_line_legacy_live_prompt_warning(release_branch:)
  <<~WARNING.chomp
    ⚠️ LEGACY LIVE RELEASE-LINE PATH
    Answering yes will create and push #{release_branch} without the release-line lease.
    This remains technically possible only for backward compatibility and violates current repository release policy.
    Operators and agents must answer no and follow the individually guarded procedure in
    internal/contributor-info/release-train-runbook.md.
  WARNING
end

def prompt_and_start_release_line!(monorepo_root:, release_branch:)
  base_version = release_branch.delete_prefix("release/")
  puts release_line_legacy_live_prompt_warning(release_branch:)
  print "Start the #{base_version} release line now? [y/N]: "
  $stdout.flush
  answer = $stdin.gets&.strip&.downcase

  unless answer == "y"
    abort "Release aborted. No release branch was created. " \
          "Re-run when you are ready to start the #{base_version} release line."
  end

  start_release_line!(monorepo_root:, release_branch:, dry_run: false)
  exit 0
end

def peeled_git_tag_sha(monorepo_root:, tag:)
  tag_output, tag_status = Open3.capture2e(
    "git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/#{tag}^{}"
  )
  return tag_output.strip if tag_status.success?

  nil
end

def remote_git_tag_exists?(monorepo_root:, tag:)
  _output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "ls-remote", "--exit-code", "--tags", "origin", "refs/tags/#{tag}"
  )
  return true if status.success?
  return false if status.exitstatus == 2

  abort "❌ Unable to verify remote git tag #{tag.inspect} before release branch promotion."
end

def fetch_remote_release_tag!(monorepo_root:, tag:, tag_type:)
  tag_ref = "refs/tags/#{tag}"
  fetch_output, fetch_status = Open3.capture2e(
    "git", "-C", monorepo_root, "fetch", "--force", "--no-tags", "--quiet", "origin", "#{tag_ref}:#{tag_ref}"
  )
  return if fetch_status.success?

  abort "❌ Unable to fetch remote #{tag_type} tag before release branch promotion.\n\n#{fetch_output.strip}"
end

def remote_release_tags(monorepo_root:, pattern:)
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "ls-remote", "--tags", "--refs", "origin", "refs/tags/#{pattern}"
  )
  unless status.success?
    abort "❌ Unable to list remote release tags before release branch promotion.\n\n#{output.strip}"
  end

  output.lines.filter_map do |line|
    ref = line.split(/\s+/, 2).last.to_s.strip
    ref.delete_prefix("refs/tags/") if ref.start_with?("refs/tags/")
  end
end

def latest_remote_rc_tag_for_version(monorepo_root:, target_gem_version:)
  candidates = remote_rc_tag_candidates_for_version(monorepo_root:, target_gem_version:)
  validate_unambiguous_remote_rc_tag_candidates!(candidates)
  candidates.max_by { |_tag, version| version }&.first
end

def remote_rc_tag_candidates_for_version(monorepo_root:, target_gem_version:)
  remote_release_tags(monorepo_root:, pattern: "v#{target_gem_version}*").filter_map do |tag|
    remote_rc_tag_candidate(tag:, target_gem_version:)
  end
end

def validate_unambiguous_remote_rc_tag_candidates!(candidates)
  ambiguous = ambiguous_remote_rc_tag_candidates(candidates)
  if ambiguous
    tags = ambiguous.map(&:first).uniq.sort.join(", ")
    abort "❌ Stable promotion is blocked by ambiguous remote RC tags for the same normalized version: #{tags}."
  end

  candidates
end

def remote_rc_tag_for_exact_version!(monorepo_root:, rc_gem_version:)
  target_gem_version = release_base_version(rc_gem_version)
  expected_version = Gem::Version.new(rc_gem_version)
  candidates = remote_rc_tag_candidates_for_version(monorepo_root:, target_gem_version:).select do |_tag, version|
    version == expected_version
  end
  validate_unambiguous_remote_rc_tag_candidates!(candidates)
  candidates.first&.first
end

def remote_rc_tag_candidate(tag:, target_gem_version:)
  gem_version = parse_release_tag_to_gem_version(tag)
  return nil unless gem_version

  version = parse_gem_version_components(gem_version)
  return nil unless release_base_version(gem_version) == target_gem_version
  return nil unless version[:prerelease_type] == "rc"

  [tag, Gem::Version.new(gem_version)]
end

def ambiguous_remote_rc_tag_candidates(candidates)
  candidates.group_by(&:last).values.find { |entries| entries.map(&:first).uniq.length > 1 }
end

def rc_tag_ancestor?(monorepo_root:, tag_sha:, head_sha:)
  ancestor_output, ancestor_status = Open3.capture2e(
    "git", "-C", monorepo_root, "merge-base", "--is-ancestor", tag_sha, head_sha
  )
  return true if ancestor_status.success?

  if ancestor_status.exitstatus != 1
    abort "❌ Unable to verify RC tag ancestry before release branch promotion.\n\n#{ancestor_output.strip}"
  end

  false
end

def commit_shas_after_rc_tag!(monorepo_root:, tag_sha:, head_sha:)
  list_output, list_status = Open3.capture2e(
    "git", "-C", monorepo_root, "rev-list", "--reverse", "#{tag_sha}..#{head_sha}"
  )
  unless list_status.success?
    abort "❌ Unable to list commits after RC tag before release branch promotion.\n\n#{list_output.strip}"
  end

  list_output.lines.map(&:strip).reject(&:empty?)
end

def release_branch_commits_after_rc_tag(monorepo_root:, tag_sha:, head_sha:)
  # Keep direct callers tolerant of equal SHAs; the primary promotion path returns before calling this helper.
  return { status: :none, commits: [] } if tag_sha == head_sha
  return { status: :not_ancestor, commits: [] } unless rc_tag_ancestor?(monorepo_root:, tag_sha:, head_sha:)

  commits = commit_shas_after_rc_tag!(monorepo_root:, tag_sha:, head_sha:)
  metadata_only = commits.all? do |sha|
    release_branch_non_runtime_commit?(monorepo_root:, sha:)
  end
  return { status: :runtime_bearing, commits: } unless metadata_only

  { status: :non_runtime_only, commits: }
end

def release_branch_non_runtime_commit?(monorepo_root:, sha:)
  metadata_touched = release_finalization_metadata_touched(monorepo_root:, sha:)
  return false if metadata_touched.nil?
  return release_finalization_metadata_commit?(monorepo_root:, sha:) if metadata_touched

  commit_non_runtime_only?(monorepo_root:, sha:)
end

def release_finalization_metadata_touched(monorepo_root:, sha:)
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "diff-tree", "--no-commit-id", "--name-only", "-r", "#{sha}^", sha
  )
  return nil unless status.success?

  paths = output.lines.map(&:strip).reject(&:empty?)
  return nil if paths.empty?

  paths.any? { |path| RELEASE_FINALIZATION_METADATA_PATHS.include?(path) }
rescue StandardError
  nil
end

def ensure_release_branch_current_version_is_rc!(current_branch:, current_checkout_version:, target_gem_version:)
  version = parse_gem_version_components(current_checkout_version)
  if version[:prerelease_type].nil?
    abort <<~ERROR
      ❌ Stable release branch promotion must start from a tagged RC.

      Current branch: #{current_branch}
      Current version: #{current_checkout_version}
      Target version: #{target_gem_version}

      Cut and verify an RC on this release branch before promoting #{target_gem_version}.
    ERROR
  end

  return if version[:prerelease_type] == "rc" && same_release_base?(current_checkout_version, target_gem_version)

  if version[:prerelease_type] != "rc"
    abort <<~ERROR
      ❌ Stable release branch promotion must use an RC prerelease.

      Current branch: #{current_branch}
      Current version: #{current_checkout_version}
      Current prerelease type: #{version[:prerelease_type]}
      Target version: #{target_gem_version}

      Promote only from an accepted RC for #{target_gem_version}.
    ERROR
  end

  abort <<~ERROR
    ❌ Stable release branch promotion must use an RC for the target version.

    Current branch: #{current_branch}
    Current version: #{current_checkout_version}
    Target version: #{target_gem_version}

    Promote only from the accepted RC for #{target_gem_version}.
  ERROR
end

def release_tag_retry_state(monorepo_root:, release_tag:, head_sha:, current_branch:, current_checkout_version:,
                            target_gem_version:, tag_type:)
  remote_tag_exists = remote_git_tag_exists?(monorepo_root:, tag: release_tag)
  local_tag_sha = peeled_git_tag_sha(monorepo_root:, tag: release_tag)
  retry_label = "#{tag_type.capitalize} release retry"

  unless remote_tag_exists
    return :none unless local_tag_sha
    return :local if local_tag_sha == head_sha

    abort <<~ERROR
      ❌ #{retry_label} is already tagged at a different commit locally.

      Current branch: #{current_branch}
      Current version: #{current_checkout_version}
      #{tag_type.capitalize} tag: #{release_tag} (#{local_tag_sha})
      Local HEAD: #{head_sha}

      Delete the local-only tag or move to the tagged commit before retrying.
    ERROR
  end

  fetch_remote_release_tag!(monorepo_root:, tag: release_tag, tag_type:)
  local_tag_sha = peeled_git_tag_sha(monorepo_root:, tag: release_tag)
  unless local_tag_sha
    abort <<~ERROR
      ❌ #{retry_label}: #{tag_type} tag was found on the remote but could not be resolved locally after fetching.

      Expected tag: #{release_tag}
      Current branch: #{current_branch}
      Current version: #{current_checkout_version}
      Target version: #{target_gem_version}

      Try running `git fetch --force origin refs/tags/#{release_tag}:refs/tags/#{release_tag}` and retrying.
    ERROR
  end

  return :remote if local_tag_sha == head_sha

  abort <<~ERROR
    ❌ #{retry_label} is already tagged at a different commit.

    Current branch: #{current_branch}
    Current version: #{current_checkout_version}
    #{tag_type.capitalize} tag: #{release_tag} (#{local_tag_sha})
    Local HEAD: #{head_sha}

    Rerun only when the existing remote #{tag_type} tag points at the current release HEAD.
  ERROR
end

def release_tag_retry_state_for_current_head(monorepo_root:, current_branch:, current_checkout_version:,
                                             target_gem_version:, tag_type:)
  return :none unless current_checkout_version == target_gem_version

  head_sha = current_git_sha!(monorepo_root, context: "#{tag_type} release retry")
  release_tag = "v#{target_gem_version}"
  tag_retry_state = release_tag_retry_state(
    monorepo_root:,
    release_tag:,
    head_sha:,
    current_branch:,
    current_checkout_version:,
    target_gem_version:,
    tag_type:
  )

  case tag_retry_state
  when :remote
    puts "ℹ️ #{tag_type.capitalize} tag #{release_tag} already points at local HEAD; " \
         "continuing idempotent release retry."
  when :local
    puts "ℹ️ Local #{tag_type} tag #{release_tag} already points at local HEAD; " \
         "continuing retry without registry publish skips until the tag exists on origin."
  end

  tag_retry_state
end

def preflight_explicit_accelerated_rc_target_tag!(monorepo_root:, target_gem_version:, current_checkout_version:)
  tag = "v#{target_gem_version}"
  local_tag_exists = local_release_tag_exists?(monorepo_root:, tag:)
  remote_tag_exists = remote_git_tag_exists?(monorepo_root:, tag:)
  if remote_tag_exists
    fetch_remote_release_tag!(monorepo_root:, tag:, tag_type: "accelerated RC")
    local_tag_exists = true
  end
  return unless local_tag_exists

  provenance = accelerated_rc_tag_provenance_for_tag!(monorepo_root:, tag:)
  unless provenance
    abort "❌ Existing ordinary lightweight RC tag #{tag} cannot be converted to accelerated publication."
  end

  tagged_sha = peeled_git_tag_sha(monorepo_root:, tag:)
  current_sha = current_git_sha!(monorepo_root, context: "accelerated RC target-tag preflight")
  matching_retry = current_checkout_version == target_gem_version &&
                   provenance["target_version"] == target_gem_version &&
                   provenance["candidate_sha"] == tagged_sha &&
                   tagged_sha == current_sha
  return provenance if matching_retry

  abort "❌ Existing accelerated RC tag #{tag} may be retried only from its exact canonical tagged candidate."
end

def remote_release_tag_retry?(retry_state)
  retry_state == :remote
end

def release_tag_at_current_head?(retry_state)
  %i[local remote].include?(retry_state)
end

def stable_release_retry_for_current_head?(monorepo_root:, current_branch:, current_checkout_version:,
                                           target_gem_version:)
  remote_release_tag_retry?(
    release_tag_retry_state_for_current_head(
      monorepo_root:,
      current_branch:,
      current_checkout_version:,
      target_gem_version:,
      tag_type: "stable"
    )
  )
end

def stable_release_retry_state_for_current_head(monorepo_root:, current_branch:, current_checkout_version:,
                                                target_gem_version:)
  release_tag_retry_state_for_current_head(
    monorepo_root:,
    current_branch:,
    current_checkout_version:,
    target_gem_version:,
    tag_type: "stable"
  )
end

def release_branch_promotion_rc_tag!(monorepo_root:, current_branch:, current_checkout_version:, target_gem_version:)
  if release_prerelease_version?(current_checkout_version)
    ensure_release_branch_current_version_is_rc!(current_branch:, current_checkout_version:, target_gem_version:)
    rc_tag = remote_rc_tag_for_exact_version!(monorepo_root:, rc_gem_version: current_checkout_version)
    rc_tag ||= "v#{current_checkout_version}"
    return { rc_tag:, stable_tag_retry: false, stable_tag_at_head: false }
  end

  if current_checkout_version != target_gem_version
    abort <<~ERROR
      ❌ Unexpected stable checkout version before release branch promotion.

      Current branch: #{current_branch}
      Current version: #{current_checkout_version}
      Target version: #{target_gem_version}

      Expected either an RC prerelease for #{target_gem_version} or the target stable version for an in-place retry.
    ERROR
  end

  # A concurrent stable-tag push after this check is still caught by the later
  # `git push --tags`; this guard only decides whether a known tag is retry-safe.
  stable_tag_retry_state = stable_release_retry_state_for_current_head(
    monorepo_root:,
    current_branch:,
    current_checkout_version:,
    target_gem_version:
  )

  rc_tag = latest_remote_rc_tag_for_version(monorepo_root:, target_gem_version:)
  if rc_tag
    return {
      rc_tag:,
      stable_tag_retry: remote_release_tag_retry?(stable_tag_retry_state),
      stable_tag_at_head: release_tag_at_current_head?(stable_tag_retry_state)
    }
  end

  abort <<~ERROR
    ❌ Stable release branch promotion retry must descend from a remote RC tag.

    Current branch: #{current_branch}
    Current version: #{current_checkout_version}
    Target version: #{target_gem_version}

    Push and verify an RC tag for #{target_gem_version} before retrying the already-bumped final promotion.
  ERROR
end

def ensure_remote_rc_tag!(monorepo_root:, rc_tag:, current_branch:, current_checkout_version:, target_gem_version:)
  return if remote_git_tag_exists?(monorepo_root:, tag: rc_tag)

  abort <<~ERROR
    ❌ Stable release branch promotion must start from a remote RC tag.

    Expected remote tag: #{rc_tag}
    Current branch: #{current_branch}
    Current version: #{current_checkout_version}
    Target version: #{target_gem_version}
  ERROR
end

def fetch_remote_rc_tag!(monorepo_root:, rc_tag:)
  fetch_remote_release_tag!(monorepo_root:, tag: rc_tag, tag_type: "RC")
end

def abort_not_ancestor_release_branch_promotion!(current_branch:, current_checkout_version:, target_gem_version:,
                                                 rc_tag:, tag_sha:, head_sha:)
  abort "❌ Stable release branch promotion must descend from the accepted RC tag.\n\n" \
        "Current branch: #{current_branch}\n" \
        "Current version: #{current_checkout_version}\n" \
        "Expected tag: #{rc_tag} (#{tag_sha})\n" \
        "Local HEAD: #{head_sha}\n\n" \
        "The release branch tip is not reachable from #{rc_tag}. Reset this release branch to #{rc_tag}, " \
        "or cut a new RC from this branch tip before promoting #{target_gem_version}."
end

def abort_runtime_bearing_release_branch_promotion!(current_branch:, current_checkout_version:, target_gem_version:,
                                                    rc_tag:, tag_sha:, head_sha:)
  abort <<~ERROR
    ❌ Stable release branch promotion must run from the accepted RC tag or metadata-only finalization commits.

    Current branch: #{current_branch}
    Current version: #{current_checkout_version}
    Expected tag: #{rc_tag} (#{tag_sha})
    Local HEAD: #{head_sha}

    Changelog/docs/comment-only and final release metadata-only commits after #{rc_tag} are allowed.
    Runtime-bearing commits require a new RC.
    Cut a new RC from this branch tip, or reset the branch to #{rc_tag} before promoting #{target_gem_version}.
  ERROR
end

def handle_release_branch_commits_after_rc_tag!(commits_after_rc_tag:, current_branch:, current_checkout_version:,
                                                target_gem_version:, rc_tag:, tag_sha:, head_sha:)
  case commits_after_rc_tag[:status]
  when :none
    nil
  when :non_runtime_only
    puts "ℹ️ Stable release branch promotion includes #{commits_after_rc_tag[:commits].length} " \
         "metadata-only commit(s) after #{rc_tag}; preserving accepted RC runtime content."
  when :not_ancestor
    abort_not_ancestor_release_branch_promotion!(
      current_branch:,
      current_checkout_version:,
      target_gem_version:,
      rc_tag:,
      tag_sha:,
      head_sha:
    )
  when :runtime_bearing
    abort_runtime_bearing_release_branch_promotion!(
      current_branch:,
      current_checkout_version:,
      target_gem_version:,
      rc_tag:,
      tag_sha:,
      head_sha:
    )
  else
    raise "Unexpected release branch RC status: #{commits_after_rc_tag[:status].inspect}"
  end
end

def ensure_release_branch_promotes_tagged_rc!(monorepo_root:, current_branch:, current_checkout_version:,
                                              target_gem_version:)
  # RC cuts target prerelease versions, so only stable promotions match release/<final>.
  return { stable_tag_retry: false, stable_tag_at_head: false } unless current_branch == "release/#{target_gem_version}"

  promotion = release_branch_promotion_rc_tag!(
    monorepo_root:,
    current_branch:,
    current_checkout_version:,
    target_gem_version:
  )
  rc_tag = promotion.fetch(:rc_tag)

  ensure_remote_rc_tag!(monorepo_root:, rc_tag:, current_branch:, current_checkout_version:, target_gem_version:)
  fetch_remote_rc_tag!(monorepo_root:, rc_tag:)

  tag_sha = peeled_git_tag_sha(monorepo_root:, tag: rc_tag)
  unless tag_sha
    abort <<~ERROR
      ❌ Stable release branch promotion: RC tag was found on the remote but could not be resolved locally after fetching.

      Expected tag: #{rc_tag}
      Current branch: #{current_branch}
      Current version: #{current_checkout_version}
      Target version: #{target_gem_version}

      Try running `git fetch --force origin refs/tags/#{rc_tag}:refs/tags/#{rc_tag}` and retrying.
    ERROR
  end

  head_sha = current_git_sha!(monorepo_root, context: "release branch promotion")

  return promotion if tag_sha == head_sha

  commits_after_rc_tag = release_branch_commits_after_rc_tag(monorepo_root:, tag_sha:, head_sha:)
  handle_release_branch_commits_after_rc_tag!(
    commits_after_rc_tag:,
    current_branch:,
    current_checkout_version:,
    target_gem_version:,
    rc_tag:,
    tag_sha:,
    head_sha:
  )
  promotion
end

# The branch whose tip CI the release gate should validate. For a release cut or
# promoted from a `release/X.Y.Z` branch, validate that branch's tip (the frozen,
# stabilized commit set the tag is being applied to); otherwise validate `main`.
# This keeps the gate honest for both RC cuts and final promotions off a release
# branch instead of always evaluating `origin/main`, which can have drifted.
def release_ci_branch(current_branch)
  current_branch.to_s.start_with?("release/") ? current_branch : "main"
end

def npm_publish_base_args(actual_gem_version:, actual_npm_version:, current_branch:)
  npm_base_args = []
  npm_dist_tag = npm_dist_tag_for_version(actual_npm_version)
  npm_base_args += ["--tag", npm_dist_tag] unless npm_dist_tag == "latest"

  is_prerelease = release_prerelease_version?(actual_gem_version)
  is_release_branch = current_branch.to_s.start_with?("release/")

  npm_base_args << "--no-git-checks" if is_prerelease || is_release_branch
  # `--publish-branch` is pnpm-specific; `publish_npm_with_retry` shells out to `pnpm publish`.
  # --no-git-checks disables pnpm's branch guard today, but keep --publish-branch
  # on final release-branch publishes so logs document the intended branch contract.
  npm_base_args += ["--publish-branch", current_branch] if !is_prerelease && is_release_branch

  npm_base_args
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
  release_truthy?(override_flag) || release_truthy?(ENV.fetch("RELEASE_VERSION_POLICY_OVERRIDE", nil))
end

def ci_status_override_enabled?(override_flag)
  release_truthy?(override_flag) || release_truthy?(ENV.fetch("RELEASE_CI_STATUS_OVERRIDE", nil))
end

def ensure_ci_status_override_is_prerelease!(allow_override:, is_prerelease:)
  return unless allow_override && !is_prerelease

  abort "❌ CI status override is allowed only for prerelease releases; " \
        "stable/final releases require healthy CI evidence."
end

def ci_status_override_allowed_for_release!(override_flag:, is_prerelease:)
  allow_override = ci_status_override_enabled?(override_flag)
  ensure_ci_status_override_is_prerelease!(allow_override:, is_prerelease:)
  allow_override
end

def validate_canonical_accelerated_rc_target!(target_gem_version)
  target_version = target_gem_version.to_s
  return if target_version.match?(ACCELERATED_RC_CANONICAL_TARGET_PATTERN)

  if target_version.match?(ACCELERATED_RC_CANONICAL_TARGET_CASE_INSENSITIVE_PATTERN)
    abort "❌ Accelerated RC publication requires canonical lowercase `.rc.` version casing."
  end
  if target_version.match?(ACCELERATED_RC_LOOSE_TARGET_PATTERN)
    abort "❌ Accelerated RC publication requires canonical npm semver numeric identifiers without leading zeroes."
  end

  abort "❌ Accelerated publication is available for explicit RC targets only."
end

def resolve_accelerated_rc_options!(requested:, explicit_version_input:, target_gem_version:, tracker:, reason:,
                                    allow_ci_override:)
  return nil unless requested

  normalized_version_input = explicit_version_input.to_s.strip
  abort "❌ Accelerated RC publication requires an explicit RC version." if normalized_version_input.empty?
  validate_canonical_accelerated_rc_target!(target_gem_version)
  unless normalized_version_input == target_gem_version
    abort "❌ Accelerated RC publication's explicit version must exactly match the resolved RC target."
  end
  unless tracker.to_s.match?(/\A[1-9]\d*\z/)
    abort "❌ Accelerated RC publication requires a release tracker issue number."
  end
  normalized_reason = normalized_accelerated_rc_reason!(reason, action: "publication")
  abort "❌ Accelerated RC publication cannot be combined with the broad CI status override." if allow_ci_override

  {
    target_gem_version:,
    tracker: tracker.to_i,
    reason: normalized_reason,
    allow_ci_override:
  }
end

def resolve_accelerated_rc_options_for_release!(requested:, explicit_version_input:, target_gem_version:, tracker:,
                                                reason:, allow_ci_override:, repo_slug:, monorepo_root:,
                                                current_checkout_version:, candidate_sha:)
  requested_options = resolve_accelerated_rc_options!(
    requested:, explicit_version_input:, target_gem_version:, tracker:, reason:, allow_ci_override:
  )
  same_candidate_retry = rc_prerelease_version?(target_gem_version) &&
                         current_checkout_version == target_gem_version
  return requested_options unless same_candidate_retry

  selected_tracker = normalize_accelerated_rc_retry_tracker(tracker)

  unless candidate_sha.to_s.match?(/\A[0-9a-f]{40}\z/)
    abort "❌ Accelerated RC same-candidate retry discovery requires the exact current candidate SHA."
  end

  authorization_args = {
    repo_slug:, monorepo_root:, target_version: target_gem_version, candidate_sha:,
    accelerated_requested: !requested_options.nil?
  }
  authorization_args[:tracker] = selected_tracker if selected_tracker
  authorization = accelerated_rc_authorization_for_same_candidate_retry!(**authorization_args)
  return requested_options unless authorization

  validate_explicit_accelerated_rc_retry_options!(requested_options, authorization) if requested_options

  if allow_ci_override
    abort "❌ Accelerated RC retry cannot be combined with the broad CI status override, even when " \
          "RELEASE_ACCELERATED_RC was omitted."
  end

  {
    target_gem_version:,
    tracker: authorization.fetch("release_tracker"),
    reason: authorization.fetch("reason"),
    allow_ci_override: false
  }
end

def normalize_accelerated_rc_retry_tracker(tracker)
  normalized_tracker = tracker.to_s.strip
  return nil if normalized_tracker.empty?
  return normalized_tracker.to_i if normalized_tracker.match?(/\A[1-9]\d*\z/)

  abort "❌ Accelerated RC same-candidate retry tracker must be a positive issue number."
end

def validate_explicit_accelerated_rc_retry_options!(requested_options, authorization)
  canonical_options = {
    target_gem_version: authorization.fetch("target_version"),
    tracker: authorization.fetch("release_tracker"),
    reason: authorization.fetch("reason"),
    allow_ci_override: false
  }
  return canonical_options if requested_options == canonical_options

  abort "❌ Explicit accelerated RC retry options must match the durable canonical authorization."
end

def normalized_accelerated_rc_reason!(reason, action:)
  normalized_reason = reason.to_s.strip
  abort "❌ Accelerated RC #{action} requires a maintainer reason." if normalized_reason.empty?
  if normalized_reason.match?(/[\r\n\0]/) || normalized_reason.include?("<!--") ||
     normalized_reason.include?("-->") || normalized_reason.length > 500
    abort "❌ Accelerated RC #{action}'s maintainer reason must be single-line plain text."
  end

  normalized_reason
end

def accelerated_rc_tracker_comment(record)
  marker = "#{ACCELERATED_RC_RECORD_MARKER_OPENER}v#{ACCELERATED_RC_RECORD_SCHEMA_VERSION} " \
           "#{canonical_accelerated_rc_encoded_payload(record)} -->"
  ci = record.fetch("ci")
  shakaperf = record.fetch("shakaperf")

  <<~MARKDOWN
    #{marker}
    ### Accelerated RC gate record — `#{record.fetch('status')}`

    - RC: `#{record.fetch('target_version')}` at `#{record.fetch('candidate_sha')}`
    - Exact-head CI: `#{ci.fetch('status')}` — #{ci.fetch('checks_url')}
    - ShakaPerf: `#{shakaperf.fetch('status')}` — #{shakaperf.fetch('run_url')}
    - Maintainer: `#{record.fetch('approved_by')}` at `#{record.fetch('recorded_at')}`
    - Reason: #{record.fetch('reason')}
  MARKDOWN
end

def accelerated_rc_records_from_comments(comments)
  comments.flat_map { |comment| accelerated_rc_records_from_comment(comment) }
end

def accelerated_rc_machine_marker_comment?(comment)
  return false unless comment.is_a?(Hash) && comment["body"].is_a?(String)

  comment.fetch("body").include?(ACCELERATED_RC_RECORD_MARKER_OPENER)
end

def accelerated_rc_records_from_comment(comment)
  return [] unless accelerated_rc_machine_marker_comment?(comment)

  body = comment.fetch("body")
  marker_count = body.scan(ACCELERATED_RC_RECORD_MARKER_OPENER).length
  abort "❌ Release tracker contains a malformed accelerated RC record." unless marker_count == 1

  opener = Regexp.escape(ACCELERATED_RC_RECORD_MARKER_OPENER)
  matches = body.scan(/#{opener}v(\d+) ([0-9a-fA-F]+) -->/)
  abort "❌ Release tracker contains a malformed accelerated RC record." unless matches.one?

  matches.map do |schema_version, encoded_payload|
    unless schema_version.to_i == ACCELERATED_RC_RECORD_SCHEMA_VERSION
      abort "❌ Release tracker contains an unsupported accelerated RC record schema."
    end

    abort "❌ Release tracker contains a malformed accelerated RC record." unless encoded_payload.length.even?

    record = JSON.parse([encoded_payload].pack("H*"))
    validate_accelerated_rc_tracker_record!(record)
    validate_canonical_accelerated_rc_encoded_payload!(record:, encoded_payload:)
  rescue ArgumentError, JSON::ParserError
    abort "❌ Release tracker contains a malformed accelerated RC record."
  end
end

def validate_accelerated_rc_tracker_record!(record)
  abort "❌ Release tracker contains a malformed accelerated RC record." unless
    valid_accelerated_rc_tracker_record?(record)

  record
end

def valid_accelerated_rc_tracker_record?(record)
  valid_accelerated_rc_identity?(record) && valid_accelerated_rc_audit_metadata?(record) &&
    valid_accelerated_rc_ci_record?(record["ci"], record["candidate_sha"]) &&
    valid_accelerated_rc_shakaperf_record?(record["shakaperf"], record["target_version"]) &&
    valid_accelerated_rc_deferred_shakaperf_candidate?(record) &&
    valid_accelerated_rc_state?(record)
end

def valid_accelerated_rc_deferred_shakaperf_candidate?(record)
  shakaperf = record.fetch("shakaperf")
  shakaperf["status"] != "pending" || shakaperf["candidate_sha"] == record.fetch("candidate_sha")
end

def accelerated_rc_exact_keys?(value, expected_keys)
  value.is_a?(Hash) && value.length == expected_keys.length && expected_keys.all? { |key| value.key?(key) }
end

def valid_accelerated_rc_state?(record)
  gate_statuses = [record.dig("ci", "status"), record.dig("shakaperf", "status")]
  case record["status"]
  when *ACCELERATED_RC_PENDING_STATUSES
    record["evidence"].empty? && gate_statuses.none?("failed")
  when "candidate-accepted"
    accelerated_rc_gate_evidence_complete?(record)
  when "candidate-rejected"
    record["evidence"].empty? && gate_statuses.include?("failed")
  else
    false
  end
end

def valid_accelerated_rc_identity?(record)
  accelerated_rc_exact_keys?(record, ACCELERATED_RC_RECORD_FIELDS) &&
    record["schema_version"] == ACCELERATED_RC_RECORD_SCHEMA_VERSION &&
    ACCELERATED_RC_RECORD_STATUSES.include?(record["status"]) &&
    record["target_version"].to_s.match?(ACCELERATED_RC_CANONICAL_TARGET_PATTERN) &&
    record["candidate_sha"].to_s.match?(/\A[0-9a-f]{40}\z/) &&
    record["runtime_tree_fingerprint"].to_s.match?(/\A[0-9a-f]{64}\z/)
end

def valid_accelerated_rc_audit_metadata?(record)
  valid_accelerated_rc_nonempty_string?(record["release_branch"]) &&
    valid_accelerated_rc_tracker_number?(record["release_tracker"]) && record["evidence"].is_a?(Hash) &&
    valid_accelerated_rc_nonempty_string?(record["approved_by"]) &&
    valid_accelerated_rc_reason?(record["reason"]) &&
    valid_accelerated_rc_nonempty_string?(record["required_follow_up"]) &&
    !shakaperf_release_gate_time(record["recorded_at"]).nil?
end

def valid_accelerated_rc_nonempty_string?(value)
  value.is_a?(String) && !value.empty?
end

def valid_accelerated_rc_tracker_number?(value)
  value.is_a?(Integer) && value.positive?
end

def valid_accelerated_rc_reason?(reason)
  reason.is_a?(String) && !reason.strip.empty? && reason.length <= 500 && !reason.match?(/[\r\n\0]/) &&
    !reason.include?("<!--") && !reason.include?("-->")
end

def valid_accelerated_rc_ci_record?(ci_snapshot, candidate_sha)
  return false unless ci_snapshot.is_a?(Hash)

  checks = ci_snapshot["non_success"]
  valid_accelerated_rc_ci_identity?(ci_snapshot, candidate_sha) &&
    checks.is_a?(Array) && checks.all? { |check| valid_accelerated_rc_ci_check?(check) } &&
    valid_accelerated_rc_ci_status?(ci_snapshot["status"], checks)
end

def valid_accelerated_rc_ci_identity?(ci_snapshot, candidate_sha)
  accelerated_rc_exact_keys?(ci_snapshot, ACCELERATED_RC_CI_FIELDS) &&
    %w[pending success failed].include?(ci_snapshot["status"]) &&
    ci_snapshot["sha"] == candidate_sha && valid_accelerated_rc_https_url?(ci_snapshot["checks_url"])
end

def valid_accelerated_rc_ci_status?(status, checks)
  failed, pending = accelerated_rc_ci_state_flags(checks)
  case status
  when "success" then !failed && !pending
  when "pending" then pending && !failed
  when "failed" then failed
  else false
  end
end

def accelerated_rc_ci_state_flags(checks)
  states = checks.map { |check| check["state"] }
  [
    states.any? { |state| accelerated_rc_failed_ci_state?(state) },
    states.any? { |state| CI_INCOMPLETE_STATUSES.include?(state) }
  ]
end

def accelerated_rc_failed_ci_state?(state)
  !CI_INCOMPLETE_STATUSES.include?(state) && !CI_PASSING_CONCLUSIONS.include?(state)
end

def valid_accelerated_rc_ci_check?(check)
  accelerated_rc_exact_keys?(check, ACCELERATED_RC_CI_CHECK_FIELDS) &&
    valid_accelerated_rc_nonempty_string?(check["name"]) &&
    valid_accelerated_rc_nonempty_string?(check["state"]) &&
    valid_accelerated_rc_https_url?(check["url"])
end

def valid_accelerated_rc_shakaperf_record?(shakaperf, target_version)
  return false unless shakaperf.is_a?(Hash) && %w[pending success failed].include?(shakaperf["status"])

  expected_fields = ACCELERATED_RC_SHAKAPERF_FIELDS + (shakaperf["status"] == "failed" ? ["conclusion"] : [])
  accelerated_rc_exact_keys?(shakaperf, expected_fields) && valid_accelerated_rc_shakaperf_identity?(shakaperf) &&
    shakaperf["target_version"] == target_version && valid_accelerated_rc_shakaperf_conclusion?(shakaperf)
end

def valid_accelerated_rc_shakaperf_identity?(shakaperf)
  shakaperf["run_id"].is_a?(Integer) && shakaperf["run_id"].positive? &&
    shakaperf["attempt"].is_a?(Integer) && shakaperf["attempt"].positive? &&
    valid_accelerated_rc_https_url?(shakaperf["run_url"]) &&
    shakaperf["candidate_sha"].to_s.match?(/\A[0-9a-f]{40}\z/) &&
    shakaperf["target_version"].to_s.match?(ACCELERATED_RC_CANONICAL_TARGET_PATTERN) &&
    !shakaperf_release_gate_time(shakaperf["release_started_at"]).nil?
end

def valid_accelerated_rc_shakaperf_conclusion?(shakaperf)
  shakaperf["status"] != "failed" ||
    (SHAKAPERF_RELEASE_GATE_TERMINAL_CONCLUSIONS.include?(shakaperf["conclusion"]) &&
      shakaperf["conclusion"] != "success")
end

def valid_accelerated_rc_https_url?(value)
  uri = URI.parse(value.to_s)
  uri.is_a?(URI::HTTPS) && !uri.host.to_s.empty? && uri.userinfo.nil?
rescue URI::InvalidURIError
  false
end

def fetch_release_tracker_comments(repo_slug:, tracker:)
  fetch_bounded_accelerated_rc_marker_comments!(repo_slug:, tracker:)
end

def fetch_accelerated_rc_tracker_records!(repo_slug:, tracker:)
  comments = fetch_release_tracker_comments(repo_slug:, tracker:)
  marker_comments = comments.select { |comment| accelerated_rc_machine_marker_comment?(comment) }
  permissions = {}
  records = marker_comments.flat_map do |comment|
    login = accelerated_rc_comment_author_login!(comment)
    permission = accelerated_rc_repository_comment_permission!(repo_slug:, login:, permissions:)
    permission_class = accelerated_rc_repository_permission_class!(permission:, login:)
    next [] if permission_class == :non_maintainer

    accelerated_rc_records_from_trusted_comment!(comment:, login:)
  end

  unless records.all? { |record| record["release_tracker"] == tracker }
    abort "❌ Accelerated RC record is bound to a different release tracker."
  end

  records
end

def fetch_repository_accelerated_rc_records_for_candidate!(repo_slug:, target_version:, candidate_sha:)
  candidate_commit_time = accelerated_rc_candidate_comment_lower_bound!(repo_slug:, candidate_sha:)
  candidate_comment_since = (shakaperf_release_gate_time(candidate_commit_time) - 1).utc.iso8601
  comments = fetch_repository_issue_comments_for_accelerated_rc_retry!(
    repo_slug:, since: candidate_comment_since
  )
  marker_comments = comments.select do |comment|
    next false unless accelerated_rc_machine_marker_comment?(comment)

    accelerated_rc_comment_author_login!(comment)

    repository_accelerated_rc_comment_plausibly_targets_candidate?(
      comment:, target_version:, candidate_sha:
    )
  end
  permissions = {}
  tracker_issues = {}
  records = marker_comments.flat_map do |comment|
    trusted_accelerated_rc_records_from_repository_comment!(
      comment:, repo_slug:, permissions:, tracker_issues:
    )
  end

  candidate_records = accelerated_rc_records_for_candidate(records, target_version:, candidate_sha:)
  validate_accelerated_rc_candidate_record_times!(candidate_records, candidate_commit_time)
  candidate_records
end

def accelerated_rc_candidate_comment_lower_bound!(repo_slug:, candidate_sha:)
  output, status = capture_gh_output(
    "api", "repos/#{repo_slug}/commits/#{candidate_sha}", "--jq", ".commit.committer.date"
  )
  abort "❌ Unable to establish the candidate commit time for bounded accelerated RC history.\n\n#{output}" unless
    status.success?

  timestamp = output.strip
  commit_time = shakaperf_release_gate_time(timestamp)
  if commit_time.nil? || commit_time > Time.now.utc
    abort "❌ Candidate commit time is missing, malformed, or in the future; durable retry history is unknown."
  end

  commit_time.utc.iso8601
end

def validate_accelerated_rc_candidate_record_times!(records, lower_bound)
  lower_bound_time = shakaperf_release_gate_time(lower_bound)
  valid = lower_bound_time && records.all? do |record|
    recorded_at = shakaperf_release_gate_time(record["recorded_at"])
    recorded_at && recorded_at >= lower_bound_time
  end
  abort "❌ Accelerated RC history predates the candidate commit; durable retry history is invalid." unless valid
end

def validated_repository_accelerated_rc_candidate_history!(
  repo_slug:, target_version:, candidate_sha:, expected_tracker: nil,
  selected_authorization: nil, allow_empty: false
)
  records = fetch_repository_accelerated_rc_records_for_candidate!(repo_slug:, target_version:, candidate_sha:)
  if records.empty?
    return { records:, tracker: nil, chain: nil } if allow_empty

    abort "❌ Repository-wide accelerated RC history is missing for the exact candidate."
  end

  trackers = records.map { |record| record["release_tracker"] }.uniq
  abort "❌ Repository-wide accelerated RC history contains conflicting release trackers." unless trackers.one?

  tracker = trackers.first
  if expected_tracker && tracker != expected_tracker
    abort "❌ Repository-wide accelerated RC history is bound to a different release tracker."
  end

  chain = validated_accelerated_rc_candidate_chain!(records, selected_authorization:)
  { records:, tracker:, chain: }
end

def repository_accelerated_rc_comment_plausibly_targets_candidate?(comment:, target_version:, candidate_sha:)
  return false unless accelerated_rc_machine_marker_comment?(comment)

  body = comment.fetch("body")
  return true if body.include?("- RC: `#{target_version}` at `#{candidate_sha}`")

  marker_count = body.scan(ACCELERATED_RC_RECORD_MARKER_OPENER).length
  opener = Regexp.escape(ACCELERATED_RC_RECORD_MARKER_OPENER)
  matches = body.scan(/#{opener}v(\d+) ([0-9a-fA-F]+) -->/)
  return true unless marker_count == 1 && matches.one?

  identities = matches.map do |schema_version, encoded_payload|
    repository_accelerated_rc_marker_candidate_identity(schema_version:, encoded_payload:)
  end
  return true if identities.any?(&:nil?)

  identities.include?([target_version, candidate_sha])
end

def repository_accelerated_rc_marker_candidate_identity(schema_version:, encoded_payload:)
  return nil unless schema_version.to_i == ACCELERATED_RC_RECORD_SCHEMA_VERSION
  return nil unless encoded_payload.length.even?

  decoded_payload = [encoded_payload].pack("H*")
  record = JSON.parse(decoded_payload)
  return nil unless valid_accelerated_rc_tracker_record?(record)
  return nil unless encoded_payload == canonical_accelerated_rc_encoded_payload(record)

  target_version, candidate_sha = record.values_at("target_version", "candidate_sha")
  [target_version, candidate_sha]
rescue ArgumentError, JSON::ParserError
  nil
end

def valid_accelerated_rc_comment_schema_shape?(comment)
  comment.is_a?(Hash) &&
    comment["id"].is_a?(Integer) && comment["id"].positive? &&
    comment["body"].is_a?(String) &&
    comment["created_at"].is_a?(String) &&
    comment["updated_at"].is_a?(String)
end

def accelerated_rc_comment_timestamps!(comment)
  created_at = Time.iso8601(comment.fetch("created_at"))
  updated_at = Time.iso8601(comment.fetch("updated_at"))
  if accelerated_rc_machine_marker_comment?(comment) && updated_at != created_at
    abort "❌ Edited accelerated RC marker comment detected; durable history must remain append-only."
  end

  [created_at, updated_at]
end

def validate_accelerated_rc_comment_schema!(comment:, repo_slug:)
  unless valid_accelerated_rc_comment_schema_shape?(comment)
    abort "❌ Accelerated RC comment page contains an invalid comment schema."
  end

  tracker = release_tracker_number_from_repository_comment_issue_url!(
    issue_url: comment["issue_url"], repo_slug:
  )
  created_at, updated_at = accelerated_rc_comment_timestamps!(comment)

  # Every API comment needs trustworthy chronology. GitHub can retain an ordinary comment after its author is deleted;
  # marker records additionally must be unedited and require an attributable trusted author later.
  { id: comment.fetch("id"), tracker:, created_at:, updated_at: }
rescue ArgumentError
  abort "❌ Accelerated RC comment page contains an invalid comment schema."
end

def validate_accelerated_rc_comment_identity!(comment:, repo_slug:, state:, expected_tracker:)
  metadata = validate_accelerated_rc_comment_schema!(comment:, repo_slug:)
  if expected_tracker && metadata.fetch(:tracker) != expected_tracker
    abort "❌ Accelerated RC comment page contains an issue URL inconsistent with its selected tracker."
  end

  comment_id = metadata.fetch(:id)
  seen_ids = state.fetch(:seen_ids)
  abort "❌ Accelerated RC comment pages contain a duplicate comment ID." if seen_ids.key?(comment_id)

  created_at = metadata.fetch(:created_at)
  previous_created_at = state[:last_created_at]
  if previous_created_at && created_at < previous_created_at
    abort "❌ Accelerated RC comment pages are out of chronological order."
  end

  seen_ids[comment_id] = true
  state[:last_created_at] = created_at
  metadata
end

def accelerated_rc_comment_page_endpoint(repo_slug:, tracker:, page:, since: nil)
  resource = tracker ? "repos/#{repo_slug}/issues/#{tracker}/comments" : "repos/#{repo_slug}/issues/comments"
  endpoint = "#{resource}?per_page=#{ACCELERATED_RC_REPOSITORY_COMMENT_PAGE_SIZE}" \
             "&sort=created&direction=asc&page=#{page}"
  since ? "#{endpoint}&since=#{URI.encode_www_form_component(since)}" : endpoint
end

def accelerated_rc_comment_source_label(tracker)
  tracker ? "release tracker ##{tracker}" : "repository"
end

def fetch_accelerated_rc_comment_page!(repo_slug:, tracker:, page:, state:, since: nil)
  endpoint = accelerated_rc_comment_page_endpoint(repo_slug:, tracker:, page:, since:)
  output, status = capture_gh_output("api", endpoint)
  source = accelerated_rc_comment_source_label(tracker)
  abort "❌ Unable to read #{source} comments for accelerated RC history.\n\n#{output}" unless status.success?

  comments = JSON.parse(output)
  valid = comments.is_a?(Array) && comments.length <= ACCELERATED_RC_REPOSITORY_COMMENT_PAGE_SIZE &&
          comments.all?(Hash)
  if valid
    comments.each do |comment|
      validate_accelerated_rc_comment_identity!(
        comment:, repo_slug:, state:, expected_tracker: tracker
      )
    end
    return comments
  end

  abort "❌ #{source.capitalize} comments returned an unexpected JSON structure."
rescue JSON::ParserError => e
  abort "❌ #{source.capitalize} comments returned invalid JSON: #{e.message}"
end

def fetch_bounded_accelerated_rc_marker_comments!(repo_slug:, tracker: nil, since: nil)
  marker_comments = []
  state = { seen_ids: {}, last_created_at: nil }
  1.upto(ACCELERATED_RC_REPOSITORY_COMMENT_MAX_PAGES) do |page|
    comments = fetch_accelerated_rc_comment_page!(repo_slug:, tracker:, page:, state:, since:)

    marker_comments.concat(
      comments.select { |comment| accelerated_rc_machine_marker_comment?(comment) }
    )
    if marker_comments.length > ACCELERATED_RC_REPOSITORY_MARKER_COMMENT_LIMIT
      source = accelerated_rc_comment_source_label(tracker)
      abort "❌ Bounded #{source} accelerated-marker limit was exceeded; durable retry history is unknown."
    end

    return marker_comments if comments.length < ACCELERATED_RC_REPOSITORY_COMMENT_PAGE_SIZE
  end

  source = accelerated_rc_comment_source_label(tracker)
  abort "❌ Bounded #{source} issue-comment page limit was reached; durable retry history is unknown."
end

def fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug:, tracker: nil, since: nil)
  fetch_bounded_accelerated_rc_marker_comments!(repo_slug:, tracker:, since:)
end

def trusted_accelerated_rc_records_from_repository_comment!(
  comment:, repo_slug:, permissions:, tracker_issues: {}
)
  login = accelerated_rc_comment_author_login!(comment)
  tracker = release_tracker_number_from_repository_comment_issue_url!(
    issue_url: comment.fetch("issue_url", nil), repo_slug:
  )

  permission = accelerated_rc_repository_comment_permission!(repo_slug:, login:, permissions:)
  permission_class = accelerated_rc_repository_permission_class!(permission:, login:)
  return [] if permission_class == :non_maintainer

  records = accelerated_rc_records_from_trusted_comment!(comment:, login:)
  unless records.all? { |record| record["release_tracker"] == tracker }
    abort "❌ Accelerated RC retry history is bound to a different release tracker."
  end
  records.each do |record|
    target_version = record.fetch("target_version")
    if tracker_issues.key?(tracker)
      validate_release_tracker_issue!(tracker_issues.fetch(tracker), tracker:, target_version:)
    else
      tracker_issues[tracker] = fetch_release_tracker_issue!(repo_slug:, tracker:, target_version:)
    end
  end

  records
end

def accelerated_rc_comment_author_login!(comment)
  unless comment.is_a?(Hash) && comment.key?("user")
    abort "❌ Accelerated RC marker author envelope is malformed; durable history is unknown."
  end

  user = comment.fetch("user")
  abort "❌ Accelerated RC machine-marker author is unattributable; durable history is unknown." if user.nil?

  valid = user.is_a?(Hash) && user.key?("login") && user["login"].is_a?(String) && !user["login"].empty?
  abort "❌ Accelerated RC marker author envelope is malformed; durable history is unknown." unless valid

  user.fetch("login")
end

def release_tracker_number_from_repository_comment_issue_url!(issue_url:, repo_slug:)
  canonical_issue_url = %r{\Ahttps://api\.github\.com/repos/#{Regexp.escape(repo_slug)}/issues/([1-9]\d*)\z}
  tracker = issue_url.match(canonical_issue_url)&.captures&.first&.to_i if issue_url.is_a?(String)
  return tracker if tracker

  abort "❌ Accelerated RC retry history must name an exact requested repository issue URL."
end

def accelerated_rc_repository_comment_permission!(repo_slug:, login:, permissions:)
  if permissions.key?(login)
    permission = permissions.fetch(login)
  else
    output, status = capture_gh_output(
      "api", "repos/#{repo_slug}/collaborators/#{login}/permission", "--jq", ".permission"
    )
    unless status.success?
      abort "❌ Unable to verify the repository permission of accelerated RC record author #{login}.\n\n#{output}"
    end

    permission = output.strip
  end

  accelerated_rc_repository_permission_class!(permission:, login:)
  permissions[login] = permission
end

def accelerated_rc_repository_permission_class!(permission:, login:)
  return :maintainer if ACCELERATED_RC_MAINTAINER_PERMISSIONS.include?(permission)
  return :non_maintainer if ACCELERATED_RC_NON_MAINTAINER_PERMISSIONS.include?(permission)

  abort "❌ Accelerated RC repository permission for #{login} is unknown; durable history cannot be ignored or trusted."
end

def accelerated_rc_records_from_trusted_comment!(comment:, login:)
  records = accelerated_rc_records_from_comment(comment)
  unless records.all? { |record| record["approved_by"] == login }
    abort "❌ Accelerated RC record approver does not match its trusted comment author."
  end

  records
end

def validate_release_tracker_issue!(issue, tracker:, target_version:)
  expected_title = "Release gate: react_on_rails #{release_base_version(target_version)}"
  eligible = issue["number"] == tracker && issue["state"] == "open" && issue["pull_request"].nil? &&
             issue["title"] == expected_title
  unless eligible
    abort "❌ Accelerated RC publication requires an active open release tracker with the exact title " \
          "#{expected_title.inspect}; ##{tracker} is not eligible."
  end

  issue
end

def fetch_release_tracker_issue!(repo_slug:, tracker:, target_version:)
  output, status = capture_gh_output("api", "repos/#{repo_slug}/issues/#{tracker}")
  abort "❌ Unable to read release tracker ##{tracker}.\n\n#{output}" unless status.success?

  validate_release_tracker_issue!(JSON.parse(output), tracker:, target_version:)
rescue JSON::ParserError => e
  abort "❌ Release tracker ##{tracker} returned invalid JSON: #{e.message}"
end

def validate_release_approver!(login:, permission:)
  unless valid_release_approver_permission?(permission)
    abort "❌ Accelerated RC approval requires write, maintain, or admin repository permission for #{login}."
  end

  login
end

def valid_release_approver_permission?(permission)
  ACCELERATED_RC_MAINTAINER_PERMISSIONS.include?(permission)
end

def current_release_approver!(repo_slug:)
  login_output, login_status = capture_gh_output("api", "user", "--jq", ".login")
  abort "❌ Unable to identify the GitHub account approving accelerated RC publication.\n\n#{login_output}" unless
    login_status.success?

  login = login_output.strip
  permission_output, permission_status = capture_gh_output(
    "api", "repos/#{repo_slug}/collaborators/#{login}/permission", "--jq", ".permission"
  )
  unless permission_status.success?
    abort "❌ Unable to verify repository permission for accelerated RC approver #{login}.\n\n#{permission_output}"
  end

  validate_release_approver!(login:, permission: permission_output.strip)
end

def post_release_tracker_comment!(repo_slug:, tracker:, body:)
  Tempfile.create(["accelerated-rc-record", ".md"]) do |file|
    file.write(body)
    file.flush
    release_write_fence!("post release tracker comment")
    output, status = capture_gh_output(
      "issue", "comment", tracker.to_s, "--repo", repo_slug, "--body-file", file.path
    )
    abort "❌ Unable to append accelerated RC evidence to release tracker ##{tracker}.\n\n#{output}" unless
      status.success?
  end
end

def validate_repository_accelerated_rc_authorization_append!(repo_slug:, tracker:, record:, allow_empty:)
  return unless record["status"] == "publication-authorized"

  history = validated_repository_accelerated_rc_candidate_history!(
    repo_slug:,
    target_version: record.fetch("target_version"),
    candidate_sha: record.fetch("candidate_sha"),
    expected_tracker: tracker,
    selected_authorization: record,
    allow_empty:
  )
  abort_if_accelerated_rc_retry_rejected!(history.fetch(:records)) unless history.fetch(:records).empty?
  history
end

def append_accelerated_rc_tracker_record!(repo_slug:, tracker:, record:)
  validate_accelerated_rc_tracker_record!(record)
  validate_repository_accelerated_rc_authorization_append!(repo_slug:, tracker:, record:, allow_empty: true)
  records = fetch_accelerated_rc_tracker_records!(repo_slug:, tracker:)
  validate_accelerated_rc_candidate_state_before_append!(records, record)

  same_identity = records.select do |existing|
    ACCELERATED_RC_RECORD_IDENTITY_FIELDS.all? { |field| existing[field] == record[field] }
  end
  duplicate = same_identity.find { |existing| accelerated_rc_same_identity_retry_equivalent?(existing, record) }
  return duplicate if duplicate

  unless same_identity.empty?
    abort "❌ Conflicting accelerated RC tracker record already exists for this status, version, and candidate."
  end

  post_release_tracker_comment!(repo_slug:, tracker:, body: accelerated_rc_tracker_comment(record))
  refreshed_records = fetch_accelerated_rc_tracker_records!(repo_slug:, tracker:)
  validate_accelerated_rc_candidate_state_before_append!(refreshed_records, record)
  posted_digest = accelerated_rc_record_digest(record)
  persisted = refreshed_records.find { |existing| accelerated_rc_record_digest(existing) == posted_digest }
  abort "❌ Accelerated RC tracker append could not be verified after posting; refusing to continue." unless persisted

  validate_repository_accelerated_rc_authorization_append!(repo_slug:, tracker:, record:, allow_empty: false)

  persisted
end

def validate_accelerated_rc_candidate_state_before_append!(records, record)
  candidate_records = accelerated_rc_records_for_candidate(
    records,
    target_version: record.fetch("target_version"),
    candidate_sha: record.fetch("candidate_sha")
  )
  validate_accelerated_rc_terminal_before_append!(candidate_records, record)

  proposed_state = candidate_records + [record]
  validated_accelerated_rc_candidate_chain!(
    proposed_state,
    require_publication: ACCELERATED_RC_TERMINAL_STATUSES.include?(record["status"])
  )
end

def validate_accelerated_rc_terminal_before_append!(candidate_records, record)
  terminal = validated_accelerated_rc_terminal_set!(candidate_records)
  return unless terminal && !accelerated_rc_retry_equivalent?(terminal, record)

  if terminal["status"] == "candidate-rejected"
    abort "❌ Accelerated RC candidate was permanently rejected; candidate-rejected is absorbing and no later " \
          "state transition may be appended."
  end

  abort "❌ Accelerated RC candidate is already terminal; only a retry-equivalent terminal record is idempotent."
end

def accelerated_rc_same_identity_retry_equivalent?(left, right)
  if left["status"] == "published-awaiting-gates" && right["status"] == "published-awaiting-gates"
    accelerated_rc_publication_completion_equivalent?(left, right)
  else
    accelerated_rc_retry_equivalent?(left, right)
  end
end

def accelerated_rc_retry_equivalent?(left, right)
  canonical_accelerated_rc_value(left.except("recorded_at")) ==
    canonical_accelerated_rc_value(right.except("recorded_at"))
end

def accelerated_rc_record_bound_to_authorization?(record, authorization)
  ACCELERATED_RC_AUTHORIZATION_BOUND_FIELDS.all? { |field| record[field] == authorization[field] } &&
    ACCELERATED_RC_CI_BOUND_FIELDS.all? { |field| record.dig("ci", field) == authorization.dig("ci", field) } &&
    ACCELERATED_RC_SHAKAPERF_BOUND_FIELDS.all? do |field|
      record.dig("shakaperf", field) == authorization.dig("shakaperf", field)
    end
end

def canonical_accelerated_rc_value(value)
  case value
  when Hash
    value.keys.sort.to_h { |key| [key, canonical_accelerated_rc_value(value.fetch(key))] }
  when Array
    value.map { |item| canonical_accelerated_rc_value(item) }
  else
    value
  end
end

def canonical_accelerated_rc_json(value)
  JSON.generate(canonical_accelerated_rc_value(value))
end

def canonical_accelerated_rc_encoded_payload(record)
  canonical_accelerated_rc_json(record).unpack1("H*")
end

def validate_canonical_accelerated_rc_encoded_payload!(record:, encoded_payload:)
  return record if encoded_payload == canonical_accelerated_rc_encoded_payload(record)

  abort "❌ Release tracker contains a malformed accelerated RC record."
end

def accelerated_rc_record_digest(record)
  Digest::SHA256.hexdigest(canonical_accelerated_rc_json(record))
end

def accelerated_rc_tag_provenance(record)
  validate_accelerated_rc_tracker_record!(record)
  {
    "schema_version" => ACCELERATED_RC_RECORD_SCHEMA_VERSION,
    "target_version" => record.fetch("target_version"),
    "candidate_sha" => record.fetch("candidate_sha"),
    "release_tracker" => record.fetch("release_tracker"),
    "authorization_digest" => accelerated_rc_record_digest(record)
  }
end

def valid_accelerated_rc_tag_provenance?(provenance)
  accelerated_rc_exact_keys?(provenance, ACCELERATED_RC_TAG_PROVENANCE_FIELDS) &&
    provenance["schema_version"] == ACCELERATED_RC_RECORD_SCHEMA_VERSION &&
    provenance["target_version"].to_s.match?(ACCELERATED_RC_CANONICAL_TARGET_PATTERN) &&
    provenance["candidate_sha"].to_s.match?(/\A[0-9a-f]{40}\z/) &&
    valid_accelerated_rc_tracker_number?(provenance["release_tracker"]) &&
    provenance["authorization_digest"].to_s.match?(/\A[0-9a-f]{64}\z/)
end

def accelerated_rc_tag_message(record)
  provenance = accelerated_rc_tag_provenance(record)
  "#{ACCELERATED_RC_TAG_PROVENANCE_MARKER} v#{ACCELERATED_RC_RECORD_SCHEMA_VERSION} " \
    "#{JSON.generate(provenance).unpack1('H*')}"
end

def accelerated_rc_tag_provenance_from_message(message)
  marker = Regexp.escape(ACCELERATED_RC_TAG_PROVENANCE_MARKER)
  marker_count = message.to_s.scan(/#{marker}\b/).length
  return nil if marker_count.zero?

  matches = message.to_s.scan(/#{marker} v(\d+) ([0-9a-f]+)/)
  abort "❌ Accelerated RC tag contains malformed provenance." unless marker_count == 1 && matches.length == 1

  schema_version, encoded_payload = matches.first
  unless schema_version.to_i == ACCELERATED_RC_RECORD_SCHEMA_VERSION && encoded_payload.length.even?
    abort "❌ Accelerated RC tag contains unsupported or malformed provenance."
  end
  provenance = JSON.parse([encoded_payload].pack("H*"))
  abort "❌ Accelerated RC tag contains malformed provenance." unless valid_accelerated_rc_tag_provenance?(provenance)

  provenance
rescue ArgumentError, JSON::ParserError
  abort "❌ Accelerated RC tag contains malformed provenance."
end

def accelerated_rc_tag_provenance_for_tag!(monorepo_root:, tag:)
  type, type_status = Open3.capture2e("git", "-C", monorepo_root, "cat-file", "-t", "refs/tags/#{tag}")
  abort "❌ Unable to inspect RC tag provenance for #{tag}: #{type}" unless type_status.success?
  return nil if type.strip == "commit"

  abort "❌ RC tag #{tag} has an unexpected git object type." unless type.strip == "tag"

  message, message_status = Open3.capture2e(
    "git", "-C", monorepo_root, "for-each-ref", "--format=%(contents)", "refs/tags/#{tag}"
  )
  abort "❌ Unable to inspect RC tag provenance for #{tag}: #{message}" unless message_status.success?

  provenance = accelerated_rc_tag_provenance_from_message(message)
  abort "❌ Annotated RC tag #{tag} lacks canonical accelerated provenance." unless provenance

  provenance
end

def capture_accelerated_rc_tag_object_output!(monorepo_root:, arguments:, error:)
  output, status = Open3.capture2e("git", "-C", monorepo_root, *arguments)
  abort error unless status.success?

  output
end

def release_tag_object_type_for_object!(monorepo_root:, tag:, tag_object_sha:)
  unless tag_object_sha.is_a?(String) && tag_object_sha.match?(/\A[0-9a-f]{40}\z/)
    abort "❌ Captured RC tag object for #{tag} is malformed."
  end

  type = capture_accelerated_rc_tag_object_output!(
    monorepo_root:,
    arguments: ["cat-file", "-t", tag_object_sha],
    error: "❌ Captured RC tag object for #{tag} is unavailable."
  ).strip
  return type if %w[commit tag].include?(type)

  abort "❌ Captured RC tag object for #{tag} has an unexpected git object type."
end

def accelerated_rc_tag_identity_for_object!(monorepo_root:, tag:, tag_object_sha:)
  unless release_tag_object_type_for_object!(monorepo_root:, tag:, tag_object_sha:) == "tag"
    abort "❌ Captured RC tag object for #{tag} is unavailable or is not an annotated tag; " \
          "refusing publication recovery."
  end

  contents = capture_accelerated_rc_tag_object_output!(
    monorepo_root:,
    arguments: ["cat-file", "-p", tag_object_sha],
    error: "❌ Unable to inspect captured RC tag object for #{tag}."
  )

  _headers, separator, message = contents.partition("\n\n")
  abort "❌ Captured RC tag object for #{tag} is malformed." if separator.empty?

  provenance = accelerated_rc_tag_provenance_from_message(message)
  abort "❌ Captured annotated RC tag object for #{tag} lacks canonical accelerated provenance." unless provenance

  candidate_output = capture_accelerated_rc_tag_object_output!(
    monorepo_root:,
    arguments: ["rev-parse", "--verify", "--quiet", "#{tag_object_sha}^{}"],
    error: "❌ Unable to peel captured RC tag object for #{tag} to its candidate."
  )
  candidate_sha = candidate_output.strip
  unless candidate_sha.match?(/\A[0-9a-f]{40}\z/)
    abort "❌ Unable to peel captured RC tag object for #{tag} to its candidate."
  end

  { tag_object_sha:, candidate_sha:, provenance: }
end

def create_accelerated_rc_tag!(monorepo_root:, tag:, record:)
  candidate_sha = record.fetch("candidate_sha")
  head_sha = current_git_sha!(monorepo_root)
  unless head_sha == candidate_sha
    abort "❌ Current HEAD moved after accelerated RC authorization; refusing to tag an unauthorized candidate."
  end

  sh_args_in_dir_for_release(
    monorepo_root, "git", "tag", "-a", tag, candidate_sha, "-m", accelerated_rc_tag_message(record)
  )
end

def validate_release_tag_candidate_sha!(monorepo_root:, tag:, candidate_sha:)
  tag_sha = peeled_git_tag_sha(monorepo_root:, tag:)
  unless tag_sha == candidate_sha
    abort "❌ Release tag #{tag} is not bound to the explicitly validated release candidate SHA."
  end

  tag_sha
end

def create_release_tag_at_candidate_sha!(monorepo_root:, tag:, candidate_sha:)
  head_sha = current_git_sha!(monorepo_root, context: "release tag creation")
  unless head_sha == candidate_sha
    abort "❌ Local HEAD moved before release tag creation; refusing to tag an unvalidated commit."
  end

  sh_args_in_dir_for_release(monorepo_root, "git", "tag", tag, candidate_sha)
  validate_release_tag_candidate_sha!(monorepo_root:, tag:, candidate_sha:)
end

def validate_release_candidate_publication_boundary!(monorepo_root:, tag:, candidate_sha:, phase:)
  head_sha = current_git_sha!(monorepo_root, context: "release #{phase}")
  unless head_sha == candidate_sha
    abort "❌ Local HEAD moved away from the validated release candidate before #{phase}; " \
          "refusing to continue."
  end

  validate_release_tag_candidate_sha!(monorepo_root:, tag:, candidate_sha:)
end

def abort_malformed_remote_release_tag!(tag:, phase:)
  abort "❌ Remote release tag #{tag} is missing or malformed before #{phase}; refusing to continue."
end

def valid_remote_release_tag_entry?(fields:, tag_ref:, peeled_ref:)
  fields.length == 2 && fields.first.match?(/\A[0-9a-f]{40}\z/) &&
    [tag_ref, peeled_ref].include?(fields.last)
end

def parse_remote_release_tag_refs!(output:, tag_ref:, peeled_ref:, tag:, phase:)
  lines = output.lines.map(&:strip).reject(&:empty?)
  refs = lines.to_h do |line|
    fields = line.split(/\s+/)
    abort_malformed_remote_release_tag!(tag:, phase:) unless
      valid_remote_release_tag_entry?(fields:, tag_ref:, peeled_ref:)

    [fields.last, fields.first]
  end
  abort_malformed_remote_release_tag!(tag:, phase:) unless refs.length == lines.length && refs.key?(tag_ref)

  refs
end

def remote_release_tag_refs!(monorepo_root:, tag:, phase:)
  tag_ref = "refs/tags/#{tag}"
  peeled_ref = "#{tag_ref}^{}"
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "ls-remote", "--tags", "origin", tag_ref, peeled_ref
  )
  unless status.success?
    abort "❌ Unable to verify remote release tag #{tag.inspect} before #{phase}.\n\n#{output.strip}"
  end

  parse_remote_release_tag_refs!(output:, tag_ref:, peeled_ref:, tag:, phase:)
end

def remote_release_tag_candidate_sha!(monorepo_root:, tag:, phase:)
  tag_ref = "refs/tags/#{tag}"
  peeled_ref = "#{tag_ref}^{}"
  refs = remote_release_tag_refs!(monorepo_root:, tag:, phase:)

  refs.fetch(peeled_ref, refs.fetch(tag_ref))
end

def local_release_tag_object_sha!(monorepo_root:, tag:, phase:)
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/#{tag}"
  )
  object_sha = output.strip
  return object_sha if status.success? && object_sha.match?(/\A[0-9a-f]{40}\z/)

  abort "❌ Unable to inspect the fetched local tag object for #{tag} before #{phase}."
end

def remote_annotated_release_tag_identity!(monorepo_root:, tag:, phase:)
  tag_ref = "refs/tags/#{tag}"
  peeled_ref = "#{tag_ref}^{}"
  refs = remote_release_tag_refs!(monorepo_root:, tag:, phase:)
  unless refs.key?(peeled_ref)
    abort "❌ Remote release tag #{tag} is not an annotated tag before #{phase}; refusing to continue."
  end

  { tag_object_sha: refs.fetch(tag_ref), candidate_sha: refs.fetch(peeled_ref) }
end

def live_annotated_release_tag_identity!(monorepo_root:, tag:, phase:, tag_object_sha: nil)
  captured_tag_object_sha = tag_object_sha || local_release_tag_object_sha!(monorepo_root:, tag:, phase:)
  identity = accelerated_rc_tag_identity_for_object!(
    monorepo_root:, tag:, tag_object_sha: captured_tag_object_sha
  )
  unless local_release_tag_object_sha!(monorepo_root:, tag:, phase:) == captured_tag_object_sha
    abort "❌ Fetched local annotated tag ref for #{tag} changed while validating provenance before #{phase}."
  end

  remote_identity = remote_annotated_release_tag_identity!(monorepo_root:, tag:, phase:)
  unless remote_identity.fetch(:tag_object_sha) == captured_tag_object_sha
    abort "❌ Live remote annotated tag object for #{tag} does not match the fetched provenance object " \
          "before #{phase}."
  end
  unless remote_identity.fetch(:candidate_sha) == identity.fetch(:candidate_sha)
    abort "❌ Remote release tag #{tag} moved away from the captured annotated tag candidate before #{phase}."
  end

  identity
end

def valid_accelerated_rc_tag_object_identity?(identity)
  accelerated_rc_exact_keys?(identity, %i[tag_object_sha candidate_sha provenance]) &&
    identity[:tag_object_sha].is_a?(String) && identity[:tag_object_sha].match?(/\A[0-9a-f]{40}\z/) &&
    identity[:candidate_sha].is_a?(String) && identity[:candidate_sha].match?(/\A[0-9a-f]{40}\z/) &&
    valid_accelerated_rc_tag_provenance?(identity[:provenance]) &&
    identity[:provenance]["candidate_sha"] == identity[:candidate_sha]
end

def validate_remote_release_tag_candidate_sha!(monorepo_root:, tag:, candidate_sha:, phase:)
  remote_sha = remote_release_tag_candidate_sha!(monorepo_root:, tag:, phase:)
  return remote_sha if remote_sha == candidate_sha

  abort "❌ Remote release tag #{tag} moved away from the validated release candidate before #{phase}; " \
        "refusing to continue."
end

def validate_repository_accelerated_rc_authorization_boundary!(monorepo_root:, record:, phase:)
  repo_slug = github_repo_slug(monorepo_root)
  history = validated_repository_accelerated_rc_candidate_history!(
    repo_slug:,
    target_version: record.fetch("target_version"),
    candidate_sha: record.fetch("candidate_sha"),
    expected_tracker: record.fetch("release_tracker"),
    selected_authorization: record
  )
  abort_if_accelerated_rc_retry_rejected!(history.fetch(:records))
  validate_accelerated_rc_authorization_live_evidence_boundary!(
    repo_slug:, monorepo_root:, authorization: record, phase:
  )
  history
end

def validate_repository_accelerated_rc_boundary_record!(monorepo_root:, record:, phase:)
  return validate_repository_accelerated_rc_authorization_boundary!(monorepo_root:, record:, phase:) if
    record["status"] == "publication-authorized"

  unless record["status"] == "candidate-accepted"
    abort "❌ Accelerated release boundary requires canonical authorization or accepted-candidate state."
  end

  repo_slug = github_repo_slug(monorepo_root)
  history = validated_repository_accelerated_rc_candidate_history!(
    repo_slug:,
    target_version: record.fetch("target_version"),
    candidate_sha: record.fetch("candidate_sha"),
    expected_tracker: record.fetch("release_tracker")
  )
  abort_if_accelerated_rc_retry_rejected!(history.fetch(:records))
  terminal = history.dig(:chain, :terminal)
  unless terminal && terminal["status"] == "candidate-accepted" &&
         accelerated_rc_retry_equivalent?(terminal, record)
    abort "❌ Accelerated final-promotion evidence changed at the repository-wide publication boundary."
  end

  history
end

def validate_accelerated_repository_publication_boundary!(monorepo_root:, record:, phase:)
  return unless record

  validate_repository_accelerated_rc_boundary_record!(monorepo_root:, record:, phase:)
end

def accelerated_repository_boundary_context!(accelerated_publication_record:, accelerated_boundary_record:)
  if accelerated_publication_record && accelerated_boundary_record
    abort "❌ Release tag handling received ambiguous accelerated boundary evidence."
  end

  record = accelerated_boundary_record || accelerated_publication_record
  tag_authorization = accelerated_publication_record
  tag_authorization ||= record if record&.fetch("status", nil) == "publication-authorized"
  { record:, tag_authorization: }
end

def valid_final_promotion_context_identity?(context:, candidate_sha:,
                                            expected_strict_final_shakaperf_identity_anchor:,
                                            expected_source_rc_tag_object_sha: nil)
  context_record = context.fetch(:record)
  ci_branch = context.fetch(:ci_branch)
  ci_snapshot = context.fetch(:ci_snapshot)
  shakaperf_record = context.fetch(:shakaperf_record)
  final_target_version = context.fetch(:final_target_version)
  shakaperf_evidence_mode = context.fetch(:shakaperf_evidence_mode)
  strict_final_shakaperf_identity_anchor = context.fetch(:strict_final_shakaperf_identity_anchor, nil)
  ci_branch.is_a?(String) && !ci_branch.empty? &&
    strict_final_shakaperf_identity_anchor == expected_strict_final_shakaperf_identity_anchor &&
    context.fetch(:candidate_sha) == candidate_sha &&
    ci_snapshot.fetch("sha") == context_record.fetch("candidate_sha") &&
    final_target_version == Gem::Version.new(context_record.fetch("target_version")).release.to_s &&
    valid_final_promotion_shakaperf_context_identity?(
      shakaperf_record:, ci_branch:, context_record:, candidate_sha:, final_target_version:, shakaperf_evidence_mode:,
      strict_final_shakaperf_identity_anchor:
    ) &&
    valid_final_promotion_source_rc_context_identity?(
      context:, context_record:, expected_source_rc_tag_object_sha:
    )
end

def valid_final_promotion_shakaperf_context_identity?(shakaperf_record:, ci_branch:, context_record:, candidate_sha:,
                                                      final_target_version:, shakaperf_evidence_mode:,
                                                      strict_final_shakaperf_identity_anchor:)
  shakaperf_candidate_sha = shakaperf_record.fetch("candidate_sha")
  return false unless valid_final_promotion_shakaperf_common_identity?(
    shakaperf_record:, ci_branch:, shakaperf_candidate_sha:
  )

  case shakaperf_evidence_mode
  when FINAL_PROMOTION_SHAKAPERF_ACCEPTED_RC_MODE
    valid_accepted_rc_final_promotion_shakaperf_identity?(
      shakaperf_record:, context_record:, shakaperf_candidate_sha:, strict_final_shakaperf_identity_anchor:
    )
  when FINAL_PROMOTION_SHAKAPERF_STRICT_FINAL_MODE
    valid_strict_final_promotion_shakaperf_identity?(
      shakaperf_record:, shakaperf_candidate_sha:, candidate_sha:, final_target_version:,
      identity_anchor: strict_final_shakaperf_identity_anchor
    )
  when FINAL_PROMOTION_SHAKAPERF_OBSERVATION_WAIVER_MODE
    shakaperf_candidate_sha == candidate_sha && shakaperf_record.fetch("target_version") == final_target_version &&
      valid_final_shakaperf_observation_waiver_snapshot?(shakaperf_record.fetch("shakaperf")) &&
      valid_strict_final_promotion_shakaperf_identity_anchor?(
        shakaperf_record:, identity_anchor: strict_final_shakaperf_identity_anchor
      )
  else
    false
  end
end

def valid_final_promotion_shakaperf_common_identity?(shakaperf_record:, ci_branch:, shakaperf_candidate_sha:)
  shakaperf_record.fetch("release_branch") == ci_branch &&
    shakaperf_record.dig("shakaperf", "candidate_sha") == shakaperf_candidate_sha &&
    shakaperf_record.dig("shakaperf", "target_version") == shakaperf_record.fetch("target_version")
end

def valid_accepted_rc_final_promotion_shakaperf_identity?(shakaperf_record:, context_record:,
                                                          shakaperf_candidate_sha:,
                                                          strict_final_shakaperf_identity_anchor:)
  strict_final_shakaperf_identity_anchor.nil? &&
    canonical_accelerated_rc_value(shakaperf_record.fetch("shakaperf")) ==
      canonical_accelerated_rc_value(context_record.fetch("shakaperf")) &&
    shakaperf_candidate_sha == context_record.dig("shakaperf", "candidate_sha")
end

def valid_strict_final_promotion_shakaperf_identity?(shakaperf_record:, shakaperf_candidate_sha:, candidate_sha:,
                                                     final_target_version:, identity_anchor:)
  shakaperf_candidate_sha == candidate_sha && shakaperf_record.fetch("target_version") == final_target_version &&
    valid_strict_final_promotion_shakaperf_identity_anchor?(shakaperf_record:, identity_anchor:)
end

def valid_strict_final_promotion_shakaperf_identity_anchor?(shakaperf_record:, identity_anchor:)
  return false unless identity_anchor.is_a?(String) && identity_anchor.frozen?
  return false unless valid_strict_final_promotion_shakaperf_record?(shakaperf_record)

  identity_anchor == final_promotion_shakaperf_identity_anchor(shakaperf_record)
end

def valid_strict_final_promotion_shakaperf_record?(record)
  return false unless accelerated_rc_exact_keys?(
    record, %w[release_branch candidate_sha target_version shakaperf]
  )

  snapshot = record.fetch("shakaperf")
  valid_strict_final_promotion_shakaperf_snapshot?(snapshot) ||
    valid_final_shakaperf_observation_waiver_snapshot?(snapshot)
end

def valid_strict_final_promotion_shakaperf_snapshot?(snapshot)
  accelerated_rc_exact_keys?(snapshot, ACCELERATED_RC_SHAKAPERF_FIELDS) && snapshot["status"] == "success" &&
    valid_strict_final_promotion_shakaperf_snapshot_identity?(snapshot)
end

def valid_strict_final_promotion_shakaperf_snapshot_identity?(snapshot)
  positive_github_id?(snapshot["run_id"]) && positive_github_id?(snapshot["attempt"]) &&
    valid_accelerated_rc_https_url?(snapshot["run_url"]) &&
    snapshot["candidate_sha"].to_s.match?(/\A[0-9a-f]{40}\z/) &&
    !shakaperf_release_gate_time(snapshot["release_started_at"]).nil?
end

def valid_final_shakaperf_observation_waiver_snapshot_identity?(snapshot)
  [
    snapshot["status"] == "observation_waived",
    positive_github_id?(snapshot["run_id"]),
    positive_github_id?(snapshot["attempt"]),
    valid_accelerated_rc_https_url?(snapshot["run_url"]),
    snapshot["candidate_sha"].to_s.match?(/\A[0-9a-f]{40}\z/),
    snapshot["target_version"].to_s.match?(SHAKAPERF_RELEASE_GATE_CANONICAL_VERSION_PATTERN),
    !release_prerelease_version?(snapshot["target_version"]),
    !shakaperf_release_gate_time(snapshot["release_started_at"]).nil?
  ].all?
end

def valid_final_shakaperf_observation_waiver_snapshot_audit?(snapshot)
  valid_accelerated_rc_tracker_number?(snapshot["release_tracker"]) &&
    snapshot["waiver_digest"].to_s.match?(/\A[0-9a-f]{64}\z/)
end

def valid_final_shakaperf_observation_waiver_snapshot_observation?(snapshot)
  snapshot["observed_status"] != "completed" && snapshot["observed_conclusion"].to_s.empty?
end

def valid_final_shakaperf_observation_waiver_snapshot?(snapshot)
  return false unless accelerated_rc_exact_keys?(snapshot, FINAL_PROMOTION_SHAKAPERF_OBSERVATION_WAIVER_FIELDS)

  valid_final_shakaperf_observation_waiver_snapshot_identity?(snapshot) &&
    valid_final_shakaperf_observation_waiver_snapshot_audit?(snapshot) &&
    valid_final_shakaperf_observation_waiver_snapshot_observation?(snapshot)
end

def final_promotion_shakaperf_identity_anchor(shakaperf_record)
  canonical_accelerated_rc_json(shakaperf_record).freeze
end

def valid_final_promotion_source_rc_context_identity?(context:, context_record:, expected_source_rc_tag_object_sha:)
  source_rc_tag_provenance = context.fetch(:source_rc_tag_provenance)
  source_rc_tag_object_sha = context.fetch(:source_rc_tag_object_sha)
  context.fetch(:source_rc_tag) == "v#{context_record.fetch('target_version')}" &&
    source_rc_tag_object_sha.is_a?(String) && source_rc_tag_object_sha.match?(/\A[0-9a-f]{40}\z/) &&
    (expected_source_rc_tag_object_sha.nil? || source_rc_tag_object_sha == expected_source_rc_tag_object_sha) &&
    context.fetch(:source_rc_candidate_sha) == context_record.fetch("candidate_sha") &&
    valid_accelerated_rc_tag_provenance?(source_rc_tag_provenance) &&
    source_rc_tag_provenance.values_at("target_version", "candidate_sha", "release_tracker") ==
      context_record.values_at("target_version", "candidate_sha", "release_tracker")
end

def validate_final_promotion_context!(boundary_record:, context:, candidate_sha:,
                                      expected_strict_final_shakaperf_identity_anchor: nil,
                                      expected_source_rc_tag_object_sha: nil)
  unless context
    if boundary_record&.fetch("status", nil) == "candidate-accepted"
      abort "❌ Release tag handling is missing accelerated final-promotion context."
    end

    return
  end

  context_record = context.fetch(:record)
  valid = boundary_record&.fetch("status", nil) == "candidate-accepted" &&
          accelerated_rc_retry_equivalent?(boundary_record, context_record) &&
          valid_final_promotion_context_identity?(
            context:, candidate_sha:, expected_strict_final_shakaperf_identity_anchor:,
            expected_source_rc_tag_object_sha:
          )
  return if valid

  abort "❌ Release tag handling received inconsistent accelerated final-promotion boundary evidence."
rescue KeyError
  abort "❌ Release tag handling received incomplete accelerated final-promotion boundary evidence."
end

def validate_accelerated_tag_publication_boundary!(
  monorepo_root:, record:, final_promotion_context:, candidate_sha:,
  expected_strict_final_shakaperf_identity_anchor:, expected_source_rc_tag_object_sha:, phase:
)
  validate_final_promotion_context!(
    boundary_record: record, context: final_promotion_context, candidate_sha:,
    expected_strict_final_shakaperf_identity_anchor:, expected_source_rc_tag_object_sha:
  )
  validate_accelerated_repository_publication_boundary!(monorepo_root:, record:, phase:)
  validate_final_promotion_ci_publication_boundary!(
    monorepo_root:, context: final_promotion_context, phase:
  )
  validate_final_promotion_shakaperf_publication_boundary!(
    monorepo_root:, context: final_promotion_context, phase:
  )
  validate_final_promotion_source_rc_tag_boundary!(
    monorepo_root:, context: final_promotion_context, expected_source_rc_tag_object_sha:, phase:
  )
end

def retain_final_promotion_shakaperf_identity_anchor(context)
  identity_anchor = context&.fetch(:strict_final_shakaperf_identity_anchor, nil)
  identity_anchor.is_a?(String) ? identity_anchor.dup.freeze : identity_anchor
end

def retain_final_promotion_source_rc_tag_object_anchor(context)
  tag_object_sha = context&.fetch(:source_rc_tag_object_sha, nil)
  tag_object_sha.is_a?(String) ? tag_object_sha.dup.freeze : tag_object_sha
end

def final_promotion_publication_identity_anchors(context)
  {
    shakaperf: retain_final_promotion_shakaperf_identity_anchor(context),
    source_rc_tag_object: retain_final_promotion_source_rc_tag_object_anchor(context)
  }
end

def validate_accelerated_tag_publication_phase!(monorepo_root:, record:, final_promotion_context:, candidate_sha:,
                                                identity_anchors:, phase:)
  validate_accelerated_tag_publication_boundary!(
    monorepo_root:, record:, final_promotion_context:, candidate_sha:,
    expected_strict_final_shakaperf_identity_anchor: identity_anchors.fetch(:shakaperf),
    expected_source_rc_tag_object_sha: identity_anchors.fetch(:source_rc_tag_object),
    phase:
  )
end

def validate_final_promotion_source_rc_tag_boundary!(
  monorepo_root:, context:, expected_source_rc_tag_object_sha:, phase:
)
  return unless context

  source_rc_tag = context.fetch(:source_rc_tag)
  expected_candidate_sha = context.fetch(:source_rc_candidate_sha)
  expected_provenance = context.fetch(:source_rc_tag_provenance)
  unless expected_source_rc_tag_object_sha == context.fetch(:source_rc_tag_object_sha)
    abort "❌ Final promotion source RC tag object identity changed before #{phase}; refusing to continue."
  end
  unless remote_git_tag_exists?(monorepo_root:, tag: source_rc_tag)
    abort "❌ Final promotion source RC tag #{source_rc_tag} disappeared before #{phase}; refusing to continue."
  end

  fetch_remote_rc_tag!(monorepo_root:, rc_tag: source_rc_tag)
  actual_identity = live_annotated_release_tag_identity!(
    monorepo_root:,
    tag: source_rc_tag,
    phase: "final promotion source RC #{phase}",
    tag_object_sha: expected_source_rc_tag_object_sha
  )
  unless actual_identity.fetch(:provenance) == expected_provenance
    abort "❌ Final promotion source RC tag #{source_rc_tag} lost or changed its canonical annotated " \
          "authorization provenance before #{phase}; refusing to continue."
  end

  actual_candidate_sha = actual_identity.fetch(:candidate_sha)
  return actual_candidate_sha if actual_candidate_sha == expected_candidate_sha

  abort "❌ Final promotion source RC tag #{source_rc_tag} moved before #{phase}; refusing to continue."
end

def ensure_release_tag_for_candidate!(monorepo_root:, tag:, candidate_sha:, tag_authorization:)
  tag_exists = system(
    "git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/#{tag}",
    out: File::NULL, err: File::NULL
  )
  if tag_exists
    if tag_authorization
      validate_existing_accelerated_rc_tag!(monorepo_root:, tag:, record: tag_authorization)
    else
      validate_release_tag_candidate_sha!(monorepo_root:, tag:, candidate_sha:)
    end
    puts "Git tag #{tag} already exists, skipping tag creation"
  elsif tag_authorization
    create_accelerated_rc_tag!(monorepo_root:, tag:, record: tag_authorization)
  else
    create_release_tag_at_candidate_sha!(monorepo_root:, tag:, candidate_sha:)
  end
end

def validate_ordinary_shakaperf_boundary!(monorepo_root:, contexts:, phase:)
  validate_ordinary_stable_shakaperf_association_boundary!(
    monorepo_root:, context: contexts.fetch(:association), phase:
  )
  validate_ordinary_stable_shakaperf_waiver_boundary!(
    monorepo_root:, context: contexts.fetch(:waiver), phase:
  )
end

def push_release_tag_for_candidate!(monorepo_root:, tag:, candidate_sha:, accelerated_publication_record: nil,
                                    accelerated_boundary_record: nil, accelerated_final_promotion_context: nil,
                                    ordinary_stable_shakaperf_association_context: nil,
                                    ordinary_stable_shakaperf_waiver_context: nil)
  shakaperf_contexts = {
    association: ordinary_stable_shakaperf_association_context,
    waiver: ordinary_stable_shakaperf_waiver_context
  }
  boundary_context = accelerated_repository_boundary_context!(
    accelerated_publication_record:, accelerated_boundary_record:
  )
  boundary_record = boundary_context.fetch(:record)
  tag_authorization = boundary_context.fetch(:tag_authorization)
  identity_anchors = final_promotion_publication_identity_anchors(accelerated_final_promotion_context)
  validate_final_promotion_context!(
    boundary_record:, context: accelerated_final_promotion_context, candidate_sha:,
    expected_strict_final_shakaperf_identity_anchor: identity_anchors.fetch(:shakaperf),
    expected_source_rc_tag_object_sha: identity_anchors.fetch(:source_rc_tag_object)
  )
  validate_accelerated_tag_publication_phase!(
    monorepo_root:, record: boundary_record, final_promotion_context: accelerated_final_promotion_context,
    candidate_sha:, identity_anchors:, phase: "tag handling"
  )
  ensure_release_tag_for_candidate!(monorepo_root:, tag:, candidate_sha:, tag_authorization:)
  validate_accelerated_tag_publication_phase!(
    monorepo_root:, record: boundary_record, final_promotion_context: accelerated_final_promotion_context,
    candidate_sha:, identity_anchors:, phase: "git tag push"
  )
  validate_release_candidate_publication_boundary!(
    monorepo_root:, tag:, candidate_sha:, phase: "git tag push"
  )
  validate_ordinary_shakaperf_boundary!(monorepo_root:, contexts: shakaperf_contexts, phase: "git tag push")
  release_write_fence!("push release tag #{tag}")
  sh_in_dir_for_release(monorepo_root, "LEFTHOOK=0 git push --tags")
  validate_accelerated_tag_publication_phase!(
    monorepo_root:, record: boundary_record, final_promotion_context: accelerated_final_promotion_context,
    candidate_sha:, identity_anchors:, phase: "package publication"
  )
  validate_release_candidate_publication_boundary!(
    monorepo_root:, tag:, candidate_sha:, phase: "package publication"
  )
  validate_remote_release_tag_candidate_sha!(
    monorepo_root:, tag:, candidate_sha:, phase: "package publication"
  )
  validate_ordinary_shakaperf_boundary!(monorepo_root:, contexts: shakaperf_contexts, phase: "package publication")
end

def validate_existing_accelerated_rc_tag!(monorepo_root:, tag:, record:)
  actual = accelerated_rc_tag_provenance_for_tag!(monorepo_root:, tag:)
  expected = accelerated_rc_tag_provenance(record)
  target_sha = peeled_git_tag_sha(monorepo_root:, tag:)
  abort "❌ Existing RC tag #{tag} does not match the persisted accelerated publication authorization." unless
    actual == expected && target_sha == expected["candidate_sha"]

  actual
end

def local_release_tag_exists?(monorepo_root:, tag:)
  _output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "show-ref", "--verify", "--quiet", "refs/tags/#{tag}"
  )
  return true if status.success?
  return false if status.exitstatus == 1

  abort "❌ Unable to inspect existing release tag #{tag} before accelerated RC retry."
end

def accelerated_rc_records_for_candidate(records, target_version:, candidate_sha:)
  records.select do |record|
    record["target_version"] == target_version && record["candidate_sha"] == candidate_sha
  end
end

def accelerated_rc_authorization_for_same_candidate_retry!(
  repo_slug:, monorepo_root:, target_version:, candidate_sha:, accelerated_requested:, tracker: nil
)
  tag = "v#{target_version}"
  tag_exists = local_release_tag_exists?(monorepo_root:, tag:)
  history = validated_repository_accelerated_rc_candidate_history!(
    repo_slug:, target_version:, candidate_sha:, expected_tracker: tracker, allow_empty: true
  )
  candidate_records = history.fetch(:records)
  if candidate_records.empty?
    return accelerated_rc_authorization_without_history!(
      monorepo_root:, tag:, tag_exists:, accelerated_requested:
    )
  end

  tracker = history.fetch(:tracker)
  fetch_release_tracker_issue!(repo_slug:, tracker:, target_version:)
  chain = history.fetch(:chain)
  terminal = chain.fetch(:terminal)
  if terminal && terminal["status"] == "candidate-rejected"
    abort "❌ Accelerated RC retry is blocked because this immutable candidate was permanently rejected."
  end

  authorization = chain.fetch(:authorization)
  validate_accelerated_rc_retry_tag_authorization!(
    candidate_records:, authorization:, tag_exists:, tracker:, target_version:, candidate_sha:, monorepo_root:, tag:
  )

  authorization
end

def accelerated_rc_authorization_without_history!(monorepo_root:, tag:, tag_exists:, accelerated_requested:)
  return nil unless tag_exists

  provenance = accelerated_rc_tag_provenance_for_tag!(monorepo_root:, tag:)
  unless provenance
    if accelerated_requested
      abort "❌ Existing ordinary lightweight RC tag #{tag} cannot be converted to accelerated publication."
    end

    return nil
  end

  abort "❌ Accelerated RC retry is blocked because its annotated tag has provenance but the durable " \
        "repository tracker chain is missing."
end

def validate_accelerated_rc_retry_tag_authorization!(candidate_records:, authorization:, tag_exists:, tracker:,
                                                     target_version:, candidate_sha:, monorepo_root:, tag:)
  return unless tag_exists

  tagged_authorization = accelerated_rc_tagged_authorization_for_retry!(
    authorizations: candidate_records.select { |record| record["status"] == "publication-authorized" },
    tracker:, target_version:, candidate_sha:, monorepo_root:, tag:
  )
  return if accelerated_rc_record_digest(tagged_authorization) == accelerated_rc_record_digest(authorization)

  abort "❌ Existing RC tag references a noncanonical accelerated publication authorization."
end

def abort_if_accelerated_rc_retry_rejected!(candidate_records)
  terminal = validated_accelerated_rc_terminal_set!(candidate_records)
  return unless terminal && terminal["status"] == "candidate-rejected"

  abort "❌ Accelerated RC retry is blocked because this immutable candidate was permanently rejected."
end

def validated_accelerated_rc_authorization_set!(candidate_records, selected_authorization: nil)
  authorizations = candidate_records.select { |record| record["status"] == "publication-authorized" }
  abort "❌ Accelerated RC state is missing its canonical publication authorization." if authorizations.empty?

  digests = authorizations.map { |record| accelerated_rc_record_digest(record) }.uniq
  abort "❌ Accelerated RC state contains conflicting canonical publication authorizations." unless digests.one?

  if selected_authorization && accelerated_rc_record_digest(selected_authorization) != digests.first
    abort "❌ Selected accelerated RC publication authorization is not canonical for this candidate."
  end

  selected_authorization || authorizations.first
end

def accelerated_rc_tagged_authorization_for_retry!(authorizations:, tracker:, target_version:, candidate_sha:,
                                                   monorepo_root:, tag:)
  provenance = accelerated_rc_tag_provenance_for_tag!(monorepo_root:, tag:)
  expected_identity = [target_version, candidate_sha, tracker]
  unless provenance && provenance.values_at("target_version", "candidate_sha", "release_tracker") == expected_identity
    abort "❌ Existing RC tag #{tag} lacks matching canonical accelerated publication provenance."
  end

  authorization = authorizations.find do |record|
    accelerated_rc_record_digest(record) == provenance["authorization_digest"]
  end
  abort "❌ Existing RC tag #{tag} references a missing canonical publication authorization." unless authorization

  authorization
end

def json_compatible_release_value(value)
  JSON.parse(JSON.generate(value))
end

def accelerated_rc_ci_check_sort_key(check)
  %w[name state url].map { |field| check[field] || check[field.to_sym] }.map(&:to_s)
end

def canonical_accelerated_rc_ci_snapshot_for_comparison(snapshot)
  normalized = json_compatible_release_value(snapshot)
  checks = normalized["non_success"]
  return normalized unless checks.is_a?(Array) && checks.all?(Hash)

  normalized["non_success"] = checks.sort_by { |check| accelerated_rc_ci_check_sort_key(check) }
  normalized
end

def build_accelerated_rc_publication_record(options:, candidate_sha:, runtime_tree_fingerprint:, release_branch:,
                                            ci_snapshot:, shakaperf:, approved_by:, recorded_at:)
  {
    "schema_version" => ACCELERATED_RC_RECORD_SCHEMA_VERSION,
    "status" => "publication-authorized",
    "target_version" => options.fetch(:target_gem_version),
    "candidate_sha" => candidate_sha,
    "runtime_tree_fingerprint" => runtime_tree_fingerprint,
    "release_branch" => release_branch,
    "release_tracker" => options.fetch(:tracker),
    "ci" => json_compatible_release_value(ci_snapshot),
    "shakaperf" => json_compatible_release_value(shakaperf),
    "reason" => options.fetch(:reason),
    "approved_by" => approved_by,
    "recorded_at" => recorded_at.iso8601,
    "required_follow_up" => "Complete immutable publication, then run " \
                            "script/release --reconcile-accelerated-rc " \
                            "before final.",
    "evidence" => {}
  }
end

def valid_accelerated_rc_retry_ci_check?(check)
  check.is_a?(Hash) && !check[:name].to_s.empty? && !check[:state].to_s.empty? &&
    valid_accelerated_rc_https_url?(check[:url])
end

def valid_accelerated_rc_retry_ci_snapshot_shape?(snapshot)
  return false unless snapshot.is_a?(Hash)
  return false unless snapshot[:non_success].is_a?(Array)
  return false unless valid_accelerated_rc_https_url?(snapshot[:checks_url])

  snapshot[:non_success].all? { |check| valid_accelerated_rc_retry_ci_check?(check) }
end

def current_accelerated_rc_retry_ci_snapshot?(snapshot, candidate_sha:)
  status = snapshot[:status]
  non_success_states = snapshot.fetch(:non_success).map { |check| check.fetch(:state) }
  incomplete = non_success_states.any? { |state| CI_INCOMPLETE_STATUSES.include?(state) }
  allowed_states = CI_INCOMPLETE_STATUSES + CI_PASSING_CONCLUSIONS
  return false unless snapshot[:sha] == candidate_sha
  return false unless non_success_states.all? { |state| allowed_states.include?(state) }
  return incomplete if status == "pending"
  return !incomplete if status == "success"

  false
end

def validate_accelerated_rc_retry_ci_snapshot!(snapshot, candidate_sha:)
  valid = valid_accelerated_rc_retry_ci_snapshot_shape?(snapshot) &&
          current_accelerated_rc_retry_ci_snapshot?(snapshot, candidate_sha:)
  return snapshot if valid

  abort "❌ Persisted accelerated RC authorization cannot be reused because current exact-candidate CI " \
        "evidence is failed, stale, malformed, or unknown."
end

def accelerated_rc_live_shakaperf_record(release_branch:, candidate_sha:, target_version:, shakaperf:)
  {
    "release_branch" => release_branch,
    "candidate_sha" => candidate_sha,
    "target_version" => target_version,
    "shakaperf" => json_compatible_release_value(shakaperf)
  }
end

def refresh_accelerated_rc_live_evidence!(repo_slug:, monorepo_root:, release_branch:, candidate_sha:,
                                          target_version:, shakaperf:, context:)
  refresh_record = accelerated_rc_live_shakaperf_record(
    release_branch:, candidate_sha:, target_version:, shakaperf:
  )
  refreshed_shakaperf = accelerated_rc_shakaperf_snapshot!(
    repo_slug:, monorepo_root:, record: refresh_record
  )
  unless refreshed_shakaperf.is_a?(Hash) && %w[pending success].include?(refreshed_shakaperf["status"])
    abort "❌ Accelerated RC #{context} live ShakaPerf evidence is failed or unknown."
  end

  refreshed_ci = fetch_accelerated_rc_ci_snapshot!(
    repo_slug:, sha: candidate_sha, monorepo_root:, ci_branch: release_branch
  )
  valid_ci = valid_accelerated_rc_retry_ci_snapshot_shape?(refreshed_ci) &&
             current_accelerated_rc_retry_ci_snapshot?(refreshed_ci, candidate_sha:)
  unless valid_ci
    abort "❌ Accelerated RC #{context} live exact-candidate CI evidence is failed, missing, stale, " \
          "malformed, or unknown."
  end

  { ci: refreshed_ci, shakaperf: refreshed_shakaperf }
end

def accelerated_rc_deferred_evidence_changed?(previous:, refreshed:)
  %i[ci shakaperf].any? do |gate|
    current = if gate == :ci
                canonical_accelerated_rc_ci_snapshot_for_comparison(refreshed.fetch(gate))
              else
                json_compatible_release_value(refreshed.fetch(gate))
              end
    prior = if gate == :ci
              canonical_accelerated_rc_ci_snapshot_for_comparison(previous.fetch(gate))
            else
              json_compatible_release_value(previous.fetch(gate))
            end
    current["status"] == "pending" && current != prior
  end
end

def confirmed_fresh_accelerated_rc_evidence!(repo_slug:, monorepo_root:, release_branch:, candidate_sha:,
                                             target_version:, tracker:, reason:, ci_snapshot:, shakaperf:)
  evidence = { ci: ci_snapshot, shakaperf: }
  confirmations = 0

  loop do
    confirm_accelerated_rc_publication!(
      version: target_version,
      candidate_sha:,
      tracker:,
      reason:,
      ci_snapshot: evidence.fetch(:ci),
      shakaperf: evidence.fetch(:shakaperf)
    )
    refreshed = refresh_accelerated_rc_live_evidence!(
      repo_slug:,
      monorepo_root:,
      release_branch:,
      candidate_sha:,
      target_version:,
      shakaperf: evidence.fetch(:shakaperf),
      context: "refreshed authorization"
    )
    return refreshed unless accelerated_rc_deferred_evidence_changed?(previous: evidence, refreshed:)

    confirmations += 1
    if confirmations >= 3
      abort "❌ Accelerated RC pending evidence did not stabilize across confirmation; refusing authorization."
    end
    puts "⚠️ Accelerated RC pending evidence changed during confirmation; review and confirm the refreshed snapshot."
    evidence = refreshed
  end
end

def fresh_accelerated_rc_authorization_evidence!(repo_slug:, monorepo_root:, release_branch:, candidate_sha:,
                                                 target_version:, tracker:, reason:, release_started_at:)
  shakaperf = run_accelerated_shakaperf_release_gate!(
    monorepo_root:, ref: release_branch, head_sha: candidate_sha, target_version:, release_started_at:
  )
  ci_snapshot = fetch_accelerated_rc_ci_snapshot!(
    repo_slug:, sha: candidate_sha, monorepo_root:, ci_branch: release_branch
  )
  confirmed_fresh_accelerated_rc_evidence!(
    repo_slug:,
    monorepo_root:,
    release_branch:,
    candidate_sha:,
    target_version:,
    tracker:,
    reason:,
    ci_snapshot:,
    shakaperf:
  )
end

def validate_accelerated_rc_authorization_live_evidence_boundary!(repo_slug:, monorepo_root:, authorization:, phase:)
  refreshed = refresh_accelerated_rc_live_evidence!(
    repo_slug:,
    monorepo_root:,
    release_branch: authorization.fetch("release_branch"),
    candidate_sha: authorization.fetch("candidate_sha"),
    target_version: authorization.fetch("target_version"),
    shakaperf: authorization.fetch("shakaperf"),
    context: "#{phase} boundary"
  )
  stored = { ci: authorization.fetch("ci"), shakaperf: authorization.fetch("shakaperf") }
  return refreshed unless accelerated_rc_deferred_evidence_changed?(previous: stored, refreshed:)

  abort "❌ Accelerated RC #{phase} boundary found materially changed pending evidence that was not confirmed."
end

def validate_persisted_accelerated_rc_authorization_evidence!(repo_slug:, monorepo_root:, authorization:)
  candidate_sha = authorization.fetch("candidate_sha")
  ci = fetch_accelerated_rc_ci_snapshot!(
    repo_slug:,
    sha: candidate_sha,
    monorepo_root:,
    ci_branch: authorization.fetch("release_branch")
  )
  validate_accelerated_rc_retry_ci_snapshot!(ci, candidate_sha:)

  shakaperf = accelerated_rc_shakaperf_snapshot!(repo_slug:, monorepo_root:, record: authorization)
  return authorization if %w[pending success].include?(shakaperf["status"])

  abort "❌ Persisted accelerated RC authorization cannot be reused because current ShakaPerf evidence failed."
end

def reuse_accelerated_rc_publication_authorization!(
  repo_slug:, monorepo_root:, history:, authorization:, tracker:, target_version:, candidate_sha:, tag:
)
  validate_accelerated_rc_retry_tag_authorization!(
    candidate_records: history.fetch(:records),
    authorization:,
    tag_exists: local_release_tag_exists?(monorepo_root:, tag:),
    tracker:,
    target_version:,
    candidate_sha:,
    monorepo_root:,
    tag:
  )
  validate_persisted_accelerated_rc_authorization_evidence!(repo_slug:, monorepo_root:, authorization:)
  puts "✓ Reusing canonical accelerated RC publication authorization from tracker ##{tracker}."
  authorization
end

def authorize_accelerated_rc_publication!(repo_slug:, monorepo_root:, release_branch:, candidate_sha:, options:,
                                          approver:, release_started_at:, tag:)
  tracker = options.fetch(:tracker)
  target_version = options.fetch(:target_gem_version)
  history = validated_repository_accelerated_rc_candidate_history!(
    repo_slug:, target_version:, candidate_sha:, expected_tracker: tracker, allow_empty: true
  )
  abort_if_accelerated_rc_retry_rejected!(history.fetch(:records)) unless history.fetch(:records).empty?
  persisted = history.dig(:chain, :authorization)
  if persisted
    return reuse_accelerated_rc_publication_authorization!(
      repo_slug:, monorepo_root:, history:, authorization: persisted, tracker:, target_version:, candidate_sha:, tag:
    )
  end

  accelerated_rc_authorization_without_history!(
    monorepo_root:,
    tag:,
    tag_exists: local_release_tag_exists?(monorepo_root:, tag:),
    accelerated_requested: true
  )

  refreshed_evidence = fresh_accelerated_rc_authorization_evidence!(
    repo_slug:,
    monorepo_root:,
    release_branch:,
    candidate_sha:,
    target_version:,
    tracker:,
    reason: options.fetch(:reason),
    release_started_at:
  )
  ci = refreshed_evidence.fetch(:ci)
  shakaperf = refreshed_evidence.fetch(:shakaperf)
  runtime_tree_fingerprint = shakaperf_runtime_tree_fingerprint(monorepo_root:, sha: candidate_sha)
  abort "❌ Unable to fingerprint the accelerated RC runtime tree; refusing unaudited publication." unless
    runtime_tree_fingerprint

  record = build_accelerated_rc_publication_record(
    options:, candidate_sha:, runtime_tree_fingerprint:, release_branch:, ci_snapshot: ci, shakaperf:,
    approved_by: approver, recorded_at: Time.now.utc
  )
  fetch_release_tracker_issue!(repo_slug:, tracker:, target_version: options.fetch(:target_gem_version))
  append_accelerated_rc_tracker_record!(repo_slug:, tracker:, record:)
end

def accelerated_rc_published_record(authorized_record:, recorded_at:, approved_by: authorized_record["approved_by"])
  authorized_record.merge(
    "status" => "published-awaiting-gates",
    "approved_by" => approved_by,
    "recorded_at" => recorded_at.iso8601,
    "required_follow_up" => "Run script/release --reconcile-accelerated-rc " \
                            "before final promotion."
  )
end

def validated_repository_accelerated_rc_publication_completion_history!(repo_slug:, tracker:, authorization:)
  history = validated_repository_accelerated_rc_candidate_history!(
    repo_slug:,
    target_version: authorization.fetch("target_version"),
    candidate_sha: authorization.fetch("candidate_sha"),
    expected_tracker: tracker,
    selected_authorization: authorization
  )
  abort_if_accelerated_rc_retry_rejected!(history.fetch(:records))
  history
end

def record_accelerated_rc_publication_complete!(repo_slug:, tracker:, authorized_record:, approved_by:, recorded_at:)
  fetch_release_tracker_issue!(repo_slug:, tracker:, target_version: authorized_record.fetch("target_version"))
  history = validated_repository_accelerated_rc_publication_completion_history!(
    repo_slug:, tracker:, authorization: authorized_record
  )
  publications = history.dig(:chain, :publications)
  if publications.empty?
    published_record = accelerated_rc_published_record(
      authorized_record: history.dig(:chain, :authorization), recorded_at:, approved_by:
    )
    append_accelerated_rc_tracker_record!(repo_slug:, tracker:, record: published_record)
  end

  refreshed_history = validated_repository_accelerated_rc_publication_completion_history!(
    repo_slug:, tracker:, authorization: authorized_record
  )
  canonical_publication = refreshed_history.dig(:chain, :publications).first
  abort "❌ Canonical published-awaiting-gates transition is missing after publication completion." unless
    canonical_publication

  canonical_publication
end

def accelerated_rc_publication_completion_equivalent?(existing, expected)
  retry_variant_fields = %w[approved_by recorded_at]
  normalize = lambda do |record|
    comparable = record.except(*retry_variant_fields)
    supported_follow_ups = [
      ACCELERATED_RC_LEGACY_PUBLICATION_FOLLOW_UP,
      "Run script/release --reconcile-accelerated-rc before final promotion.",
      "Run script/release --reconcile-accelerated-rc before promoting this RC to final.",
      "Run script/release --reconcile-accelerated-rc #{record['target_version']} " \
      "before promoting this RC to final."
    ]
    if supported_follow_ups.include?(comparable["required_follow_up"])
      comparable["required_follow_up"] = ACCELERATED_RC_PUBLICATION_FOLLOW_UP_CANONICAL_VALUE
    end
    canonical_accelerated_rc_value(comparable)
  end

  normalize.call(existing) == normalize.call(expected)
end

def validated_accelerated_rc_publication_set!(candidate_records, authorization, require_publication: false)
  publications = candidate_records.select { |record| record["status"] == "published-awaiting-gates" }
  if publications.empty?
    abort "❌ Canonical published-awaiting-gates transition is missing." if require_publication

    return publications
  end

  expected = accelerated_rc_published_record(
    authorized_record: authorization,
    approved_by: authorization["approved_by"],
    recorded_at: Time.at(0).utc
  )
  unless publications.all? { |record| accelerated_rc_publication_completion_equivalent?(record, expected) }
    abort "❌ Accelerated RC publication set contains state that is not the canonical authorized transition."
  end

  publications
end

def validated_accelerated_rc_terminal_set!(candidate_records)
  terminal_records = candidate_records.select do |record|
    ACCELERATED_RC_TERMINAL_STATUSES.include?(record["status"])
  end
  return nil if terminal_records.empty?

  rejected = terminal_records.select { |record| record["status"] == "candidate-rejected" }
  if rejected.any? && rejected.length != terminal_records.length
    abort "❌ Accelerated RC candidate was permanently rejected; candidate-rejected is absorbing and " \
          "contradictory terminal history is invalid."
  end

  canonical = terminal_records.first
  unless terminal_records.all? { |record| accelerated_rc_retry_equivalent?(record, canonical) }
    abort "❌ Accelerated RC state contains conflicting #{canonical.fetch('status')} terminal records."
  end

  canonical
end

def validated_accelerated_rc_candidate_chain!(
  candidate_records,
  selected_authorization: nil,
  require_publication: false
)
  authorization = validated_accelerated_rc_authorization_set!(
    candidate_records, selected_authorization:
  )
  unless accelerated_rc_authorization_chain_valid?(candidate_records, authorization)
    abort "❌ Accelerated RC tracker state is not bound to the canonical publication authorization."
  end

  terminal = validated_accelerated_rc_terminal_set!(candidate_records)
  publications = validated_accelerated_rc_publication_set!(
    candidate_records,
    authorization,
    require_publication: require_publication || !terminal.nil?
  )
  validate_accelerated_rc_transition_order!(candidate_records)

  { authorization:, publications:, terminal: }
end

def validate_accelerated_rc_transition_order!(candidate_records)
  current_phase = -1
  previous_time = nil

  candidate_records.each do |record|
    phase = accelerated_rc_transition_phase!(record["status"])
    if phase < current_phase || (phase.positive? && current_phase < phase - 1)
      abort "❌ Accelerated RC tracker transition order is invalid; expected authorization, publication, terminal."
    end

    recorded_at = accelerated_rc_transition_recorded_at!(record)
    if previous_time && recorded_at < previous_time
      abort "❌ Accelerated RC tracker transition timestamps must be parseable and monotonic."
    end

    current_phase = phase
    previous_time = recorded_at
  end

  candidate_records
end

def accelerated_rc_transition_phase!(status)
  phase = {
    "publication-authorized" => 0,
    "published-awaiting-gates" => 1,
    "candidate-accepted" => 2,
    "candidate-rejected" => 2
  }[status]
  abort "❌ Accelerated RC tracker transition order contains an unknown state." unless phase

  phase
end

def accelerated_rc_transition_recorded_at!(record)
  recorded_at = shakaperf_release_gate_time(record["recorded_at"])
  abort "❌ Accelerated RC tracker transition timestamps must be parseable and monotonic." unless recorded_at

  recorded_at
end

def accelerated_rc_terminal_record(records:, target_version:, candidate_sha:)
  candidate_records = records.select do |record|
    record["target_version"] == target_version && record["candidate_sha"] == candidate_sha &&
      ACCELERATED_RC_RECORD_STATUSES.include?(record["status"])
  end
  validated_accelerated_rc_terminal_set!(candidate_records)
end

def accelerated_rc_published_record!(records:, target_version:)
  matching = accelerated_rc_records_for_target(records, target_version)
  abort "❌ No accelerated RC tracker record exists for #{target_version}." if matching.empty?

  latest_publication = accelerated_rc_latest_record_with_status(matching, "published-awaiting-gates")
  abort "❌ No published-awaiting-gates record exists for #{target_version}." unless latest_publication

  candidate_sha = latest_publication.fetch("candidate_sha")
  candidate_records = accelerated_rc_records_for_candidate(matching, target_version:, candidate_sha:)
  chain = validated_accelerated_rc_candidate_chain!(candidate_records, require_publication: true)
  chain.fetch(:terminal) || latest_publication
end

def accelerated_rc_records_for_target(records, target_version)
  records.select { |record| record["target_version"] == target_version }
end

def accelerated_rc_record_with_status(records, status)
  records.find { |record| record["status"] == status }
end

def accelerated_rc_latest_record_with_status(records, status)
  records.reverse.find { |record| record["status"] == status }
end

def accelerated_rc_authorization_chain_valid?(records, authorization)
  authorization && records.all? { |record| accelerated_rc_record_bound_to_authorization?(record, authorization) }
end

def accelerated_rc_shakaperf_snapshot!(repo_slug:, monorepo_root:, record:)
  stored = record.fetch("shakaperf")
  run = refresh_shakaperf_release_gate_run!(repo_slug:, run: { "databaseId" => stored.fetch("run_id") })
  run_url = validated_accelerated_rc_shakaperf_run_url!(
    repo_slug:, run:, stored:, ref: record.fetch("release_branch")
  )
  if active_shakaperf_release_gate_run?(run)
    if accelerated_rc_shakaperf_requires_prerun?(record)
      abort "❌ Pending ShakaPerf evidence must match the exact RC candidate; " \
            "a different-SHA pre-run must complete and pass live mechanical verification."
    end

    return stored.merge("status" => "pending", "run_id" => run.fetch("databaseId"), "run_url" => run_url)
  end

  unless run["status"] == "completed"
    abort "❌ ShakaPerf reconciliation is unknown for #{run_url}; refusing to accept or reject the RC."
  end
  unless SHAKAPERF_RELEASE_GATE_TERMINAL_CONCLUSIONS.include?(run["conclusion"])
    abort "❌ ShakaPerf reconciliation is unknown for #{run_url}; refusing to accept or reject the RC."
  end
  if run["conclusion"] != "success"
    return stored.merge(
      "status" => "failed",
      "conclusion" => run["conclusion"],
      "run_id" => run.fetch("databaseId"),
      "run_url" => run_url
    )
  end

  verified_accelerated_rc_shakaperf_success_snapshot!(
    repo_slug:, monorepo_root:, record:, stored:, run:, run_url:
  )
end

def verified_accelerated_rc_shakaperf_success_snapshot!(repo_slug:, monorepo_root:, record:, stored:, run:, run_url:)
  release_started_at = shakaperf_release_gate_time(stored["release_started_at"])
  abort "❌ Stored ShakaPerf release start time is invalid; reconciliation remains unknown." unless release_started_at

  rejection = shakaperf_release_gate_run_evidence_rejection(
    repo_slug:,
    monorepo_root:,
    ref: record.fetch("release_branch"),
    head_sha: record.fetch("candidate_sha"),
    target_version: record.fetch("target_version"),
    run:,
    release_started_at:,
    require_prerun: accelerated_rc_shakaperf_requires_prerun?(record)
  )
  abort "❌ ShakaPerf reconciliation evidence is unknown or invalid: #{rejection}" if rejection

  stored.merge("status" => "success", "run_id" => run.fetch("databaseId"), "run_url" => run_url)
end

def validated_accelerated_rc_shakaperf_run_url!(repo_slug:, run:, stored:, ref:)
  validate_accelerated_shakaperf_run_metadata!(repo_slug:, run:)
  unless valid_accelerated_rc_shakaperf_run_identity?(repo_slug:, run:, stored:, ref:)
    abort "❌ Refreshed ShakaPerf run identity is unknown or malformed; reconciliation remains blocked."
  end

  run.fetch("url")
end

def valid_accelerated_rc_shakaperf_run_identity?(repo_slug:, run:, stored:, ref:)
  return false unless stored.is_a?(Hash) && valid_accelerated_shakaperf_run_metadata?(repo_slug:, run:)
  return false unless valid_accelerated_shakaperf_run_url?(
    repo_slug:, run_id: stored["run_id"], url: stored["run_url"]
  )

  run["databaseId"] == stored["run_id"] && run["attempt"] == stored["attempt"] &&
    shakaperf_release_gate_run_matches_target?(
      run:, ref:, head_sha: stored["candidate_sha"], target_version: stored["target_version"]
    )
end

def accelerated_rc_shakaperf_requires_prerun?(record)
  record.fetch("shakaperf").fetch("candidate_sha") != record.fetch("candidate_sha")
end

def confirm_accelerated_rc_publication!(version:, candidate_sha:, tracker:, reason:, ci_snapshot:, shakaperf:)
  print_accelerated_rc_publication_summary(
    version:, candidate_sha:, tracker:, reason:, ci_snapshot:, shakaperf:
  )
  print "Publish this RC while the named gates finish? [y/N] "
  $stdout.flush
  answer = $stdin.gets&.strip&.downcase
  abort "Accelerated RC publication aborted." unless answer == "y"
end

def abort_invalid_accelerated_rc_confirmation_evidence!
  abort "❌ Accelerated RC confirmation evidence is malformed or incomplete; refusing publication."
end

def normalized_accelerated_rc_confirmation_hash!(value)
  abort_invalid_accelerated_rc_confirmation_evidence! unless value.is_a?(Hash)

  value.each_with_object({}) do |(key, nested_value), normalized|
    valid_key = key.is_a?(String) || key.is_a?(Symbol)
    abort_invalid_accelerated_rc_confirmation_evidence! unless valid_key
    normalized_key = key.to_s
    abort_invalid_accelerated_rc_confirmation_evidence! if normalized.key?(normalized_key)
    normalized[normalized_key] = nested_value
  end
end

def valid_accelerated_rc_confirmation_check?(check)
  valid_accelerated_rc_nonempty_string?(check["name"]) &&
    valid_accelerated_rc_nonempty_string?(check["state"]) &&
    check["url"].is_a?(String) && valid_accelerated_rc_https_url?(check["url"])
end

def normalized_accelerated_rc_confirmation_checks!(checks)
  abort_invalid_accelerated_rc_confirmation_evidence! unless checks.is_a?(Array)

  checks.map { |check| normalized_accelerated_rc_confirmation_hash!(check) }
end

def valid_accelerated_rc_confirmation_ci?(snapshot)
  %w[pending success].include?(snapshot["status"]) &&
    snapshot["checks_url"].is_a?(String) && valid_accelerated_rc_https_url?(snapshot["checks_url"]) &&
    snapshot["non_success"].all? { |check| valid_accelerated_rc_confirmation_check?(check) } &&
    valid_accelerated_rc_ci_status?(snapshot["status"], snapshot["non_success"])
end

def valid_accelerated_rc_confirmation_shakaperf?(shakaperf)
  %w[pending success].include?(shakaperf["status"]) &&
    shakaperf["run_url"].is_a?(String) && valid_accelerated_rc_https_url?(shakaperf["run_url"])
end

def normalized_accelerated_rc_confirmation_evidence!(ci_snapshot:, shakaperf:)
  ci = normalized_accelerated_rc_confirmation_hash!(ci_snapshot)
  shakaperf_snapshot = normalized_accelerated_rc_confirmation_hash!(shakaperf)
  ci["non_success"] = normalized_accelerated_rc_confirmation_checks!(ci["non_success"])
  valid = valid_accelerated_rc_confirmation_ci?(ci) &&
          valid_accelerated_rc_confirmation_shakaperf?(shakaperf_snapshot)
  abort_invalid_accelerated_rc_confirmation_evidence! unless valid

  [ci, shakaperf_snapshot]
end

def print_accelerated_rc_publication_summary(version:, candidate_sha:, tracker:, reason:, ci_snapshot:, shakaperf:)
  ci_snapshot, shakaperf = normalized_accelerated_rc_confirmation_evidence!(ci_snapshot:, shakaperf:)
  puts "\n#{'#' * 80}"
  puts "ACCELERATED RC PUBLICATION CONFIRMATION"
  puts "#" * 80
  puts "  RC version: #{version}"
  puts "  Candidate SHA: #{candidate_sha}"
  puts "  Release tracker: ##{tracker}"
  puts "  Exact-head CI: #{ci_snapshot.fetch('status')} (#{ci_snapshot.fetch('checks_url')})"
  print_accelerated_rc_non_success_checks(ci_snapshot)
  puts "  ShakaPerf: #{shakaperf.fetch('status')} (#{shakaperf.fetch('run_url')})"
  puts "  Maintainer reason: #{reason}"
  puts "#" * 80
end

def print_accelerated_rc_non_success_checks(ci_snapshot)
  ci_snapshot.fetch("non_success").each do |check|
    puts "    - #{check.fetch('name')}: #{check.fetch('state')}"
    puts "      #{check.fetch('url')}"
  end
end

def reconcile_accelerated_rc_record(published_record:, ci_snapshot:, shakaperf:, evidence:, approved_by:, reason:,
                                    recorded_at:)
  if [ci_snapshot["status"], shakaperf["status"]].include?("failed")
    return published_record.merge(
      "status" => "candidate-rejected",
      "ci" => ci_snapshot,
      "shakaperf" => shakaperf,
      "evidence" => {},
      "approved_by" => approved_by,
      "reason" => reason,
      "recorded_at" => recorded_at,
      "required_follow_up" => "Do not promote this immutable RC; fix the failure and cut the next RC."
    )
  end

  missing = ACCELERATED_RC_REQUIRED_EVIDENCE.reject do |name|
    valid_accelerated_rc_https_url?(evidence[name])
  end
  unless ci_snapshot["status"] == "success" && shakaperf["status"] == "success" && missing.empty?
    abort "❌ Accelerated RC candidate cannot be accepted while required gate evidence is incomplete."
  end

  published_record.merge(
    "status" => "candidate-accepted",
    "ci" => ci_snapshot,
    "shakaperf" => shakaperf,
    "evidence" => evidence,
    "approved_by" => approved_by,
    "reason" => reason,
    "recorded_at" => recorded_at,
    "required_follow_up" => "Proceed only through the strict final promotion gates."
  )
end

def validate_repository_accelerated_rc_reconciliation_history!(repo_slug:, tracker:, transition:, authorization:)
  history = validated_repository_accelerated_rc_candidate_history!(
    repo_slug:,
    target_version: transition.fetch("target_version"),
    candidate_sha: transition.fetch("candidate_sha"),
    expected_tracker: tracker,
    selected_authorization: authorization
  )
  repository_terminal = history.dig(:chain, :terminal)
  return history unless repository_terminal &&
                        !accelerated_rc_retry_equivalent?(repository_terminal, transition)

  if repository_terminal["status"] == "candidate-rejected"
    abort "❌ Repository-wide accelerated RC history permanently rejected this candidate; " \
          "candidate-rejected is absorbing."
  end

  abort "❌ Repository-wide accelerated RC history contains a conflicting terminal transition."
end

def accelerated_rc_reconciliation_context!(records:, target_version:)
  published_record = accelerated_rc_published_record!(records:, target_version:)
  candidate_records = accelerated_rc_records_for_candidate(
    records,
    target_version: published_record.fetch("target_version"),
    candidate_sha: published_record.fetch("candidate_sha")
  )
  authorization = validated_accelerated_rc_candidate_chain!(
    candidate_records, require_publication: true
  ).fetch(:authorization)
  { published_record:, authorization: }
end

def validate_accelerated_rc_publication_recovery_tag!(monorepo_root:, tag:, authorization:, candidate_sha:)
  phase = "accelerated RC publication recovery"
  fetch_remote_release_tag!(monorepo_root:, tag:, tag_type: "accelerated RC publication recovery")
  local_tag_object_sha = local_release_tag_object_sha!(monorepo_root:, tag:, phase:)
  local_identity = live_annotated_release_tag_identity!(
    monorepo_root:, tag:, phase:, tag_object_sha: local_tag_object_sha
  )
  expected_provenance = accelerated_rc_tag_provenance(authorization)
  unless local_identity.fetch(:provenance) == expected_provenance &&
         candidate_sha == expected_provenance.fetch("candidate_sha")
    abort "❌ Captured annotated tag object for #{tag} does not match the persisted accelerated publication " \
          "authorization."
  end
  unless local_identity.fetch(:candidate_sha) == candidate_sha
    abort "❌ Remote release tag #{tag} moved away from the validated release candidate before #{phase}; " \
          "refusing to continue."
  end

  local_identity.slice(:tag_object_sha, :candidate_sha)
end

def validate_accelerated_rc_complete_publication_evidence!(
  monorepo_root:, tag:, authorization:, candidate_sha:, target_version:
)
  initial_tag_identity = validate_accelerated_rc_publication_recovery_tag!(
    monorepo_root:, tag:, authorization:, candidate_sha:
  )
  verify_complete_release_registry_publication!(gem_version: target_version)
  final_tag_identity = validate_accelerated_rc_publication_recovery_tag!(
    monorepo_root:, tag:, authorization:, candidate_sha:
  )
  return if final_tag_identity == initial_tag_identity

  abort "❌ Live remote annotated tag object for #{tag} changed during registry verification; " \
        "refusing publication recovery."
end

def recover_accelerated_rc_publication_for_reconciliation!(
  repo_slug:, monorepo_root:, tracker:, target_version:, records:, approved_by:
)
  matching = accelerated_rc_records_for_target(records, target_version)
  return records if matching.any? { |record| record["status"] == "published-awaiting-gates" }

  candidate_shas = matching.map { |record| record["candidate_sha"] }.uniq
  unless candidate_shas.one?
    abort "❌ Missing accelerated RC publication cannot be recovered from absent or ambiguous candidate history."
  end

  candidate_sha = candidate_shas.first
  candidate_records = accelerated_rc_records_for_candidate(
    matching, target_version:, candidate_sha:
  )
  authorization = validated_accelerated_rc_candidate_chain!(candidate_records).fetch(:authorization)
  history = validated_repository_accelerated_rc_publication_completion_history!(
    repo_slug:, tracker:, authorization:
  )
  unless history.dig(:chain, :publications).any?
    validate_canonical_accelerated_rc_target!(target_version)
    tag = "v#{target_version}"
    validate_accelerated_rc_complete_publication_evidence!(
      monorepo_root:, tag:, authorization:, candidate_sha:, target_version:
    )
    record_accelerated_rc_publication_complete!(
      repo_slug:,
      tracker:,
      authorized_record: authorization,
      approved_by:,
      recorded_at: Time.now.utc
    )
  end

  refreshed_records = fetch_accelerated_rc_tracker_records!(repo_slug:, tracker:)
  accelerated_rc_published_record!(records: refreshed_records, target_version:)
  refreshed_records
end

def existing_accelerated_rc_reconciliation_record!(repo_slug:, tracker:, context:)
  terminal_record = context.fetch(:published_record)
  return nil unless ACCELERATED_RC_TERMINAL_STATUSES.include?(terminal_record["status"])

  validate_repository_accelerated_rc_reconciliation_history!(
    repo_slug:, tracker:, transition: terminal_record, authorization: context.fetch(:authorization)
  )
  terminal_accelerated_rc_reconciliation_record!(terminal_record)
end

def accelerated_rc_reconciliation_gate_snapshots!(repo_slug:, monorepo_root:, published_record:)
  candidate_sha = published_record.fetch("candidate_sha")
  ci = json_compatible_release_value(
    fetch_accelerated_rc_ci_snapshot!(
      repo_slug:,
      sha: candidate_sha,
      monorepo_root:,
      ci_branch: published_record.fetch("release_branch"),
      fail_on_failure: false
    )
  )
  shakaperf = if ci["status"] == "failed"
                published_record.fetch("shakaperf")
              else
                accelerated_rc_shakaperf_snapshot!(repo_slug:, monorepo_root:, record: published_record)
              end
  { ci:, shakaperf: }
end

def append_accelerated_rc_reconciliation_record!(repo_slug:, tracker:, record:, authorization:)
  validate_repository_accelerated_rc_reconciliation_history!(
    repo_slug:, tracker:, transition: record, authorization:
  )
  append_accelerated_rc_tracker_record!(repo_slug:, tracker:, record:)
  validate_repository_accelerated_rc_reconciliation_history!(
    repo_slug:, tracker:, transition: record, authorization:
  )
  record
end

def run_accelerated_rc_reconciliation!(repo_slug:, monorepo_root:, tracker:, target_version:, reason:, evidence:)
  fetch_release_tracker_issue!(repo_slug:, tracker:, target_version:)
  approved_by = current_release_approver!(repo_slug:)
  records = fetch_accelerated_rc_tracker_records!(repo_slug:, tracker:)
  records = recover_accelerated_rc_publication_for_reconciliation!(
    repo_slug:, monorepo_root:, tracker:, target_version:, records:, approved_by:
  )
  context = accelerated_rc_reconciliation_context!(records:, target_version:)
  terminal_record = existing_accelerated_rc_reconciliation_record!(repo_slug:, tracker:, context:)
  return terminal_record if terminal_record

  published_record = context.fetch(:published_record)
  snapshots = accelerated_rc_reconciliation_gate_snapshots!(repo_slug:, monorepo_root:, published_record:)
  reconciled_record = reconcile_accelerated_rc_record(
    published_record:,
    ci_snapshot: snapshots.fetch(:ci),
    shakaperf: snapshots.fetch(:shakaperf),
    evidence:,
    approved_by:,
    reason: normalized_accelerated_rc_reason!(reason, action: "reconciliation"),
    recorded_at: Time.now.utc.iso8601
  )
  append_accelerated_rc_reconciliation_record!(
    repo_slug:, tracker:, record: reconciled_record, authorization: context.fetch(:authorization)
  )
  if reconciled_record["status"] == "candidate-rejected"
    abort "❌ Accelerated RC candidate was rejected. Do not promote this immutable RC; " \
          "fix the failure and cut the next RC."
  end

  puts "✓ Accelerated RC candidate accepted with complete deferred and downstream evidence."
  reconciled_record
end

def terminal_accelerated_rc_reconciliation_record!(record)
  return nil unless ACCELERATED_RC_TERMINAL_STATUSES.include?(record["status"])

  if record["status"] == "candidate-rejected"
    abort "❌ Accelerated RC candidate was already rejected and can never be promoted; cut the next RC."
  end

  puts "Accelerated RC reconciliation is already terminal: #{record.fetch('status')}."
  record
end

def release_branch_promotion_tag_selection!(monorepo_root:, rc_tag:, source_rc_tag_identity:)
  phase = "accepted accelerated RC selection"
  if source_rc_tag_identity
    unless valid_accelerated_rc_tag_object_identity?(source_rc_tag_identity)
      abort "❌ Final promotion is blocked: supplied source RC tag identity is malformed."
    end
    tag_identity = live_annotated_release_tag_identity!(
      monorepo_root:, tag: rc_tag, phase:, tag_object_sha: source_rc_tag_identity.fetch(:tag_object_sha)
    )
    unless tag_identity == source_rc_tag_identity
      abort "❌ Final promotion is blocked: source RC tag identity changed during accepted-record selection."
    end

    return { tag_identity: }
  end

  tag_object_sha = local_release_tag_object_sha!(monorepo_root:, tag: rc_tag, phase:)
  tag_object_type = release_tag_object_type_for_object!(monorepo_root:, tag: rc_tag, tag_object_sha:)
  return { ordinary_candidate_sha: tag_object_sha } if tag_object_type == "commit"

  {
    tag_identity: live_annotated_release_tag_identity!(
      monorepo_root:, tag: rc_tag, phase:, tag_object_sha:
    )
  }
end

def ordinary_rc_record_for_release_branch_promotion!(monorepo_root:, rc_tag:, tracker_input:, candidate_sha:)
  repo_slug = github_repo_slug(monorepo_root)
  rc_version = parse_release_tag_to_gem_version(rc_tag)
  if tracker_input
    unless tracker_input.to_s.match?(/\A[1-9]\d*\z/)
      abort "❌ Final promotion is blocked: RELEASE_TRACKER must be a positive issue number."
    end
    fetch_release_tracker_issue!(repo_slug:, tracker: tracker_input.to_i, target_version: rc_version)
  end

  history = fetch_repository_accelerated_rc_records_for_candidate!(
    repo_slug:, target_version: rc_version, candidate_sha:
  )
  return nil if history.empty?

  abort "❌ Final promotion is blocked: lightweight RC tag #{rc_tag} has durable accelerated history " \
        "but lacks canonical accelerated provenance."
end

def accepted_accelerated_rc_record_for_release_branch_promotion!(monorepo_root:, rc_tag:, final_head_sha:,
                                                                 tracker_input:, source_rc_tag_identity: nil)
  tag_selection = release_branch_promotion_tag_selection!(monorepo_root:, rc_tag:, source_rc_tag_identity:)
  if tag_selection.key?(:ordinary_candidate_sha)
    return ordinary_rc_record_for_release_branch_promotion!(
      monorepo_root:,
      rc_tag:,
      tracker_input:,
      candidate_sha: tag_selection.fetch(:ordinary_candidate_sha)
    )
  end

  tag_identity = tag_selection.fetch(:tag_identity)
  tag_provenance = tag_identity.fetch(:provenance)

  validate_literal_accelerated_rc_tag_name!(rc_tag:, tag_provenance:)

  tracker = tag_provenance.fetch("release_tracker")
  unless tracker_input.to_s.match?(/\A[1-9]\d*\z/) && tracker_input.to_i == tracker
    abort "❌ Final promotion is blocked: RELEASE_TRACKER must match the canonical tracker recorded " \
          "in the accelerated RC tag."
  end

  repo_slug = github_repo_slug(monorepo_root)
  rc_version = tag_provenance.fetch("target_version")
  fetch_release_tracker_issue!(repo_slug:, tracker:, target_version: rc_version)
  rc_sha = tag_identity.fetch(:candidate_sha)
  history = validated_repository_accelerated_rc_candidate_history!(
    repo_slug:, target_version: rc_version, candidate_sha: rc_sha, expected_tracker: tracker
  )
  accepted_accelerated_rc_record_for_promotion!(
    records: history.fetch(:records),
    rc_version:,
    rc_sha:,
    final_head_sha:,
    monorepo_root:,
    tag_provenance:
  )
end

def validate_literal_accelerated_rc_tag_name!(rc_tag:, tag_provenance:)
  expected_tag = "v#{tag_provenance.fetch('target_version')}"
  return if rc_tag == expected_tag

  abort "❌ Final promotion requires the literal canonical accelerated RC tag #{expected_tag}; " \
        "aliases are not accepted for provenance-bearing candidates."
end

def accepted_accelerated_rc_record_for_promotion!(records:, rc_version:, rc_sha:, final_head_sha:, monorepo_root:,
                                                  tag_provenance:)
  matching_records = records.select { |record| record["target_version"] == rc_version }
  candidate_records = accelerated_rc_promotion_candidate_records!(
    matching_records:, rc_version:, rc_sha:, tag_provenance:
  )
  return nil unless candidate_records

  abort_if_accelerated_rc_candidate_rejected!(candidate_records:, rc_version:)
  validate_accepted_accelerated_rc_record_for_promotion!(
    record: candidate_records.last, rc_version:, rc_sha:, final_head_sha:, monorepo_root:
  )
end

def accelerated_rc_promotion_candidate_records!(matching_records:, rc_version:, rc_sha:, tag_provenance:)
  return nil unless accelerated_rc_tag_provenance_required!(matching_records:, tag_provenance:)

  validate_accelerated_rc_promotion_tag_identity!(tag_provenance:, rc_version:, rc_sha:)

  candidate_records = accelerated_rc_records_for_candidate(
    matching_records, target_version: rc_version, candidate_sha: rc_sha
  )
  authorization = accelerated_rc_authorization_for_provenance(candidate_records, tag_provenance)
  unless authorization
    abort "❌ Final promotion is blocked: canonical accelerated RC publication authorization is missing " \
          "or does not match the RC tag provenance."
  end
  validated_accelerated_rc_candidate_chain!(
    candidate_records, selected_authorization: authorization, require_publication: true
  )

  candidate_records
end

def accelerated_rc_tag_provenance_required!(matching_records:, tag_provenance:)
  return true if tag_provenance
  return false if matching_records.empty?

  abort "❌ Final promotion is blocked: accelerated RC tracker records exist, but the RC tag lacks " \
        "canonical accelerated-publication provenance."
end

def validate_accelerated_rc_promotion_tag_identity!(tag_provenance:, rc_version:, rc_sha:)
  return if tag_provenance["target_version"] == rc_version && tag_provenance["candidate_sha"] == rc_sha

  abort "❌ Final promotion is blocked: RC tag provenance does not match the selected RC version and SHA."
end

def accelerated_rc_authorization_for_provenance(candidate_records, tag_provenance)
  candidate_records.find do |record|
    record["status"] == "publication-authorized" &&
      accelerated_rc_record_digest(record) == tag_provenance["authorization_digest"]
  end
end

def abort_if_accelerated_rc_candidate_rejected!(candidate_records:, rc_version:)
  terminal = validated_accelerated_rc_terminal_set!(candidate_records)
  return unless terminal && terminal["status"] == "candidate-rejected"

  abort "❌ Final promotion is blocked: #{rc_version} was permanently rejected. Cut the next immutable RC."
end

def validate_accepted_accelerated_rc_record_for_promotion!(record:, rc_version:, rc_sha:, final_head_sha:,
                                                           monorepo_root:)
  unless record["status"] == "candidate-accepted"
    abort "❌ Final promotion is blocked: #{rc_version} has deferred RC gates in state " \
          "#{record['status'].inspect}. Do not promote pending, rejected, or unreconciled evidence."
  end
  abort "❌ Final promotion is blocked: accepted evidence is not bound to the RC tag SHA." unless
    record["candidate_sha"] == rc_sha
  abort "❌ Final promotion is blocked: accepted RC evidence is incomplete." unless
    accelerated_rc_gate_evidence_complete?(record)
  unless accelerated_rc_runtime_equivalent?(
    record:, rc_sha:, final_head_sha:, monorepo_root:
  )
    abort "❌ Final promotion is blocked: the final tip is not runtime-equivalent to the accepted RC candidate."
  end

  record
end

def accelerated_rc_gate_evidence_complete?(record)
  evidence = record.fetch("evidence", {})
  record.dig("ci", "status") == "success" && record.dig("shakaperf", "status") == "success" &&
    evidence.keys.sort == ACCELERATED_RC_REQUIRED_EVIDENCE.sort &&
    ACCELERATED_RC_REQUIRED_EVIDENCE.all? { |name| valid_accelerated_rc_https_url?(evidence[name]) }
end

def refresh_accepted_rc_ci_evidence_for_promotion!(repo_slug:, monorepo_root:, ci_branch:, record:)
  candidate_sha = record.fetch("candidate_sha")
  snapshot = fetch_accelerated_rc_ci_snapshot!(
    repo_slug:,
    sha: candidate_sha,
    monorepo_root:,
    ci_branch:
  )
  valid_snapshot = valid_accelerated_rc_retry_ci_snapshot_shape?(snapshot) &&
                   current_accelerated_rc_retry_ci_snapshot?(snapshot, candidate_sha:) &&
                   snapshot[:status] == "success"
  unless valid_snapshot
    abort "❌ Final promotion is blocked: refreshed exact-RC CI is failed, pending, missing, malformed, " \
          "stale, unknown, or not candidate-bound."
  end

  snapshot
end

def validate_final_promotion_ci_publication_boundary!(monorepo_root:, context:, phase:)
  return unless context

  record = context.fetch(:record)
  expected_snapshot = context.fetch(:ci_snapshot)
  refreshed_snapshot = refresh_accepted_rc_ci_evidence_for_promotion!(
    repo_slug: github_repo_slug(monorepo_root),
    monorepo_root:,
    ci_branch: context.fetch(:ci_branch),
    record:
  )
  return refreshed_snapshot if
    canonical_accelerated_rc_ci_snapshot_for_comparison(refreshed_snapshot) ==
    canonical_accelerated_rc_ci_snapshot_for_comparison(expected_snapshot)

  abort "❌ Final promotion #{phase} boundary found materially changed exact-candidate CI evidence."
end

def validate_final_promotion_shakaperf_publication_boundary!(monorepo_root:, context:, phase:)
  return unless context

  carried_record = context.fetch(:shakaperf_record)
  expected_snapshot = carried_record.fetch("shakaperf")
  if context.fetch(:shakaperf_evidence_mode) == FINAL_PROMOTION_SHAKAPERF_OBSERVATION_WAIVER_MODE
    return validate_final_shakaperf_observation_waiver_publication_boundary!(
      monorepo_root:, carried_record:, expected_snapshot:, phase:
    )
  end
  refresh_record = final_promotion_shakaperf_refresh_record!(context:, carried_record:)
  refreshed_snapshot = accelerated_rc_shakaperf_snapshot!(
    repo_slug: github_repo_slug(monorepo_root), monorepo_root:, record: refresh_record
  )
  unless refreshed_snapshot.is_a?(Hash) && refreshed_snapshot["status"] == "success"
    abort "❌ Final promotion #{phase} boundary ShakaPerf evidence is failed, missing, malformed, or unknown."
  end
  return refreshed_snapshot if canonical_accelerated_rc_value(refreshed_snapshot) ==
                               canonical_accelerated_rc_value(expected_snapshot)

  abort "❌ Final promotion #{phase} boundary found materially changed ShakaPerf evidence."
end

def validate_final_shakaperf_observation_waiver_publication_boundary!(monorepo_root:, carried_record:,
                                                                      expected_snapshot:, phase:,
                                                                      boundary_label: "Final promotion")
  unless valid_final_shakaperf_observation_waiver_snapshot?(expected_snapshot)
    abort "❌ #{boundary_label} #{phase} ShakaPerf observation waiver snapshot is malformed."
  end

  repo_slug = github_repo_slug(monorepo_root)
  tracker = expected_snapshot.fetch("release_tracker")
  entries = trusted_shakaperf_release_tracker_records!(repo_slug:, tracker:)
  waiver = selected_final_shakaperf_observation_waiver(
    entries:,
    repo_slug:,
    tracker:,
    ref: carried_record.fetch("release_branch"),
    head_sha: carried_record.fetch("candidate_sha"),
    target_version: carried_record.fetch("target_version")
  )
  unless exact_final_shakaperf_observation_waiver_snapshot_match?(waiver:, expected_snapshot:)
    abort "❌ #{boundary_label} #{phase} ShakaPerf observation waiver changed, disappeared, or is conflicting."
  end

  validate_current_final_shakaperf_observation_waiver_run!(
    repo_slug:,
    waiver:,
    ref: carried_record.fetch("release_branch"),
    head_sha: carried_record.fetch("candidate_sha"),
    target_version: carried_record.fetch("target_version")
  )
  expected_snapshot
rescue ShakaperfGateMissingRunError
  abort "❌ Selected ShakaPerf run is missing or deleted at #{boundary_label.downcase} #{phase}; " \
        "the observation waiver cannot continue."
end

def exact_final_shakaperf_observation_waiver_snapshot_match?(waiver:, expected_snapshot:)
  return false unless waiver

  digest = Digest::SHA256.hexdigest(canonical_accelerated_rc_json(waiver))
  digest == expected_snapshot.fetch("waiver_digest") &&
    waiver.values_at("run_id", "run_attempt", "run_url") ==
      expected_snapshot.values_at("run_id", "attempt", "run_url")
end

def ordinary_stable_shakaperf_waiver_context_identity(context)
  canonical_accelerated_rc_json(
    "carried_record" => context.fetch(:carried_record),
    "expected_snapshot" => context.fetch(:expected_snapshot)
  )
end

def valid_ordinary_stable_shakaperf_waiver_context?(context)
  required_keys = %i[carried_record expected_snapshot identity_anchor]
  return false unless context.is_a?(Hash) && context.keys.sort == required_keys.sort

  carried_record = context.fetch(:carried_record)
  expected_snapshot = context.fetch(:expected_snapshot)
  identity_anchor = context.fetch(:identity_anchor)
  return false unless carried_record.is_a?(Hash)

  [
    accelerated_rc_exact_keys?(carried_record, %w[release_branch candidate_sha target_version]),
    valid_final_shakaperf_observation_waiver_snapshot?(expected_snapshot),
    carried_record.values_at("candidate_sha", "target_version") ==
      expected_snapshot.values_at("candidate_sha", "target_version"),
    identity_anchor.is_a?(String),
    identity_anchor.frozen?,
    identity_anchor == ordinary_stable_shakaperf_waiver_context_identity(context)
  ].all?
rescue KeyError
  false
end

def validate_ordinary_stable_shakaperf_waiver_boundary!(monorepo_root:, context:, phase:)
  return unless context

  unless valid_ordinary_stable_shakaperf_waiver_context?(context)
    abort "❌ Ordinary stable #{phase} ShakaPerf observation waiver context is malformed or changed."
  end

  repo_slug = github_repo_slug(monorepo_root)
  tracker = context.dig(:expected_snapshot, "release_tracker")
  target_version = context.dig(:expected_snapshot, "target_version")
  fetch_release_tracker_issue!(repo_slug:, tracker:, target_version:)
  validate_final_shakaperf_observation_waiver_publication_boundary!(
    monorepo_root:,
    carried_record: context.fetch(:carried_record),
    expected_snapshot: context.fetch(:expected_snapshot),
    phase:,
    boundary_label: "Ordinary stable release"
  )
end

def validate_current_final_shakaperf_observation_waiver_run!(repo_slug:, waiver:, ref:, head_sha:, target_version:)
  run = fetch_selected_shakaperf_release_gate_run!(repo_slug:, run_id: waiver.fetch("run_id"))
  observed_run = exact_final_shakaperf_waiver_run!(
    repo_slug:, ref:, head_sha:, target_version:, run: normalized_selected_shakaperf_release_gate_run(run)
  )
  unless observed_run["attempt"] == waiver.fetch("run_attempt")
    abort "❌ Current ShakaPerf run attempt does not match the final observation waiver."
  end
  if observed_run["status"] == "completed" || !observed_run["conclusion"].to_s.empty?
    abort "❌ A terminal ShakaPerf result cannot remain covered by a final observation waiver."
  end
  unless SHAKAPERF_RELEASE_GATE_ACTIVE_STATUSES.include?(observed_run["status"])
    abort "❌ Final ShakaPerf observation waiver found an unknown current run state."
  end

  observed_run
rescue ShakaperfGateMissingRunError
  raise
rescue ShakaperfGateObservationError
  nil
end

def final_promotion_shakaperf_refresh_record!(context:, carried_record:)
  case context.fetch(:shakaperf_evidence_mode)
  when FINAL_PROMOTION_SHAKAPERF_ACCEPTED_RC_MODE
    carried_record.merge("candidate_sha" => context.fetch(:record).fetch("candidate_sha"))
  when FINAL_PROMOTION_SHAKAPERF_STRICT_FINAL_MODE, FINAL_PROMOTION_SHAKAPERF_OBSERVATION_WAIVER_MODE
    carried_record
  else
    abort "❌ Final promotion ShakaPerf boundary has an unknown evidence mode."
  end
rescue KeyError
  abort "❌ Final promotion ShakaPerf boundary has incomplete evidence identity."
end

def accepted_rc_record_at_publication_boundary!(monorepo_root:, rc_tag:, final_head_sha:, tracker_input:, record:)
  unless remote_git_tag_exists?(monorepo_root:, tag: rc_tag)
    abort "❌ Final promotion is blocked: the live remote RC tag disappeared at the publication boundary."
  end
  fetch_remote_rc_tag!(monorepo_root:, rc_tag:)

  phase = "final promotion accepted-record publication boundary"
  tag_object_sha = local_release_tag_object_sha!(monorepo_root:, tag: rc_tag, phase:)
  source_rc_tag_identity = live_annotated_release_tag_identity!(
    monorepo_root:, tag: rc_tag, phase:, tag_object_sha:
  )

  boundary_record = accepted_accelerated_rc_record_for_release_branch_promotion!(
    monorepo_root:, rc_tag:, final_head_sha:, tracker_input:, source_rc_tag_identity:
  )
  abort "❌ Final promotion is blocked: accelerated RC evidence disappeared at the publication boundary." unless
    boundary_record
  unless accelerated_rc_retry_equivalent?(boundary_record, record)
    abort "❌ Final promotion is blocked: the accepted RC record changed at the publication boundary."
  end

  { record: boundary_record, source_rc_tag_identity: }
end

def validate_final_promotion_boundary_head!(monorepo_root:, final_head_sha:)
  boundary_head_sha = current_git_sha!(monorepo_root, context: "final promotion publication boundary")
  return if boundary_head_sha == final_head_sha

  abort "❌ Final promotion is blocked: local HEAD moved after validation at the publication boundary."
end

def exact_final_shakaperf_observation_waiver_snapshot?(run:, record:, ref:, head_sha:, target_version:)
  [
    run["observationWaived"] == true,
    record.values_at("branch", "candidate_sha", "target_version") == [ref, head_sha, target_version],
    record.values_at("run_id", "run_attempt", "run_url") == run.values_at("databaseId", "attempt", "url"),
    run["status"] != "completed",
    run["conclusion"].to_s.empty?
  ].all?
end

def ordinary_stable_shakaperf_association_context_identity(context)
  canonical_accelerated_rc_json(
    "association_identity" => context.fetch(:association_identity),
    "expected_run" => context.fetch(:expected_run),
    "release_branch" => context.fetch(:release_branch),
    "release_candidate_sha" => context.fetch(:release_candidate_sha),
    "release_started_at" => context.fetch(:release_started_at),
    "release_tracker" => context.fetch(:release_tracker),
    "target_version" => context.fetch(:target_version)
  )
end

def ordinary_stable_shakaperf_association_context_shape?(context)
  required_keys = %i[
    association_identity expected_run identity_anchor release_branch release_candidate_sha release_started_at
    release_tracker target_version
  ]
  return false unless context.is_a?(Hash) && context.keys.sort == required_keys.sort

  accelerated_rc_exact_keys?(
    context.fetch(:association_identity), SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_IDENTITY_FIELDS
  ) && accelerated_rc_exact_keys?(
    context.fetch(:expected_run), %w[run_id attempt run_url status conclusion]
  )
end

def valid_ordinary_stable_shakaperf_association_context?(context)
  return false unless ordinary_stable_shakaperf_association_context_shape?(context)

  association = context.fetch(:association_identity)
  expected_run = context.fetch(:expected_run)
  anchor = context.fetch(:identity_anchor)

  [
    valid_accelerated_rc_tracker_number?(context.fetch(:release_tracker)),
    valid_accelerated_rc_nonempty_string?(context.fetch(:release_branch)),
    context.fetch(:release_candidate_sha).to_s.match?(/\A[0-9a-f]{40}\z/),
    !release_prerelease_version?(context.fetch(:target_version)),
    !shakaperf_release_gate_time(context.fetch(:release_started_at)).nil?,
    association.values_at("release_tracker", "branch", "target_version") ==
      context.values_at(:release_tracker, :release_branch, :target_version),
    association.values_at("run_id", "run_attempt", "run_url") ==
      expected_run.values_at("run_id", "attempt", "run_url"),
    expected_run.values_at("status", "conclusion") == %w[completed success],
    anchor.is_a?(String),
    anchor.frozen?,
    anchor == ordinary_stable_shakaperf_association_context_identity(context)
  ].all?
rescue KeyError
  false
end

def ordinary_stable_shakaperf_association_context_applicable?(tracker:, run:, target_version:)
  tracker && !release_prerelease_version?(target_version) && run.is_a?(ShakaperfAssociationBackedRun) &&
    run.values_at("status", "conclusion") == %w[completed success]
end

def ordinary_stable_shakaperf_expected_run(run)
  normalized_run = normalized_selected_shakaperf_release_gate_run(run)
  {
    "run_id" => normalized_run.fetch("databaseId"),
    "attempt" => normalized_run.fetch("attempt"),
    "run_url" => normalized_run.fetch("url"),
    "status" => normalized_run.fetch("status"),
    "conclusion" => normalized_run.fetch("conclusion")
  }
end

def build_ordinary_stable_shakaperf_association_context(association:, expected_run:, tracker:, ref:, head_sha:,
                                                        target_version:, release_started_at:)
  started_at = shakaperf_release_gate_time(release_started_at)
  abort "❌ Ordinary stable ShakaPerf association context has an invalid release start time." unless started_at

  association_identity = SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_IDENTITY_FIELDS.to_h do |field|
    [field, association.fetch(field)]
  end
  context = {
    association_identity:,
    expected_run:,
    release_branch: ref,
    release_candidate_sha: head_sha,
    release_started_at: started_at.iso8601,
    release_tracker: tracker,
    target_version:
  }
  context[:identity_anchor] = ordinary_stable_shakaperf_association_context_identity(context).freeze
  context.freeze
end

def ordinary_stable_shakaperf_association_context!(repo_slug:, tracker:, run:, ref:, head_sha:, target_version:,
                                                   release_started_at:)
  return nil unless ordinary_stable_shakaperf_association_context_applicable?(tracker:, run:, target_version:)

  expected_run = ordinary_stable_shakaperf_expected_run(run)
  entry = selected_shakaperf_release_tracker_record!(
    repo_slug:, tracker:, ref:, head_sha:, target_version:, run_id: expected_run.fetch("run_id")
  )
  unless entry && entry[:kind] == :association
    abort "❌ Successful tracker-backed ShakaPerf run is missing its canonical association."
  end

  association = entry.fetch(:record)
  current_identity = SHAKAPERF_RELEASE_TRACKER_ASSOCIATION_IDENTITY_FIELDS.to_h do |field|
    [field, association[field]]
  end
  unless current_identity == run.association_identity
    abort "❌ ShakaPerf association provenance changed before context creation."
  end
  unless association.values_at("run_id", "run_attempt", "run_url") ==
         expected_run.values_at("run_id", "attempt", "run_url")
    abort "❌ Ordinary stable ShakaPerf association context does not match the successful selected run."
  end

  build_ordinary_stable_shakaperf_association_context(
    association:, expected_run:, tracker:, ref:, head_sha:, target_version:, release_started_at:
  )
end

def validate_ordinary_stable_shakaperf_association_boundary!(monorepo_root:, context:, phase:)
  return unless context

  unless valid_ordinary_stable_shakaperf_association_context?(context)
    abort "❌ Ordinary stable #{phase} ShakaPerf association context is malformed or changed."
  end

  repo_slug = github_repo_slug(monorepo_root)
  tracker = context.fetch(:release_tracker)
  target_version = context.fetch(:target_version)
  fetch_release_tracker_issue!(repo_slug:, tracker:, target_version:)
  expected_run = context.fetch(:expected_run)
  observed_run = reuse_shakaperf_release_tracker_evidence(
    repo_slug:,
    monorepo_root:,
    tracker:,
    ref: context.fetch(:release_branch),
    head_sha: context.fetch(:release_candidate_sha),
    target_version:,
    release_started_at: shakaperf_release_gate_time(context.fetch(:release_started_at)),
    run_id: expected_run.fetch("run_id"),
    expected_association_identity: context.fetch(:association_identity)
  )
  abort "❌ Ordinary stable release #{phase} ShakaPerf association disappeared or is not reusable." unless observed_run

  observed_identity = {
    "run_id" => observed_run["databaseId"],
    "attempt" => observed_run["attempt"],
    "run_url" => observed_run["url"],
    "status" => observed_run["status"],
    "conclusion" => observed_run["conclusion"]
  }
  return observed_run if observed_identity == expected_run

  abort "❌ Ordinary stable release #{phase} ShakaPerf run identity or result changed."
rescue ShakaperfGateObservationError => e
  abort "❌ Ordinary stable release ShakaPerf association could not be re-observed before #{phase}.\n\n#{e.message}"
end

def build_final_shakaperf_observation_waiver_snapshot(run:, record:, head_sha:, target_version:, started_at:)
  {
    status: "observation_waived",
    run_id: record.fetch("run_id"),
    attempt: record.fetch("run_attempt"),
    run_url: record.fetch("run_url"),
    candidate_sha: head_sha,
    target_version:,
    release_started_at: started_at.iso8601,
    observed_status: run["status"],
    observed_conclusion: run["conclusion"],
    release_tracker: record.fetch("release_tracker"),
    waiver_digest: Digest::SHA256.hexdigest(canonical_accelerated_rc_json(record))
  }
end

def final_shakaperf_observation_waiver_snapshot!(run:, ref:, head_sha:, target_version:, release_started_at:)
  record = run.fetch("waiverRecord", nil)
  validate_final_shakaperf_observation_waiver_record!(record)
  valid = exact_final_shakaperf_observation_waiver_snapshot?(run:, record:, ref:, head_sha:, target_version:)
  abort "❌ Final promotion ShakaPerf observation waiver identity is malformed or not exact." unless valid

  started_at = shakaperf_release_gate_time(release_started_at)
  abort "❌ Final promotion ShakaPerf observation waiver has an invalid release start time." unless started_at

  build_final_shakaperf_observation_waiver_snapshot(run:, record:, head_sha:, target_version:, started_at:)
end

def ordinary_stable_shakaperf_waiver_context!(run:, ref:, head_sha:, target_version:, release_started_at:)
  return nil unless run.is_a?(Hash) && run["observationWaived"] == true

  abort "❌ Ordinary ShakaPerf observation waiver context is allowed for stable releases only." if
    release_prerelease_version?(target_version)

  expected_snapshot = json_compatible_release_value(
    final_shakaperf_observation_waiver_snapshot!(
      run:, ref:, head_sha:, target_version:, release_started_at:
    )
  )
  carried_record = {
    "release_branch" => ref,
    "candidate_sha" => head_sha,
    "target_version" => target_version
  }
  context = { carried_record:, expected_snapshot: }
  context[:identity_anchor] = ordinary_stable_shakaperf_waiver_context_identity(context).freeze
  context.freeze
end

def strict_final_promotion_shakaperf_snapshot!(monorepo_root:, current_branch:, final_head_sha:, target_version:,
                                               release_started_at:, allow_ci_override:, dry_run:, tracker: nil,
                                               run_selector: nil, waiver_reason: nil)
  run = run_shakaperf_release_gate!(
    monorepo_root:,
    ref: current_branch,
    head_sha: final_head_sha,
    target_version:,
    release_started_at:,
    allow_override: allow_ci_override,
    dry_run:,
    tracker:,
    run_selector:,
    waiver_reason:
  )
  if run.is_a?(Hash) && run["observationWaived"] == true
    return final_shakaperf_observation_waiver_snapshot!(
      run:, ref: current_branch, head_sha: final_head_sha, target_version:, release_started_at:
    )
  end
  unless run.is_a?(Hash) && run["status"] == "completed" && run["conclusion"] == "success"
    abort "❌ Final promotion is blocked: strict ShakaPerf gate identity is missing, malformed, or unknown."
  end
  unless run["headSha"] == final_head_sha
    abort "❌ Final promotion is blocked: strict ShakaPerf gate is not bound to the exact final candidate."
  end

  accelerated_shakaperf_snapshot(
    repo_slug: github_repo_slug(monorepo_root),
    run:,
    ref: current_branch,
    candidate_sha: final_head_sha,
    target_version:,
    release_started_at:,
    status: "success"
  )
end

def final_promotion_boundary_context(final_head_sha:, current_branch:, record:, ci_snapshot:, shakaperf_evidence:,
                                     final_target_version:, source_rc_context:)
  normalized_shakaperf = json_compatible_release_value(shakaperf_evidence.fetch(:snapshot))
  shakaperf_evidence_mode = shakaperf_evidence.fetch(:mode)
  shakaperf_record = {
    "release_branch" => current_branch,
    "candidate_sha" => normalized_shakaperf.fetch("candidate_sha"),
    "target_version" => normalized_shakaperf.fetch("target_version"),
    "shakaperf" => normalized_shakaperf
  }
  context = {
    candidate_sha: final_head_sha,
    ci_branch: current_branch,
    final_target_version:,
    record:,
    ci_snapshot: json_compatible_release_value(ci_snapshot),
    shakaperf_evidence_mode:,
    shakaperf_record:
  }
  if [FINAL_PROMOTION_SHAKAPERF_STRICT_FINAL_MODE, FINAL_PROMOTION_SHAKAPERF_OBSERVATION_WAIVER_MODE].include?(
    shakaperf_evidence_mode
  )
    context[:strict_final_shakaperf_identity_anchor] = final_promotion_shakaperf_identity_anchor(shakaperf_record)
  end
  context.merge(source_rc_context)
end

def final_promotion_source_rc_context!(monorepo_root:, rc_tag:, record:, source_rc_tag_identity:)
  unless valid_accelerated_rc_tag_object_identity?(source_rc_tag_identity)
    abort "❌ Final promotion is blocked: source RC tag identity is missing or malformed."
  end
  phase = "final-promotion context construction"
  identity = live_annotated_release_tag_identity!(
    monorepo_root:,
    tag: rc_tag,
    phase:,
    tag_object_sha: source_rc_tag_identity.fetch(:tag_object_sha)
  )
  provenance = identity.fetch(:provenance)
  expected_identity = record.values_at("target_version", "candidate_sha", "release_tracker")
  valid = provenance && rc_tag == "v#{record.fetch('target_version')}" &&
          identity == source_rc_tag_identity &&
          provenance.values_at("target_version", "candidate_sha", "release_tracker") == expected_identity &&
          identity.fetch(:candidate_sha) == record.fetch("candidate_sha")
  abort "❌ Final promotion is blocked: source RC tag lacks matching canonical accelerated provenance." unless valid

  {
    source_rc_tag: rc_tag,
    source_rc_tag_object_sha: identity.fetch(:tag_object_sha),
    source_rc_candidate_sha: record.fetch("candidate_sha"),
    source_rc_tag_provenance: provenance
  }
end

def final_promotion_shakaperf_snapshot!(repo_slug:, monorepo_root:, current_branch:, final_head_sha:, record:,
                                        target_version:, release_started_at:, allow_ci_override:, dry_run:,
                                        tracker: nil, run_selector: nil, waiver_reason: nil)
  reused = if run_selector
             false
           else
             reuse_accepted_rc_shakaperf_evidence!(
               repo_slug:, monorepo_root:, ref: current_branch, head_sha: final_head_sha, record:
             )
           end
  if reused
    return {
      mode: FINAL_PROMOTION_SHAKAPERF_ACCEPTED_RC_MODE,
      snapshot: record.fetch("shakaperf")
    }
  end

  strict_snapshot = strict_final_promotion_shakaperf_snapshot!(
    monorepo_root:,
    current_branch:,
    final_head_sha:,
    target_version:,
    release_started_at:,
    allow_ci_override:,
    dry_run:,
    tracker:,
    run_selector:,
    waiver_reason:
  )
  mode = if strict_snapshot.fetch(:status) == "observation_waived"
           FINAL_PROMOTION_SHAKAPERF_OBSERVATION_WAIVER_MODE
         else
           FINAL_PROMOTION_SHAKAPERF_STRICT_FINAL_MODE
         end
  {
    mode:,
    snapshot: strict_snapshot
  }
end

def final_promotion_context_after_boundary!(repo_slug:, monorepo_root:, current_branch:, rc_tag:, final_head_sha:,
                                            target_version:, ci_snapshot:, shakaperf_evidence:,
                                            boundary_selection:)
  boundary_record = boundary_selection.fetch(:record)
  boundary_ci_snapshot = refresh_accepted_rc_ci_evidence_for_promotion!(
    repo_slug:, monorepo_root:, ci_branch: current_branch, record: boundary_record
  )
  unless canonical_accelerated_rc_ci_snapshot_for_comparison(boundary_ci_snapshot) ==
         canonical_accelerated_rc_ci_snapshot_for_comparison(ci_snapshot)
    abort "❌ Final promotion is blocked: exact-candidate CI evidence changed at the publication boundary."
  end
  validate_final_promotion_boundary_head!(monorepo_root:, final_head_sha:)
  source_rc_context = final_promotion_source_rc_context!(
    monorepo_root:,
    rc_tag:,
    record: boundary_record,
    source_rc_tag_identity: boundary_selection.fetch(:source_rc_tag_identity)
  )

  final_promotion_boundary_context(
    final_head_sha:,
    current_branch:,
    record: boundary_record,
    ci_snapshot: boundary_ci_snapshot,
    shakaperf_evidence:,
    final_target_version: target_version,
    source_rc_context:
  )
end

def run_accepted_rc_final_promotion_gates!(repo_slug:, monorepo_root:, current_branch:, rc_tag:, tracker_input:,
                                           final_head_sha:, record:, target_version:, release_started_at:,
                                           allow_ci_override:, dry_run:, shakaperf_tracker: nil,
                                           shakaperf_run_selector: nil, shakaperf_waiver_reason: nil)
  unless accelerated_rc_runtime_equivalent?(
    record:, rc_sha: record.fetch("candidate_sha"), final_head_sha:, monorepo_root:
  )
    abort "❌ Final promotion is blocked: post-bump runtime drift requires a new accepted RC; " \
          "a fresh final ShakaPerf run cannot replace accepted candidate evidence."
  end

  ci_snapshot = refresh_accepted_rc_ci_evidence_for_promotion!(
    repo_slug:, monorepo_root:, ci_branch: current_branch, record:
  )
  shakaperf_evidence = final_promotion_shakaperf_snapshot!(
    repo_slug:,
    monorepo_root:,
    current_branch:,
    final_head_sha:,
    record:,
    target_version:,
    release_started_at:,
    allow_ci_override:,
    dry_run:,
    tracker: shakaperf_tracker,
    run_selector: shakaperf_run_selector,
    waiver_reason: shakaperf_waiver_reason
  )

  boundary_selection = accepted_rc_record_at_publication_boundary!(
    monorepo_root:, rc_tag:, final_head_sha:, tracker_input:, record:
  )
  final_promotion_context_after_boundary!(
    repo_slug:, monorepo_root:, current_branch:, rc_tag:, final_head_sha:, target_version:, ci_snapshot:,
    shakaperf_evidence:, boundary_selection:
  )
end

def accelerated_rc_runtime_equivalent?(record:, rc_sha:, final_head_sha:, monorepo_root:)
  fingerprint = record["runtime_tree_fingerprint"]
  return false unless fingerprint.to_s.match?(/\A[0-9a-f]{64}\z/)

  candidate_fingerprint = shakaperf_runtime_tree_fingerprint(monorepo_root:, sha: rc_sha)
  return false unless candidate_fingerprint == fingerprint
  return true if final_head_sha == rc_sha

  commits_after_rc = release_branch_commits_after_rc_tag(
    monorepo_root:, tag_sha: rc_sha, head_sha: final_head_sha
  )
  valid_accelerated_rc_non_runtime_classification?(commits_after_rc)
end

def valid_accelerated_rc_non_runtime_classification?(classification)
  return false unless accelerated_rc_exact_keys?(classification, %i[status commits])

  commits = classification[:commits]
  classification[:status] == :non_runtime_only && commits.is_a?(Array) && !commits.empty? &&
    commits.all? { |sha| sha.is_a?(String) && sha.match?(/\A[0-9a-f]{40}\z/) }
end

def reuse_accepted_rc_shakaperf_evidence!(repo_slug:, monorepo_root:, ref:, head_sha:, record:)
  stored = record.fetch("shakaperf")
  run = refresh_shakaperf_release_gate_run!(repo_slug:, run: { "databaseId" => stored.fetch("run_id") })
  validate_accelerated_shakaperf_run_metadata!(repo_slug:, run:)
  unless valid_accelerated_rc_shakaperf_run_identity?(repo_slug:, run:, stored:, ref:)
    puts "Accepted RC ShakaPerf evidence is not reusable (run identity changed); running the strict final gate."
    return false
  end
  run_url = run.fetch("url")
  unless run["status"] == "completed" && run["conclusion"] == "success"
    puts "Accepted RC ShakaPerf evidence is not reusable (workflow is no longer a successful terminal run): #{run_url}"
    return false
  end

  release_started_at = shakaperf_release_gate_time(stored["release_started_at"])
  unless release_started_at
    puts "Accepted RC ShakaPerf evidence is not reusable (stored release start time is invalid): #{run_url}"
    return false
  end

  rejection = shakaperf_release_gate_run_evidence_rejection(
    repo_slug:,
    monorepo_root:,
    ref:,
    head_sha:,
    target_version: record.fetch("target_version"),
    run:,
    release_started_at:,
    require_prerun: accelerated_rc_shakaperf_requires_prerun?(record)
  )
  if rejection
    puts "Accepted RC ShakaPerf evidence is not reusable (#{rejection}): #{run_url}"
    return false
  end

  puts "✓ Reusing accepted RC ShakaPerf evidence for runtime-equivalent final promotion: #{run_url}"
  true
rescue KeyError => e
  puts "Accepted RC ShakaPerf evidence is not reusable (missing #{e.key.inspect}); running the strict final gate."
  false
end

# Escape hatch: force the CI gate to evaluate origin/main HEAD verbatim instead
# of walking back over non-runtime-only commits (see `main_ci_evaluation_sha`).
def ci_evaluate_head_only?
  release_truthy?(ENV.fetch("RELEASE_CI_EVALUATE_HEAD", nil))
end

# Statuses considered "incomplete" — anything not yet a finalized conclusion.
CI_INCOMPLETE_STATUSES = %w[in_progress queued waiting requested pending].freeze
# Conclusions considered acceptable. `skipped`/`neutral` are not failures (e.g. docs-only
# paths-ignore skips, or workflows that intentionally short-circuit).
CI_PASSING_CONCLUSIONS = %w[success skipped neutral].freeze
CI_CHECK_RUN_STATUSES = (CI_INCOMPLETE_STATUSES + ["completed"]).freeze
CI_COMPLETED_CONCLUSIONS = %w[
  action_required cancelled failure neutral skipped stale success timed_out
].freeze
CI_LEGACY_STATUS_STATES = %w[error failure pending success].freeze
CI_JSONL_FRAME_KEY = "_release_ci_jsonl_frame"
CI_JSONL_ENVELOPE_FRAME = "envelope"
CI_JSONL_ITEM_FRAME = "item"
CI_CHECK_RUNS_JSONL_QUERY = [
  'if type == "object" and (.check_runs | type == "array") then',
  [
    "[\"#{CI_JSONL_FRAME_KEY}\", \"#{CI_JSONL_ENVELOPE_FRAME}\", \"check_runs\"], ",
    "(.check_runs[] | [\"#{CI_JSONL_FRAME_KEY}\", \"#{CI_JSONL_ITEM_FRAME}\", .])"
  ].join,
  'else error("expected check_runs array") end'
].join(" ")
CI_STATUSES_JSONL_QUERY = [
  'if type == "object" and (.sha | type == "string" and test("[^[:space:]]")) and ' \
  '(.statuses | type == "array") then',
  [
    "[\"#{CI_JSONL_FRAME_KEY}\", \"#{CI_JSONL_ENVELOPE_FRAME}\", {\"name\": \"statuses\", \"sha\": .sha}], ",
    "(.statuses[] | [\"#{CI_JSONL_FRAME_KEY}\", \"#{CI_JSONL_ITEM_FRAME}\", .])"
  ].join,
  'else error("expected status object with sha and statuses array") end'
].join(" ")
REQUIRED_CHECKS_JQ_QUERY = [
  "{contexts, checks: (if .checks == null then []",
  'elif (.checks | type) == "array" then (.checks | map({context, app_id}))',
  "else .checks end)}"
].join(" ")
REQUIRED_CHECK_DISCOVERY_UNKNOWN = Object.new.freeze
BRANCH_RULES_PAGE_SIZE = 100
BRANCH_RULES_API_HEADERS = [
  "-H", "Accept: application/vnd.github+json",
  "-H", "X-GitHub-Api-Version: 2022-11-28"
].freeze

# Upper bound on how many consecutive non-runtime-only commits the CI gate will
# walk past when choosing which origin/main commit to evaluate. Bounds the git
# work and guards against an unbounded walk; beyond this we evaluate wherever we
# stopped. A real chain of docs/changelog commits is far shorter than this.
MAIN_CI_NONRUNTIME_WALK_LIMIT = 25

def ci_branch_fetch_refspec(ci_branch)
  return ci_branch unless ci_branch.start_with?("release/")

  "+refs/heads/#{ci_branch}:refs/remotes/origin/#{ci_branch}"
end

def handle_release_branch_identity_violation!(message:, dry_run:)
  if dry_run
    puts "⚠️ DRY RUN: #{message.sub(/\A❌\s*/, '')}"
    return
  end

  abort message
end

# Abort in strict mode when a release branch local HEAD differs from the remote.
# In dry-run mode, warn and continue so the releaser still sees remote CI state.
# The normal CI override must not bypass this: otherwise the release could tag a
# local commit whose remote release-branch CI belongs to a different SHA.
def ensure_release_branch_head_matches_remote!(monorepo_root:, ci_branch:, remote_sha:, dry_run:)
  return unless ci_branch.start_with?("release/")

  head_output, head_status = Open3.capture2e("git", "-C", monorepo_root, "rev-parse", "HEAD")
  unless head_status.success?
    handle_release_branch_identity_violation!(
      message: "❌ Unable to resolve local HEAD before release CI status check.\n\n#{head_output}",
      dry_run:
    )
    # Strict mode aborts above; dry-run mode should still evaluate remote CI after warning.
    return
  end

  local_sha = head_output.strip
  return if local_sha == remote_sha

  handle_release_branch_identity_violation!(
    message: <<~MESSAGE,
      ❌ Local HEAD does not match origin/#{ci_branch} before release CI status check.

      Local HEAD: #{local_sha}
      origin/#{ci_branch}: #{remote_sha}

      Push, reset, or rebase the release branch so the commit being tagged is the same commit whose CI is being validated.
    MESSAGE
    dry_run:
  )
  # Strict mode aborts above; dry-run mode should still evaluate remote CI after warning.
end

def fetch_main_ci_checks(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
  release_branch = ci_branch.start_with?("release/")
  fetch_refspec = ci_branch_fetch_refspec(ci_branch)
  fetch_output, fetch_status = Open3.capture2e(
    "git", "-C", monorepo_root, "fetch", "origin", fetch_refspec, "--quiet"
  )
  unless fetch_status.success?
    message = "❌ Unable to fetch origin/#{ci_branch} for CI status check.\n\n#{fetch_output}"
    if release_branch
      handle_release_branch_identity_violation!(message:, dry_run:)
    else
      handle_main_ci_status_violation!(message:, allow_override:, dry_run:)
    end
    return nil
  end

  sha_output, sha_status = Open3.capture2e("git", "-C", monorepo_root, "rev-parse", "origin/#{ci_branch}")
  unless sha_status.success?
    message = "❌ Unable to resolve origin/#{ci_branch} HEAD.\n\n#{sha_output}"
    if release_branch
      handle_release_branch_identity_violation!(message:, dry_run:)
    else
      handle_main_ci_status_violation!(message:, allow_override:, dry_run:)
    end
    return nil
  end
  remote_sha = sha_output.strip
  # Strict mode aborts on mismatch. Dry-run mode warns and continues so
  # the releaser still sees the remote CI state instead of silently skipping it.
  ensure_release_branch_head_matches_remote!(
    monorepo_root:,
    ci_branch:,
    remote_sha:,
    dry_run:
  )

  # Evaluate the most recent commit that actually ran the full suite. When HEAD
  # is changelog/docs/comment-only (e.g. the pre-release `update-changelog`
  # commit), CI path-skips the runtime suite there, so its checks tell us
  # nothing about release health — walk back to the last runtime-bearing commit.
  sha = main_ci_evaluation_sha(monorepo_root:, head_sha: remote_sha, ref: "origin/#{ci_branch}")

  repo_slug = github_repo_slug(monorepo_root)
  result = fetch_ci_check_runs_for_sha(repo_slug:, sha:)
  if result[:error]
    handle_main_ci_status_violation!(message: result[:error], allow_override:, dry_run:)
    return nil
  end

  { sha:, head_sha: remote_sha, repo_slug:, check_runs: result[:check_runs] }
end

def fetch_ci_check_runs_for_sha(repo_slug:, sha:)
  api_path = "repos/#{repo_slug}/commits/#{sha}/check-runs"
  result = fetch_github_jsonl(
    api_path:, jq_query: CI_CHECK_RUNS_JSONL_QUERY, api_name: "Checks", response_name: "check_runs", sha:,
    envelope_name: "check_runs", item_validator: ->(run) { valid_ci_check_run?(run, sha:) }
  )
  return result if result[:error]

  { check_runs: result[:items] }
end

def fetch_ci_statuses_for_sha(repo_slug:, sha:)
  api_path = "repos/#{repo_slug}/commits/#{sha}/status"
  result = fetch_github_jsonl(
    api_path:, jq_query: CI_STATUSES_JSONL_QUERY, api_name: "Statuses", response_name: "statuses", sha:,
    envelope_name: "statuses", envelope_validator: ->(envelope) { valid_ci_statuses_envelope?(envelope, sha:) },
    item_validator: method(:valid_ci_status?)
  )
  return result if result[:error]

  { statuses: result[:items] }
end

# Query a GitHub API endpoint as JSONL without deciding whether a failure can be
# overridden. The normal release gate and exact-HEAD recovery diagnostic apply
# different policy to the same evidence, so callers receive fail-closed errors.
def fetch_github_jsonl(api_path:, jq_query:, api_name:, response_name:, sha:, envelope_name:, item_validator:,
                       envelope_validator: nil)
  output, status = Open3.capture2e("gh", "api", "--paginate", "--jq", jq_query, api_path)
  return { error: "❌ Unable to query GitHub #{api_name} API for #{sha}.\n\n#{output}" } unless status.success?

  items = validated_github_jsonl_items(output:, envelope_name:, item_validator:, envelope_validator:)
  return { error: "❌ Received malformed GitHub #{api_name} evidence for #{sha}; release remains blocked." } unless items

  { items: }
rescue Errno::ENOENT
  { error: "❌ GitHub CLI (`gh`) is not installed. Install it from https://cli.github.com/ and retry." }
rescue JSON::ParserError => e
  { error: "❌ Failed to parse #{response_name} response from gh: #{e.message}\n\nOutput:\n#{output}" }
end

def validated_github_jsonl_items(output:, envelope_name:, item_validator:, envelope_validator: nil)
  parsed_items = parse_gh_jsonl(output)
  return unless parsed_items
  return unless valid_github_jsonl_frames?(parsed_items, envelope_name:, envelope_validator:)

  items = github_jsonl_frame_items(parsed_items, envelope_name:, envelope_validator:)
  return unless items.all?(&item_validator)

  items
end

def valid_github_jsonl_frames?(parsed_items, envelope_name:, envelope_validator:)
  return false unless github_jsonl_envelope_frame?(parsed_items.first, envelope_name:, envelope_validator:)

  parsed_items.all? do |item|
    github_jsonl_envelope_frame?(item, envelope_name:, envelope_validator:) || github_jsonl_item_frame?(item)
  end
end

def github_jsonl_frame_items(parsed_items, envelope_name:, envelope_validator:)
  parsed_items.reject { |item| github_jsonl_envelope_frame?(item, envelope_name:, envelope_validator:) }
              .map { |item| item[2] }
end

def github_jsonl_envelope_frame?(item, envelope_name:, envelope_validator:)
  return false unless item.is_a?(Array) && item.length == 3
  return false unless item[0] == CI_JSONL_FRAME_KEY && item[1] == CI_JSONL_ENVELOPE_FRAME

  envelope_validator ? envelope_validator.call(item[2]) : item[2] == envelope_name
end

def github_jsonl_item_frame?(item)
  item.is_a?(Array) && item.length == 3 && item[0] == CI_JSONL_FRAME_KEY && item[1] == CI_JSONL_ITEM_FRAME
end

def parse_gh_jsonl(output)
  output = normalized_utf8_output(output)
  return unless output

  output.lines.reject { |line| line.strip.empty? }.map do |line|
    JSON.parse(line)
  end
end

def normalized_utf8_output(output)
  return unless output.is_a?(String)

  output = output.dup
  output.force_encoding(Encoding::UTF_8) if output.encoding == Encoding::BINARY
  return unless output.valid_encoding? && output.encoding.ascii_compatible?

  output.encode(Encoding::UTF_8)
rescue ArgumentError, Encoding::CompatibilityError, Encoding::InvalidByteSequenceError,
       Encoding::UndefinedConversionError
  nil
end

def valid_ci_check_run_app?(run)
  return true unless run.key?("app")

  app = run["app"]
  return false unless app.is_a?(Hash) && app.key?("id")

  positive_github_id?(app["id"])
end

def valid_ci_check_run_suite?(run)
  return true unless run.key?("check_suite")

  suite = run["check_suite"]
  suite.is_a?(Hash) && positive_github_id?(suite["id"])
end

def valid_ci_check_run_identity?(run)
  return false unless run.is_a?(Hash) && positive_github_id?(run["id"])
  return false unless run["name"].is_a?(String) && !run["name"].empty?

  valid_ci_check_run_app?(run) && valid_ci_check_run_suite?(run)
end

def valid_ci_check_run_state?(run)
  return false unless CI_CHECK_RUN_STATUSES.include?(run["status"])

  if run["status"] == "completed"
    CI_COMPLETED_CONCLUSIONS.include?(run["conclusion"])
  else
    run["conclusion"].nil?
  end
end

def positive_github_id?(id)
  id.is_a?(Integer) && id.positive?
end

def valid_ci_check_run?(run, sha: nil)
  valid_ci_check_run_identity?(run) && valid_ci_check_run_state?(run) && (sha.nil? || run["head_sha"] == sha)
end

def valid_ci_statuses_envelope?(envelope, sha:)
  sha.is_a?(String) && !sha.empty? && envelope.is_a?(Hash) &&
    envelope["name"] == "statuses" && envelope["sha"] == sha
end

def valid_ci_status?(status)
  status.is_a?(Hash) && positive_github_id?(status["id"]) &&
    status["context"].is_a?(String) && !status["context"].empty? &&
    CI_LEGACY_STATUS_STATES.include?(status["state"]) && valid_ci_status_created_at?(status)
end

def valid_ci_status_created_at?(status)
  !parsed_ci_status_created_at(status).nil?
end

def parsed_ci_status_created_at(status)
  created_at = status["created_at"]
  return unless created_at.is_a?(String) && !created_at.strip.empty?

  Time.iso8601(created_at)
rescue ArgumentError
  nil
end

# Choose which remote ref commit the CI gate should evaluate. Starting at
# `head_sha`, walk back over commits that do not prove release health: commits
# that `script/ci-changes-detector` classifies as non-runtime-only, plus final
# release metadata-only commits on `release/*` branches. The walk stops at HEAD
# when a commit is not provably skippable, so the behavior degrades to the
# original "evaluate HEAD" gate.
def main_ci_evaluation_sha(monorepo_root:, head_sha:, ref: "origin/main")
  return head_sha if ci_evaluate_head_only?

  current = head_sha
  skipped = []
  MAIN_CI_NONRUNTIME_WALK_LIMIT.times do
    break unless main_ci_walkback_commit?(monorepo_root:, sha: current, ref:)

    parent = git_parent_sha(monorepo_root:, sha: current)
    break if parent.nil?

    skipped << current
    current = parent
  end

  log_main_ci_walkback(head_sha:, evaluated_sha: current, skipped:, ref:) unless skipped.empty?
  current
end

def log_main_ci_walkback(head_sha:, evaluated_sha:, skipped:, ref:)
  puts "ℹ️ #{ref} HEAD #{head_sha[0, 8]} is release-gate metadata or non-runtime-only; " \
       "CI can skip the full runtime suite on such commits."
  puts "   Skipped #{skipped.length} release-gate commit(s): #{skipped.map { |s| s[0, 8] }.join(', ')}"
  puts "   Evaluating CI on #{evaluated_sha[0, 8]} — the most recent commit that ran the full suite."
  puts "   Strict exact-HEAD recovery is offered only after exact-HEAD CI evidence is complete and healthy."
end

def main_ci_walkback_commit?(monorepo_root:, sha:, ref:)
  return true if commit_non_runtime_only?(monorepo_root:, sha:)
  return false unless ref.to_s.start_with?("origin/release/")

  release_finalization_metadata_commit?(monorepo_root:, sha:)
end

# Whether `sha`'s changes are *provably* non-runtime-only per the canonical CI
# detector. Returns true only when the detector positively reports
# `non_runtime_only=true`; every other outcome (script missing, git/detector
# failure, unparseable output, or an explicit `false`) returns false. Conflating
# "unknown" with "runtime-bearing" is the safe direction for a release gate: the
# walk stops and the current commit is evaluated rather than skipped on a guess.
def commit_non_runtime_only?(monorepo_root:, sha:)
  detector = File.join(monorepo_root, "script", "ci-changes-detector")
  return false unless File.executable?(detector)

  Dir.mktmpdir("ror-ci-detector") do |dir|
    output_file = File.join(dir, "github_output")
    File.write(output_file, "")
    # The detector writes `non_runtime_only=true|false` to $GITHUB_OUTPUT — the
    # same machine interface CI consumes — so we reuse its path classification
    # instead of re-deriving paths-ignore rules here. `<sha>^ <sha>` diffs just
    # that commit; a non-HEAD current ref means no uncommitted folding.
    _stdout, status = Open3.capture2e(
      { "GITHUB_OUTPUT" => output_file }, detector, "#{sha}^", sha, chdir: monorepo_root
    )
    return false unless status.success?

    flag = File.read(output_file).lines.reverse.find { |line| line.start_with?("non_runtime_only=") }
    return false if flag.nil?

    flag.split("=", 2).last.strip == "true"
  end
rescue StandardError
  false
end

def release_finalization_metadata_commit?(monorepo_root:, sha:)
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "diff-tree", "--no-commit-id", "--name-status", "-r", "#{sha}^", sha
  )
  return false unless status.success?

  changes = output.lines.map { |line| release_finalization_metadata_path(line) }

  # Empty diffs are not metadata commits. Non-modification entries map to nil
  # via release_finalization_metadata_path and fail the all? block below.
  changes.any? && changes.all? do |path|
    path &&
      RELEASE_FINALIZATION_METADATA_PATHS.include?(path) &&
      release_finalization_metadata_content_only?(monorepo_root:, sha:, path:)
  end
rescue UnhandledReleaseFinalizationMetadataPathError
  raise
rescue StandardError => e
  warn "⚠️ Unable to inspect release finalization metadata for #{sha}: #{e.class}: #{e.message}; " \
       "treating commit as runtime-bearing."
  false
end

def release_finalization_metadata_path(change_line)
  status_code, path, extra = change_line.chomp.split("\t", 3)
  return nil unless status_code == "M"
  return nil if path.nil? || extra

  path
end

def release_finalization_metadata_content_only?(monorepo_root:, sha:, path:)
  before = git_file_at_commit(monorepo_root:, ref: "#{sha}^", path:)
  after = git_file_at_commit(monorepo_root:, ref: sha, path:)
  return false if before.nil? || after.nil?

  release_finalization_metadata_contents_only?(before:, after:, path:)
end

def release_finalization_metadata_contents_only?(before:, after:, path:)
  if path.end_with?("package.json")
    package_json_version_only_change?(before, after)
  elsif path.end_with?("version.rb")
    normalized_version_file(before) == normalized_version_file(after)
  elsif path.end_with?("Gemfile.lock")
    normalized_release_gemfile_lock(before) == normalized_release_gemfile_lock(after)
  else
    raise UnhandledReleaseFinalizationMetadataPathError,
          "Unhandled release finalization metadata path type: #{path.inspect}"
  end
end

def git_file_at_commit(monorepo_root:, ref:, path:)
  output, status = Open3.capture2e("git", "-C", monorepo_root, "show", "#{ref}:#{path}")
  return nil unless status.success?

  output
end

def package_json_version_only_change?(before, after)
  before_json = JSON.parse(before)
  after_json = JSON.parse(after)
  before_version = before_json["version"]
  after_version = after_json["version"]

  !!(before_version && after_version && before_version != after_version &&
     before_json.except("version") == after_json.except("version"))
rescue JSON::ParserError
  false
end

def normalized_version_file(content)
  content.gsub(/(\bVERSION = )"[^"]+"/, '\1"__RELEASE_VERSION__"')
end

def normalized_release_gemfile_lock(content)
  content.gsub(/\b(react_on_rails(?:_pro)? \((?:= )?)[^)]+(\))/, '\1__RELEASE_VERSION__\2')
end

# First parent of `sha`, or nil at a root commit (or on any git failure) so the
# walk terminates cleanly.
def git_parent_sha(monorepo_root:, sha:)
  output, status = Open3.capture2e(
    "git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "#{sha}^"
  )
  return nil unless status.success?

  parent = output.strip
  parent.empty? ? nil : parent
end

def fetch_main_commit_statuses(repo_slug:, sha:, allow_override:, dry_run:)
  result = fetch_ci_statuses_for_sha(repo_slug:, sha:)
  return result[:statuses] unless result[:error]

  handle_main_ci_status_violation!(message: result[:error], allow_override:, dry_run:)
  # Only reached in override/dry-run mode; strict mode aborts above.
  nil
end

def normalize_status_as_check_run(status)
  state = status["state"]
  conclusion = normalize_status_conclusion(state)
  {
    "id" => status["id"],
    "name" => status["context"],
    # `pending` must stay in CI_INCOMPLETE_STATUSES so commit statuses still block as in-progress.
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
      context_statuses.max_by { |status| [parsed_ci_status_created_at(status), status["id"]] }
    end
end

def normalize_required_check_entries(checks)
  checks.map { |check| { context: check["context"], app_id: check["app_id"] } }.uniq
end

def valid_required_check_entry?(check)
  return false unless check.is_a?(Hash)
  return false unless check.key?("app_id")

  context = check["context"]
  return false unless context.is_a?(String) && !context.empty?

  check["app_id"].nil? || check["app_id"] == -1 || positive_github_id?(check["app_id"])
end

def valid_required_check_contexts?(contexts)
  contexts.is_a?(Array) && contexts.all? { |context| context.is_a?(String) && !context.empty? }
end

def valid_required_checks_payload?(parsed)
  return false unless parsed.is_a?(Hash)
  return false unless parsed.key?("contexts") && parsed.key?("checks")

  contexts_payload = parsed["contexts"]
  checks_payload = parsed["checks"]
  return false unless valid_required_check_contexts?(contexts_payload)
  return false unless checks_payload.is_a?(Array)

  checks_payload.all? { |check| valid_required_check_entry?(check) }
end

def normalize_required_checks_payload(parsed)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN unless valid_required_checks_payload?(parsed)

  checks = normalize_required_check_entries(parsed["checks"])
  check_contexts = checks.map { |check| check[:context] }
  # GitHub mirrors required status-check names into both `contexts` and `checks`.
  # Keep the modern `checks` entry when names overlap so one required gate is
  # evaluated once, with its app pin preserved.
  contexts = parsed["contexts"].uniq - check_contexts

  # A structurally valid empty configuration means no branch protection is
  # configured. Malformed responses return the unknown sentinel above.
  contexts.empty? && checks.empty? ? nil : { contexts:, checks: }
end

def valid_branch_rules_identity?(rule)
  rule.is_a?(Hash) &&
    rule["type"].is_a?(String) && !rule["type"].empty? &&
    rule["ruleset_source_type"].is_a?(String) && !rule["ruleset_source_type"].empty? &&
    rule["ruleset_source"].is_a?(String) && !rule["ruleset_source"].empty? &&
    positive_github_id?(rule["ruleset_id"])
end

def valid_ruleset_required_check?(check)
  return false unless check.is_a?(Hash)

  context = check["context"]
  integration_id = check["integration_id"]
  context.is_a?(String) && !context.empty? && (integration_id.nil? || positive_github_id?(integration_id))
end

def valid_branch_rules_pages?(parsed_pages)
  parsed_pages.is_a?(Array) && !parsed_pages.empty? && parsed_pages.all?(Array)
end

def ruleset_required_checks(rule)
  return [] unless rule["type"] == "required_status_checks"

  parameters = rule["parameters"]
  checks = parameters["required_status_checks"] if parameters.is_a?(Hash)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN unless checks.is_a?(Array)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN unless checks.all? { |check| valid_ruleset_required_check?(check) }

  checks.map { |check| { "context" => check["context"], "app_id" => check["integration_id"] } }
end

def required_checks_from_branch_rules(rules)
  rules.each_with_object([]) do |rule, required_checks|
    checks = ruleset_required_checks(rule)
    return REQUIRED_CHECK_DISCOVERY_UNKNOWN if checks.equal?(REQUIRED_CHECK_DISCOVERY_UNKNOWN)

    required_checks.concat(checks)
  end
end

def normalize_branch_rules_pages(parsed_pages)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN unless valid_branch_rules_pages?(parsed_pages)

  rules = parsed_pages.flatten(1)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN unless rules.all? { |rule| valid_branch_rules_identity?(rule) }

  required_checks = required_checks_from_branch_rules(rules)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN if required_checks.equal?(REQUIRED_CHECK_DISCOVERY_UNKNOWN)

  normalized = normalize_required_checks_payload("contexts" => [], "checks" => required_checks)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN if normalized.equal?(REQUIRED_CHECK_DISCOVERY_UNKNOWN)

  { required_checks: normalized, active_rule_count: rules.length }
end

def branch_rules_required_checks(repo_slug:, encoded_branch:)
  api_path = "repos/#{repo_slug}/rules/branches/#{encoded_branch}?per_page=#{BRANCH_RULES_PAGE_SIZE}"
  output, status = capture_gh_output(
    "api", "--paginate", "--slurp", *BRANCH_RULES_API_HEADERS, api_path
  )
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN unless status.success?

  normalize_branch_rules_pages(JSON.parse(output))
rescue JSON::ParserError
  REQUIRED_CHECK_DISCOVERY_UNKNOWN
end

def combine_required_check_discoveries(*discoveries)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN if discoveries.any? do |discovery|
    discovery.equal?(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
  end

  checks = discoveries.compact.flat_map { |discovery| discovery.fetch(:checks) }
  contexts = discoveries.compact.flat_map { |discovery| discovery.fetch(:contexts) }
  normalize_required_checks_payload(
    "contexts" => contexts,
    "checks" => checks.map { |check| { "context" => check.fetch(:context), "app_id" => check.fetch(:app_id) } }
  )
end

def gh_included_json_response(output)
  header_block, body, newline = gh_included_response_parts(output)
  status = gh_included_response_status(header_block, newline:)
  return nil unless status

  body = JSON.parse(body)
  return nil unless body.is_a?(Hash)

  { status:, body: }
rescue JSON::ParserError
  nil
end

def gh_included_response_parts(output)
  output = normalized_utf8_output(output)
  return [nil, nil, nil] unless output

  status_line_parts = gh_included_response_status_line_parts(output)
  return [nil, nil, nil] unless status_line_parts && valid_gh_included_response_bytes?(output)

  status_line, status_newline, remainder = status_line_parts
  newline = gh_included_response_newline(remainder)
  # gh writes the status line with the platform newline, then writes HTTP
  # headers with CRLF. Accept that CLI byte shape while continuing
  # to reject the inverse or arbitrarily mixed framing.
  return [nil, nil, nil] unless compatible_gh_included_response_newlines?(status_newline, newline)

  headers, body = gh_included_response_headers_and_body(remainder, newline:)
  return [nil, nil, nil] unless headers && body

  header_block = headers.empty? ? status_line : [status_line, headers].join(newline)
  [header_block, body, newline]
end

def gh_included_response_headers_and_body(remainder, newline:)
  separator = "#{newline}#{newline}"
  if remainder.start_with?(newline)
    body = remainder.delete_prefix(newline)
    return if body.include?(separator)

    return ["", body]
  end

  headers, body, *trailing_sections = remainder.split(separator, -1)
  [headers, body] if trailing_sections.empty? && headers && body
end

def gh_included_response_status_line_parts(output)
  output.match(/\A([^\r\n]+)(\r?\n)(.*)\z/m)&.captures
end

def compatible_gh_included_response_newlines?(status_newline, header_newline)
  return false unless header_newline

  status_newline == header_newline || (status_newline == "\n" && header_newline == "\r\n")
end

def gh_included_response_newline(output)
  return unless output.is_a?(String)
  return "\n" unless output.include?("\r")
  return unless output.include?("\r\n") && !output.match?(/\r(?!\n)|(?<!\r)\n/)

  "\r\n"
end

def valid_gh_included_response_bytes?(output)
  !output.match?(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/)
end

def gh_included_response_status(header_block, newline:)
  return nil unless header_block

  header_lines = header_block.split(newline, -1)
  status_match = header_lines.shift&.match(%r{\AHTTP/\d\.\d (\d{3})(?: [^\r\n]+)?\z})
  return nil unless status_match
  return nil unless header_lines.all? { |header| header.match?(/\A[!#$%&'*+\-.^_`|~0-9A-Za-z]+:[ \t]*[^\r\n]*\z/) }
  return nil if header_lines.any? { |header| header.match?(/\Astatus:/i) }

  status_match[1].to_i
end

def required_status_checks_protection_state(output)
  response = gh_included_json_response(output)
  return unless response&.dig(:status) == 404

  case response.dig(:body, "message")
  when "Branch not protected"
    false
  when "Required status checks not enabled"
    true
  end
end

def valid_branch_protection_payload?(branch, branch_name:)
  branch.is_a?(Hash) && branch["name"] == branch_name && [true, false].include?(branch["protected"])
end

def classic_required_checks_absence_corroborated?(branch_protected:, expected_protected:, ruleset_active_rule_count:)
  branch_protected == expected_protected ||
    (!expected_protected && branch_protected && ruleset_active_rule_count.positive?)
end

def corroborated_classic_required_checks_absence(
  repo_slug:, branch_name:, encoded_branch:, expected_protected:, ruleset_active_rule_count:
)
  branch_output, branch_status = capture_gh_output("api", "repos/#{repo_slug}/branches/#{encoded_branch}")
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN unless branch_status.success?

  branch = JSON.parse(branch_output)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN unless valid_branch_protection_payload?(branch, branch_name:)
  if classic_required_checks_absence_corroborated?(
    branch_protected: branch["protected"], expected_protected:, ruleset_active_rule_count:
  )
    return nil
  end

  REQUIRED_CHECK_DISCOVERY_UNKNOWN
rescue JSON::ParserError
  REQUIRED_CHECK_DISCOVERY_UNKNOWN
end

def classic_required_checks_for_branch(
  repo_slug:, branch_name:, encoded_branch:, required_status_checks_path:, ruleset_active_rule_count:
)
  output, status = capture_gh_output("api", "--jq", REQUIRED_CHECKS_JQ_QUERY, required_status_checks_path)
  return normalize_required_checks_payload(JSON.parse(output)) if status.success?

  included_output, _included_error, included_status = capture_gh_stdout_and_stderr(
    "api", "--include", required_status_checks_path
  )
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN if included_status.success?

  expected_protected = required_status_checks_protection_state(included_output)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN if expected_protected.nil?

  corroborated_classic_required_checks_absence(
    repo_slug:, branch_name:, encoded_branch:, expected_protected:, ruleset_active_rule_count:
  )
rescue JSON::ParserError
  REQUIRED_CHECK_DISCOVERY_UNKNOWN
end

def required_check_names_for_branch(monorepo_root:, repo_slug: nil, ci_branch: "main")
  repo_slug ||= github_repo_slug(monorepo_root)
  encoded_branch = URI.encode_www_form_component(ci_branch.to_s)
  api_path = "repos/#{repo_slug}/branches/#{encoded_branch}/protection/required_status_checks"
  # Keep legacy `contexts` separate from modern `checks` entries. Modern
  # required checks can be pinned to a GitHub App via `app_id`; legacy contexts
  # may be satisfied by either a Checks API run or a commit-status context.
  # Precondition: `fetch_main_ci_checks` already verified `gh` is installed
  # before `validate_main_ci_status!` calls this helper. The remaining failure
  # mode here is "branch protection unknown". Keep it distinct from a known
  # unprotected branch so exact-HEAD recovery can fail closed.
  ruleset_discovery = branch_rules_required_checks(repo_slug:, encoded_branch:)
  return REQUIRED_CHECK_DISCOVERY_UNKNOWN if ruleset_discovery.equal?(REQUIRED_CHECK_DISCOVERY_UNKNOWN)

  classic_discovery = classic_required_checks_for_branch(
    repo_slug:,
    branch_name: ci_branch.to_s,
    encoded_branch:,
    required_status_checks_path: api_path,
    ruleset_active_rule_count: ruleset_discovery.fetch(:active_rule_count)
  )
  combine_required_check_discoveries(classic_discovery, ruleset_discovery.fetch(:required_checks))
end

def check_run_app_id(run)
  # nil is the branch-protection wildcard; GitHub check-run app IDs are integers.
  run.dig("app", "id")
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

def legacy_context_present?(context:, check_runs:, legacy_status_runs:)
  matching_check_run = check_runs.any? do |run|
    run["name"] == context
  end

  matching_check_run || legacy_status_runs.any? { |run| run["name"] == context }
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
  statuses
    .select { |status| status_contexts.include?(status["context"]) }
    .then { |relevant_statuses| latest_commit_statuses(relevant_statuses) }
    .map { |status| normalize_status_as_check_run(status) }
end

def format_ci_status_run_line(run, kind:)
  icon = kind == :in_progress ? "⏳" : "❌"
  detail = kind == :in_progress ? (run["status"] || "in_progress") : (run["conclusion"] || "incomplete")
  url = run["html_url"].to_s
  url.strip.empty? ? "  #{icon} #{detail}: #{run['name']}" : "  #{icon} #{detail}: #{run['name']}\n      #{url}"
end

def format_main_ci_status_violation(kind:, short_sha:, runs:, ci_branch: "main") # rubocop:disable Metrics/CyclomaticComplexity
  ref = "origin/#{ci_branch}"
  header = case kind
           when :in_progress
             "⏳ CI is still in progress on #{ref} (commit #{short_sha})."
           when :no_checks
             message = "❌ No CI check runs visible on #{ref} (commit #{short_sha}). " \
                       "CI may not have started yet, or the GitHub Checks API is unavailable."
             if ci_branch.start_with?("release/")
               "#{message} If this release branch was just pushed, wait for at least one CI run to complete " \
                 "before retrying."
             else
               message
             end
           when :no_required_checks
             "❌ No required CI check runs found on #{ref} (commit #{short_sha})."
           when :missing_required_checks
             "❌ Some required CI checks are missing on #{ref} (commit #{short_sha}). " \
             "Branch protection would refuse this merge."
           when :failed
             "❌ CI on #{ref} is not healthy (commit #{short_sha})."
           when :unknown_status
             "❌ Check run(s) with unrecognized status on #{ref} (commit #{short_sha})."
           else
             raise ArgumentError, "Unknown CI violation kind: #{kind.inspect}"
           end
  return header if runs.nil? || runs.empty?

  lines = runs.map { |run| format_ci_status_run_line(run, kind:) }
  "#{header}\n\n#{lines.join("\n")}"
end

def main_ci_status_override_guidance(prefix: "")
  <<~GUIDANCE.strip
    #{prefix}DANGEROUS PRERELEASE-ONLY LAST RESORT — preview an override only if the failures are known-unrelated:
    #{prefix}this waives the release CI-status gate and does not establish healthy CI evidence.
    #{prefix}  RELEASE_CI_STATUS_OVERRIDE=true bundle exec rake "release[VERSION,true]"
    #{prefix}  # or pass override_ci_status as the 4th positional argument:
    #{prefix}  bundle exec rake "release[VERSION,true,false,true]"
    #{release_version_placeholder_guidance(prefix:)}
    #{release_compound_live_boundary_guidance.lines.map { |line| "#{prefix}#{line}" }.join}
  GUIDANCE
end

def handle_main_ci_status_violation!(message:, allow_override:, dry_run:)
  if dry_run
    puts "⚠️ DRY RUN: CI evidence below would block a real release:"
    puts message
    puts "⚠️ DRY RUN: Real release remains blocked."
    puts main_ci_status_override_guidance(prefix: "⚠️ DRY RUN: ")
    return
  end

  if allow_override
    puts "⚠️ CI STATUS OVERRIDE enabled — proceeding despite the following:"
    puts message.lines.map { |line| "  #{line}" }.join
    return
  end

  abort "#{message}\n\n#{main_ci_status_override_guidance}"
end

def deduplicate_ci_check_runs(check_runs)
  check_runs
    .group_by { |run| [run.dig("check_suite", "id") || run["id"], run["name"], check_run_app_id(run)] }
    .map { |_key, runs| runs.max_by { |run| run["id"] } }
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
def main_ci_status_evaluation(check_runs:, legacy_status_runs:, required_names:, is_prerelease:, sha:,
                              ci_branch:)
  check_runs = deduplicate_ci_check_runs(check_runs)
  short_sha = sha[0, 8]
  if check_runs.empty? && legacy_status_runs.empty?
    message = format_main_ci_status_violation(kind: :no_checks, short_sha:, runs: nil, ci_branch:)
    return { kind: :no_checks, message: }
  end

  evaluated = if is_prerelease && required_names
                check_runs.select do |run|
                  required_names[:contexts].include?(run["name"]) ||
                    required_names[:checks].any? { |required_check| required_check_matches_run?(required_check, run) }
                end + legacy_status_runs
              else
                check_runs + legacy_status_runs
              end

  failed = evaluated.select do |run|
    run["status"] == "completed" && !CI_PASSING_CONCLUSIONS.include?(run["conclusion"])
  end
  if failed.any?
    message = format_main_ci_status_violation(kind: :failed, short_sha:, runs: failed, ci_branch:)
    return { kind: :failed, message: }
  end

  unless required_names.nil?
    required_labels = required_check_labels(required_names)
    missing_required = missing_required_checks(
      required_checks: required_names,
      check_runs:,
      legacy_status_runs:
    )
    if missing_required[:count] == required_check_count(required_names)
      message = format_main_ci_status_violation(kind: :no_required_checks, short_sha:, runs: nil, ci_branch:) +
                "\nRequired: #{required_labels.join(', ')}"
      return { kind: :no_required_checks, message: }
    end
    if missing_required[:labels].any?
      message = format_main_ci_status_violation(kind: :missing_required_checks, short_sha:, runs: nil, ci_branch:) +
                "\nRequired: #{required_labels.join(', ')}\nMissing: #{missing_required[:labels].join(', ')}"
      return { kind: :missing_required_checks, message: }
    end
  end

  in_progress = evaluated.select { |run| CI_INCOMPLETE_STATUSES.include?(run["status"]) }
  if in_progress.any?
    message = format_main_ci_status_violation(kind: :in_progress, short_sha:, runs: in_progress, ci_branch:)
    return { kind: :in_progress, message: }
  end

  unknown = evaluated.reject do |run|
    run["status"] == "completed" || CI_INCOMPLETE_STATUSES.include?(run["status"])
  end
  if unknown.any?
    message = format_main_ci_status_violation(kind: :unknown_status, short_sha:, runs: unknown, ci_branch:)
    return { kind: :unknown_status, message: }
  end

  healthy_count = required_names ? required_check_count(required_names) : evaluated.length
  { kind: :healthy, healthy_count: }
end

def exact_head_unknown_guidance(error)
  "❌ Exact HEAD evidence is unknown; release remains blocked.\n\n#{error}"
end

def recovery_ci_evidence_healthy?(check_runs:, statuses:)
  return false unless check_runs.all? { |run| valid_ci_check_run?(run) }
  return false unless statuses.all? { |status| valid_ci_status?(status) }

  normalized = normalized_ci_evidence(check_runs:, statuses:)
  normalized[:check_runs].all? do |run|
    run["status"] == "completed" && CI_PASSING_CONCLUSIONS.include?(run["conclusion"])
  end && normalized[:statuses].all? { |status| status["state"] == "success" }
end

def normalized_ci_evidence(check_runs:, statuses:)
  { check_runs: deduplicate_ci_check_runs(check_runs), statuses: latest_commit_statuses(statuses) }
end

def accelerated_rc_ci_snapshot(sha:, repo_slug:, check_runs:, statuses:, required_names: nil, fail_on_failure: true)
  checks_url = "https://github.com/#{repo_slug}/commit/#{sha}/checks"
  runs = deduplicate_ci_check_runs(check_runs) +
         latest_commit_statuses(statuses).map { |status| normalize_status_as_check_run(status) }
  if runs.empty?
    abort "❌ Accelerated RC publication's exact-head CI evidence is unknown (no checks or statuses returned)."
  end
  failed = runs.select do |run|
    run["status"] == "completed" && !CI_PASSING_CONCLUSIONS.include?(run["conclusion"])
  end
  if failed.any? && fail_on_failure
    lines = failed.map do |run|
      run_url = run["html_url"].to_s.empty? ? checks_url : run["html_url"]
      "- #{run['name']}: #{run['conclusion']}\n  #{run_url}"
    end
    abort "❌ Accelerated RC publication found known failed exact-head CI evidence:\n#{lines.join("\n")}"
  end
  validate_accelerated_rc_required_checks!(required_names:, check_runs:, statuses:) if failed.empty?

  non_success = runs.filter_map do |run|
    next if run["status"] == "completed" && run["conclusion"] == "success"

    state = run["status"] == "completed" ? run["conclusion"] : run["status"]
    {
      name: run["name"],
      state:,
      url: run["html_url"].to_s.empty? ? checks_url : run["html_url"].to_s
    }
  end
  non_success.sort_by! { |check| accelerated_rc_ci_check_sort_key(check) }
  status = if failed.any?
             "failed"
           elsif runs.any? { |run| CI_INCOMPLETE_STATUSES.include?(run["status"]) }
             "pending"
           else
             "success"
           end

  {
    status:,
    sha:,
    checks_url:,
    non_success:
  }
end

def validate_accelerated_rc_required_checks!(required_names:, check_runs:, statuses:)
  return unless required_names

  legacy_status_runs = legacy_status_runs_for_required_contexts(required_checks: required_names, statuses:)
  missing = missing_required_checks(required_checks: required_names, check_runs:, legacy_status_runs:)
  return if missing[:count].zero?

  abort "❌ Required exact-head CI checks have not appeared: #{missing[:labels].join(', ')}. " \
        "Accelerated RC evidence remains incomplete."
end

def accelerated_rc_required_checks!(repo_slug:, monorepo_root:, ci_branch:)
  required_names = required_check_names_for_branch(monorepo_root:, repo_slug:, ci_branch:)
  return required_names unless required_names.equal?(REQUIRED_CHECK_DISCOVERY_UNKNOWN)

  abort "❌ Required exact-head CI check discovery is unknown; accelerated RC publication remains blocked."
end

def fetch_accelerated_rc_ci_snapshot!(repo_slug:, sha:, monorepo_root: nil, ci_branch: nil, fail_on_failure: true)
  check_result = fetch_ci_check_runs_for_sha(repo_slug:, sha:)
  abort "#{check_result[:error]}\n\n❌ Accelerated RC exact-head CI evidence is unknown." if check_result[:error]

  status_result = fetch_ci_statuses_for_sha(repo_slug:, sha:)
  abort "#{status_result[:error]}\n\n❌ Accelerated RC exact-head CI evidence is unknown." if status_result[:error]

  required_names = if monorepo_root && ci_branch
                     accelerated_rc_required_checks!(repo_slug:, monorepo_root:, ci_branch:)
                   end
  accelerated_rc_ci_snapshot(
    sha:,
    repo_slug:,
    check_runs: check_result.fetch(:check_runs),
    statuses: status_result.fetch(:statuses),
    required_names:,
    fail_on_failure:
  )
end

def exact_head_recovery_guidance(repo_slug:, monorepo_root:, head_sha:, evaluated_sha:, required_names:,
                                 is_prerelease:, ci_branch:, required_checks_known: true, current_branch: nil,
                                 target_gem_version: nil)
  return nil if head_sha.nil? || head_sha == evaluated_sha
  unless required_checks_known
    return exact_head_unknown_guidance("❌ Required CI check discovery is unknown; release remains blocked.")
  end

  check_result = fetch_ci_check_runs_for_sha(repo_slug:, sha: head_sha)
  return exact_head_unknown_guidance(check_result[:error]) if check_result[:error]

  status_result = fetch_ci_statuses_for_sha(repo_slug:, sha: head_sha)
  return exact_head_unknown_guidance(status_result[:error]) if status_result[:error]

  normalized_evidence = normalized_ci_evidence(
    check_runs: check_result[:check_runs],
    statuses: status_result[:statuses]
  )
  unless recovery_ci_evidence_healthy?(check_runs: check_result[:check_runs], statuses: status_result[:statuses])
    raw_status_runs = normalized_evidence[:statuses].map do |status|
      normalize_status_as_check_run(status)
    end
    raw_evaluation = main_ci_status_evaluation(
      check_runs: normalized_evidence[:check_runs],
      legacy_status_runs: raw_status_runs,
      required_names: nil,
      is_prerelease: false,
      sha: head_sha,
      ci_branch:
    )
    case raw_evaluation[:kind]
    when :in_progress
      return "⏳ Exact HEAD #{head_sha[0, 8]} still has pending CI evidence. " \
             "Wait for it to complete; release remains blocked.\n\n#{raw_evaluation[:message]}"
    when :failed
      return [
        "❌ Exact HEAD #{head_sha[0, 8]} has failing CI evidence. Release remains blocked.",
        raw_evaluation[:message] || "❌ Exact HEAD evidence is not healthy."
      ].join("\n\n")
    else
      return "❌ Exact HEAD #{head_sha[0, 8]} does not provide complete healthy CI evidence; " \
             "release remains blocked.\n\n#{raw_evaluation[:message] || '❌ Exact HEAD evidence is not healthy.'}"
    end
  end

  legacy_status_runs = if required_names
                         legacy_status_runs_for_required_contexts(
                           required_checks: required_names,
                           statuses: status_result[:statuses]
                         )
                       else
                         []
                       end

  evaluation = main_ci_status_evaluation(
    check_runs: check_result[:check_runs],
    legacy_status_runs:,
    required_names:,
    is_prerelease:,
    sha: head_sha,
    ci_branch:
  )

  case evaluation[:kind]
  when :healthy
    if target_gem_version.to_s.empty?
      return exact_head_unknown_guidance(
        "❌ Exact HEAD is healthy, but the resolved release version is unavailable; release remains blocked."
      )
    end
    unless supervised_release_branch_allowed?(current_branch:, target_gem_version:)
      branch_label = current_branch.to_s.empty? ? "unknown" : current_branch
      return "❌ Exact HEAD #{head_sha[0, 8]} is healthy, but current branch #{branch_label} is not supported by " \
             "script/release for #{target_gem_version}; wrapper recovery remains blocked."
    end
    prepared_head_version = prepared_release_version_from_changelog_at_revision(
      monorepo_root:,
      revision: head_sha
    )
    if prepared_head_version.to_s.empty?
      return "❌ Exact HEAD #{head_sha[0, 8]} is healthy, but script/release cannot resolve a prepared " \
             "CHANGELOG.md version; wrapper recovery remains blocked."
    end
    unless prepared_head_version == target_gem_version
      return "❌ Exact HEAD #{head_sha[0, 8]} is healthy, but script/release would select #{prepared_head_version} " \
             "while the diagnostic target is #{target_gem_version}; wrapper recovery remains blocked."
    end
    prepared_checkout_version = prepared_release_version_from_changelog(monorepo_root:)
    if prepared_checkout_version.to_s.empty?
      return "❌ Exact HEAD #{head_sha[0, 8]} is healthy, but the current checkout has no prepared " \
             "CHANGELOG.md version; wrapper recovery remains blocked."
    end
    unless prepared_checkout_version == target_gem_version
      return "❌ Exact HEAD #{head_sha[0, 8]} is healthy, but the current checkout would select " \
             "#{prepared_checkout_version} while the diagnostic target is #{target_gem_version}; " \
             "wrapper recovery remains blocked."
    end

    <<~GUIDANCE.strip
      ✓ Exact HEAD #{head_sha[0, 8]} has complete healthy CI evidence.
      Preview a re-evaluation of that exact HEAD (strict evaluation, not a waiver):
        script/release --dry-run --evaluate-head

      Live retry through the supervised release path:
        script/release --evaluate-head

      #{release_compound_live_boundary_guidance}
    GUIDANCE
  when :in_progress
    "⏳ Exact HEAD #{head_sha[0, 8]} still has pending CI evidence. " \
    "Wait for it to complete; release remains blocked.\n\n#{evaluation[:message]}"
  when :failed
    "❌ Exact HEAD #{head_sha[0, 8]} has failing CI evidence. Release remains blocked.\n\n#{evaluation[:message]}"
  else
    "❌ Exact HEAD #{head_sha[0, 8]} does not provide complete healthy CI evidence; " \
    "release remains blocked.\n\n#{evaluation[:message]}"
  end
end

def validate_main_ci_status!(monorepo_root:, is_prerelease:, allow_override:, dry_run:, ci_branch: "main",
                             target_gem_version: nil, defer_pending: false, current_branch: nil)
  ensure_ci_status_override_is_prerelease!(allow_override:, is_prerelease:)
  puts "\nChecking CI status on origin/#{ci_branch}..."

  data = fetch_main_ci_checks(monorepo_root:, allow_override:, dry_run:, ci_branch:)
  return if data.nil?

  strict_exact_head_evaluation = ci_evaluate_head_only?
  sha = data[:sha]
  repo_slug = data[:repo_slug]
  required_args = { monorepo_root:, ci_branch: }
  required_args[:repo_slug] = repo_slug if repo_slug
  required_names = required_check_names_for_branch(**required_args)
  required_checks_known = !required_names.equal?(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
  unless required_checks_known
    handle_main_ci_status_violation!(
      message: "❌ Required CI check discovery is unknown for origin/#{ci_branch}; release remains blocked.",
      allow_override:,
      dry_run:
    )
    return
  end

  statuses = []
  statuses_fetched = false
  legacy_status_runs = []
  legacy_status_fetch_unknown = false
  has_legacy_status_requirements = required_names && legacy_status_contexts_for_required_checks(required_names).any?
  if has_legacy_status_requirements || strict_exact_head_evaluation
    statuses_fetched = true
    statuses = fetch_main_commit_statuses(
      repo_slug: repo_slug || github_repo_slug(monorepo_root), sha:, allow_override:, dry_run:
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
      legacy_status_fetch_unknown = true
      statuses = []
    end
    return if strict_exact_head_evaluation && legacy_status_fetch_unknown
  end

  if strict_exact_head_evaluation
    strict_evidence_valid = data[:check_runs].all? { |run| valid_ci_check_run?(run) } &&
                            statuses.all? { |status| valid_ci_status?(status) }
    unless strict_evidence_valid
      handle_main_ci_status_violation!(
        message: "❌ Strict exact-HEAD CI evidence is malformed or unknown; release remains blocked.",
        allow_override:,
        dry_run:
      )
      return
    end

    normalized_evidence = normalized_ci_evidence(check_runs: data[:check_runs], statuses:)
    unless recovery_ci_evidence_healthy?(check_runs: data[:check_runs], statuses:)
      raw_status_runs = normalized_evidence[:statuses].map { |status| normalize_status_as_check_run(status) }
      raw_evaluation = main_ci_status_evaluation(
        check_runs: normalized_evidence[:check_runs],
        legacy_status_runs: raw_status_runs,
        required_names: nil,
        is_prerelease: false,
        sha:,
        ci_branch:
      )
      handle_main_ci_status_violation!(
        message: raw_evaluation[:message] || "❌ Strict exact-HEAD CI evidence is not healthy; release remains blocked.",
        allow_override:,
        dry_run:
      )
      return
    end
  end

  if has_legacy_status_requirements
    legacy_status_runs = legacy_status_runs_for_required_contexts(required_checks: required_names, statuses:)
  end

  evaluation = main_ci_status_evaluation(
    check_runs: data[:check_runs],
    legacy_status_runs:,
    required_names:,
    is_prerelease:,
    sha:,
    ci_branch:
  )
  if evaluation[:kind] == :in_progress && defer_pending && is_prerelease
    puts "⚠️ ACCELERATED RC: deferring pending CI until post-publication reconciliation."
    puts evaluation.fetch(:message)
    return evaluation.merge(sha:)
  end
  if evaluation[:kind] != :healthy
    message = evaluation[:message]
    if %i[no_checks no_required_checks].include?(evaluation[:kind]) && !statuses_fetched
      statuses = fetch_main_commit_statuses(
        repo_slug: repo_slug || github_repo_slug(monorepo_root), sha:, allow_override:, dry_run:
      )
      if statuses.nil?
        legacy_status_fetch_unknown = true
        statuses = []
      end
    end
    recovery_eligible = !legacy_status_fetch_unknown && recovery_ci_evidence_healthy?(
      check_runs: data[:check_runs], statuses:
    )
    if recovery_eligible && %i[no_checks no_required_checks].include?(evaluation[:kind])
      guidance = exact_head_recovery_guidance(
        repo_slug:,
        monorepo_root:,
        head_sha: data[:head_sha],
        evaluated_sha: sha,
        required_names:,
        is_prerelease:,
        ci_branch:,
        required_checks_known:,
        current_branch:,
        target_gem_version:
      )
      message += "\n\n#{guidance}" if guidance
    end
    handle_main_ci_status_violation!(message:, allow_override:, dry_run:)
    return
  end

  return if legacy_status_fetch_unknown

  qualifier = is_prerelease && required_names ? "required " : ""
  noun = evaluation[:healthy_count] == 1 ? "check" : "checks"
  ci_label = ci_branch == "main" ? "Main CI" : "CI on origin/#{ci_branch}"
  puts "✓ #{ci_label} is healthy on #{sha[0, 8]} (#{evaluation[:healthy_count]} #{qualifier}#{noun})"
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
def validate_release_version_policy!(monorepo_root:, target_gem_version:, allow_override:, fetch_tags: true,
                                     allow_existing_target_tag: false,
                                     release_branch_final_promotion: false,
                                     # Final promotions need the same scoped tag-order check as RC cuts.
                                     release_branch_tag_scope: release_branch_final_promotion)
  tagged_versions = tagged_release_gem_versions(monorepo_root, fetch_tags:)
  tagged_version_order_candidates = if release_branch_tag_scope
                                      tagged_versions.select do |version|
                                        !release_prerelease_version?(version) ||
                                          same_release_base?(version, target_gem_version)
                                      end
                                    else
                                      tagged_versions
                                    end
  latest_tagged_version = tagged_version_order_candidates.max_by { |version| Gem::Version.new(version) }
  target_version = Gem::Version.new(target_gem_version)

  if latest_tagged_version && target_version <= Gem::Version.new(latest_tagged_version)
    if allow_existing_target_tag && target_version == Gem::Version.new(latest_tagged_version)
      puts "ℹ️ VERSION POLICY: Existing target tag #{target_gem_version} points at this release HEAD; " \
           "continuing idempotent release retry."
      return
    end

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

  # Keep stable releases global even when prereleases are scoped by release base;
  # a backport RC behind a newer stable line must use the explicit override path.
  stable_versions = tagged_versions.reject { |version| release_prerelease_version?(version) }
  if release_branch_final_promotion
    stable_versions = stable_versions.select { |version| Gem::Version.new(version) < target_version }
  end
  latest_stable_version = stable_versions.max_by { |version| Gem::Version.new(version) }
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

def report_release_dry_run_changelog(version:, has_changelog:)
  return if has_changelog

  puts "⚠️ Prerelease dry run for #{version}: no matching non-empty CHANGELOG.md section; " \
       "no GitHub release would be created."
end

def release_compound_live_boundary_guidance
  <<~GUIDANCE.chomp
    Live release uses only `script/release`, which selects the prepared CHANGELOG.md version, acquires the
    matching release-line lease, and performs fresh authoritative fences before every outward write. Direct
    live Rake is refused without its private supervisor contract; use `bundle exec rake
    "release[VERSION,true]"` only for an explicit internal preview. See
    internal/contributor-info/release-train-runbook.md for automation compatibility and recovery procedures.
  GUIDANCE
end

def release_version_placeholder_guidance(prefix: "")
  "#{prefix}Replace VERSION with the exact requested version or the exact CHANGELOG.md version " \
    "before running this preview."
end

def report_release_dry_run_follow_up(version:)
  puts <<~GUIDANCE

    #{release_compound_live_boundary_guidance}
    Preview this exact version again with:
      bundle exec rake "release[#{version},true]"
  GUIDANCE
end

def report_github_release_notes_preflight!(version:, changelog_notes:)
  return unless changelog_notes

  github_notes = github_release_notes(notes: changelog_notes, tag: "v#{version}")
  puts "  GitHub:    ✓ release body prepared before publishing " \
       "(#{changelog_notes.length} → #{github_notes.length} characters)"
end

def confirm_release!(version:, monorepo_root:, dry_run: false)
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  has_changelog = extract_changelog_section(changelog_path:, version:)

  if !has_changelog && !release_prerelease_version?(version)
    abort <<~ERROR
      ❌ Stable release #{version} requires a non-empty CHANGELOG.md section.

      Refusing to continue before confirmation, tagging, or publication.
      Stamp the changelog for #{version}, complete the final-release gates, and preview explicitly:
        bundle exec rake "release[#{version},true]"

      #{release_compound_live_boundary_guidance}
    ERROR
  end

  report_github_release_notes_preflight!(version:, changelog_notes: has_changelog)

  return report_release_dry_run_changelog(version:, has_changelog:) if dry_run

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

def compact_github_release_notes(notes)
  compacted_notes = notes.gsub(
    %r{\[PR (\d+)\]\(https://github\.com/shakacode/react_on_rails/pull/\1\)}
  ) { "##{Regexp.last_match(1)}" }
  compacted_notes = compacted_notes.gsub(
    %r{\[(?:Issue|issue) (\d+)\]\(https://github\.com/shakacode/react_on_rails/issues/\1\)}
  ) { "##{Regexp.last_match(1)}" }
  compacted_notes.gsub(%r{\[([A-Za-z0-9](?:[A-Za-z0-9-]{0,38}))\]\(https://github\.com/\1\)}) do
    username = Regexp.last_match(1)
    "[#{username}](/#{username})"
  end
end

def github_release_body_within_limit?(notes)
  notes.length <= GITHUB_RELEASE_BODY_MAX_LENGTH
end

def ensure_github_release_body_within_limit!(notes)
  return notes if github_release_body_within_limit?(notes)

  abort "❌ Prepared GitHub release notes still exceed GitHub's #{GITHUB_RELEASE_BODY_MAX_LENGTH}-character limit."
end

def github_release_omission(tag)
  <<~MARKDOWN

    ---

    > Some changelog entries were omitted from this page to fit GitHub's release-description limit.
    > Read the [complete #{tag} changelog](https://github.com/shakacode/react_on_rails/blob/#{tag}/CHANGELOG.md).

    ---

  MARKDOWN
end

def github_release_escaped_excerpt(notes, character_budget:, from:)
  low = 0
  high = [notes.length, character_budget].min

  while low < high
    count = (low + high + 1) / 2
    candidate = from == :beginning ? notes[0, count] : notes[-count, count]
    if CGI.escapeHTML(candidate).length <= character_budget
      low = count
    else
      high = count - 1
    end
  end

  excerpt = from == :beginning ? notes[0, low] : notes[-low, low]
  CGI.escapeHTML(excerpt)
end

def github_release_excerpt(title:, escaped_notes:)
  "#### #{title} (excerpt)\n\n<pre>#{escaped_notes}</pre>"
end

def truncate_github_release_notes(notes:, tag:)
  omission = github_release_omission(tag).strip
  beginning_template = github_release_excerpt(title: "Beginning of release notes", escaped_notes: "")
  ending_template = github_release_excerpt(title: "End of release notes", escaped_notes: "")
  fixed_content = [beginning_template, omission, ending_template].join("\n\n")
  available_characters = GITHUB_RELEASE_BODY_MAX_LENGTH - fixed_content.length
  beginning_budget = available_characters * 3 / 4
  ending_budget = available_characters - beginning_budget
  beginning = github_release_escaped_excerpt(notes, character_budget: beginning_budget, from: :beginning)
  ending = github_release_escaped_excerpt(notes, character_budget: ending_budget, from: :ending)

  [
    github_release_excerpt(title: "Beginning of release notes", escaped_notes: beginning),
    omission,
    github_release_excerpt(title: "End of release notes", escaped_notes: ending)
  ].join("\n\n")
end

def github_release_notes(notes:, tag:)
  compacted_notes = compact_github_release_notes(notes)
  return compacted_notes if github_release_body_within_limit?(compacted_notes)

  truncated_notes = truncate_github_release_notes(notes: compacted_notes, tag:)
  ensure_github_release_body_within_limit!(truncated_notes)
end

def prepare_github_release_context(monorepo_root:, gem_version:)
  prerelease = release_prerelease_version?(gem_version)
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  notes = extract_changelog_section(changelog_path:, version: gem_version)
  abort "❌ Could not find `### [#{gem_version}]` in CHANGELOG.md. Add that section and retry." unless notes

  notes = github_release_notes(notes:, tag: "v#{gem_version}")

  {
    notes:,
    prerelease:,
    tag: "v#{gem_version}",
    title: "v#{gem_version}"
  }
end

def abort_github_release_publish_failure!(tag)
  version = tag.delete_prefix("v")
  abort <<~ERROR
    ❌ Failed to publish GitHub release #{tag}.

    The git tag and registry packages may already be published.
    #{github_release_sync_preview_guidance(version:)}
  ERROR
end

def github_release_sync_preview_guidance(version:)
  <<~GUIDANCE.chomp
    Direct live sync_github_release is refused without the private release supervisor contract. For a
    fenced idempotent create or edit, keep #{version} as the prepared CHANGELOG.md version and use
    `script/release`; do not invoke this task live directly.
    See internal/contributor-info/release-train-runbook.md for the recovery procedure.
    Preview the idempotent GitHub-only sync step with:
      bundle exec rake "sync_github_release[#{version},true]"
  GUIDANCE
end

# rubocop:disable Metrics/AbcSize
def publish_or_update_github_release(monorepo_root:, release_context:, dry_run:)
  ensure_git_tag_exists!(monorepo_root:, tag: release_context[:tag])

  if dry_run
    puts "DRY RUN: Would create or update GitHub release #{release_context[:tag]}" \
         "#{release_context[:prerelease] ? ' (prerelease)' : ''}"
    return
  end

  repo_slug = github_repo_slug(monorepo_root)

  Tempfile.create(["react-on-rails-release-notes-", ".md"]) do |tmp|
    tmp.write(release_context[:notes])
    tmp.flush

    release_exists = system("gh", "release", "view", release_context[:tag], "--repo", repo_slug,
                            chdir: monorepo_root, out: File::NULL, err: File::NULL)
    abort "❌ Unable to run `gh`. Ensure GitHub CLI is installed and on PATH." if release_exists.nil?

    release_command = if release_exists
                        ["gh", "release", "edit", release_context[:tag], "--repo", repo_slug,
                         "--title", release_context[:title], "--notes-file", tmp.path,
                         "--prerelease=#{release_context[:prerelease]}", "--draft=false"]
                      else
                        command = ["gh", "release", "create", release_context[:tag], "--repo", repo_slug,
                                   "--verify-tag", "--title", release_context[:title],
                                   "--notes-file", tmp.path]
                        command << "--prerelease" if release_context[:prerelease]
                        command
                      end

    puts "Publishing GitHub release #{release_context[:tag]}#{release_context[:prerelease] ? ' (prerelease)' : ''}"
    release_write_fence!("#{release_command.fetch(2)} GitHub release #{release_context[:tag]}")
    success = system(*release_command, chdir: monorepo_root)
    abort_github_release_publish_failure!(release_context[:tag]) unless success
  end
end
# rubocop:enable Metrics/AbcSize

def sync_github_release_after_publish(monorepo_root:, gem_version:, dry_run:)
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  section = extract_changelog_section(changelog_path:, version: gem_version)
  unless section
    puts "################################################################################"
    puts "Skipping GitHub release: no CHANGELOG.md section for #{gem_version}."
    puts "After adding the changelog section:"
    puts github_release_sync_preview_guidance(version: gem_version)
    puts "################################################################################"
    return
  end

  verify_gh_auth(monorepo_root:)
  release_context = prepare_github_release_context(monorepo_root:, gem_version:)
  publish_or_update_github_release(monorepo_root:, release_context:, dry_run:)
  return if dry_run || github_release_complete?(monorepo_root:, version: gem_version)

  abort_github_release_publish_failure!(release_context.fetch(:tag))
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

def argumentless_prerelease_release_requires_explicit_version?(
  changelog_version:,
  current_version:,
  starting_version: current_version
)
  return false unless release_prerelease_version?(starting_version)
  return true unless changelog_version
  return true unless release_prerelease_version?(changelog_version)

  versions_to_advance = [starting_version, current_version].uniq
  return true unless versions_to_advance.all? { |version| same_release_base?(changelog_version, version) }

  changelog_gem_version = Gem::Version.new(changelog_version)
  versions_to_advance.any? { |version| changelog_gem_version <= Gem::Version.new(version) }
end

def argumentless_prerelease_release_message(changelog_version:, current_version:)
  stable_version = release_base_version(current_version)

  <<~ERROR
    ❌ No explicit release version was supplied.

    Current version: #{current_version}
    Latest changelog version: #{changelog_version || 'none'}

    Refusing to infer stable #{stable_version} from an argument-less prerelease retry.

    To preview resuming #{current_version} publication, run:
      bundle exec rake "release[#{current_version},true]"

    To prepare the final #{stable_version} release, add a non-empty CHANGELOG.md section for #{stable_version},
    complete the final-release gates, then preview:
      bundle exec rake "release[#{stable_version},true]"

    #{release_compound_live_boundary_guidance}
  ERROR
end

def untagged_changelog_current_version?(monorepo_root:, changelog_version:, current_version:)
  return false unless changelog_version
  return false unless Gem::Version.new(changelog_version) == Gem::Version.new(current_version)

  !version_tagged?(monorepo_root, changelog_version)
end

def resolve_version_input(version_input, monorepo_root, current_version: nil,
                          argumentless_starting_prerelease_version: nil)
  stripped = version_input.to_s.strip
  return stripped unless stripped.empty?

  changelog_version = extract_latest_changelog_version(monorepo_root:)
  current_version ||= current_gem_version(monorepo_root)
  starting_version = [argumentless_starting_prerelease_version, current_version].compact.first

  if argumentless_prerelease_release_requires_explicit_version?(changelog_version:, current_version:,
                                                                starting_version:)
    abort argumentless_prerelease_release_message(changelog_version:, current_version:)
  end

  if changelog_version && Gem::Version.new(changelog_version) > Gem::Version.new(current_version)
    puts "Found CHANGELOG.md version: #{changelog_version} (current: #{current_version})"
    return changelog_version
  end

  # If the latest changelog version matches the current version but hasn't been
  # tagged yet, use it. This handles the case where the changelog was updated
  # and the version bumped in a prior step (e.g., RC → stable promotion).
  if untagged_changelog_current_version?(monorepo_root:, changelog_version:, current_version:)
    puts "Found untagged CHANGELOG.md version: #{changelog_version} (current: #{current_version})"
    return changelog_version
  end

  puts "No new version found in CHANGELOG.md (latest: #{changelog_version || 'none'}, current: #{current_version})."
  puts "Falling back to patch bump."
  "patch"
end

def fetch_rubygems_versions(gem_name, api_url: RUBYGEMS_VERSIONS_API_URL)
  uri = URI("#{api_url}/#{URI.encode_www_form_component(gem_name)}.json")
  response = Net::HTTP.start(
    uri.hostname,
    uri.port,
    use_ssl: uri.scheme == "https",
    open_timeout: RUBYGEMS_VERSIONS_OPEN_TIMEOUT_SECONDS,
    read_timeout: RUBYGEMS_VERSIONS_READ_TIMEOUT_SECONDS
  ) do |http|
    http.get(uri.request_uri)
  end
  [response.body, response]
end

def abort_npm_release_readiness!(reason, recovery:)
  abort <<~ERROR
    ❌ npm release readiness failed: #{reason}.

    #{recovery}
  ERROR
end

def supervised_release_retry_command(dry_run:, evaluate_head:)
  command = ["script/release"]
  command << "--dry-run" if dry_run
  command << "--evaluate-head" if evaluate_head
  command.join(" ")
end

def declared_pnpm_release_version!(monorepo_root:, retry_command: "script/release")
  package_json = JSON.parse(File.read(File.join(monorepo_root, "package.json")))
  package_manager = package_json["packageManager"]
  match = package_manager.to_s.match(/\Apnpm@(?<version>\d+\.\d+\.\d+)(?:\+sha512\.[0-9a-f]+)?\z/i)
  return match[:version] if match

  abort_npm_release_readiness!(
    "root packageManager must declare an exact pnpm version",
    recovery: <<~RECOVERY.strip
      Restore an exact pnpm@X.Y.Z pin in the root packageManager field.
      Then retry:
        #{retry_command}
    RECOVERY
  )
rescue Errno::ENOENT, JSON::ParserError => e
  abort_npm_release_readiness!(
    "root packageManager cannot be verified (#{e.class}: #{e.message})",
    recovery: <<~RECOVERY.strip
      Restore a readable root package.json with a valid exact packageManager pin.
      Then retry:
        #{retry_command}
    RECOVERY
  )
end

def capture_npm_release_readiness_command(monorepo_root, *command, retry_command: "script/release")
  Open3.capture2e(*command, chdir: monorepo_root)
rescue StandardError => e
  abort_npm_release_readiness!(
    "npm toolchain command failed to start (#{e.class}: #{e.message})",
    recovery: <<~RECOVERY.strip
      Restore the repository-declared pnpm command on PATH.
      Then retry:
        #{retry_command}
    RECOVERY
  )
end

def abort_stale_npm_release_dependencies!(retry_command: "script/release")
  abort_npm_release_readiness!(
    "installed dependency state is missing or stale",
    recovery: <<~RECOVERY.strip
      Required recovery:
        pnpm install --frozen-lockfile
      Then retry:
        #{retry_command}

      Optional broader environment refresh (not required for this failure):
        bin/setup
    RECOVERY
  )
end

def abort_pnpm_release_version_mismatch!(installed_version:, declared_version:, retry_command: "script/release")
  abort_npm_release_readiness!(
    "installed pnpm version #{installed_version.inspect} does not match packageManager #{declared_version.inspect}",
    recovery: <<~RECOVERY.strip
      Activate pnpm #{declared_version} declared by the root packageManager, then verify:
        pnpm --version
      Then retry:
        #{retry_command}
    RECOVERY
  )
end

def abort_pnpm_release_version_probe_failure!(output:, retry_command: "script/release")
  abort_npm_release_readiness!(
    "pnpm --version failed\n\n#{output.to_s.strip}",
    recovery: <<~RECOVERY.strip
      Restore the repository-declared pnpm command on PATH, then verify:
        pnpm --version
      Then retry:
        #{retry_command}
    RECOVERY
  )
end

def abort_npm_release_package_build!(package_name:, output:, retry_command: "script/release")
  abort_npm_release_readiness!(
    "#{package_name} build failed\n\n#{output.to_s.strip}",
    recovery: <<~RECOVERY.strip
      Fix the package build failure, then verify:
        pnpm --filter #{package_name} run build
      Then retry:
        #{retry_command}
    RECOVERY
  )
end

def validate_npm_release_readiness!(monorepo_root:, retry_command: "script/release")
  declared_pnpm_version = declared_pnpm_release_version!(monorepo_root:, retry_command:)
  workspace_lock = File.join(monorepo_root, "pnpm-lock.yaml")
  installed_lock = File.join(monorepo_root, "node_modules", ".pnpm", "lock.yaml")
  dependency_state_ready = File.file?(workspace_lock) && File.file?(installed_lock) &&
                           File.binread(workspace_lock) == File.binread(installed_lock)
  abort_stale_npm_release_dependencies!(retry_command:) unless dependency_state_ready

  version_output, version_status = capture_npm_release_readiness_command(
    monorepo_root, "pnpm", "--version", retry_command:
  )
  installed_pnpm_version = version_output.to_s.strip
  abort_pnpm_release_version_probe_failure!(output: version_output, retry_command:) unless version_status.success?

  unless installed_pnpm_version == declared_pnpm_version
    abort_pnpm_release_version_mismatch!(
      installed_version: installed_pnpm_version,
      declared_version: declared_pnpm_version,
      retry_command:
    )
  end

  NPM_RELEASE_PACKAGE_NAMES.each do |package_name|
    output, status = capture_npm_release_readiness_command(
      monorepo_root, "pnpm", "--filter", package_name, "run", "build", retry_command:
    )
    next if status.success?

    abort_npm_release_package_build!(package_name:, output:, retry_command:)
  end

  puts "✓ npm release packages are ready to publish"
end

def current_npm_release_readiness_sha!(monorepo_root:, context:)
  sha = current_git_sha!(monorepo_root, context:)
  return sha if sha.match?(/\A[0-9a-f]{40}\z/i)

  abort "❌ Unable to bind npm release readiness to an exact git SHA before #{context}."
end

def refresh_npm_release_readiness_after_pull!(monorepo_root:, readiness_sha:, retry_command: "script/release")
  post_pull_sha = current_npm_release_readiness_sha!(
    monorepo_root:,
    context: "post-pull npm release readiness verification"
  )
  return readiness_sha if post_pull_sha == readiness_sha

  validate_npm_release_readiness!(monorepo_root:, retry_command:)
  validated_sha = current_npm_release_readiness_sha!(
    monorepo_root:,
    context: "post-pull npm release readiness binding"
  )
  if validated_sha != post_pull_sha
    abort "❌ HEAD changed while npm release readiness was running; retry from a stable checkout."
  end

  validated_sha
end

def rubygem_version_published?(gem_name, version, api_url: RUBYGEMS_VERSIONS_API_URL)
  output, response = fetch_rubygems_versions(gem_name, api_url:)
  return false unless response.is_a?(Net::HTTPSuccess)

  versions = JSON.parse(output)
  versions.any? do |metadata|
    metadata.is_a?(Hash) && metadata["number"] == version
  end
rescue JSON::ParserError => e
  warn "⚠️  Unable to parse RubyGems metadata for #{gem_name}: #{e.message}; attempting publish."
  false
rescue StandardError => e
  warn "⚠️  Unable to check RubyGems metadata for #{gem_name}: #{e.class}: #{e.message}; attempting publish."
  false
end

def valid_rubygems_version_metadata?(versions)
  versions.is_a?(Array) && versions.all? do |metadata|
    metadata.is_a?(Hash) && metadata["number"].is_a?(String) && !metadata["number"].empty?
  end
end

def verify_rubygem_version_published!(gem_name, expected_version, api_url: RUBYGEMS_VERSIONS_API_URL)
  output, response = fetch_rubygems_versions(gem_name, api_url:)
  unless response.is_a?(Net::HTTPSuccess)
    abort "❌ Unable to verify exact RubyGem #{gem_name} #{expected_version} for publication recovery."
  end

  versions = JSON.parse(output)
  unless valid_rubygems_version_metadata?(versions)
    abort "❌ RubyGems returned malformed version metadata for #{gem_name}; publication recovery is unknown."
  end
  unless versions.any? { |metadata| metadata["number"] == expected_version }
    abort "❌ Exact RubyGem #{gem_name} #{expected_version} is not visible; publication recovery is incomplete."
  end

  puts "✓ Verified RubyGem #{gem_name} #{expected_version}"
rescue JSON::ParserError => e
  abort "❌ Unable to parse RubyGems metadata for #{gem_name} during publication recovery: #{e.message}"
rescue StandardError => e
  abort "❌ Unable to verify RubyGem #{gem_name} during publication recovery: #{e.class}: #{e.message}"
end

def verify_complete_release_registry_publication!(gem_version:)
  npm_version = ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(gem_version)
  NPM_RELEASE_PACKAGE_NAMES.each do |package_name|
    verify_npm_package_published!(package_name, npm_version)
  end
  RUBYGEMS_RELEASE_GEM_NAMES.each do |gem_name|
    verify_rubygem_version_published!(gem_name, gem_version)
  end
end

def abort_existing_registry_artifact_without_retry!(artifact_ref:, registry_name:)
  abort <<~ERROR
    ❌ #{artifact_ref} is already visible on #{registry_name}.

    Refusing to treat the existing artifact as this release unless this run is a proven idempotent retry.
    Verify the artifact source or remove the conflicting version before retrying.
  ERROR
end

def release_registry_publish_conflicts(gem_version:, npm_version:)
  npm_conflicts = NPM_RELEASE_PACKAGE_NAMES.select do |package_name|
    npm_package_already_published?(package_name, npm_version)
  end
  rubygems_conflicts = RUBYGEMS_RELEASE_GEM_NAMES.select do |gem_name|
    rubygem_version_published?(gem_name, gem_version)
  end

  npm_conflicts.map { |package_name| "npm package #{package_name}@#{npm_version}" } +
    rubygems_conflicts.map { |gem_name| "RubyGem #{gem_name} #{gem_version}" }
end

def preflight_registry_publish_conflicts!(gem_version:, npm_version:, idempotent_retry:)
  return if idempotent_retry

  conflicts = release_registry_publish_conflicts(gem_version:, npm_version:)
  return if conflicts.empty?

  abort <<~ERROR
    ❌ Target release artifacts already exist outside an idempotent retry.

    Existing artifacts:
    #{conflicts.map { |artifact| "  - #{artifact}" }.join("\n")}

    Verify the artifact source or remove the conflicting version before tagging and publishing this release.
  ERROR
end

def release_registry_publication_complete?(gem_version:, npm_version:)
  NPM_RELEASE_PACKAGE_NAMES.all? do |package_name|
    npm_package_already_published?(package_name, npm_version)
  end && RUBYGEMS_RELEASE_GEM_NAMES.all? do |gem_name|
    rubygem_version_published?(gem_name, gem_version)
  end
end

def github_release_complete?(monorepo_root:, version:)
  release_context = prepare_github_release_context(monorepo_root:, gem_version: version)
  repo_slug = github_repo_slug(monorepo_root)
  output, status = capture_gh_output(
    "release", "view", release_context.fetch(:tag), "--repo", repo_slug,
    "--json", "tagName,name,body,isDraft,isPrerelease"
  )
  return false unless status.success?

  release = JSON.parse(output)
  release.is_a?(Hash) && release == {
    "tagName" => release_context.fetch(:tag),
    "name" => release_context.fetch(:title),
    "body" => release_context.fetch(:notes),
    "isDraft" => false,
    "isPrerelease" => release_context.fetch(:prerelease)
  }
rescue JSON::ParserError
  false
end

def abort_if_fully_published_release!(monorepo_root:, gem_version:, npm_version:, idempotent_retry:)
  return unless idempotent_retry
  return unless release_registry_publication_complete?(gem_version:, npm_version:)
  return unless github_release_complete?(monorepo_root:, version: gem_version)

  abort <<~ERROR
    ❌ #{gem_version} is already fully published.

    Prepare and commit the next non-empty CHANGELOG.md section immediately after
    `### [Unreleased]`, then rerun:

      script/release
  ERROR
end

def skip_existing_rubygem_publish?(gem_name:, published_version:, idempotent_retry:)
  return false unless published_version
  return false unless rubygem_version_published?(gem_name, published_version)

  unless idempotent_retry
    abort_existing_registry_artifact_without_retry!(
      artifact_ref: "RubyGem #{gem_name} #{published_version}",
      registry_name: "RubyGems.org"
    )
  end

  puts "ℹ️ RubyGem #{gem_name} #{published_version} is already visible on RubyGems.org; skipping publish."
  true
end

def validated_gem_release_max_retries!(value)
  max_retries = value.is_a?(String) ? Integer(value, 10) : value
  return max_retries if max_retries.is_a?(Integer) && max_retries.positive?

  abort "❌ GEM_RELEASE_MAX_RETRIES must be a positive base-10 integer; got #{value.inspect}."
rescue ArgumentError, TypeError
  abort "❌ GEM_RELEASE_MAX_RETRIES must be a positive base-10 integer; got #{value.inspect}."
end

def publish_gem_with_retry(dir, gem_name, otp: nil, published_version: nil, idempotent_retry: false,
                           max_retries: ENV.fetch("GEM_RELEASE_MAX_RETRIES", "3"))
  max_retries = validated_gem_release_max_retries!(max_retries)
  puts "\nPublishing #{gem_name} gem to RubyGems.org..."
  current_otp = normalize_otp_code(otp, service_name: "RubyGems")

  return current_otp if skip_existing_rubygem_publish?(gem_name:, published_version:, idempotent_retry:)

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
      release_write_fence!("publish RubyGem #{gem_name} attempt #{retry_count + 1}")
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

def npm_package_already_published?(package_name, expected_version, registry_url: NPM_REGISTRY_URL)
  package_ref = "#{package_name}@#{expected_version}"
  output, status = fetch_npm_package_metadata(package_ref, registry_url:)
  return false unless status.success?

  metadata = JSON.parse(output)
  actual_version = metadata.is_a?(Hash) ? metadata["version"] : metadata.to_s
  return false unless actual_version == expected_version

  workspace_dependencies = workspace_protocol_dependencies(metadata)
  unless workspace_dependencies.empty?
    abort <<~ERROR
      ❌ #{package_ref} is already published with workspace protocol dependencies.

      Published packages must not contain workspace:* install-time dependencies because external package managers
      cannot resolve them from npm.

      Offending dependencies:
      #{workspace_dependencies.map { |dependency| "  - #{dependency}" }.join("\n")}
    ERROR
  end

  true
rescue JSON::ParserError => e
  warn "⚠️  Unable to parse npm metadata for #{package_ref}: #{e.message}; attempting publish."
  false
end

def sanitized_npm_publish_output(output, otp:)
  sanitized = output.to_s.dup
  sanitized.gsub!(otp.to_s, "[REDACTED]") unless otp.to_s.empty?
  sanitized.gsub!(/(--otp(?:=|\s+))\d+/i, '\\1[REDACTED]')
  sanitized.gsub!(/\b(otp(?:\s+code)?\s*[:=]\s*)\d+/i, '\\1[REDACTED]')
  sanitized.strip
end

def npm_publish_failure_category(output)
  text = output.to_s
  return :otp_challenge if text.match?(/\bEOTP\b/i)
  return :authentication_failure if text.match?(/\b(?:ENEEDAUTH|E401)\b|authentication (?:is )?required/i)
  return :local_lifecycle if npm_publish_local_lifecycle_failure?(text)
  return :registry_rejection if text.match?(NPM_PUBLISH_REGISTRY_REJECTION_PATTERN)
  return :otp_challenge if text.match?(
    /one[- ]time (?:password|passcode)|\botp(?: code)?\b.*\b(?:required|invalid|expired)\b/i
  )
  return :transient if text.match?(NPM_PUBLISH_TRANSIENT_PATTERN)

  :unknown
end

def npm_publish_local_lifecycle_failure?(text)
  return true if text.match?(NPM_PUBLISH_LOCAL_LIFECYCLE_HARD_PATTERN)

  text.each_line.any? do |line|
    line.match?(NPM_PUBLISH_LOCAL_LIFECYCLE_BANNER_PATTERN) &&
      line.match?(NPM_PUBLISH_LOCAL_LIFECYCLE_FAILURE_CONTEXT_PATTERN)
  end || text.each_line.any? { |line| line.match?(/\berror\s+TS\d+\b/i) }
end

def run_npm_publish_attempt!(dir:, package_name:, attempt:, publish_args:, otp:)
  command_args = ["pnpm", "publish", *publish_args]
  command_args += ["--otp", otp] if otp
  release_write_fence!("publish npm #{package_name} attempt #{attempt}")
  output, status = Open3.capture2e(*command_args, chdir: dir)
  return if status.success?

  sanitized_output = sanitized_npm_publish_output(output, otp:)
  raise NpmPublishAttemptError.new(
    category: npm_publish_failure_category(output),
    details: sanitized_output.empty? ? "command failed without diagnostic output" : sanitized_output
  )
rescue NpmPublishAttemptError
  raise
rescue StandardError => e
  raise NpmPublishAttemptError.new(
    category: :unknown,
    details: "command could not be executed (#{e.class}: #{sanitized_npm_publish_output(e.message, otp:)})"
  )
end

def retry_npm_publish_after_error(error:, package_name:, attempt:, max_retries:, current_otp:)
  raise error if NPM_PUBLISH_HARD_FAILURE_CATEGORIES.include?(error.category)

  if attempt >= max_retries
    warn "\n❌ Failed to publish #{package_name} after #{max_retries} classified attempts"
    raise error
  end

  warn "\n⚠️  #{package_name} publish #{error.category.to_s.tr('_', ' ')} " \
       "(attempt #{attempt}/#{max_retries})"
  warn error.message
  if error.category == :otp_challenge
    warn "Prompting for a fresh NPM OTP before retrying."
    return prompt_for_otp("NPM")
  end

  delay = [2**(attempt - 1), NPM_PUBLISH_MAX_BACKOFF_SECONDS].min
  warn "Retrying the transient npm failure in #{delay} seconds with the same OTP."
  sleep delay
  current_otp
end

def publish_npm_with_retry(dir, package_name, base_args: [], otp: nil, idempotent_retry: false, max_retries: 3)
  puts "\nPublishing #{package_name}..."
  current_otp = normalize_otp_code(otp, service_name: "NPM")
  publish_args = Array(base_args)
  npm_package_name, npm_package_version = parse_npm_package_ref(package_name)

  if npm_package_already_published?(npm_package_name, npm_package_version)
    unless idempotent_retry
      abort_existing_registry_artifact_without_retry!(artifact_ref: "npm package #{package_name}", registry_name: "npm")
    end

    puts "ℹ️ npm package #{package_name} is already visible on npm; skipping publish."
    return current_otp
  end

  attempt = 0
  uncertain_publish_attempt = false
  loop do
    attempt += 1
    begin
      with_publishable_package_json(dir, npm_package_version) do
        run_npm_publish_attempt!(dir:, package_name:, attempt:, publish_args:, otp: current_otp)
      end
      verify_npm_package_published!(npm_package_name, npm_package_version)
      return current_otp
    rescue NpmPublishAttemptError => e
      uncertain_publish_attempt ||= e.category == :transient
      recoverable_after_uncertainty =
        uncertain_publish_attempt && NPM_PUBLISH_UNCERTAIN_RECOVERY_CATEGORIES.include?(e.category)
      if recoverable_after_uncertainty && npm_package_already_published?(npm_package_name, npm_package_version)
        puts "✓ npm package #{package_name} is visible after an uncertain publish attempt; treating it as successful."
        return current_otp
      end

      current_otp = retry_npm_publish_after_error(
        error: e, package_name:, attempt:, max_retries:, current_otp:
      )
    end
  end
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
skip git branch checks, allowing releases from non-main branches. A stable release may run from
`main` (standard) or from a matching `release/X.Y.Z` branch (release-train RC -> final promotion,
see internal/contributor-info/release-train-runbook.md).

Retry safety: Never drop the version argument when previewing recovery from an interrupted release.
Preview the exact version, for example `bundle exec rake \"release[16.2.0.rc.1,true]\"`. An argument-less
command from a prerelease checkout fails closed instead of inferring promotion to the stable version.

Live release entry point: `script/release`. It reads the first prepared version after
`### [Unreleased]`, acquires the matching release-line claim under a fresh process UUID, and
supervises this task with fresh authoritative per-write lease fences.
Direct live `bundle exec rake release[...]` is refused without that private wrapper contract;
use Rake directly only with `dry_run=true`. See internal/contributor-info/release-train-runbook.md
for one-time machine setup, automation compatibility, recovery, and the supervised reconciliation path.

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
  - empty (auto): from a prerelease checkout, use only a newer same-line prerelease from CHANGELOG.md;
    otherwise abort with explicit retry guidance. From a stable checkout, use a newer CHANGELOG.md version
    or derive a patch candidate; the stable changelog gate still requires a matching non-empty section.
2nd argument: Dry run (true/false, default: false)
3rd argument: Override version policy checks (true/false, default: false)
4th argument: Override prerelease CI gates only (true/false, default: false)

Release CI policy:
  Before releasing, the script checks CI status on the tip of the branch being released:
  origin/main for a standard release, or origin/release/X.Y.Z when releasing from a release branch.
  - It evaluates the most recent commit that ran the full suite: if HEAD is
    changelog/docs/comment-only (e.g. the pre-release `update-changelog`
    commit), CI path-skips the runtime suite there, so the gate walks back to
    the last runtime-bearing commit instead of waiting on meaningless checks.
    The CI gate prints a strict exact-HEAD retry command only after it has found complete healthy
    CI evidence on the fetched final tip.
  - Stable releases require every check run on the commit to have succeeded.
  - Pre-releases require only the GitHub-branch-protection-required checks
    to have succeeded.
  A prepared next-version CHANGELOG.md push on release/** automatically starts
  the ShakaPerf RSC FOUC gate. After pushing the version bump commit, the script
  reuses that pre-run only when its artifact proves the same branch/version,
  pre-release time ordering, freshness, and an identical runtime tree across
  allowlisted release metadata changes. Otherwise it dispatches an exact-head
  workflow_dispatch gate and waits for verified evidence before creating/pushing
  the tag and publishing npm packages or Ruby gems.
  RELEASE_SHAKAPERF_RUN can bind an already successful exact run to RELEASE_TRACKER after full
  GitHub/schema-v2 verification. Later invocations re-fetch and re-verify that durable association.
  If that gate fails, the remote branch has the version-bump commit but no release
  tag or published packages. Preserve the failure evidence; do not rerun or revert
  this partial release. Follow the partial-publication recovery procedure in the runbook.
  In-progress checks and failing gates block the release until they pass. An explicitly approved
  prerelease-only waiver may use the 4th argument or RELEASE_CI_STATUS_OVERRIDE=true.
  An explicit RC may instead use the audited accelerated path to publish while only pending
  exact-head CI and ShakaPerf gates finish. That path rejects known failures and unknown evidence,
  records immutable candidate evidence on a maintainer-controlled release tracker, and must be
  reconciled before final promotion. It never applies to stable/final releases.

Environment variables:
  VERBOSE=1                    # Enable verbose logging (shows all output)
  NPM_OTP=<code>               # Provide NPM one-time password (reused for all NPM publishes)
  RUBYGEMS_OTP=<code>          # Provide RubyGems one-time password (reused for both gems)
  RELEASE_VERSION_POLICY_OVERRIDE=true # Override release version policy checks
  RELEASE_CI_STATUS_OVERRIDE=true      # DANGEROUS prerelease-only release CI waiver
  RELEASE_ACCELERATED_RC=true           # Enable audited pending-gate publication from matching release/X.Y.Z
  RELEASE_TRACKER=<issue>               # Active release tracker for ShakaPerf evidence/accelerated RC/final promotion
  RELEASE_SHAKAPERF_RUN=<id-or-url>      # Verify, save, and reuse one exact ShakaPerf run; not a waiver
  RELEASE_FINAL_SHAKAPERF_WAIVER_REASON=<reason> # Stable-only gate-observation failure waiver; tracked and scoped
  RELEASE_ACCELERATED_RC_REASON=<reason> # Single-line maintainer rationale for accelerated publication
  GEM_RELEASE_MAX_RETRIES=<n>  # Positive base-10 integer max retry attempts (default: 3)

Examples:
  script/release                              # Only supported live publication path
  script/release --dry-run                    # Preview the prepared version without coordination
  script/release --reconcile-accelerated-rc   # Supervised accelerated-RC reconciliation
  rake \"release[,true]\"                       # Preview auto-detected version
  rake \"release[patch,true]\"                  # Preview patch bump (16.1.1 → 16.1.2)
  rake \"release[minor,true]\"                  # Preview minor bump (16.1.1 → 16.2.0)
  rake \"release[major,true]\"                  # Preview major bump (16.1.1 → 17.0.0)
  rake \"release[16.2.0,true]\"                 # Preview explicit version
  rake \"release[16.2.0.beta.1,true]\"          # Preview prerelease (→ 16.2.0-beta.1 for NPM)
  RELEASE_ACCELERATED_RC=true RELEASE_TRACKER=<issue> RELEASE_ACCELERATED_RC_REASON=<reason> \
    rake \"release[16.2.0.rc.1,true]\"          # Preview an accelerated RC
  RELEASE_TRACKER=<issue> RELEASE_SHAKAPERF_RUN=<run-id-or-url> \
    rake \"release[16.2.0,true]\"               # Preview the selector's target and tracker inputs
  VERBOSE=1 rake \"release[patch,true]\"        # Preview with verbose logging")
task :release, %i[version dry_run override_version_policy override_ci_status] do |_t, args|
  monorepo_root = current_monorepo_root
  release_started_at = Time.now.utc

  args_hash = args.to_hash

  is_dry_run = release_truthy?(args_hash[:dry_run])
  release_retry_command = supervised_release_retry_command(
    dry_run: is_dry_run,
    evaluate_head: ci_evaluate_head_only?
  )
  activate_release_lease_guard!(dry_run: is_dry_run)
  is_verbose = ENV["VERBOSE"] == "1"
  allow_version_policy_override = version_policy_override_enabled?(args_hash[:override_version_policy])
  npm_otp = ENV.fetch("NPM_OTP", nil)
  rubygems_otp = ENV.fetch("RUBYGEMS_OTP", nil)
  gem_release_max_retries = unless is_dry_run
                              validated_gem_release_max_retries!(ENV.fetch("GEM_RELEASE_MAX_RETRIES", "3"))
                            end

  current_branch_output, current_branch_status = Open3.capture2e(
    "git", "-C", monorepo_root, "rev-parse", "--abbrev-ref", "HEAD"
  )
  abort "❌ Failed to determine current git branch.\n\n#{current_branch_output}" unless current_branch_status.success?
  current_branch = current_branch_output.strip

  # Check if there are uncommitted changes
  ReactOnRails::GitUtils.uncommitted_changes?(RaisingMessageHandler.new)

  # Configure output verbosity
  verbose(is_verbose)

  initial_readiness_sha = current_npm_release_readiness_sha!(
    monorepo_root:,
    context: "initial npm release readiness verification"
  )
  validate_npm_release_readiness!(monorepo_root:, retry_command: release_retry_command)
  validated_readiness_sha = current_npm_release_readiness_sha!(
    monorepo_root:,
    context: "initial npm release readiness binding"
  )
  if validated_readiness_sha != initial_readiness_sha
    abort "❌ HEAD changed while npm release readiness was running; retry from a stable checkout."
  end
  npm_readiness_sha = validated_readiness_sha

  released_gem_version = nil
  released_npm_version = nil
  accelerated_publication_record = nil
  final_promotion_context = nil
  ordinary_stable_shakaperf_association_context = nil
  ordinary_stable_shakaperf_waiver_context = nil
  argumentless_starting_prerelease_version = if args_hash.fetch(:version, "").to_s.strip.empty?
                                               starting_version = current_gem_version(monorepo_root)
                                               starting_version if release_prerelease_version?(starting_version)
                                             end

  with_release_checkout(monorepo_root:, dry_run: is_dry_run) do |release_root|
    release_paths_hash = release_paths(release_root)
    unless is_dry_run
      sh_in_dir_for_release(release_root, "git pull --rebase")
      npm_readiness_sha = refresh_npm_release_readiness_after_pull!(
        monorepo_root: release_root,
        readiness_sha: npm_readiness_sha,
        retry_command: release_retry_command
      )
    end

    validate_supervised_release_version_after_pull!(
      monorepo_root: release_root,
      selected_version: args_hash.fetch(:version, "").to_s.strip,
      dry_run: is_dry_run
    )

    version_input = resolve_release_version_before_auth!(
      version_input: args_hash.fetch(:version, ""),
      monorepo_root: release_root,
      dry_run: is_dry_run,
      current_version: argumentless_starting_prerelease_version
    )

    current_checkout_version = current_gem_version(release_root)
    resolved_target_gem_version = compute_target_gem_version(
      current_gem_version: current_checkout_version,
      version_input:
    )
    version_converter = ReactOnRails::VersionSyntaxConverter.new
    resolved_target_npm_version = version_converter.rubygem_to_npm(resolved_target_gem_version)
    is_prerelease = release_prerelease_version?(resolved_target_gem_version)
    unless is_dry_run
      abort_if_fully_published_release!(
        monorepo_root: release_root,
        gem_version: resolved_target_gem_version,
        npm_version: resolved_target_npm_version,
        idempotent_retry: current_checkout_version == resolved_target_gem_version
      )
    end
    shakaperf_run_selector = normalized_optional_release_value(ENV.fetch("RELEASE_SHAKAPERF_RUN", nil))
    shakaperf_waiver_reason = normalized_optional_release_value(
      ENV.fetch("RELEASE_FINAL_SHAKAPERF_WAIVER_REASON", nil)
    )
    if shakaperf_waiver_reason
      abort "❌ RELEASE_FINAL_SHAKAPERF_WAIVER_REASON is allowed for stable releases only." if is_prerelease
      validate_final_shakaperf_observation_waiver_reason!(shakaperf_waiver_reason)
    end
    release_tracker_input = ENV.fetch("RELEASE_TRACKER", nil)
    explicit_shakaperf_control = !shakaperf_run_selector.to_s.empty? || !shakaperf_waiver_reason.to_s.empty?
    accelerated_rc_requested = release_truthy?(ENV.fetch("RELEASE_ACCELERATED_RC", nil))
    if accelerated_rc_requested && shakaperf_run_selector
      abort "❌ RELEASE_ACCELERATED_RC=true cannot be combined with RELEASE_SHAKAPERF_RUN."
    end
    shakaperf_tracker = if accelerated_rc_requested && !explicit_shakaperf_control
                          nil
                        else
                          validated_shakaperf_release_tracker!(
                            monorepo_root: release_root,
                            tracker_input: release_tracker_input,
                            required: explicit_shakaperf_control,
                            target_version: resolved_target_gem_version
                          )
                        end
    prerelease_tag_retry_state = :none
    if is_prerelease
      prerelease_tag_retry_state = release_tag_retry_state_for_current_head(
        monorepo_root: release_root,
        current_branch:,
        current_checkout_version:,
        target_gem_version: resolved_target_gem_version,
        tag_type: "prerelease"
      )
    end
    allow_ci_status_override = ci_status_override_allowed_for_release!(
      override_flag: args_hash[:override_ci_status],
      is_prerelease:
    )
    accelerated_rc_same_candidate_retry = rc_prerelease_version?(resolved_target_gem_version) &&
                                          current_checkout_version == resolved_target_gem_version
    accelerated_rc_retry_probe = !accelerated_rc_requested && accelerated_rc_same_candidate_retry
    repo_slug = github_repo_slug(release_root) if accelerated_rc_requested || accelerated_rc_retry_probe
    accelerated_rc_options = resolve_accelerated_rc_options_for_release!(
      requested: accelerated_rc_requested,
      explicit_version_input: args_hash.fetch(:version, ""),
      target_gem_version: resolved_target_gem_version,
      tracker: release_tracker_input,
      reason: ENV.fetch("RELEASE_ACCELERATED_RC_REASON", nil),
      allow_ci_override: allow_ci_status_override,
      repo_slug:,
      monorepo_root: release_root,
      current_checkout_version:,
      candidate_sha: accelerated_rc_same_candidate_retry ? current_git_sha!(release_root) : nil
    )
    if accelerated_rc_options && shakaperf_run_selector
      abort "❌ Persisted accelerated RC retry cannot be combined with RELEASE_SHAKAPERF_RUN."
    end
    if accelerated_rc_options
      ensure_accelerated_rc_release_branch!(
        current_branch:,
        target_gem_version: resolved_target_gem_version
      )
    end
    if accelerated_rc_options && accelerated_rc_requested
      preflight_explicit_accelerated_rc_target_tag!(
        monorepo_root: release_root,
        target_gem_version: resolved_target_gem_version,
        current_checkout_version:
      )
    end
    accelerated_approver = nil
    if accelerated_rc_options
      repo_slug ||= github_repo_slug(release_root)
      fetch_release_tracker_issue!(
        repo_slug:,
        tracker: accelerated_rc_options.fetch(:tracker),
        target_version: accelerated_rc_options.fetch(:target_gem_version)
      )
      accelerated_approver = current_release_approver!(repo_slug:)
    end

    # When cutting an rc from `main` and `release/X.Y.Z` does not yet exist, offer
    # to start the release line here instead of tagging the rc off `main`. If the
    # operator accepts (or the branch already exists), this exits before any
    # tagging. `release_root == monorepo_root` in normal mode, so the offer
    # operates on the real repo; `main` was already refreshed by `git pull --rebase`.
    maybe_offer_release_branch_cut!(
      monorepo_root: release_root,
      current_branch:,
      target_gem_version: resolved_target_gem_version,
      dry_run: is_dry_run
    )

    ensure_release_branch_matches_target_base!(
      current_branch:,
      target_gem_version: resolved_target_gem_version
    )

    unless is_prerelease || stable_release_branch_allowed?(current_branch:,
                                                           target_gem_version: resolved_target_gem_version)
      abort <<~ERROR
        ❌ Stable release must be run from `main` or the matching release branch!

        Current branch: #{current_branch}
        Target version: #{resolved_target_gem_version}

        To release a stable version, run from one of:
          - main (standard release):
              git checkout main && git pull --rebase
          - release/#{resolved_target_gem_version} (RC → final promotion, per the release-train runbook):
              promote the last good RC in place; do not re-cut from main

        For pre-release versions (beta, alpha, rc, etc.), preview from any branch with:
          rake "release[#{resolved_target_gem_version.sub(/(\d+\.\d+\.\d+)/, '\\1.beta.1')},true]"

        #{release_compound_live_boundary_guidance}
      ERROR
    end

    release_branch_promotion = { stable_tag_retry: false, stable_tag_at_head: false }
    unless is_prerelease
      release_branch_promotion = ensure_release_branch_promotes_tagged_rc!(
        monorepo_root: release_root,
        current_branch:,
        current_checkout_version:,
        target_gem_version: resolved_target_gem_version
      )
    end
    release_branch_final_promotion = !is_prerelease && current_branch == "release/#{resolved_target_gem_version}"
    accepted_rc_record = nil
    if release_branch_final_promotion
      rc_tag = release_branch_promotion.fetch(:rc_tag)
      accepted_rc_record = accepted_accelerated_rc_record_for_release_branch_promotion!(
        monorepo_root: release_root,
        rc_tag:,
        final_head_sha: current_git_sha!(release_root),
        tracker_input: ENV.fetch("RELEASE_TRACKER", nil)
      )
    end

    # Validate the tip of the branch we are actually releasing from: the
    # release/X.Y.Z tip for an RC cut or final promotion, otherwise origin/main.
    ci_branch = release_ci_branch(current_branch)
    release_branch_tag_scope = current_branch == "release/#{release_base_version(resolved_target_gem_version)}"
    main_stable_tag_retry_state = :none
    if !is_prerelease && current_branch == "main"
      main_stable_tag_retry_state = stable_release_retry_state_for_current_head(
        monorepo_root: release_root,
        current_branch:,
        current_checkout_version:,
        target_gem_version: resolved_target_gem_version
      )
    end
    idempotent_publish_retry = release_branch_promotion.fetch(:stable_tag_retry) ||
                               remote_release_tag_retry?(main_stable_tag_retry_state) ||
                               remote_release_tag_retry?(prerelease_tag_retry_state)
    target_tag_at_head = release_branch_promotion.fetch(:stable_tag_at_head) ||
                         release_tag_at_current_head?(main_stable_tag_retry_state) ||
                         release_tag_at_current_head?(prerelease_tag_retry_state)

    validate_main_ci_status!(
      monorepo_root: release_root,
      is_prerelease:,
      allow_override: allow_ci_status_override,
      dry_run: is_dry_run,
      ci_branch:,
      current_branch:,
      target_gem_version: resolved_target_gem_version,
      defer_pending: !accelerated_rc_options.nil?
    )

    validate_release_version_policy!(
      monorepo_root: release_root,
      target_gem_version: resolved_target_gem_version,
      allow_override: allow_version_policy_override,
      fetch_tags: true,
      allow_existing_target_tag: target_tag_at_head,
      release_branch_final_promotion:,
      release_branch_tag_scope:
    )

    unless is_dry_run
      preflight_registry_publish_conflicts!(
        gem_version: resolved_target_gem_version,
        npm_version: resolved_target_npm_version,
        idempotent_retry: idempotent_publish_retry
      )
    end

    confirm_release!(version: resolved_target_gem_version, monorepo_root: release_root, dry_run: is_dry_run)

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
    actual_npm_version = version_converter.rubygem_to_npm(actual_gem_version)

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
    unbundled_sh_in_dir_for_release(release_paths_hash[:monorepo_root], "bundle install#{bundle_quiet_flag}")
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
      push_release_version_commit!(release_root)
      release_candidate_sha = current_git_sha!(release_root)
      validated_release_candidate_sha = release_candidate_sha
      tag_name = "v#{actual_gem_version}"
      if accelerated_rc_options
        accelerated_publication_record = authorize_accelerated_rc_publication!(
          repo_slug:,
          monorepo_root: release_root,
          release_branch: current_branch,
          candidate_sha: release_candidate_sha,
          options: accelerated_rc_options,
          approver: accelerated_approver,
          release_started_at:,
          tag: tag_name
        )
      elsif accepted_rc_record
        final_promotion_context = run_accepted_rc_final_promotion_gates!(
          repo_slug: github_repo_slug(release_root),
          monorepo_root: release_root,
          current_branch:,
          rc_tag:,
          tracker_input: ENV.fetch("RELEASE_TRACKER", nil),
          final_head_sha: release_candidate_sha,
          record: accepted_rc_record,
          target_version: actual_gem_version,
          release_started_at:,
          allow_ci_override: allow_ci_status_override,
          dry_run: is_dry_run,
          shakaperf_tracker:,
          shakaperf_run_selector:,
          shakaperf_waiver_reason:
        )
        validated_release_candidate_sha = final_promotion_context.fetch(:candidate_sha)
        accepted_rc_record = final_promotion_context.fetch(:record)
      else
        shakaperf_result = run_shakaperf_release_gate!(
          monorepo_root: release_root,
          ref: current_branch,
          head_sha: release_candidate_sha,
          target_version: actual_gem_version,
          release_started_at:,
          allow_override: allow_ci_status_override,
          dry_run: is_dry_run,
          tracker: shakaperf_tracker,
          run_selector: shakaperf_run_selector,
          waiver_reason: shakaperf_waiver_reason
        )
        if shakaperf_result.is_a?(Hash) && shakaperf_result["observationWaived"] == true
          ordinary_stable_shakaperf_waiver_context = ordinary_stable_shakaperf_waiver_context!(
            run: shakaperf_result,
            ref: current_branch,
            head_sha: release_candidate_sha,
            target_version: actual_gem_version,
            release_started_at:
          )
        else
          ordinary_stable_shakaperf_association_context = ordinary_stable_shakaperf_association_context!(
            repo_slug: github_repo_slug(release_root),
            tracker: shakaperf_tracker,
            run: shakaperf_result,
            ref: current_branch,
            head_sha: release_candidate_sha,
            target_version: actual_gem_version,
            release_started_at:
          )
        end
      end

      push_release_tag_for_candidate!(
        monorepo_root: release_root,
        tag: tag_name,
        candidate_sha: validated_release_candidate_sha,
        accelerated_boundary_record: accelerated_publication_record || accepted_rc_record,
        accelerated_final_promotion_context: final_promotion_context,
        ordinary_stable_shakaperf_association_context:,
        ordinary_stable_shakaperf_waiver_context:
      )

      puts "\n#{'=' * 80}"
      puts "Publishing PUBLIC packages to npmjs.org..."
      puts "=" * 80

      current_npm_otp = npm_otp

      if current_npm_otp
        puts "Using provided NPM OTP for NPM package publications..."
      else
        puts "\nNOTE: You will be prompted for NPM OTP code if needed."
        puts "TIP: Set NPM_OTP environment variable to provide OTP upfront."
      end

      npm_dist_tag = npm_dist_tag_for_version(actual_npm_version)
      puts "NPM target: #{actual_npm_version} (dist-tag: #{npm_dist_tag})"
      npm_base_args = npm_publish_base_args(
        actual_gem_version:,
        actual_npm_version:,
        current_branch:
      )

      if release_prerelease_version?(actual_gem_version)
        puts "Pre-release version detected - skipping git branch checks for NPM publish"
      elsif current_branch.start_with?("release/")
        puts "Release branch detected - allowing NPM publish from #{current_branch}"
      end

      current_npm_otp = publish_npm_with_retry(
        File.join(release_root, "packages", "react-on-rails"),
        "react-on-rails@#{actual_npm_version}",
        base_args: npm_base_args,
        otp: current_npm_otp,
        idempotent_retry: idempotent_publish_retry
      )

      current_npm_otp = publish_npm_with_retry(
        File.join(release_root, "packages", "react-on-rails-pro"),
        "react-on-rails-pro@#{actual_npm_version}",
        base_args: npm_base_args,
        otp: current_npm_otp,
        idempotent_retry: idempotent_publish_retry
      )

      puts "\n#{'=' * 80}"
      puts "Publishing PUBLIC node-renderer to npmjs.org..."
      puts "=" * 80

      current_npm_otp = publish_npm_with_retry(
        File.join(release_root, "packages", "react-on-rails-pro-node-renderer"),
        "react-on-rails-pro-node-renderer@#{actual_npm_version}",
        base_args: npm_base_args,
        otp: current_npm_otp,
        idempotent_retry: idempotent_publish_retry
      )

      publish_npm_with_retry(
        File.join(release_root, "packages", "create-react-on-rails-app"),
        "create-react-on-rails-app@#{actual_npm_version}",
        base_args: npm_base_args,
        otp: current_npm_otp,
        idempotent_retry: idempotent_publish_retry
      )

      puts "\n#{'=' * 80}"
      puts "Publishing PUBLIC Ruby gems..."
      puts "=" * 80

      current_rubygems_otp = resolve_rubygems_otp_for_publish(rubygems_otp)

      current_rubygems_otp = publish_gem_with_retry(
        release_paths_hash[:gem_root],
        "react_on_rails",
        otp: current_rubygems_otp,
        published_version: actual_gem_version,
        idempotent_retry: idempotent_publish_retry,
        max_retries: gem_release_max_retries
      )

      publish_gem_with_retry(
        release_paths_hash[:pro_gem_root],
        "react_on_rails_pro",
        otp: current_rubygems_otp,
        published_version: actual_gem_version,
        idempotent_retry: idempotent_publish_retry,
        max_retries: gem_release_max_retries
      )

      if accelerated_publication_record
        tracker = accelerated_publication_record.fetch("release_tracker")
        record_accelerated_rc_publication_complete!(
          repo_slug:,
          tracker:,
          authorized_record: accelerated_publication_record,
          recorded_at: Time.now.utc,
          approved_by: accelerated_approver
        )
        puts "⚠️ RC published with gates still reconciling. Before final promotion, run:"
        puts "  RELEASE_TRACKER=#{tracker} script/release --reconcile-accelerated-rc"
      end
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
    report_release_dry_run_follow_up(version: released_gem_version)
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

Direct live sync_github_release is refused without the private release supervisor contract. Preview this
task directly; for a fenced idempotent create or edit, keep the exact published version as the prepared
CHANGELOG.md section and use `script/release`. See internal/contributor-info/release-train-runbook.md.

Arguments:
1st argument: Gem version in RubyGems format (required), e.g. 16.4.0 or 16.4.0.rc.1
2nd argument: Dry run (true/false, default: false)

Examples:
  rake \"sync_github_release[16.4.0,true]\"
  rake \"sync_github_release[16.4.0.rc.1,true]\"
")
task :sync_github_release, %i[gem_version dry_run] do |_t, args|
  monorepo_root = current_monorepo_root
  args_hash = args.to_hash
  is_dry_run = release_truthy?(args_hash[:dry_run])

  requested_gem_version = args_hash[:gem_version].to_s.strip
  if requested_gem_version.empty?
    abort "❌ gem_version is required. Usage: " \
          "rake \"sync_github_release[16.4.0,true]\" or rake \"sync_github_release[16.4.0.rc.1,true]\""
  end
  validate_requested_version_input!(requested_gem_version)
  activate_release_lease_guard!(dry_run: is_dry_run)

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

# Resolve the base `X.Y.Z` for `rake "release:start"`. An explicit arg is the
# branch base and must be a strict stable version (rc/prerelease forms are
# rejected — the rc index belongs in the changelog, not the branch name). With no
# arg, derive the base from the top changelog header when it is an `X.Y.Z.rc.N`
# rc; otherwise abort asking for an explicit `X.Y.Z`.
def resolve_release_start_base_version(version_arg, monorepo_root:)
  requested = version_arg.to_s.strip
  unless requested.empty?
    unless requested.match?(/\A\d+\.\d+\.\d+\z/)
      abort <<~ERROR
        ❌ Invalid release line version: #{requested.inspect}

        Pass the stable base of the release line as X.Y.Z (e.g. 17.0.0). The rc
        index lives in CHANGELOG.md, not the branch name — do not pass 17.0.0.rc.0.
      ERROR
    end
    return requested
  end

  changelog_version = extract_latest_changelog_version(monorepo_root:)
  if changelog_version && rc_prerelease_version?(changelog_version)
    base = release_base_version(changelog_version)
    puts "ℹ️ Derived release line #{base} from the top CHANGELOG.md header (#{changelog_version})."
    return base
  end

  abort <<~ERROR
    ❌ Could not determine which release line to start.

    The top CHANGELOG.md header is not an rc (found: #{changelog_version || 'none'}).
    Preview the release line explicitly: bundle exec rake "release:start[17.0.0,true]"

    #{release_compound_live_boundary_guidance}
  ERROR
end

# rubocop:disable Metrics/BlockLength
namespace :release do
  desc("Reconcile an accelerated RC's deferred gates and record an accepted or rejected tracker state.")
  task :reconcile_accelerated_rc, [:version] do |_t, args|
    monorepo_root = current_monorepo_root
    activate_release_lease_guard!(dry_run: false)
    target_version = args[:version].to_s.strip
    abort "❌ Accelerated RC reconciliation requires an explicit RC version." if target_version.empty?
    validate_canonical_accelerated_rc_target!(target_version)
    ReactOnRails::GitUtils.uncommitted_changes?(RaisingMessageHandler.new)
    sh_in_dir_for_release(monorepo_root, "git pull --rebase")
    validate_supervised_release_version_after_pull!(
      monorepo_root:,
      selected_version: target_version,
      dry_run: false
    )

    tracker_input = ENV.fetch("RELEASE_TRACKER", nil)
    unless tracker_input.to_s.match?(/\A[1-9]\d*\z/)
      abort "❌ Accelerated RC reconciliation requires RELEASE_TRACKER=<active issue number>."
    end

    reason = ENV.fetch("RELEASE_ACCELERATED_RC_RECONCILIATION_REASON", nil)
    evidence = {
      "demo_fleet" => ENV.fetch("RELEASE_DEMO_FLEET_EVIDENCE_URL", nil),
      "behavioral" => ENV.fetch("RELEASE_BEHAVIORAL_EVIDENCE_URL", nil),
      "artifacts" => ENV.fetch("RELEASE_ARTIFACT_EVIDENCE_URL", nil)
    }
    verify_gh_auth(monorepo_root:)
    run_accelerated_rc_reconciliation!(
      repo_slug: github_repo_slug(monorepo_root),
      monorepo_root:,
      tracker: tracker_input.to_i,
      target_version:,
      reason:,
      evidence:
    )
  end

  desc("Start a release line: create + push release/X.Y.Z from origin/main, then stop for CI.

Cuts the ephemeral release branch the release train stabilizes on. It does NOT tag rc.0 — the
release CI gate evaluates the branch tip and a just-pushed branch has no checks yet, so creating
the branch and cutting rc.0 must be two steps with a CI run between them. After CI runs on the new
branch tip, preview rc.0 with `bundle exec rake \"release[17.0.0.rc.0,true]\"`.

Live release:start remains **policy-blocked**, not runtime-enforced: it is still technically callable
without the publication wrapper's lifetime/per-write contract. Use its dry run and the separately fenced procedure in
internal/contributor-info/release-train-runbook.md; `script/release` starts only after the release branch exists.

Arguments:
1st argument: Release line base version X.Y.Z (optional). When omitted, derived from the top
              CHANGELOG.md rc header. Pass the stable base (17.0.0), never 17.0.0.rc.0.
2nd argument: Dry run (true/false, default: false)

Examples:
  rake \"release:start[17.0.0,true]\"   # preview creating release/17.0.0 from origin/main
  rake \"release:start[,true]\"         # preview a line derived from CHANGELOG.md")
  task :start, %i[version dry_run] do |_t, args|
    monorepo_root = current_monorepo_root
    args_hash = args.to_hash
    is_dry_run = release_truthy?(args_hash[:dry_run])

    current_branch_output, current_branch_status = Open3.capture2e(
      "git", "-C", monorepo_root, "rev-parse", "--abbrev-ref", "HEAD"
    )
    abort "❌ Failed to determine current git branch.\n\n#{current_branch_output}" unless current_branch_status.success?
    current_branch = current_branch_output.strip

    unless current_branch == "main"
      abort <<~ERROR
        ❌ Release lines are cut from `main` (the branch is created from origin/main).

        Current branch: #{current_branch}

        Switch to main first:
          git checkout main && git pull --rebase
      ERROR
    end

    # Reuse the standard uncommitted-changes guard (raises with guidance when dirty).
    ReactOnRails::GitUtils.uncommitted_changes?(RaisingMessageHandler.new)

    base_version = resolve_release_start_base_version(args_hash.fetch(:version, ""), monorepo_root:)
    release_branch = "release/#{base_version}"

    start_release_line!(monorepo_root:, release_branch:, dry_run: is_dry_run)
  end
end
# rubocop:enable Metrics/BlockLength
