# frozen_string_literal: true

require "English"
require "open3"

module ReactOnRails
  module GitUtils
    DIRTY_WORKTREE_WARNING = <<~MSG.strip
      You have uncommitted changes. The generator will continue, but reviewing the
      generated diff is easier if you commit or stash your current work first.
    MSG

    MISSING_GIT_WARNING = <<~MSG.strip
      Git is not installed. The generator will continue, but version control makes it
      much easier to review the generated changes and back out partial installs.
    MSG

    def self.uncommitted_changes?(message_handler, git_installed: true)
      return false if ci_environment?

      unless git_installed
        error = <<~MSG.strip
          Git is not installed. Please install Git and commit your changes before continuing.

          The React on Rails generator creates many new files and version control helps
          track what was generated versus your existing code.
        MSG
        message_handler.add_error(error)
        return true
      end

      return false if clean_worktree?

      error = <<~MSG.strip
        You have uncommitted changes. Please commit or stash them before continuing.

        The React on Rails generator creates many new files and it's important to keep
        your existing changes separate from the generated code for easier review.
      MSG
      message_handler.add_error(error)
      true
    end

    def self.warn_if_uncommitted_changes(message_handler, git_installed: true)
      return false if ci_environment?

      unless git_installed
        message_handler.add_warning(MISSING_GIT_WARNING)
        return true
      end

      return false if clean_worktree?

      message_handler.add_warning(DIRTY_WORKTREE_WARNING)
      true
    end

    def self.ci_environment?
      ENV["CI"] == "true"
    end
    private_class_method :ci_environment?

    def self.clean_worktree?
      output, status = Open3.capture2e("git", "status", "--porcelain")
      status.success? && output.strip.empty?
    end
    private_class_method :clean_worktree?
  end
end
