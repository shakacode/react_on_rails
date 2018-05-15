# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
SERVER_BUNDLE_PATH = File.expand_path("../app/assets/webpack/server-bundle.js", __dir__)

require_relative "simplecov_helper"
require_relative("../config/environment")

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require_relative "spec_helper"
require "rspec/rails"
require "capybara/rspec"
require "capybara-screenshot/rspec"

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Ensure that if we are running js tests, we are using latest webpack assets
  # This will use the defaults of :js and :server_rendering meta tags
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Capybara config
  #
  # selenium_firefox webdriver only works for Travis-CI builds.
  default_driver = :selenium_chrome_headless

  supported_drivers = %i[ poltergeist poltergeist_errors_ok selenium_chrome_headless
                          selenium_chrome selenium_firefox selenium]
  driver = ENV["DRIVER"].try(:to_sym) || default_driver

  raise "Unsupported driver: #{driver} (supported = #{supported_drivers})" unless supported_drivers.include?(driver)

  case driver
  when :poltergeist, :poltergeist_errors_ok
    require "capybara/poltergeist"
    Capybara.register_driver :poltergeist_errors_ok do |app|
      Capybara::Poltergeist::Driver.new(app, js_errors: false)
    end
    config.after :each do |_example|
      page.driver.restart if defined?(page.driver.restart)
    end
  when :selenium_chrome
    Capybara.register_driver :selenium_chrome do |app|
      Capybara::Selenium::Driver.new(app, browser: :chrome)
    end
    Capybara::Screenshot.register_driver(:selenium_chrome) do |js_driver, path|
      js_driver.browser.save_screenshot(path)
    end
  when :selenium_chrome_headless
    Capybara.register_driver :selenium_chrome_headless do |app|
      capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(chromeOptions: { args: %w[headless disable-gpu] })
      Capybara::Selenium::Driver.new app, browser: :chrome, desired_capabilities: capabilities
    end
    Capybara::Screenshot.register_driver(:selenium_chrome_headless) do |js_driver, path|
      js_driver.browser.save_screenshot(path)
    end
  when :selenium_firefox, :selenium
    Capybara.register_driver :selenium_firefox do |app|
      Capybara::Selenium::Driver.new(app, browser: :firefox)
    end
    Capybara::Screenshot.register_driver(:selenium_firefox) do |js_driver, path|
      js_driver.browser.save_screenshot(path)
    end
    driver = :selenium_firefox
  end

  Capybara.javascript_driver = driver

  puts "Capybara using driver: #{Capybara.javascript_driver}"

  Capybara::Screenshot.prune_strategy = { keep: 10 }
  # [END] Capybara config

  # This will insert a <base> tag with the asset host into the pages created by
  # save_and_open_page, meaning that relative links will be loaded from the
  # development server if it is running.
  Capybara.asset_host = "http://localhost:3000"

  def js_errors_driver
    Capybara.javascript_driver == :poltergeist ? :poltergeist_errors_ok : Capybara.javascript_driver
  end
end
