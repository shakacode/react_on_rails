# frozen_string_literal: true

require "connection_pool"
require_relative "server_rendering_pool/ruby_embedded_java_script"

# Based on the react-rails gem.
# None of these methods should be called directly.
# See app/helpers/react_on_rails_helper.rb
module ReactOnRails
  module ServerRenderingPool
    class << self
      def react_on_rails_pro?
        @react_on_rails_pro ||= gem_available?("react_on_rails_pro")
      end

      def pool
        @pool ||= if react_on_rails_pro?
                    ReactOnRailsPro::ServerRenderingPool::ProRendering
                  else
                    ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
                  end
      end

      delegate :reset_pool_if_server_bundle_was_modified, :reset_pool, to: :pool

      def server_render_js_with_console_logging(js_code, render_options)
        pool.exec_server_render_js(js_code, render_options)
      end

      private

      def gem_available?(name)
        Gem::Specification.find_by_name(name)
      rescue Gem::LoadError
        false
      rescue StandardError
        Gem.available?(name)
      end
    end
  end
end
