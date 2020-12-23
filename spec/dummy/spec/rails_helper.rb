# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
SERVER_BUNDLE_PATH = File.expand_path("../../public/webpack/#{ENV['RAILS_ENV']}/server-bundle.js", __FILE__)

require_relative "simplecov_helper"
require_relative "spec_helper"

require_relative("../config/environment")

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "capybara/rails"
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
# ActiveRecord::Migration.maintain_test_schema!

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Ensure that if we are running js tests, we are using latest webpack assets
  # This is false since we're using rails/webpacker webpacker.yml test.compile == true
  # ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config, :requires_webpack_assets)
  # config.define_derived_metadata(file_path: %r{spec/(system|requests|helpers)}) do |metadata|
  #   metadata[:requires_webpack_assets] = true
  # end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # For React on Rails Pro, using loadable-stats.json
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # Tests do not hit the DB
  # config.use_transactional_fixtures = true

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
  config.include Capybara::DSL
  #
  # selenium_firefox webdriver only works for Travis-CI builds.
  default_driver = :selenium_chrome_headless

  supported_drivers = %i[selenium_chrome_headless selenium_chrome selenium selenium_headless]
  driver = ENV["DRIVER"].try(:to_sym).presence || default_driver
  Capybara.default_driver = driver

  raise "Unsupported driver: #{driver} (supported = #{supported_drivers})" unless supported_drivers.include?(driver)

  Capybara.javascript_driver = driver
  Capybara.default_driver = driver

  Capybara.register_server(Capybara.javascript_driver) do |app, port|
    require "rack/handler/puma"
    Rack::Handler::Puma.run(app, Port: port)
  end

  config.before(:each, type: :system, js: true) do
    driven_by driver
  end

  # Capybara.default_max_wait_time = 15
  puts "=" * 80
  puts "Capybara using driver: #{Capybara.javascript_driver}"
  puts "=" * 80

  Capybara.save_path = Rails.root.join("tmp", "capybara")
  Capybara::Screenshot.prune_strategy = { keep: 10 }

  # https://github.com/mattheworiordan/capybara-screenshot/issues/243#issuecomment-620423225
  config.retry_callback = proc do |ex|
    Capybara.reset_sessions! if ex.metadata[:js]
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
    Capybara.javascript_driver
  end
end
