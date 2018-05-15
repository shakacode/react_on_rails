# frozen_string_literal: true

require "open-uri"

module ReactOnRails
  module ServerRenderingPool
    class RubyEmbeddedJavaScript
      class << self
        def reset_pool
          options = {
            size: ReactOnRails.configuration.server_renderer_pool_size,
            timeout: ReactOnRails.configuration.server_renderer_timeout
          }
          @js_context_pool = ConnectionPool.new(options) { create_js_context }
        end

        def reset_pool_if_server_bundle_was_modified
          return unless ReactOnRails.configuration.development_mode

          file_mtime = File.mtime(ReactOnRails::Utils.server_bundle_js_file_path)
          @server_bundle_timestamp ||= file_mtime
          return if @server_bundle_timestamp == file_mtime

          @server_bundle_timestamp = file_mtime

          ReactOnRails::ServerRenderingPool.reset_pool
        end

        # js_code: JavaScript expression that returns a string.
        # render_options: lib/react_on_rails/react_component/render_options.rb
        # Using these options:
        #    trace: saves the executed JS to a file, used in development
        #    logging_on_server: put on server logs, not just in browser console
        #
        # Returns a Hash:
        #   html: string of HTML for direct insertion on the page by evaluating js_code
        #   consoleReplayScript: script for replaying console
        #   hasErrors: true if server rendering errors
        # Note, js_code does not have to be based on React.
        # js_code MUST RETURN json stringify Object
        # Calling code will probably call 'html_safe' on return value before rendering to the view.
        def exec_server_render_js(js_code, render_options, js_evaluator = nil)
          js_evaluator ||= self
          if render_options.trace
            @file_index ||= 1
            trace_js_code_used("Evaluating code to server render.", js_code,
                               "tmp/server-generated-#{@file_index % 10}.js")
            @file_index += 1
          end
          json_string = js_evaluator.eval_js(js_code, render_options)
          result = nil
          begin
            result = JSON.parse(json_string)
          rescue JSON::ParserError => e
            raise ReactOnRails::JsonParseError.new(e, json_string)
          end

          if render_options.logging_on_server
            console_script = result["consoleReplayScript"]
            console_script_lines = console_script.split("\n")
            console_script_lines = console_script_lines[2..-2]
            re = /console\.(log|error)\.apply\(console, \["\[SERVER\] (?<msg>.*)"\]\);/
            if console_script_lines
              console_script_lines.each do |line|
                match = re.match(line)
                Rails.logger.info { "[react_on_rails] #{match[:msg]}" } if match
              end
            end
          end
          result
        end

        def trace_js_code_used(msg, js_code, file_name = "tmp/server-generated.js", force: false)
          return unless ReactOnRails.configuration.trace || force
          # Set to anything to print generated code.
          File.write(file_name, js_code)
          msg = <<-MSG.strip_heredoc
            #{'Z' * 80}
            [react_on_rails] #{msg}
            JavaScript code used: #{file_name}
            #{'Z' * 80}
          MSG
          if force
            Rails.logger.error(msg)
          else
            Rails.logger.info(msg)
          end
        end

        def eval_js(js_code, _render_options)
          @js_context_pool.with do |js_context|
            result = js_context.eval(js_code)
            js_context.eval("console.history = []")
            result
          end
        end

        def create_js_context
          return if ReactOnRails.configuration.server_bundle_js_file.blank?

          server_js_file = ReactOnRails::Utils.server_bundle_js_file_path

          begin
            bundle_js_code = File.read(server_js_file)
          rescue StandardError => e
            msg = "You specified server rendering JS file: #{server_js_file}, but it cannot be "\
                "read. You may set the server_bundle_js_file in your configuration to be \"\" to "\
                "avoid this warning.\nError is: #{e}"
            raise ReactOnRails::Error, msg
          end
          # rubocop:disable Layout/IndentHeredoc
          base_js_code = <<-JS
#{console_polyfill}
#{execjs_timer_polyfills}
#{bundle_js_code};
          JS
          # rubocop:enable Layout/IndentHeredoc
          file_name = "tmp/base_js_code.js"
          begin
            if ReactOnRails.configuration.trace
              Rails.logger.info { "[react_on_rails] Created JavaScript context with file #{server_js_file}" }
            end
            ExecJS.compile(base_js_code)
          rescue StandardError => e
            msg = "ERROR when compiling base_js_code! "\
              "See file #{file_name} to "\
              "correlate line numbers of error. Error is\n\n#{e.message}"\
              "\n\n#{e.backtrace.join("\n")}"
            Rails.logger.error(msg)
            trace_js_code_used("Error when compiling JavaScript code for the context.", base_js_code,
                               file_name, force: true)
            raise e
          end
        end

        def execjs_timer_polyfills
          # rubocop:disable Layout/IndentHeredoc
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

function clearTimeout() {
  #{undefined_for_exec_js_logging('clearTimeout')}
}
          JS
          # rubocop:enable Layout/IndentHeredoc
        end

        def undefined_for_exec_js_logging(function_name)
          if ReactOnRails.configuration.trace
            "console.error('[React on Rails Rendering] #{function_name} is not defined for server rendering.');\n"\
            "  console.error(getStackTrace().join('\\n'));"
          else
            ""
          end
        end

        # Reimplement console methods for replaying on the client
        def console_polyfill
          # rubocop:disable Layout/IndentHeredoc
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
          # rubocop:enable Layout/IndentHeredoc
        end
      end
    end
  end
end
