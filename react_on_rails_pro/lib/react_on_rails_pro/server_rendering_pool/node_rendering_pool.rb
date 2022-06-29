# frozen_string_literal: true

module ReactOnRailsPro
  module ServerRenderingPool
    # This implementation of the rendering pool uses NodeJS to execute javasript code
    class NodeRenderingPool
      RENDERED_HTML_KEY = "renderedHtml"

      class << self
        attr_accessor :bundle_hash

        def reset_pool
          ReactOnRailsPro::Request.reset_connection
        end

        def reset_pool_if_server_bundle_was_modified
          # Resetting the pool for server bundle modifications is accomplished by changing the mtime
          # of the server bundle in the request to the remote rendering server.
          # In non-development mode, we don't need to re-read this value.
          return @bundle_hash if @bundle_hash.present? && !ReactOnRails.configuration.development_mode

          @bundle_hash = ReactOnRailsPro::Utils.bundle_hash
        end

        def renderer_bundle_file_name
          "#{ReactOnRailsPro::Utils.bundle_hash}.js"
        end

        # js_code: JavaScript expression that returns a string.
        # Returns a Hash:
        #   html: string of HTML for direct insertion on the page by evaluating js_code
        #   consoleReplayScript: script for replaying console
        #   hasErrors: true if server rendering errors
        # Note, js_code does not have to be based on React.
        # js_code MUST RETURN json stringify Object
        # Calling code will probably call 'html_safe' on return value before rendering to the view.
        def exec_server_render_js(js_code, render_options)
          # The secret sauce is passing self as the 3rd param, the js_evaluator
          render_options.set_option(:throw_js_errors, ReactOnRailsPro.configuration.throw_js_errors)
          ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
            .exec_server_render_js(js_code, render_options, self)
        end

        def eval_js(js_code, render_options, send_bundle: false)
          ReactOnRailsPro::ServerRenderingPool::ProRendering
            .set_request_digest_on_render_options(js_code, render_options)

          # In case this method is called with simple, raw JS, not depending on the bundle, next line
          # is needed.
          @bundle_hash ||= ReactOnRailsPro::Utils.bundle_hash

          # TODO: Remove the request_digest. See https://github.com/shakacode/react_on_rails_pro/issues/119
          # From the request path
          # path = "/bundles/#{@bundle_hash}/render"
          path = "/bundles/#{@bundle_hash}/render/#{render_options.request_digest}"

          response = ReactOnRailsPro::Request.render_code(path, js_code, send_bundle)

          case response.code
          when "200"
            response.body
          when "410"
            # 410 is a special value meaning send the updated bundle with the next request.
            eval_js(js_code, render_options, send_bundle: true)
          when "400"
            raise ReactOnRailsPro::Error,
                  "Renderer unhandled error at the VM level: #{response.code}:\n#{response.body}"
          else
            raise ReactOnRailsPro::Error, "Unknown response code from renderer: #{response.code}:\n#{response.body}"
          end
        rescue StandardError => e
          raise e unless ReactOnRailsPro.configuration.renderer_use_fallback_exec_js

          fallback_exec_js(js_code, render_options, e)
        end

        def fallback_exec_js(js_code, render_options, error)
          Rails.logger.warn do
            "[ReactOnRailsPro] Falling back to ExecJS because of #{error}"
          end
          fallback_renderer = ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript

          # Pool is actually discarded btw requests:
          # 1) not to keep ExecJS in memory once NodeRenderer is available back
          # 2) to avoid issues with server bundle changes
          fallback_renderer.reset_pool
          result = fallback_renderer.eval_js(js_code, render_options)
          fallback_renderer.instance_variable_set(:@js_context_pool, nil)
          result
        end

        if defined?(ScoutApm)
          include ScoutApm::Tracer
          instrument_method :exec_server_render_js, type: "ReactOnRails", name: "Node React Server Rendering"
        end
      end
    end
  end
end
