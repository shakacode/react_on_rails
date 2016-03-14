module ReactOnRails
  module TestHelper
    # Because you will probably want to run RSpec tests that rely on compiled webpack assets
    # (typically, your integration/feature specs where `js: true`), you will want to ensure you
    # don't accidentally run tests on missing or stale webpack assets. If you did use stale
    # Webpack assets, you will get invalid test results as your tests do not use the very latest
    # JavaScript code.
    #
    # Call this method from inside of the `RSpec.configure` block in your `spec/rails_helper.rb`
    # file, passing the config as an argument. You can customize this to your particular needs by
    # replacing any of the default components.
    #
    # RSpec.configure do |config|
    #   ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
    #
    # You can pass an RSpec metatag as an list of parameter to this helper method
    # if you want this helper to run on examples other than where `js: true` or
    # `server_rendering: true` (default). The helper will compile webpack files at most
    # once per test run.
    #
    # If you do not want to be slowed down by re-compiling webpack assets from scratch every test
    # run, you can call `npm run build:client` (and `npm run build:server` if doing server
    # rendering) to have webpack recompile these files in the background, which will be *much*
    # faster. The helper looks for these processes and will abort recompiling if it finds them
    # to be running.
    #
    # See docs/additional_reading/rspec_configuration.md for more info
    #
    # Params:
    # config - config for rspec
    # metatags - metatags to add the ensure_assets_compiled check.
    #            Default is :js, :server_rendering
    def self.configure_rspec_to_compile_assets(config, *metatags)
      metatags = [:js, :server_rendering] if metatags.empty?

      metatags.each do |metatag|
        config.before(:example, metatag) { ReactOnRails::TestHelper.ensure_assets_compiled }
      end
    end

    # Main entry point to ensuring assets are compiled. See `configure_rspec_to_compile_assets` for
    # an example of usage.
    #
    # Typical usage passes all params as nil defaults.
    # webpack_assets_status_checker: provide: `up_to_date?`, `whats_not_up_to_date`, `client_dir`
    #                         defaults to ReactOnRails::TestHelper::WebpackAssetsStatusChecker
    # webpack_process_checker: provide one method: `def running?`
    #                         defaults to ReactOnRails::TestHelper::WebpackProcessChecker
    # webpack_assets_compiler: provide one method: `def compile`
    #                         defaults to ReactOnRails::TestHelper::WebpackAssetsCompiler
    # client_dir and generated_assets_dir are passed into the default webpack_assets_status_checker if you
    #                        don't provide one.
    # webpack_generated_files List of files to check for up-to-date-status, defaulting to
    #                        webpack_generated_files in your configuration
    def self.ensure_assets_compiled(webpack_assets_status_checker: nil,
                                    webpack_assets_compiler: nil,
                                    webpack_process_checker: nil,
                                    client_dir: nil,
                                    generated_assets_dir: nil,
                                    webpack_generated_files: nil)

      if webpack_assets_status_checker.nil?
        client_dir ||= Rails.root.join("client")
        generated_assets_dir ||= ReactOnRails.configuration.generated_assets_dir
        webpack_generated_files ||= ReactOnRails.configuration.webpack_generated_files

        webpack_assets_status_checker ||=
          WebpackAssetsStatusChecker.new(client_dir: client_dir,
                                         generated_assets_dir: generated_assets_dir,
                                         webpack_generated_files: webpack_generated_files
                                        )

        unless @printed_once
          puts
          puts "====> React On Rails: Checking #{webpack_assets_status_checker.generated_assets_dir} for "\
          "outdated/missing bundles"
          puts
          @printed_once = true
        end
      end

      webpack_assets_compiler ||= WebpackAssetsCompiler.new
      webpack_process_checker ||= WebpackProcessChecker.new

      ReactOnRails::TestHelper::EnsureAssetsCompiled.new(
        webpack_assets_status_checker: webpack_assets_status_checker,
        webpack_assets_compiler: webpack_assets_compiler,
        webpack_process_checker: webpack_process_checker
      ).call
    end
  end
end
