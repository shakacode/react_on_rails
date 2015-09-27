(function() {
  window.__helloWorldData0__ = {"helloWorldData":{"name":"Mr. Server Side Rendering"}};
  var renderIfDomNodePresent = function() {
    try {
      var domNode = document.getElementById('HelloWorld-react-component-0');
      if (domNode) {
        console.log("RENDERED HelloWorld with data_variable __helloWorldData0__ to dom node with id: HelloWorld-react-component-0");
        var reactElement = (function(React) {
          var props = __helloWorldData0__;
          return React.createElement(HelloWorld, props);
        })(this.React);

        React.render(reactElement, domNode);
      }

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
        var domNode = document.getElementById('HelloWorld-react-component-0');
        React.unmountComponentAtNode(domNode);
      };
      document.addEventListener("page:before-unload", removePageChangeListener);

      renderIfDomNodePresent();
    }
    document.addEventListener("page:change", onPageChange);
  }

})();
