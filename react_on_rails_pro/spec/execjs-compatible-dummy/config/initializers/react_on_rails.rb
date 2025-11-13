# frozen_string_literal: true

# ExecJS-compatible dummy app configuration
# This app tests compatibility with legacy webpacker setup
# See docs/api-reference/configuration.md for complete documentation

ReactOnRails.configure do |config|
  ################################################################################
  # Essential Configuration
  ################################################################################
  # Configure server bundle for server-side rendering
  config.server_bundle_js_file = "server-bundle.js"

  # Test configuration
  config.build_test_command = "RAILS_ENV=test bin/webpacker"

  ################################################################################
  # File System Based Component Registry (Optional - Disabled for this test)
  ################################################################################
  # Uncomment to enable automatic component registration:
  # config.components_subdirectory = "ror_components"
  # config.auto_load_bundle = true
  config.auto_load_bundle = false

  ################################################################################
  # Advanced Configuration
  ################################################################################
  # Most options have sensible defaults. For advanced configuration including
  # component loading strategies, server bundle security, and more, see:
  # https://github.com/shakacode/react_on_rails/blob/master/docs/api-reference/configuration.md
end
