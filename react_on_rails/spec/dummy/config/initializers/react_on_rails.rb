# frozen_string_literal: true

# ⚠️ TEST CONFIGURATION - Do not copy directly for production apps
# This is the dummy app configuration used for testing React on Rails features.
# See docs/configuration/README.md for production configuration guidance.

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
  def self.adjust_props_for_client_side_hydration(component_name, props)
    props[:modificationTarget] = "client-only" if component_name == "HelloWorldProps"
    props
  end
end

ReactOnRails.configure do |config|
  ################################################################################
  # Essential Configuration
  ################################################################################
  config.server_bundle_js_file = "server-bundle.js"
  config.components_subdirectory = "startup"
  config.auto_load_bundle = true

  ################################################################################
  # Test-specific Advanced Configuration
  ################################################################################
  # Testing server bundles from public path instead of private directory
  config.server_bundle_output_path = nil
  config.enforce_private_server_bundles = false

  # Testing with fixed DOM IDs for easier test assertions
  config.random_dom_id = false # default is true

  # Testing with explicit loading strategy
  config.generated_component_packs_loading_strategy = :defer

  # Testing advanced rendering customization
  config.rendering_extension = RenderingExtension
  config.rendering_props_extension = RenderingPropsExtension
end
