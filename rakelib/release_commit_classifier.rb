# frozen_string_literal: true

require "json"
require "open3"
require "tmpdir"

# Canonical CI verdict and content-aware release promotion classification.
module ReleaseCommitClassifier
  class UnhandledReleaseFinalizationMetadataPathError < StandardError; end

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

  # Shared with the live Rake helpers so preview and publishing guards cannot drift.
  module Promotion
    private

    def release_finalization_metadata_paths
      RELEASE_FINALIZATION_METADATA_PATHS
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

      paths.any? { |path| release_finalization_metadata_paths.include?(path) }
    rescue StandardError
      nil
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
          release_finalization_metadata_paths.include?(path) &&
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

    def commit_non_runtime_only?(monorepo_root:, sha:)
      ReleaseCommitClassifier.non_runtime_only?(monorepo_root:, sha:)
    end
  end

  extend Promotion

  module_function

  def promotion_non_runtime_only?(monorepo_root:, sha:)
    release_branch_non_runtime_commit?(monorepo_root:, sha:)
  end

  def non_runtime_only?(monorepo_root:, sha:)
    detector = File.join(monorepo_root, "script", "ci-changes-detector")
    return false unless File.executable?(detector)

    Dir.mktmpdir("ror-ci-detector") do |dir|
      output_file = File.join(dir, "github_output")
      File.write(output_file, "")
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
end
