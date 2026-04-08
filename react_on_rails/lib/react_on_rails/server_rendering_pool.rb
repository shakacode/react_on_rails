# frozen_string_literal: true

require "connection_pool"
require_relative "server_rendering_pool/ruby_embedded_java_script"

# Based on the react-rails gem.
# DEPRECATED: Use ReactOnRails.rendering_strategy instead.
# This module is kept for backward compatibility with direct callers.
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

      # @deprecated Use ReactOnRails.rendering_strategy.execute_js instead
      def server_render_js_with_console_logging(js_code, render_options)
        emit_deprecation_warning(__method__)
        pool.exec_server_render_js(js_code, render_options)
      end

      private

      def emit_deprecation_warning(method_name)
        return if @deprecation_warned

        @deprecation_warned = true
        Rails.logger.warn(
          "[REACT ON RAILS] DEPRECATION: ReactOnRails::ServerRenderingPool.#{method_name} is deprecated. " \
          "Use ReactOnRails.rendering_strategy instead. " \
          "Direct pool access will be removed in a future version."
        )
      end
    end
  end
end
