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
  config.node_modules_location = "client"
  config.generated_assets_dir = File.join(%w(app assets webpack))
  config.webpack_generated_files = %w(app-bundle.css app-bundle.js vendor-bundle.js server-bundle.js)
  config.server_bundle_js_file = "server-bundle.js"
  config.build_test_command = "yarn run build:test"
  config.build_production_command = "yarn run build:production"
  config.prerender = true
  config.trace = Rails.env.development?
  config.development_mode = Rails.env.development?
  config.replay_console = true
  config.logging_on_server = true
  config.raise_on_prerender_error = false
  config.server_renderer_pool_size = 1
  config.server_renderer_timeout = 20
  config.rendering_extension = RenderingExtension
  config.symlink_non_digested_assets_regex = /\.(png|jpg|jpeg|gif|tiff|woff|ttf|eot|svg|map)/

  # Use Node renderer instead of embeded ExecJS:
  config.server_render_method = "NodeJSHttp"
end

# TODO: It is better to add additional condition to react_on_rails gem instead of this monkey patch:
module ReactOnRails
  module ServerRenderingPool
    class << self
      def pool
        if ReactOnRails.configuration.server_render_method == "NodeJS"
          ServerRenderingPool::Node
        elsif ReactOnRails.configuration.server_render_method == "NodeJSHttp"
          ReactOnRailsRenderer::RenderingPool
        else
          ServerRenderingPool::Exec
        end
      end

      # rubocop:disable Style/MethodMissing
      def method_missing(sym, *args, &block)
        pool.send sym, *args, &block
      end
    end
  end
end
