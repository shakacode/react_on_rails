# frozen_string_literal: true

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
    # run, you can call `yarn run build:client` (and `yarn run build:server` if doing server
    # rendering) to have webpack recompile these files in the background, which will be *much*
    # faster. The helper looks for these processes and will abort recompiling if it finds them
    # to be running.
    #
    # See docs/additional-reading/rspec-configuration.md for more info
    #
    # Params:
    # config - config for rspec
    # metatags - metatags to add the ensure_assets_compiled check.
    #            Default is :js, :server_rendering, :controller
    def self.configure_rspec_to_compile_assets(config, *metatags)
      metatags = %i[js server_rendering controller] if metatags.empty?

      metatags.each do |metatag|
        config.before(:example, metatag) { ReactOnRails::TestHelper.ensure_assets_compiled }
      end
    end

    # Main entry point to ensuring assets are compiled. See `configure_rspec_to_compile_assets` for
    # an example of usage.
    #
    # Typical usage passes all params as nil defaults.
    # webpack_assets_status_checker: provide: `up_to_date?`, `whats_not_up_to_date`, `source_path`
    #                         defaults to ReactOnRails::TestHelper::WebpackAssetsStatusChecker
    # webpack_assets_compiler: provide one method: `def compile`
    #                         defaults to ReactOnRails::TestHelper::WebpackAssetsCompiler
    # source_path and generated_assets_full_path are passed into the default webpack_assets_status_checker if you
    #                        don't provide one.
    # webpack_generated_files List of files to check for up-to-date-status, defaulting to
    #                        webpack_generated_files in your configuration
    def self.ensure_assets_compiled(webpack_assets_status_checker: nil,
                                    webpack_assets_compiler: nil,
                                    source_path: nil,
                                    generated_assets_full_path: nil,
                                    webpack_generated_files: nil)
      ReactOnRails::WebpackerUtils.check_manifest_not_cached
      if webpack_assets_status_checker.nil?
        source_path ||= ReactOnRails::Utils.source_path
        generated_assets_full_path ||= ReactOnRails::Utils.generated_assets_full_path
        webpack_generated_files ||= ReactOnRails.configuration.webpack_generated_files

        webpack_assets_status_checker ||=
          WebpackAssetsStatusChecker.new(source_path: source_path,
                                         generated_assets_full_path: generated_assets_full_path,
                                         webpack_generated_files: webpack_generated_files)

        unless @printed_once
          puts
          puts "====> React On Rails: Checking files in "\
            "#{webpack_assets_status_checker.generated_assets_full_path} for "\
            "outdated/missing bundles based on source_path #{source_path}"
          puts
          @printed_once = true
        end
      end

      webpack_assets_compiler ||= WebpackAssetsCompiler.new

      ReactOnRails::TestHelper::EnsureAssetsCompiled.new(
        webpack_assets_status_checker: webpack_assets_status_checker,
        webpack_assets_compiler: webpack_assets_compiler
      ).call
    end
  end
end
