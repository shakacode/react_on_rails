# frozen_string_literal: true

module ReactOnRailsPro
  module ServerRenderingPool
    class ProRendering
      RENDERED_HTML_KEY = "renderedHtml"

      class << self
        def pool
          @pool ||= if ReactOnRailsPro.configuration.node_renderer?
                      ::ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
                    else
                      ::ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
                    end
        end

        delegate :reset_pool_if_server_bundle_was_modified, :reset_pool, to: :pool

        def exec_server_render_js(js_code, render_options)
          ::ReactOnRailsPro::Utils.with_trace(render_options.react_component_name) do
            if ReactOnRailsPro.configuration.prerender_caching &&
               render_options.internal_option(:skip_prerender_cache).nil?
              prerender_cache_key = cache_key(render_options)
              prerender_cache_hit = true
              result = Rails.cache.fetch(prerender_cache_key) do
                prerender_cache_hit = false
                render_on_pool(js_code, render_options)
              end
              # Pass back the cache key in the results only if the result is a Hash
              if result.is_a?(Hash)
                result[:RORP_CACHE_KEY] = prerender_cache_key
                result[:RORP_CACHE_HIT] = prerender_cache_hit
              end
              result
            else
              render_on_pool(js_code, render_options)
            end
          end
        end

        private

        def without_random_values(js_code)
          # domNodeId are random to enable multiple instance of the same react component on a page.
          # See https://github.com/shakacode/react_on_rails_pro/issues/44
          js_code.gsub(/domNodeId: '[\w-]*',/, "")
        end

        def cache_key(render_options)
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
