# frozen_string_literal: true

require "English"
require "open3"

module ReactOnRails
  module GitUtils
    CI_TRUTHY_VALUES = %w[1 true yes].freeze

    DIRTY_WORKTREE_WARNING = <<~MSG.strip
      You have uncommitted changes. The generator will continue, but reviewing the
      generated diff is easier if you commit or stash your current work first.
    MSG

    MISSING_GIT_WARNING = <<~MSG.strip
      Git is not installed. The generator will continue, but version control makes it
      much easier to review the generated changes and back out partial installs.
    MSG

    NOT_A_GIT_REPOSITORY_WARNING = <<~MSG.strip
      Git is installed, but this directory is not a Git repository yet. The generator
      will continue, but initializing Git makes it much easier to review the generated
      changes and back out partial installs.
    MSG

    def self.uncommitted_changes?(message_handler, git_installed: true)
      report_worktree_issues(message_handler, git_installed: git_installed, as_error: true)
    end

    def self.warn_if_uncommitted_changes(message_handler, git_installed: true)
      report_worktree_issues(message_handler, git_installed: git_installed, as_error: false)
    end

    def self.skip_worktree_check?
      truthy_env?(ENV.fetch("CI", nil)) || truthy_env?(ENV.fetch("COVERAGE", nil))
    end

    def self.truthy_env?(value)
      CI_TRUTHY_VALUES.include?(value.to_s.strip.downcase)
    end

    def self.worktree_status
      output, status = Open3.capture2e("git", "status", "--porcelain")
      return :clean if status.success? && output.strip.empty?
      # Exit code 128 is git's standard fatal error (e.g., not a git repository)
      return :not_a_git_repository if status.exitstatus == 128

      :dirty
    rescue Errno::ENOENT
      # git binary not found despite passing the cli_exists? check
      :git_not_installed
    end

    def self.report_worktree_issues(message_handler, git_installed:, as_error:)
      return false if skip_worktree_check?

      status = git_installed ? worktree_status : :git_not_installed
      return false if status == :clean

      msg = worktree_message(status, as_error: as_error)
      as_error ? message_handler.add_error(msg) : message_handler.add_warning(msg)
      true
    end
    private_class_method :report_worktree_issues

    def self.worktree_message(status, as_error:)
      case status
      when :not_a_git_repository
        as_error ? not_a_git_repository_error_message : NOT_A_GIT_REPOSITORY_WARNING
      when :git_not_installed
        as_error ? missing_git_error_message : MISSING_GIT_WARNING
      else
        as_error ? dirty_worktree_error_message : DIRTY_WORKTREE_WARNING
      end
    end
    private_class_method :worktree_message

    def self.dirty_worktree_error_message
      <<~MSG.strip
        You have uncommitted changes. Please commit or stash them before continuing.

        The React on Rails generator creates many new files and it's important to keep
        your existing changes separate from the generated code for easier review.
      MSG
    end

    def self.missing_git_error_message
      <<~MSG.strip
        Git is not installed. Please install Git and commit your changes before continuing.

        The React on Rails generator creates many new files and version control helps
        track what was generated versus your existing code.
      MSG
    end

    def self.not_a_git_repository_error_message
      <<~MSG.strip
        Git is installed, but this directory is not a Git repository yet. Initialize Git
        and commit or stash your changes before continuing.

        The React on Rails generator creates many new files and version control helps
        track what was generated versus your existing code.
      MSG
    end
  end
end
