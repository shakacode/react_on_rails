# frozen_string_literal: true

# React on Rails configuration
# See https://reactonrails.com/docs/configuration/
# for complete documentation of all configuration options.

ReactOnRails.configure do |config|
  ################################################################################
  # Server Rendering (Recommended)
  ################################################################################
  # Configure server bundle for server-side rendering with `prerender: true`
  # Set to "" if you're not using server rendering
  config.server_bundle_js_file = "server-bundle.js"

  # ⚠️ RECOMMENDED: Use Shakapacker 9.0+ private_output_path instead
  #
  # If using Shakapacker 9.0+, add to config/shakapacker.yml:
  #   private_output_path: ssr-generated
  #
  # React on Rails will auto-detect this value, eliminating the need to set it here.
  # This keeps your webpack and Rails configs in sync automatically.
  #
  # For older Shakapacker versions or custom setups, manually configure:
  # config.server_bundle_output_path = "ssr-generated"
  #
  # The path is relative to Rails.root and should point to a private directory
  # (outside of public/) for security. Run 'rails react_on_rails:doctor' to verify.

  # Enforce that server bundles are only loaded from private (non-public) directories.
  # When true, server bundles will only be loaded from the configured server_bundle_output_path.
  # This is recommended for production to prevent server-side code from being exposed.
  config.enforce_private_server_bundles = true

  ################################################################################
  # Test Configuration (Recommended)
  ################################################################################
  # ⚠️ IMPORTANT: Two mutually exclusive approaches - use ONLY ONE:
  #
  # RECOMMENDED APPROACH: Use ReactOnRails::TestHelper with build_test_command
  # - Compiles test assets before first render (reliable for SSR and client tests)
  # - Compiles at most once per test run
  # - Works with RSpec and Minitest
  #
  # ALTERNATIVE APPROACH: Set `compile: true` in config/shakapacker.yml test section
  # - Simpler setup, but less explicit control
  # - Can be slower due to on-demand recompilation
  # - See: https://reactonrails.com/docs/building-features/testing-configuration/
  #
  # RSpec apps should also add to spec/rails_helper.rb (inside RSpec.configure):
  #   ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  #
  config.build_test_command = "RAILS_ENV=test bin/shakapacker"

  config.auto_load_bundle = true
  config.components_subdirectory = "ror_components"
  ################################################################################
  # Advanced Configuration
  ################################################################################
  # Most configuration options have sensible defaults and don't need to be set.
  # For advanced options including:
  # - File-based component registry (components_subdirectory, auto_load_bundle)
  # - Component loading strategies (async/defer/sync)
  # - Server bundle security and organization
  # - I18n configuration
  # - Server rendering pool configuration
  # - Custom rendering extensions
  # - And more...
  #
  # See: https://reactonrails.com/docs/configuration/
end
