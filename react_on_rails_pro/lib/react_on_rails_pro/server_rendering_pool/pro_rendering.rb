module ReactOnRailsPro
  module ServerRenderingPool
    class ProRendering
      class << self
        def pool
          @pool ||= if ReactOnRailsPro.configuration.server_render_method == "VmRenderer"
                      ReactOnRailsPro::VmRenderingPool
                    else
                      ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
                    end
        end

        delegate :reset_pool_if_server_bundle_was_modified, :reset_pool,
                 :exec_server_render_js, to: :pool
      end
    end
  end
end
