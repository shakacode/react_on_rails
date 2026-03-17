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

    def self.uncommitted_changes?(message_handler, git_installed: true)
      return false if skip_worktree_check?

      unless git_installed
        message_handler.add_error(missing_git_error_message)
        return true
      end

      return false if clean_worktree?

      message_handler.add_error(dirty_worktree_error_message)
      true
    end

    def self.warn_if_uncommitted_changes(message_handler, git_installed: true)
      return false if skip_worktree_check?

      unless git_installed
        message_handler.add_warning(MISSING_GIT_WARNING)
        return true
      end

      return false if clean_worktree?

      message_handler.add_warning(DIRTY_WORKTREE_WARNING)
      true
    end

    def self.skip_worktree_check?
      truthy_env?(ENV.fetch("CI", nil))
    end

    def self.truthy_env?(value)
      CI_TRUTHY_VALUES.include?(value.to_s.strip.downcase)
    end

    def self.clean_worktree?
      output, status = Open3.capture2e("git", "status", "--porcelain")
      status.success? && output.strip.empty?
    rescue Errno::ENOENT
      false
    end

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
  end
end
