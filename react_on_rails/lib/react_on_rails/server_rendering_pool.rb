# frozen_string_literal: true

require "connection_pool"
require_relative "server_rendering_pool/ruby_embedded_java_script"

# Pooling mechanism for server-side JavaScript rendering.
# Based on the react-rails gem.
# None of these methods should be called directly.
module ReactOnRails
  module ServerRenderingPool
    class << self
      # Returns the appropriate rendering pool based on whether pro or free version
      # @return [ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript,
      #             ReactOnRailsPro::ServerRenderingPool::ProRendering]
      def pool
        @pool ||= if ReactOnRails::Utils.react_on_rails_pro?
                    ReactOnRailsPro::ServerRenderingPool::ProRendering
                  else
                    ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
                  end
      end

      delegate :reset_pool_if_server_bundle_was_modified, :reset_pool, to: :pool

      # Renders JavaScript with console logging enabled
      # @param js_code [String] The JavaScript code to render
      # @param render_options [Hash] Rendering options
      # @return [String] The rendered result
      def server_render_js_with_console_logging(js_code, render_options)
        pool.exec_server_render_js(js_code, render_options)
      end
    end
  end
end
