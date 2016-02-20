if ENV['CI']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'pry'

require 'rspec'
require 'hashie'
require 'rspec/pending_for'

RSpec.configure do |config|
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end
end
