require "net/http"
require "uri"
require "rest_client"

module ReactOnRailsPro
  class VmRenderingPool
    RENDERED_HTML_KEY = "renderedHtml".freeze

    class << self
      # This implementation of the rendering pool uses NodeJS to execute javasript code
      def reset_pool
        # No need for this method
      end

      def reset_pool_if_server_bundle_was_modified
        if @bundle_update_utc_timestamp.present? && !ReactOnRails.configuration.development_mode
          return @bundle_update_utc_timestamp
        end

        bundle_update_time = File.mtime(ReactOnRails::Utils.server_bundle_js_file_path)
        @bundle_update_utc_timestamp = (bundle_update_time.utc.to_f * 1000).to_i
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
        ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript.exec_server_render_js(js_code, render_options, self)
      end

      def renderer_url(rendering_request_digest)
        port = if ReactOnRailsPro.configuration.renderer_port
                 ":#{ReactOnRailsPro.configuration.renderer_port}"
               else
                 ""
               end

        "#{ReactOnRailsPro.configuration.renderer_protocol}://" \
        "#{ReactOnRailsPro.configuration.renderer_host}" \
        "#{port}" \
        "/bundles/#{@bundle_update_utc_timestamp}/render/#{rendering_request_digest}"
      end

      def eval_js(js_code)
        # TODO: JUSTIN figure out what this is.
        # TODO: Remove gsub when fix random UIDs in domNodeId:
        rendering_request_digest = Digest::MD5.hexdigest(js_code.gsub(/domNodeId: '[\w-]*',/, ""))

        response = RestClient.post(
          renderer_url(rendering_request_digest),
          renderingRequest: js_code,
          gemVersion: ReactOnRailsPro::VERSION,
          protocolVersion: ReactOnRailsPro::PROTOCOL_VERSION,
          password: ReactOnRailsPro.configuration.password
        )

        parsed_response = JSON.parse(response.body)
        parsed_response[RENDERED_HTML_KEY]

      # rest_client treats non 2xx HTTP status for POST requests as an exception:
      rescue RestClient::ExceptionWithResponse => status_exception
        Rails.logger.debug { exception_debug_message(status_exception) }
        case status_exception.response.code
        when 410
          update_bundle_and_eval_js(js_code)
        when 412
          raise "Rendering server doesn't accept gem's protocol version"
        # when 307
        #  eval_js(js_code)
        else
          raise "Unknown response code #{status_exception.response.code}."
        end
      rescue Errno::ECONNREFUSED
        fallback_exec_js(js_code)
      end

      def update_bundle_and_eval_js(js_code)
        # TODO: Remove gsub when fix random UIDs in domNodeId:
        rendering_request_digest = Digest::MD5.hexdigest(js_code.gsub(/domNodeId: '[\w-]*',/, ""))

        response = RestClient.post(
          renderer_url(rendering_request_digest),
          renderingRequest: js_code,
          bundle: File.new(ReactOnRails::Utils.server_bundle_js_file_path),
          gemVersion: ReactOnRailsPro::VERSION,
          protocolVersion: ReactOnRailsPro::PROTOCOL_VERSION,
          password: ReactOnRailsPro.configuration.password
        )

        parsed_response = JSON.parse(response.body)
        parsed_response[RENDERED_HTML_KEY]
      rescue RestClient::ExceptionWithResponse => status_exception
        Rails.logger.warn { exception_debug_message(status_exception) }

        case status_exception.response.code
        when 412
          raise "Renderer version does not match gem version"
        # when 307
        #  eval_js(js_code)
        else
          raise "Unknown response code #{status_exception.response.code}."
        end
      rescue Errno::ECONNREFUSED
        fallback_exec_js(js_code)
      end

      def fallback_exec_js(js_code)
        Rails.logger.warn { "Can't connect to VmRenderer renderer, fallback to ExecJS" }
        fallback_renderer = ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript

        # Pool is actually discarded btw requests:
        # 1) not to keep ExecJS in memory once VmRenderer is available back
        # 2) to avoid issues with server bundle changes
        fallback_renderer.reset_pool
        result = fallback_renderer.eval_js(js_code)
        fallback_renderer.instance_variable_set(:@js_context_pool, nil)
        result
      end

      def exception_debug_message(exception)
        "[ReactOnRails Renderer]: #{exception.response.code}\n#{exception.response.headers}\n#{exception.response}"
      end
    end
  end
end
