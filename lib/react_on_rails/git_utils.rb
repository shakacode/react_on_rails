module ReactOnRails
  module GitUtils
    def self.uncommitted_changes?(message_handler)
      return false if ENV["COVERAGE"]
      status = `git status`
      return false if status.include?("nothing to commit, working directory clean")
      error = "You have uncommitted code. Please commit or stash your changes before continuing"
      message_handler.add_error(error)
      true
    end
  end
end
