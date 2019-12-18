# frozen_string_literal: true

# Starts SimpleCov for code coverage.

if ENV["COVERAGE"] == "true"
  require "simplecov"

  # Using a command name prevents results from getting clobbered by other test suites
  example_name = File.basename(File.expand_path("../..", __dir__))
  SimpleCov.command_name(example_name)

  SimpleCov.start("rails") do
    # Consider the entire gem project as the root
    # (typically this will be the folder named "react_on_rails")
    gem_root_path = File.expand_path("../../../..", __dir__)
    root gem_root_path

    # Don't report anything that has "spec" in the path
    add_filter do |src|
      src.filename =~ %r{\/spec\/}
    end
  end
end
