# frozen_string_literal: true

if defined?(CypressOnRails)
  CypressOnRails.configure do |c|
    c.api_prefix = ""
    c.install_folder = File.expand_path("#{__dir__}/../../e2e/playwright")
    # WARNING!! CypressOnRails can execute arbitrary ruby code
    # please use with extra caution if enabling on hosted servers or starting your local server on 0.0.0.0
    c.use_middleware = !Rails.env.production?
    #  c.use_vcr_middleware = !Rails.env.production?
    #  # Use this if you want to use use_cassette wrapper instead of manual insert/eject
    #  # c.use_vcr_use_cassette_middleware = !Rails.env.production?
    #  # Pass custom VCR options
    #  c.vcr_options = {
    #    hook_into: :webmock,
    #    default_cassette_options: { record: :once },
    #    cassette_library_dir: File.expand_path("#{__dir__}/../../e2e/playwright/fixtures/vcr_cassettes")
    #  }
    c.logger = Rails.logger

    # Server configuration for rake tasks (cypress:open, cypress:run, playwright:open, playwright:run)
    # c.server_host = 'localhost'  # or use ENV['CYPRESS_RAILS_HOST']
    # c.server_port = 3001         # or use ENV['CYPRESS_RAILS_PORT']
    # c.transactional_server = true  # Enable automatic transaction rollback between tests

    # Server lifecycle hooks for rake tasks
    # c.before_server_start = -> { DatabaseCleaner.clean_with(:truncation) }
    # c.after_server_start = -> { puts "Test server started on port #{CypressOnRails.configuration.server_port}" }
    # c.after_transaction_start = -> { Rails.application.load_seed }
    # c.after_state_reset = -> { Rails.cache.clear }
    # c.before_server_stop = -> { puts "Stopping test server..." }

    # If you want to enable a before_request logic, such as authentication, logging, sending metrics, etc.
    #   Refer to https://www.rubydoc.info/gems/rack/Rack/Request for the `request` argument.
    #   Return nil to continue through the Cypress command. Return a response [status, header, body] to halt.
    # c.before_request = lambda { |request|
    #   unless request.env['warden'].authenticate(:secret_key)
    #     return [403, {}, ["forbidden"]]
    #   end
    # }
  end

  # # if you compile your asssets on CI
  # if ENV['CYPRESS'].present? && ENV['CI'].present?
  #  Rails.application.configure do
  #    config.assets.compile = false
  #    config.assets.unknown_asset_fallback = false
  #  end
  # end
end
