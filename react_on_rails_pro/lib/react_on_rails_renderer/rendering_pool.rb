require 'net/http'
require 'uri'

module ReactOnRailsRenderer
  class RenderingPool
    # This implementation of the rendering pool uses NodeJS to execute javasript code
    def self.reset_pool
      # TODO: We should be able to reload bundle on Express server here.
    end

    def self.reset_pool_if_server_bundle_was_modified
      # No need for this method, the server bundle is automatically reset by node when changes
      # Empty implementation to conform to ServerRenderingPool interface
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

      def eval_js(js_code)
        uri = URI.parse("http://localhost:3000")
        header = {'Content-Type': 'application/json'}
        request = Net::HTTP::Post.new(uri.request_uri, header)

        request.body = {code: js_code}.to_json

        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end

        response.body
      end
    end
  end
end
