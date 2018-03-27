# frozen_string_literal: true

module RenderingExtension
  # Return a Hash that contains custom values from the view context that will get passed to
  # all calls to react_component and redux_store for rendering
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

ReactOnRails.configure do |config|
  config.node_modules_location = "client" # Pre 9.0.0 always used "client"
  config.build_production_command = "yarn run build:production"
  config.build_test_command = "yarn run build:test"
  config.generated_assets_dir = File.join(%w[app assets webpack])
  config.webpack_generated_files = %w[app-bundle.js vendor-bundle.js server-bundle.js]
  config.server_bundle_js_file = "server-bundle.js"
  config.rendering_extension = RenderingExtension
  # Client js uses assets not digested by rails.
  # For any asset matching this regex, a file is copied to the correct path to have a digest.
  # To disable creating digested assets, set this parameter to nil.
  config.symlink_non_digested_assets_regex = /\.(png|jpg|jpeg|gif|tiff|woff|ttf|eot|svg|map)/
end
