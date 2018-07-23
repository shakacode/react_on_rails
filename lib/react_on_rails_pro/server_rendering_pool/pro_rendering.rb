module ReactOnRailsPro
  module ServerRenderingPool
    class ProRendering
      RENDERED_HTML_KEY = "renderedHtml".freeze

      class << self
        def pool
          @pool ||= if ReactOnRailsPro.configuration.server_renderer == "VmRenderer"
                      ::ReactOnRailsPro::ServerRenderingPool::VmRenderingPool
                    else
                      ::ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
                    end
        end

        delegate :reset_pool_if_server_bundle_was_modified, :reset_pool, to: :pool

        def exec_server_render_js(js_code, render_options)
          ::ReactOnRailsPro::Utils.with_trace(render_options.react_component_name) do
            set_request_digest_on_render_options(js_code, render_options)
            if ReactOnRailsPro.configuration.prerender_caching
              Rails.cache.fetch(cache_key(js_code, render_options)) do
                render_on_pool(js_code, render_options)
              end
            else
              render_on_pool(js_code, render_options)
            end
          end
        end

        def set_request_digest_on_render_options(js_code, render_options)
          return unless render_options.request_digest.blank?

          digest = if render_options.has_random_dom_id?
                     Rails.logger.info { "[ReactOnRailsPro] Rendering #{render_options.react_component_name}. "\
              "Suggest setting `id` on react_component or setting react_on_rails.rb initializer "\
              "config.random_dom_id to false for BETTER performance." }
                     Digest::MD5.hexdigest(without_random_values(js_code))
                   else
                     Digest::MD5.hexdigest(js_code)
                   end
          render_options.request_digest = digest
        end

        private

        def without_random_values(js_code)
          # domNodeId are random to enable multiple instance of the same react component on a page.
          # See https://github.com/shakacode/react_on_rails_pro/issues/44
          js_code.gsub(/domNodeId: '[\w-]*',/, "")
        end

        def cache_key(js_code, render_options)
          set_request_digest_on_render_options(js_code, render_options )

          [
            *ReactOnRailsPro::Cache.base_cache_key("ror_pro_rendered_html",
                                                   prerender: render_options.prerender),
            render_options.request_digest
          ]
        end

        def render_on_pool(js_code, render_options)
          pool.exec_server_render_js(js_code, render_options)
        end
      end
    end
  end
end
