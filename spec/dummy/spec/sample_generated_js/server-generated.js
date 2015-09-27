(function () {
  var htmlResult = '';
  var consoleReplay = '';
  try {
    htmlResult = (function(React) {
      console.log("RENDERED HelloWorld with data_variable __helloWorldData0__ to dom node with id: HelloWorld-react-component-0");
      var reactElement = (function(React) {
        var props = {"helloWorldData":{"name":"Mr. Server Side Rendering"}};
        return React.createElement(HelloWorld, props);
      })(this.React);

      return React.renderToString(reactElement);
    })(this.React);

  }
  catch(e) {
    var lineOne =
          'ERROR: You specified the option generator_function (could be in your defaults) to be\n';
    var lastLine =
          'A generator function takes a single arg of props and returns a ReactElement.';

    var msg = '';
    var shouldBeGeneratorError = lineOne +
          'false, but the React component \'HelloWorld\' seems to be a generator function.\n' +
    lastLine;
    var reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
    if (reMatchShouldBeGeneratorError.test(e.message)) {
      msg += shouldBeGeneratorError + '\n\n';
      console.error(shouldBeGeneratorError);
    }

    var shouldBeGeneratorError = lineOne +
          'true, but the React component \'HelloWorld\' is not a generator function.\n' +
    lastLine;
    var reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;
    if (reMatchShouldNotBeGeneratorError.test(e.message)) {
      msg += shouldBeGeneratorError + '\n\n';
      console.error(shouldBeGeneratorError);
    }

    console.error('Exception in rendering!');
    if (e.fileName) {
      console.error('location: ' + e.fileName + ':' + e.lineNumber);
    }
    console.error('message: ' + e.message);
    console.error('stack: ' + e.stack);
    msg += 'Exception in rendering!\n' +
      (e.fileName ? '\nlocation: ' + e.fileName + ':' + e.lineNumber : '') +
      '\nMessage: ' + e.message + '\n\n' + e.stack;

    var reactElement = React.createElement('pre', null, msg);
    result = React.renderToString(reactElement);

  }

  var history = console.history;
  if (history && history.length > 0) {
    consoleReplay += '\n<script>';
    history.forEach(function (msg) {
      consoleReplay += '\nconsole.' + msg.level + '.apply(console, ' + JSON.stringify(msg.arguments) + ');';
    });
    consoleReplay += '\n</script>';
  }

  return JSON.stringify([htmlResult, consoleReplay]);
})()
