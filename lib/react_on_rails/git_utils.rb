# frozen_string_literal: true

require "English"

module ReactOnRails
  module GitUtils
    def self.uncommitted_changes?(message_handler)
      return false if ENV["COVERAGE"] == "true"
      status = `git status --porcelain`
      return false if $CHILD_STATUS.success? && status.empty?
      error = if !$CHILD_STATUS.success?
                "You do not have Git installed. Please install Git, and commit your changes before continuing"
              else
                "You have uncommitted code. Please commit or stash your changes before continuing"
              end
      message_handler.add_error(error)
      true
    end
  end
end
