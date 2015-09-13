# Kudos to react-rails for how to do the polyfill of the console!
# https://github.com/reactjs/react-rails/blob/master/lib/react/server_rendering/sprockets_renderer.rb

module ReactOnRails
  class ReactRenderer
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
        (function (history) {
          if (history && history.length > 0) {
            result += '\\n<script>';
            history.forEach(function (msg) {
              result += '\\nconsole.' + msg.level + '.apply(console, ' + JSON.stringify(msg.arguments) + ');';
            });
            result += '\\n</script>';
          }
        })(console.history);
    JS

    DEBUGGER = <<-JS
      if (typeof window !== 'undefined') { debugger; }
    JS

    def base_js_code
      <<-JS.strip_heredoc
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

      js_code_wrapper = <<-JS.strip_heredoc
      (function () {
        var result = '';
        try {
          result = #{js_code}
        }
        catch(e) {
          #{DEBUGGER}
          var generatorError =
            'ERROR: You did not specify the option generator_function to be true, but the \\n' +
            'react component \\'#{component_name}\\' seems to be a generator function.\\n' +
            'A generator function is on that takes a single arg of props and returns a ReactElement.';
          var reMatchGeneratorError = /Can't add property context, object is not extensible/;
          var hasGeneratorError = reMatchGeneratorError.test(e.message);
          var msg = '';
          if (hasGeneratorError) {
            msg = generatorError + '\\n\\n';
            console.error(generatorError);
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
        #{after_render};
        return result;
      })()
      JS
      @context.eval(js_code_wrapper)
    end

    private

    def after_render
      @replay_console ? CONSOLE_REPLAY : ""
    end

    def bundle_js_code
      js_file = Rails.root.join(ReactOnRails.configuration.bundle_js_file)
      File.read(js_file)
    end
  end
end
