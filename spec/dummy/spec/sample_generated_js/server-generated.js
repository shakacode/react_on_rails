  (function () {
    var result = '';
    try {
      result = (function(React) {
        var reactElement = (function(React) {
          var props = {"helloWorldData":{"name":"Mr. Server Side Rendering"}};
          return React.createElement(HelloWorldES5, props);
        })(this.React);

        return React.renderToString(reactElement);
      })(this.React);

    }
    catch(e) {
      var lineOne =
            'ERROR: You specifed the option generator_function (could be in your defaults) to be\n';
      var lastLine =
            'A generator function takes a single arg of props and returns a ReactElement.';

      var msg = '';
      var shouldBeGeneratorError = lineOne +
            'false, but the react component \'HelloWorldES5\' seems to be a generator function.\n' +
      lastLine;
      var reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
      if (reMatchShouldBeGeneratorError.test(e.message)) {
        msg += shouldBeGeneratorError + '\n\n';
        console.error(shouldBeGeneratorError);
      }

      var shouldBeGeneratorError = lineOne +
            'true, but the react component \'HelloWorldES5\' is not a generator function.\n' +
      lastLine;
      var reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;
      if (reMatchShouldNotBeGeneratorError.test(e.message)) {
        msg += shouldBeGeneratorError + '\n\n';
        console.error(shouldBeGeneratorError);
      }

      console.error('SERVER SIDE: Exception in server side rendering!');
      if (e.fileName) {
        console.error('SERVER SIDE: location: ' + e.fileName + ':' + e.lineNumber);
      }
      console.error('SERVER SIDE: message: ' + e.message);
      console.error('SERVER SIDE: stack: ' + e.stack);
      msg += 'SERVER SIDE Exception in rendering!\n' +
        (e.fileName ? '\nlocation: ' + e.fileName + ':' + e.lineNumber : '') +
        '\nMessage: ' + e.message + '\n\n' + e.stack;

      var reactElement = React.createElement('pre', null, msg);
      result = React.renderToString(reactElement);
    }

    var history = console.history;
    if (history && history.length > 0) {
      result += '\n<script>';
      history.forEach(function (msg) {
        result += '\nconsole.' + msg.level + '.apply(console, ' + JSON.stringify(msg.arguments) + ');';
      });
      result += '\n</script>';
    }

    return result;
  })()
