# frozen_string_literal: true

require "English"

module ReactOnRails
  module GitUtils
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
  end
end
