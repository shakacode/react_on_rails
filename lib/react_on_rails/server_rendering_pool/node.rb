# frozen_string_literal: true

module ReactOnRails
  module ServerRenderingPool
    class Node
      # This implementation of the rendering pool uses NodeJS to execute javasript code
      def self.reset_pool
        options = {
          size: ReactOnRails.configuration.server_renderer_pool_size,
          timeout: ReactOnRails.configuration.server_renderer_timeout
        }
        @js_context_pool = ConnectionPool.new(options) { create_js_context }
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
          eof_symbol = "\r\n\0"
          max_int = (2**30 - 1)
          @js_context_pool.with do |js_context|
            js_context.send(js_code + eof_symbol, 0)
            result = ""
            while result[-eof_symbol.length..-1] != eof_symbol
              result += js_context.recv(max_int)
            end
            result[0..-eof_symbol.length]
          end
        end

        def create_js_context
          begin
            client = UNIXSocket.new("client/node/node.sock")
            client.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
          rescue StandardError => e
            Rails.logger.error("Unable to connect to socket: client/node/node.sock. \
              Make sure node server is up and running.")
            Rails.logger.error(e)
            raise e
          end
          client
        end
      end
    end
  end
end
