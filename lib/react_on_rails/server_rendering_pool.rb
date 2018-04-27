# frozen_string_literal: true

require "connection_pool"
require_relative "server_rendering_pool/ruby_embedded_java_script"

# Based on the react-rails gem.
# None of these methods should be called directly.
# See app/helpers/react_on_rails_helper.rb
module ReactOnRails
  module ServerRenderingPool
    class << self
      def pool
        @pool ||= if ReactOnRails::Utils.react_on_rails_pro?
                    ReactOnRailsPro::ServerRenderingPool::ProRendering
                  else
                    ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
                  end
      end

      delegate :reset_pool_if_server_bundle_was_modified, :reset_pool, to: :pool

      def server_render_js_with_console_logging(js_code, render_options)
        pool.exec_server_render_js(js_code, render_options)
      end
    end
  end
end
