# frozen_string_literal: true

require "English"

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
      # Skip check in CI environments - CI often makes temporary modifications
      # (e.g., script/convert for minimum version testing) before running generators
      return false if ENV["CI"] == "true" || ENV["COVERAGE"] == "true"

      status = `git status --porcelain`
      return false if git_installed && status&.empty?

      error = if git_installed
                <<~MSG.strip
                  You have uncommitted changes. Please commit or stash them before continuing.

                  The React on Rails generator creates many new files and it's important to keep
                  your existing changes separate from the generated code for easier review.
                MSG
              else
                <<~MSG.strip
                  Git is not installed. Please install Git and commit your changes before continuing.

                  The React on Rails generator creates many new files and version control helps
                  track what was generated versus your existing code.
                MSG
              end
      message_handler.add_error(error)
      true
    end

    def self.warn_if_uncommitted_changes(message_handler, git_installed: true)
      return false if ENV["CI"] == "true" || ENV["COVERAGE"] == "true"

      status = `git status --porcelain`
      return false if git_installed && status&.empty?

      message_handler.add_warning(git_installed ? DIRTY_WORKTREE_WARNING : MISSING_GIT_WARNING)
      true
    end
  end
end
