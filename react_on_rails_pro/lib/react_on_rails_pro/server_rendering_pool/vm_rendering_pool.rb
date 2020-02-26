# frozen_string_literal: true

require "net/http"
require "net/http/post/multipart"
require "uri"
require "persistent_http"

module ReactOnRailsPro
  module ServerRenderingPool
    # This implementation of the rendering pool uses NodeJS to execute javasript code
    class VmRenderingPool
      RENDERED_HTML_KEY = "renderedHtml"

      class << self
        attr_accessor :bundle_update_utc_timestamp

        def reset_pool
          Rails.logger.info { "[ReactOnRailsPro] Setting up connection VM Renderer at #{renderer_url_base}" }

          # NOTE: there are multiple similar gems
          # We use https://github.com/bpardee/persistent_http/blob/master/lib/persistent_http.rb
          # Not: https://github.com/drbrain/net-http-persistent
          @connection = PersistentHTTP.new(
            name: "ReactOnRailsProVmRendererClient",
            logger: Rails.logger,
            pool_size: ReactOnRailsPro.configuration.renderer_http_pool_size,
            pool_timeout: ReactOnRailsPro.configuration.renderer_http_pool_timeout,
            warn_timeout: ReactOnRailsPro.configuration.renderer_http_pool_warn_timeout,
            force_retry: true,
            url: ReactOnRailsPro.configuration.renderer_url
          )
        end

        def reset_pool_if_server_bundle_was_modified
          # Resetting the pool for server bundle modifications is accomplished by changing the mtime
          # of the server bundle in the request to the remote rendering server.
          # In non-development mode, we don't need to re-read this value.
          if @bundle_update_utc_timestamp.present? && !ReactOnRails.configuration.development_mode
            return @bundle_update_utc_timestamp
          end

          @bundle_update_utc_timestamp = bundle_utc_timestamp
        end

        def renderer_bundle_file_name
          "#{bundle_utc_timestamp}.js"
        end

        def bundle_utc_timestamp
          bundle_update_time = File.mtime(ReactOnRails::Utils.server_bundle_js_file_path)
          (bundle_update_time.utc.to_f * 1000).to_i
        end

        def renderer_url_base
          ReactOnRailsPro.configuration.renderer_url
        end

        def renderer_url(rendering_request_digest)
          "#{renderer_url_base}/bundles/#{@bundle_update_utc_timestamp}/render/#{rendering_request_digest}"
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
          ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
            .exec_server_render_js(js_code, render_options, self)
        end

        def request_form_data(js_code, send_bundle)
          form_data = {
            "renderingRequest" => js_code,
            "gemVersion" => ReactOnRailsPro::VERSION,
            "protocolVersion" => "1.0.0",
            "password" => ReactOnRailsPro.configuration.renderer_password
          }

          if send_bundle
            form_data["bundle"] = UploadIO.new(
              File.new(ReactOnRails::Utils.server_bundle_js_file_path),
              ReactOnRails::Utils.server_bundle_js_file_path
            )
          end
          form_data
        end

        def eval_js(js_code, render_options, send_bundle: false)
          ReactOnRailsPro::ServerRenderingPool::ProRendering
            .set_request_digest_on_render_options(js_code, render_options)

          path = "/bundles/#{@bundle_update_utc_timestamp}/render/#{render_options.request_digest}"

          request = Net::HTTP::Post::Multipart.new(path, request_form_data(js_code, send_bundle))

          begin
            response = @connection.request(request)
          rescue StandardError => e
            raise ReactOnRailsPro::Error, "Can't connect to VmRenderer renderer at #{renderer_url_base}.\n"\
                  "Original error:\n#{e}"
          end

          case response.code
          when "200"
            response.body
          when "410"
            # 410 is a special value meaning send the updated bundle with the next request.
            eval_js(js_code, render_options, send_bundle: true)
          when "400"
            raise ReactOnRailsPro::Error,
                  "Renderer unhandled error at the VM level: #{response.code}:\n#{response.body}"
          when "412"
            # 412 is a protocol error, meaning the server and renderer are running incompatible versions
            # of React on Rails.
            raise ReactOnRailsPro::Error, response.body
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
          # 1) not to keep ExecJS in memory once VmRenderer is available back
          # 2) to avoid issues with server bundle changes
          fallback_renderer.reset_pool
          result = fallback_renderer.eval_js(js_code, render_options)
          fallback_renderer.instance_variable_set(:@js_context_pool, nil)
          result
        end
      end
    end
  end
end
