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
            # See https://github.com/shakacode/react_on_rails_pro/issues/119 for why
            # the digest is on the render options.
            # TODO: the request digest should be removed unless prerender caching is used
            set_request_digest_on_render_options(js_code, render_options)

            # Cache non-streaming immediately. For streaming, optionally cache via write-through.
            if cache_enabled_for?(render_options)
              render_with_cache(js_code, render_options)
            else
              render_on_pool(js_code, render_options)
            end
          end
        end

        # See https://github.com/shakacode/react_on_rails_pro/issues/119 for why
        # the digest is on the render options.
        def set_request_digest_on_render_options(js_code, render_options)
          return unless render_options.request_digest.blank?

          digest = if render_options.random_dom_id?
                     Rails.logger.info do
                       "[ReactOnRailsPro] Rendering #{render_options.react_component_name}. " \
                         "Suggest setting `id` on react_component or setting react_on_rails.rb initializer " \
                         "config.random_dom_id to false for BETTER performance."
                     end
                     Digest::MD5.hexdigest(without_random_values(js_code))
                   else
                     Digest::MD5.hexdigest(js_code)
                   end
          render_options.request_digest = digest
        end

        private

        def cache_enabled_for?(render_options)
          ReactOnRailsPro.configuration.prerender_caching &&
            render_options.internal_option(:skip_prerender_cache).nil?
        end

        def render_with_cache(js_code, render_options)
          prerender_cache_key = cache_key(js_code, render_options)
          prerender_cache_hit = true

          result = if render_options.streaming?
                     render_streaming_with_cache(prerender_cache_key, js_code, render_options)
                   else
                     Rails.cache.fetch(prerender_cache_key) do
                       prerender_cache_hit = false
                       render_on_pool(js_code, render_options)
                     end
                   end

          # Pass back the cache key in the results only if the result is a Hash
          if result.is_a?(Hash)
            result[:RORP_CACHE_KEY] = prerender_cache_key
            result[:RORP_CACHE_HIT] = prerender_cache_hit
          end

          result
        end

        def render_streaming_with_cache(prerender_cache_key, js_code, render_options)
          # Streaming path: try to serve from cache; otherwise wrap upstream stream
          cached_stream = ReactOnRailsPro::StreamCache.fetch_stream(prerender_cache_key)
          return cached_stream if cached_stream

          upstream = render_on_pool(js_code, render_options)
          ReactOnRailsPro::StreamCache.wrap_and_cache(
            prerender_cache_key,
            upstream,
            cache_options: render_options.internal_option(:cache_options)
          )
        end

        def without_random_values(js_code)
          # domNodeId are random to enable multiple instance of the same react component on a page.
          # See https://github.com/shakacode/react_on_rails_pro/issues/44
          js_code.gsub(/domNodeId: '[\w-]*',/, "")
        end

        def cache_key(js_code, render_options)
          set_request_digest_on_render_options(js_code, render_options)

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
