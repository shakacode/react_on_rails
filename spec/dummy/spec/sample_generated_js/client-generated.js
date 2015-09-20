(function() {
  window.__helloWorldES5Data0__ = {"helloWorldData":{"name":"Mr. Server Side Rendering"}};
  var renderIfDomNodePresent = function() {
    try {
      var domNode = document.getElementById('HelloWorldES5-react-component-0');
      if (domNode) {
        console.log("CLIENT SIDE RENDERED HelloWorldES5 with data_variable __helloWorldES5Data0__ to dom node with id: HelloWorldES5-react-component-0");

        var reactElement = (function(React) {
          var props = __helloWorldES5Data0__;
          return React.createElement(HelloWorldES5, props);
        })(this.React);

        React.render(reactElement, domNode);
      }

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

  }

  var turbolinksInstalled = typeof(Turbolinks) !== 'undefined';
  if (!turbolinksInstalled) {
    console.warn("WARNING: NO TurboLinks detected in JS, but it's in your Gemfile");
    document.addEventListener("DOMContentLoaded", function(event) {
      console.log("DOMContentLoaded event fired");
      renderIfDomNodePresent();
    });

  } else {
    function onPageChange(event) {
      var removePageChangeListener = function() {
        document.removeEventListener("page:change", onPageChange);
        document.removeEventListener("page:before-unload", removePageChangeListener);
        var domNode = document.getElementById('HelloWorldES5-react-component-0');
        React.unmountComponentAtNode(domNode);
      };
      document.addEventListener("page:before-unload", removePageChangeListener);

      renderIfDomNodePresent();
    }
    document.addEventListener("page:change", onPageChange);
  }

})();
