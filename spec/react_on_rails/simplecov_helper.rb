# frozen_string_literal: true

# Starts SimpleCov for code coverage.

if ENV["COVERAGE"] == "true"
  require "simplecov"
  # Using a command name prevents results from getting clobbered by other test
  # suites
  SimpleCov.command_name "gem-tests"
  SimpleCov.start do
    # Don't include coverage reports on files in "spec" folder
    add_filter do |src|
      src.filename =~ %r{/spec/}
    end
  end
end
