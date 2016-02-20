require "bundler/setup"
require "active_support"
require "rails/version"

if Rails::VERSION::STRING > "4.0"
  require "active_support/testing/autorun"
else
  require "test/unit"
end


if ActiveSupport.respond_to?(:test_order=)
  ActiveSupport.test_order = :random
end
