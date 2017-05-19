require "net/http"
require "uri"
require "rest_client"

module ReactOnRailsRenderer
  class RenderingPool
    RENDERED_HTML_KEY = "renderedHtml".freeze

    # This implementation of the rendering pool uses NodeJS to execute javasript code
    def self.reset_pool
      # No need for this method
    end

    def self.reset_pool_if_server_bundle_was_modified
      bundle_update_time = File.mtime(ReactOnRails::Utils.default_server_bundle_js_file_path)
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
    def self.server_render_js_with_console_logging(js_code)
      if trace_react_on_rails?
        @file_index ||= 1
        trace_messsage(js_code, "tmp/server-generated-#{@file_index % 10}.js")
        @file_index += 1
      end
      json_string = eval_js(js_code)
      JSON.parse(json_string)
    end

    class << self
      private

      def trace_messsage(js_code, file_name = "tmp/server-generated.js", force = false)
        return unless trace_react_on_rails? || force
        # Set to anything to print generated code.
        puts "Z" * 80
        puts "react_renderer.rb: 92"
        puts "wrote file #{file_name}"
        File.write(file_name, js_code)
        puts "Z" * 80
      end

      def trace_react_on_rails?
        ENV["TRACE_REACT_ON_RAILS"].present?
      end

      def renderer_url
        port = if ReactOnRailsRenderer.configuration.renderer_port
                 ":#{ReactOnRailsRenderer.configuration.renderer_port}"
               else
                 ""
               end

        "#{ReactOnRailsRenderer.configuration.renderer_protocol}://" \
        "#{ReactOnRailsRenderer.configuration.renderer_host}" \
        "#{port}" \
        "/render"
      end

      def eval_js(js_code)
        response = RestClient.post(
          renderer_url,
          renderingRequest: js_code,
          bundleUpdateTimeUtc: @bundle_update_utc_timestamp,
          password: ReactOnRailsRenderer.configuration.password
        )

        parsed_response = JSON.parse(response.body)
        parsed_response[RENDERED_HTML_KEY]

      # rest_client treats non 2xx HTTP status for POST requests as an exception:
      rescue RestClient::ExceptionWithResponse => status_exception
        p "zZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZz"

        case status_exception.response.code
        when 410
          update_bundle_and_eval_js(js_code)
        #when 307
        #  eval_js(js_code)
        else
          raise "Unknown response code #{status_exception.response.code}."
        end

      # Retry if connection refused, for example one worker died but new one was not forked yet:
      #rescue Errno::ECONNREFUSED
      #  eval_js(js_code)
      end

      def update_bundle_and_eval_js(js_code)
        response = RestClient.post(
          renderer_url,
          renderingRequest: js_code,
          bundle: File.new(ReactOnRails::Utils.default_server_bundle_js_file_path),
          bundleUpdateTimeUtc: @bundle_update_utc_timestamp,
          password: ReactOnRailsRenderer.configuration.password
        )

        parsed_response = JSON.parse(response.body)
        parsed_response[RENDERED_HTML_KEY]
=begin
      rescue RestClient::ExceptionWithResponse => status_exception
        p "zZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZz"

        case status_exception.response.code
        when 410
          update_bundle_and_eval_js(js_code)
        #when 307
        #  eval_js(js_code)
        else
          raise "Unknown response code #{status_exception.response.code}."
        end
      #rescue Errno::ECONNREFUSED
      #  update_bundle_and_eval_js(js_code)
=end
      end
    end
  end
end
