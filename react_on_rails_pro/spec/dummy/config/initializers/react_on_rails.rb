# frozen_string_literal: true

# ⚠️ TEST CONFIGURATION - Do not copy directly for production apps
# This is the Pro dummy app configuration used for testing React on Rails Pro features.
# See docs/api-reference/configuration.md for production configuration guidance.

# Advanced: Custom rendering extension to add values to railsContext
module RenderingExtension
  def self.custom_context(view_context)
    if view_context.controller.is_a?(ActionMailer::Base)
      {}
    else
      {
        somethingUseful: view_context.session[:something_useful]
      }
    end
  end
end

# Advanced: Custom props extension for client-side hydration
module RenderingPropsExtension
  def self.adjust_props_for_client_side_hydration(_component_name, props)
    if props.instance_of?(Hash)
      props.except(:ssrOnlyProps)
    else
      props
    end
  end
end

ReactOnRails.configure do |config|
  ################################################################################
  # Essential Configuration
  ################################################################################
  config.server_bundle_js_file = "server-bundle.js"
  config.components_subdirectory = "ror-auto-load-components"
  config.auto_load_bundle = true

  ################################################################################
  # Pro Feature Testing: Server Bundle Security
  ################################################################################
  # Testing private server bundle enforcement (recommended for production)
  config.enforce_private_server_bundles = true
  config.server_bundle_output_path = "ssr-generated"

  ################################################################################
  # Test-specific Advanced Configuration
  ################################################################################
  # Testing with fixed DOM IDs for easier test assertions
  config.random_dom_id = false # default is true

  # Testing advanced rendering customization
  config.rendering_extension = RenderingExtension
  config.rendering_props_extension = RenderingPropsExtension

  # NOTE: build_test_command and webpack_generated_files are commented out
  # because we've set test.compile to true in shakapacker.yml
  # config.build_test_command = "pnpm run build:test"
  # config.webpack_generated_files = %w[server-bundle.js manifest.json]
end
