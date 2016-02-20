ENV['RAILS_ENV'] ||= 'test'

require_relative 'app/config/environment'
require_relative '../lib/autoprefixer-rails'

require 'rspec/rails'

RSpec.configure do |c|
  c.filter_run_excluding not_jruby: RUBY_PLATFORM == 'java'
end
