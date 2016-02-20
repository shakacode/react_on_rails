
require 'parslet'

require 'parslet/rig/rspec'
require 'parslet/atoms/visitor'
require 'parslet/export'

RSpec.configure do |config|
  config.mock_with :flexmock

  begin
    # Here's to the worst idea ever, rspec. This is why we'll be leaving you soon.
    config.expect_with :rspec do |c|
      c.syntax = [:should, :expect]
    end
  rescue NoMethodError
    # If the feature is missing, ignore it. 
  end
  
  # Exclude other ruby versions by giving :ruby => 1.8 or :ruby => 1.9
  #
  config.filter_run_excluding :ruby => lambda { |version|
    RUBY_VERSION.to_s !~ /^#{Regexp.escape(version.to_s)}/
  }
end

def catch_failed_parse
  begin
    yield
  rescue Parslet::ParseFailed => exception
  end
  exception.cause
end

def slet name, &block
  let(name, &block)
  subject(&block)
end