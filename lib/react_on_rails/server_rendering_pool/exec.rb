module ReactOnRails
  module ServerRenderingPool
    # This implementation of the rendering pool uses ExecJS to execute javasript code
    class Exec
      def self.reset_pool
        options = {
          size: ReactOnRails.configuration.server_renderer_pool_size,
          timeout: ReactOnRails.configuration.server_renderer_timeout
        }
        @js_context_pool = ConnectionPool.new(options) { create_js_context }
      end

      def self.reset_pool_if_server_bundle_was_modified
        return unless ReactOnRails.configuration.development_mode
        file_mtime = File.mtime(ReactOnRails::Utils.default_server_bundle_js_file_path)
        @server_bundle_timestamp ||= file_mtime
        return if @server_bundle_timestamp == file_mtime
        ReactOnRails::ServerRenderingPool.reset_pool
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
        result = JSON.parse(json_string)

        if ReactOnRails.configuration.logging_on_server
          console_script = result["consoleReplayScript"]
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
          @js_context_pool.with do |js_context|
            result = js_context.eval(js_code)
            js_context.eval("console.history = []")
            result
          end
        end

        def create_js_context
          server_js_file = ReactOnRails::Utils.default_server_bundle_js_file_path
          if server_js_file.present? && File.exist?(server_js_file)
            bundle_js_code = File.read(server_js_file)
            base_js_code = <<-JS
#{console_polyfill}
            #{execjs_timer_polyfills}
            #{bundle_js_code};
            JS
            file_name = "tmp/base_js_code.js"
            begin
              trace_messsage(base_js_code, file_name)
              ExecJS.compile(base_js_code)
            rescue => e
              msg = "ERROR when compiling base_js_code! "\
              "See file #{file_name} to "\
              "correlate line numbers of error. Error is\n\n#{e.message}"\
              "\n\n#{e.backtrace.join("\n")}"
              puts msg
              Rails.logger.error(msg)
              trace_messsage(base_js_code, file_name, true)
              raise e
            end
          else
            if server_js_file.present?
              msg = "You specified server rendering JS file: #{server_js_file}, but it cannot be "\
              "read. You may set the server_bundle_js_file in your configuration to be \"\" to "\
              "avoid this warning"
              Rails.logger.warn msg
              puts msg
            end
            ExecJS.compile("")
          end
        end

        def execjs_timer_polyfills
          <<-JS
function getStackTrace () {
  var stack;
  try {
    throw new Error('');
  }
  catch (error) {
    stack = error.stack || '';
  }
  stack = stack.split('\\n').map(function (line) { return line.trim(); });
  return stack.splice(stack[0] == 'Error' ? 2 : 1);
}

function setInterval() {
  #{undefined_for_exec_js_logging('setInterval')}
}

function setTimeout() {
  #{undefined_for_exec_js_logging('setTimeout')}
}
          JS
        end

        def undefined_for_exec_js_logging(function_name)
          if trace_react_on_rails?
            "console.error('#{function_name} is not defined for execJS. See "\
          "https://github.com/sstephenson/execjs#faq. Note babel-polyfill may call this.');\n"\
          "  console.error(getStackTrace().join('\\n'));"
          else
            ""
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
end
