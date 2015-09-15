# Kudos to react-rails for how to do the polyfill of the console!
# https://github.com/reactjs/react-rails/blob/master/lib/react/server_rendering/sprockets_renderer.rb

module ReactOnRails
  class ReactRenderer
    TRACE = true # Set to true to print generated code.
    # Reimplement console methods for replaying on the client
    CONSOLE_POLYFILL = <<-JS
var console = { history: [] };
['error', 'log', 'info', 'warn'].forEach(function (level) {
  console[level] = function () {
    console.history.push({level: level, arguments: Array.prototype.slice.call(arguments)});
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
  result += '\\n<script>';
  history.forEach(function (msg) {
    result += '\\nconsole.' + msg.level + '.apply(console, ' + JSON.stringify(msg.arguments) + ');';
  });
  result += '\\n</script>';
}
    JS

    DEBUGGER = <<-JS
      if (typeof window !== 'undefined') { debugger; }
    JS

    def base_js_code
      <<-JS
        #{CONSOLE_POLYFILL}
        #{bundle_js_code};
      JS
    end

    def initialize(options)
      @context = ExecJS.compile(base_js_code)
      @replay_console = options.fetch(:replay_console) { ReactOnRails.configuration.replay_console }
    end

    # js_code: JavaScript expression that returns a string.
    # Returns a string of HTML for direct insertion on the page by evaluating js_code.
    #   Note, js_code does not have to be based on React.
    # Calling code will probably call 'html_safe' on return value before rendering to the view.
    def render_js(js_code, options = {})
      component_name = options.fetch(:react_component_name, "")

      result_js_code = "result = #{js_code}"

      js_code_wrapper = <<-JS
(function () {
  var result = '';
  #{ReactOnRails::ReactRenderer.wrap_code_with_exception_handler(result_js_code, component_name)}
  #{after_render};
  return result;
})()
      JS

      puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
      puts "react_renderer.rb: 92"
      puts "js_code_wrapper = #{js_code_wrapper.ai}"
      puts "wrote file server-generated.js"
      File.write('server-generated.js', js_code_wrapper)
      puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"

      @context.eval(js_code_wrapper)
    end

    def self.wrap_code_with_exception_handler(js_code, component_name)
      <<-JS
      try {
        #{js_code}
      }
      catch(e) {
        var lineOne =
              'ERROR: You specifed the option generator_function (could be in your defaults) to be\\n';
        var lastLine =
              'A generator function takes a single arg of props and returns a ReactElement.';

        var msg = '';
        var shouldBeGeneratorError = lineOne +
              'false, but the react component \\'#{component_name}\\' seems to be a generator function.\\n' +
        lastLine;
        var reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
        if (reMatchShouldBeGeneratorError.test(e.message)) {
          msg += shouldBeGeneratorError + '\\n\\n';
        console.error(shouldBeGeneratorError);
        }

        var shouldBeGeneratorError = lineOne +
              'true, but the react component \\'#{component_name}\\' is not a generator function.\\n' +
        lastLine;
        var reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;
        if (reMatchShouldNotBeGeneratorError.test(e.message)) {
          msg += shouldBeGeneratorError + '\\n\\n';
        console.error(shouldBeGeneratorError);
        }

        console.error('SERVER SIDE: Exception in server side rendering!');
        if (e.fileName) {
          console.error('SERVER SIDE: location: ' + e.fileName + ':' + e.lineNumber);
        }
        console.error('SERVER SIDE: message: ' + e.message);
        console.error('SERVER SIDE: stack: ' + e.stack);
        msg += 'SERVER SIDE Exception in rendering!\\n' +
          (e.fileName ? '\\nlocation: ' + e.fileName + ':' + e.lineNumber : '') +
          '\\nMessage: ' + e.message + '\\n\\n' + e.stack;

        var reactElement = React.createElement('pre', null, msg);
        result = React.renderToString(reactElement);
      }
      JS
    end

    private

    def after_render
      @replay_console ? CONSOLE_REPLAY : ""
    end

    def bundle_js_code
      js_file = Rails.root.join(ReactOnRails.configuration.server_bundle_js_file)
      File.read(js_file)
    end
  end
end
