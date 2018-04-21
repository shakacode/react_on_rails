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

      delegate :server_render_js_with_console_logging, :reset_pool_if_server_bundle_was_modified,
               :reset_pool, to: :pool

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
