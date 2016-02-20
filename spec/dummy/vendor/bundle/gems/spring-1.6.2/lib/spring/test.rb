require "active_support"
require "active_support/test_case"

ActiveSupport.test_order = :random

module Spring
  module Test
    class << self
      attr_accessor :root
    end

    require "spring/test/application"
    require "spring/test/application_generator"
    require "spring/test/rails_version"
    require "spring/test/watcher_test"
    require "spring/test/acceptance_test"
  end
end
