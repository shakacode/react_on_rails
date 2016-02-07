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
    # You can pass an RSpec metatag as an optional second parameter to this helper method
    # if you want this helper to run on examples other than where `js: true` (default). The helper
    # will compile webpack files at most once per test run.
    #
    # If you do not want to be slowed down by re-compiling webpack assets from scratch every test
    # run, you can call `npm run build:client` (and `npm run build:server` if doing server
    # rendering) to have webpack recompile these files in the background, which will be *much*
    # faster. The helper looks for these processes and will abort recompiling if it finds them
    # to be running.
    #
    # See docs/additional_reading/rspec_configuration.md for more info
    def self.configure_rspec_to_compile_assets(config, metatag = :js)
      config.before(:example, metatag) { ReactOnRails::TestHelper.ensure_assets_compiled }
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
    # client_dir and compiled_dirs are passed into the default webpack_assets_status_checker if you
    #                         don't provide one.
    def self.ensure_assets_compiled(webpack_assets_status_checker: nil,
                                    webpack_assets_compiler: nil,
                                    webpack_process_checker: nil,
                                    client_dir: nil,
                                    compiled_dirs: nil)

      if webpack_assets_status_checker.nil?
        client_dir ||= Rails.root.join("client")
        compiled_dirs ||= ReactOnRails.configuration.generated_assets_dirs
        webpack_assets_status_checker ||=
          WebpackAssetsStatusChecker.new(client_dir: client_dir,
                                         compiled_dirs: compiled_dirs)
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
