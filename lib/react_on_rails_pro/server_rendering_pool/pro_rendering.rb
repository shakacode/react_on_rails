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
            render_options.request_digest = request_digest(js_code)
            if ReactOnRailsPro.configuration.prerender_caching
              Rails.cache.fetch(cache_key(js_code, render_options)) do
                render_on_pool(js_code, render_options)
              end
            else
              render_on_pool(js_code, render_options)
            end
          end
        end

        def request_digest(js_code)
          Digest::MD5.hexdigest(without_random_values(js_code))
        end

        private

        def without_random_values(js_code)
          # domNodeId are random to enable multiple instance of the same react component on a page.
          # See https://github.com/shakacode/react_on_rails_pro/issues/44
          js_code.gsub(/domNodeId: '[\w-]*',/, "")
        end

        def cache_key(js_code, render_options)
          [
            *ReactOnRailsPro::Cache.base_cache_key("ror_pro_rendered_html",
                                                   prerender: render_options.prerender),
            request_digest(js_code)
          ]
        end

        def render_on_pool(js_code, render_options)
          pool.exec_server_render_js(js_code, render_options)
        end
      end
    end
  end
end
