require 'net/http'
require 'uri'
require 'rest_client'

module ReactOnRailsRenderer
  class RenderingPool
    # This implementation of the rendering pool uses NodeJS to execute javasript code
    def self.reset_pool
      # No need for this method
      update_bundle
    end

    def self.reset_pool_if_server_bundle_was_modified
      return unless ReactOnRails.configuration.development_mode
      file_mtime = File.mtime(ReactOnRails::Utils.default_server_bundle_js_file_path)
      @server_bundle_timestamp ||= file_mtime
      return if @server_bundle_timestamp == file_mtime
      #ReactOnRails::ServerRenderingPool.reset_pool
      p '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Gem want to reset the pool'
      @server_bundle_timestamp = file_mtime
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
        uri = URI.parse("http://localhost:3000/render")
        header = { 'Content-Type': 'application/json' }
        request = Net::HTTP::Post.new(uri.request_uri, header)

        request.body = {renderingRequest: js_code}.to_json

        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end

        parsed_response = JSON.parse(response.body)
        parsed_response["renderedHtml"]
      end

      def update_bundle
        RestClient.post(
          'http://localhost:3000/bundle',
          :name_of_file_param => File.new(ReactOnRails::Utils.default_server_bundle_js_file_path))
      end
    end
  end
end
