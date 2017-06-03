# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "simplecov_helper"
require_relative "spec_helper"

require_relative("../config/environment")

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "capybara/rspec"
require "capybara/poltergeist"
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
# Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

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
  default_driver = :poltergeist_no_animations

  supported_drivers = %i[ poltergeist poltergeist_errors_ok
                          poltergeist_no_animations webkit
                          selenium_chrome selenium_firefox selenium]
  driver = ENV["DRIVER"].try(:to_sym) || default_driver
  Capybara.default_driver = driver

  unless supported_drivers.include?(driver)
    raise "Unsupported driver: #{driver} (supported = #{supported_drivers})"
  end

  case driver
  when :poltergeist, :poltergeist_errors_ok, :poltergeist_no_animations
    basic_opts = {
      window_size: [1300, 1800],
      screen_size: [1400, 1900],
      phantomjs_options: ["--load-images=no", "--ignore-ssl-errors=true"],
      timeout: 180
    }

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, basic_opts)
    end

    no_animation_opts = basic_opts.merge( # Leaving animations off, as a sleep was still needed.
      extensions: ["#{Rails.root}/spec/support/phantomjs-disable-animations.js"]
    )

    Capybara.register_driver :poltergeist_no_animations do |app|
      Capybara::Poltergeist::Driver.new(app, no_animation_opts)
    end

    Capybara.register_driver :poltergeist_errors_ok do |app|
      Capybara::Poltergeist::Driver.new(app, no_animation_opts.merge(js_errors: false))
    end
    Capybara::Screenshot.register_driver(:poltergeist) do |js_driver, path|
      js_driver.browser.save_screenshot(path)
    end
    Capybara::Screenshot.register_driver(:poltergeist_no_animations) do |js_driver, path|
      js_driver.render(path, full: true)
    end
    Capybara::Screenshot.register_driver(:poltergeist_errors_ok) do |js_driver, path|
      js_driver.render(path, full: true)
    end

  when :selenium_chrome
    DriverRegistration.register_selenium_chrome
  when :selenium_firefox, :selenium
    DriverRegistration.register_selenium_firefox
    driver = :selenium_firefox
  end

  Capybara.javascript_driver = driver
  Capybara.default_driver = driver

  Capybara.register_server(Capybara.javascript_driver) do |app, port|
    require "rack/handler/puma"
    Rack::Handler::Puma.run(app, Port: port)
  end

  # Capybara.default_max_wait_time = 15
  puts "=" * 80
  puts "Capybara using driver: #{Capybara.javascript_driver}"
  puts "=" * 80

  Capybara.save_path = Rails.root.join("tmp", "capybara")
  Capybara::Screenshot.prune_strategy = { keep: 10 }

  config.use_transactional_fixtures = false

  config.append_after(:each) do
    Capybara.reset_sessions!
  end

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

  # This will insert a <base> tag with the asset host into the pages created by
  # save_and_open_page, meaning that relative links will be loaded from the
  # development server if it is running.
  Capybara.asset_host = "http://localhost:3000"

  def js_errors_driver
    Capybara.javascript_driver == :poltergeist ? :poltergeist_errors_ok : Capybara.javascript_driver
  end

  def js_selenium_driver
    driver = Capybara.javascript_driver == :selenium_firefox ? :selenium_firefox : :selenium_chrome
    if driver == :selenium_firefox
      DriverRegistration.register_selenium_firefox
    else
      DriverRegistration.register_selenium_chrome
    end
    driver
  end
end
