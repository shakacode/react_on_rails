require 'capybara/cucumber'
require 'capybara-screenshot'
require 'capybara-screenshot/cucumber'
require 'aruba/cucumber'
require 'aruba/jruby'

Capybara::Screenshot.register_filename_prefix_formatter(:cucumber) do |fault|
  'my_screenshot'
end

Before do
  @aruba_timeout_seconds = 60
end if RUBY_PLATFORM == 'java'

After('@restore-capybara-default-session') do
  Capybara.session_name = nil
end
