require 'connection_pool'

# Based on the react-rails gem
module ReactOnRails
  class ServerRenderingPool
    def self.reset_pool
      options = { size: ReactOnRails.configuration.server_renderer_pool_size,
                  timeout: ReactOnRails.configuration.server_renderer_pool_size }
      @@js_context_pool = ConnectionPool.new(options) { create_js_context }
    end

    def self.eval_js(js_code)
      @@js_context_pool.with do |js_context|
        result = js_context.eval(js_code)
        js_context.eval(CLEAR_CONSOLE)
        result
      end
    end

    def self.create_js_context
      server_js_file = ReactOnRails.configuration.server_bundle_js_file
      if server_js_file.present? && File.exist?(server_js_file)
        bundle_js_code = File.read(server_js_file)
        base_js_code = <<-JS
#{CONSOLE_POLYFILL}
#{bundle_js_code};
#{::Rails.application.assets['react_on_rails.js'].to_s};
        JS
        ExecJS.compile(base_js_code)
      else
        if server_js_file.present?
          Rails.logger.warn("You specified server rendering JS file: #{server_js_file}, but it cannot be read.")
        end
        ExecJS.compile("")
      end
    end

    CLEAR_CONSOLE = <<-JS
      console.history = []
    JS

    # Reimplement console methods for replaying on the client
    CONSOLE_POLYFILL = <<-JS
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

    class PrerenderError < RuntimeError
      def initialize(component_name, props, js_message)
        message = ["Encountered error \"#{js_message}\" when prerendering #{component_name} with #{props}",
                    js_message.backtrace.join("\n")].join("\n")
        super(message)
      end
    end
  end
end
