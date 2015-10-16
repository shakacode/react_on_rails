require "simplecov"
# Not necessary to explicitly start SimpleCov here because of presence of
# the .simplecov file
# Using a command name prevents results from getting clobbered by other test
# suites
SimpleCov.command_name "gem-specs"
require "spec_helper"

describe ReactOnRails do
  it "has a version number" do
    expect(ReactOnRails::VERSION).not_to be nil
  end
end
