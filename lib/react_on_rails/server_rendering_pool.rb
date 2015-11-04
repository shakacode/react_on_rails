require "connection_pool"

# Based on the react-rails gem.
# None of these methods should be called directly.
# See app/helpers/react_on_rails_helper.rb
module ReactOnRails
  class ServerRenderingPool
    def self.reset_pool
      options = { size: ReactOnRails.configuration.server_renderer_pool_size,
                  timeout: ReactOnRails.configuration.server_renderer_pool_size }
      @js_context_pool = ConnectionPool.new(options) { create_js_context }
    end

    def self.reset_pool_if_server_bundle_was_modified
      return unless ReactOnRails.configuration.development_mode
      file_mtime = File.mtime(ReactOnRails.configuration.server_bundle_js_file)
      first_time = @server_bundle_timestamp.nil?
      return if first_time || @server_bundle_timestamp == file_mtime
      ReactOnRails::ServerRenderingPool.reset_pool
      @server_bundle_timestamp = file_mtime
    end

    class PrerenderError < RuntimeError
      def initialize(component_name, props, js_message)
        message = ["Encountered error \"#{js_message}\" when prerendering #{component_name} with #{props}",
                   js_message.backtrace.join("\n")].join("\n")
        super(message)
      end
    end

    # js_code: JavaScript expression that returns a string.
    # Returns an Array:
    # [0]: string of HTML for direct insertion on the page by evaluating js_code
    # [1]: console messages
    #   Note, js_code does not have to be based on React.
    # js_code MUST RETURN json stringify array of two elements
    # Calling code will probably call 'html_safe' on return value before rendering to the view.
    def self.server_render_js_with_console_logging(js_code)
      trace_messsage(js_code)

      json_string = eval_js(js_code)
      # element 0 is the html, element 1 is the script tag for the server console output
      result = JSON.parse(json_string)

      if ReactOnRails.configuration.logging_on_server
        console_script = result[1]
        console_script_lines = console_script.split("\n")
        console_script_lines = console_script_lines[2..-2]
        re = /console\.log\.apply\(console, \["\[SERVER\] (?<msg>.*)"\]\);/
        if console_script_lines
          console_script_lines.each do |line|
            match = re.match(line)
            Rails.logger.info { "[react_on_rails] #{match[:msg]}" } if match
          end
        end
      end
      result
    end

    class << self
      private

      def trace_messsage(js_code)
        return unless ENV["TRACE_REACT_ON_RAILS"].present?
        # Set to anything to print generated code.
        puts "Z" * 80
        puts "react_renderer.rb: 92"
        puts "wrote file tmp/server-generated.js"
        File.write("tmp/server-generated.js", js_code)
        puts "Z" * 80
      end

      def eval_js(js_code)
        @js_context_pool.with do |js_context|
          result = js_context.eval(js_code)
          js_context.eval("console.history = []")
          result
        end
      end

      def create_js_context
        server_js_file = ReactOnRails.configuration.server_bundle_js_file
        if server_js_file.present? && File.exist?(server_js_file)
          bundle_js_code = File.read(server_js_file)
          base_js_code = <<-JS
#{console_polyfill}
          #{bundle_js_code};
#{::Rails.application.assets['react_on_rails.js']};
          JS
          ExecJS.compile(base_js_code)
        else
          if server_js_file.present?
            Rails.logger.warn("You specified server rendering JS file: #{server_js_file}, but it cannot be read.")
          end
          ExecJS.compile("")
        end
      end

      # Reimplement console methods for replaying on the client
      def console_polyfill
        <<-JS
var console = { history: [] };
['error', 'log', 'info', 'warn'].forEach(function (level) {
  console[level] = function () {
    var argArray = Array.prototype.slice.call(arguments);
    if (argArray.length > 0) {
      argArray[0] = '[SERVER] ' + argArray[0];
    }
    console.history.push({level: level, arguments: argArray});
  };
});
        JS
      end
    end
  end
end
