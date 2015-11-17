(function() {
  this.ReactOnRails = {};

  ReactOnRails.clientRenderReactComponent = function(options) {
    var componentName = options.componentName;
    var domId = options.domId;
    var props = options.props;
    var trace = options.trace;
    var generatorFunction = options.generatorFunction;
    var expectTurboLinks = options.expectTurboLinks;

    var renderIfDomNodePresent = function() {
      try {
        var domNode = document.getElementById(domId);
        if (domNode) {
          var reactElement = createReactElement(componentName, props,
            domId, trace, generatorFunction);
          provideClientReact().render(reactElement, domNode);
        }
      }
      catch (e) {
        ReactOnRails.handleError({
          e: e,
          componentName: componentName,
          serverSide: false,
        });
      }
    };

    var turbolinksInstalled = (typeof Turbolinks !== 'undefined');
    if (!expectTurboLinks || (!turbolinksInstalled && expectTurboLinks)) {
      if (expectTurboLinks) {
        console.warn('WARNING: NO TurboLinks detected in JS, but it is in your Gemfile');
      }

      document.addEventListener('DOMContentLoaded', function(event) {
        renderIfDomNodePresent();
      });
    } else {
      function onPageChange(event) {
        var removePageChangeListener = function() {
          document.removeEventListener('page:change', onPageChange);
          document.removeEventListener('page:before-unload', removePageChangeListener);
          var domNode = document.getElementById(domId);
          provideClientReact().unmountComponentAtNode(domNode);
        };

        document.addEventListener('page:before-unload', removePageChangeListener);

        renderIfDomNodePresent();
      }

      document.addEventListener('page:change', onPageChange);
    }
  };

  ReactOnRails.serverRenderReactComponent = function(options) {
    var componentName = options.componentName;
    var domId = options.domId;
    var props = options.props;
    var trace = options.trace;
    var generatorFunction = options.generatorFunction;

    var htmlResult = '';
    var consoleReplay = '';

    try {
      var reactElement = createReactElement(componentName, props, domId, trace, generatorFunction);
      htmlResult = provideServerReact().renderToString(reactElement);
    }
    catch (e) {
      htmlResult = ReactOnRails.handleError({
        e: e,
        componentName: componentName,
        serverSide: true,
      });
    }

    consoleReplay = ReactOnRails.buildConsoleReplay();
    return JSON.stringify([htmlResult, consoleReplay]);
  };

  // Passing either componentName or jsCode
  ReactOnRails.handleError = function(options) {
    var e = options.e;
    var componentName = options.componentName;
    var jsCode = options.jsCode;
    var serverSide = options.serverSide;

    var lineOne =
      'ERROR: You specified the option generator_function (could be in your defaults) to be\n';
    var lastLine =
      'A generator function takes a single arg of props and returns a ReactElement.';

    console.error('Exception in rendering!');

    var msg = '';
    if (componentName) {
      var shouldBeGeneratorError = lineOne +
        'false, but the React component \'' + componentName + '\' seems to be a generator function.\n' +
        lastLine;
      var reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
      if (reMatchShouldBeGeneratorError.test(e.message)) {
        msg += shouldBeGeneratorError + '\n\n';
        console.error(shouldBeGeneratorError);
      }

      var shouldBeGeneratorError = lineOne +
        'true, but the React component \'' + componentName + '\' is not a generator function.\n' +
        lastLine;
      var reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;
      if (reMatchShouldNotBeGeneratorError.test(e.message)) {
        msg += shouldBeGeneratorError + '\n\n';
        console.error(shouldBeGeneratorError);
      }
    }

    if (jsCode) {
      console.error('JS code was: ' + jsCode);
    }

    if (e.fileName) {
      console.error('location: ' + e.fileName + ':' + e.lineNumber);
    }

    console.error('message: ' + e.message);
    console.error('stack: ' + e.stack);
    if (serverSide) {
      msg += 'Exception in rendering!\n' +
        (e.fileName ? '\nlocation: ' + e.fileName + ':' + e.lineNumber : '') +
        '\nMessage: ' + e.message + '\n\n' + e.stack;
      var reactElement = React.createElement('pre', null, msg);
      return provideServerReact().renderToString(reactElement);
    }
  };

  ReactOnRails.buildConsoleReplay = function() {
    var consoleReplay = '';

    var history = console.history;
    if (history && history.length > 0) {
      consoleReplay += '\n<script>';
      history.forEach(function(msg) {
        consoleReplay += '\nconsole.' + msg.level + '.apply(console, ' +
          JSON.stringify(msg.arguments) + ');';
      });

      consoleReplay += '\n</script>';
    }

    return consoleReplay;
  };

  function createReactElement(componentName, props, domId, trace, generatorFunction) {
    if (trace) {
      console.log('RENDERED ' + componentName + ' to dom node with id: ' + domId);
    }

    if (generatorFunction) {
      return this[componentName](props);
    } else {
      return React.createElement(this[componentName], props);
    }
  }

  function provideClientReact() {
    if (typeof ReactDOM === 'undefined') {
      return React;
    }

    return ReactDOM;
  }

  function provideServerReact() {
    if (typeof ReactDOMServer === 'undefined') {
      return React;
    }

    return ReactDOMServer;
  }
}.call(this));
