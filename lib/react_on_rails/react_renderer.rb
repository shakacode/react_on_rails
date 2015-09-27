# Kudos to react-rails for how to do the polyfill of the console!
# https://github.com/reactjs/react-rails/blob/master/lib/react/server_rendering/sprockets_renderer.rb

module ReactOnRails
  class ReactRenderer
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

    # Script to write to the browser console.
    # NOTE: result comes from enclosing closure and is the server generated HTML
    # that we intend to write to the browser. Thus, the script tag will get executed right after
    # the HTML is rendered.
    CONSOLE_REPLAY = <<-JS
    var history = console.history;
    if (history && history.length > 0) {
      consoleReplay += '\\n<script>';
      history.forEach(function (msg) {
        consoleReplay += '\\nconsole.' + msg.level + '.apply(console, ' + JSON.stringify(msg.arguments) + ');';
      });
      consoleReplay += '\\n</script>';
    }
    JS

    DEBUGGER = <<-JS
      if (typeof window !== 'undefined') { debugger; }
    JS

    def initialize(options)
      @replay_console = options.fetch(:replay_console) { ReactOnRails.configuration.replay_console }
    end

    # js_code: JavaScript expression that returns a string.
    # Returns an Array:
    # [0]: string of HTML for direct insertion on the page by evaluating js_code
    # [1]: console messages
    #   Note, js_code does not have to be based on React.
    # Calling code will probably call 'html_safe' on return value before rendering to the view.
    def render_js(js_code, options = {})
      component_name = options.fetch(:react_component_name, "")
      server_side = options.fetch(:server_side, false)

      result_js_code = "      htmlResult = #{js_code}"

      js_code_wrapper = <<-JS
  (function () {
    var htmlResult = '';
    var consoleReplay = '';
#{ReactOnRails::ReactRenderer.wrap_code_with_exception_handler(result_js_code, component_name)}
      #{console_replay_js_code}
    return JSON.stringify([htmlResult, consoleReplay]);
  })()
      JS

      if ENV["TRACE_REACT_ON_RAILS"].present? # Set to anything to print generated code.
        puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
        puts "react_renderer.rb: 92"
        puts "wrote file tmp/server-generated.js"
        File.write("tmp/server-generated.js", js_code_wrapper)
        puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
      end

      if js_context
        json_string = js_context.eval(js_code_wrapper)
      else
        json_string = ExecJS.eval(js_code_wrapper)
      end
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
            if match
              Rails.logger.info { "[react_on_rails] #{match[:msg]}" }
            end
          end
        end
      end
      return result
    end

    def self.wrap_code_with_exception_handler(js_code, component_name)
      <<-JS
    try {
#{js_code}
    }
    catch(e) {
      var lineOne =
            'ERROR: You specified the option generator_function (could be in your defaults) to be\\n';
      var lastLine =
            'A generator function takes a single arg of props and returns a ReactElement.';

      var msg = '';
      var shouldBeGeneratorError = lineOne +
            'false, but the React component \\'#{component_name}\\' seems to be a generator function.\\n' +
      lastLine;
      var reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
      if (reMatchShouldBeGeneratorError.test(e.message)) {
        msg += shouldBeGeneratorError + '\\n\\n';
        console.error(shouldBeGeneratorError);
      }

      var shouldBeGeneratorError = lineOne +
            'true, but the React component \\'#{component_name}\\' is not a generator function.\\n' +
      lastLine;
      var reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;
      if (reMatchShouldNotBeGeneratorError.test(e.message)) {
        msg += shouldBeGeneratorError + '\\n\\n';
        console.error(shouldBeGeneratorError);
      }

      #{render_error_messages}
    }
      JS
    end

    private

    def self.render_error_messages
      <<-JS
      console.error('Exception in rendering!');
      if (e.fileName) {
        console.error('location: ' + e.fileName + ':' + e.lineNumber);
      }
      console.error('message: ' + e.message);
      console.error('stack: ' + e.stack);
      msg += 'Exception in rendering!\\n' +
        (e.fileName ? '\\nlocation: ' + e.fileName + ':' + e.lineNumber : '') +
        '\\nMessage: ' + e.message + '\\n\\n' + e.stack;

      var reactElement = React.createElement('pre', null, msg);
      result = React.renderToString(reactElement);
      JS
    end

    def console_replay_js_code
      (@replay_console || ReactOnRails.configuration.logging_on_server) ? CONSOLE_REPLAY : ""
    end

    def base_js_code(bundle_js_code)
      <<-JS
#{CONSOLE_POLYFILL}
      #{bundle_js_code};
      JS
    end

    def js_context
      if @js_context.nil?
        @js_context = begin
          server_js_file = ReactOnRails.configuration.server_bundle_js_file
          if server_js_file.present? && File.exist?(server_js_file)
            bundle_js_code = File.read(server_js_file)
            ExecJS.compile(base_js_code(bundle_js_code))
          else
            if server_js_file.present?
              Rails.logger.warn("You specified server rendering JS file: #{server_js_file}, but it cannot be read.")
            end
            false # using false so we don't try every time if no server_js file
          end
        end
      end
      @js_context
    end
  end
end
