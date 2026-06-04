# frozen_string_literal: true

require "rspec/core"

$LOAD_PATH.unshift(File.expand_path("../../scripts/load/lib", __dir__))

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
