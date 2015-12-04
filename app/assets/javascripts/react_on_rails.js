(function() {
  this.ReactOnRails = {};
  var turbolinksInstalled = (typeof Turbolinks !== 'undefined');

  ReactOnRails.serverRenderReactComponent = function(options) {
    var componentName = options.componentName;
    var domId = options.domId;
    var props = options.props;
    var trace = options.trace;
    var generatorFunction = options.generatorFunction;
    var location = options.location;
    var htmlResult = '';
    var consoleReplay = '';
    var hasErrors = false;

    try {
      var reactElementOrRouterResult = createReactElementOrRouterResult(componentName, props,
        domId, trace, generatorFunction, location);
      if (isRouterResult(reactElementOrRouterResult)) {

        // We let the client side handle any redirect
        // Set hasErrors in case we want to throw a Rails exception
        hasErrors = !!reactElementOrRouterResult.routeError;
        if (hasErrors) {
          console.error('React Router ERROR: ' +
            JSON.stringify(reactElementOrRouterResult.routeError));
        } else {
          if (trace) {
            redirectLocation = reactElementOrRouterResult.redirectLocation;
            redirectPath = redirectLocation.pathname + redirectLocation.search;
            console.log('ROUTER REDIRECT: ' + componentName + ' to dom node with id: ' + domId +
              ', redirect to ' + redirectPath);
          }
        }
      } else {
        htmlResult = provideServerReact().renderToString(reactElementOrRouterResult);
      }
    }
    catch (e) {
      hasErrors = true;
      htmlResult = ReactOnRails.handleError({
        e: e,
        componentName: componentName,
        serverSide: true,
      });
    }

    consoleReplayScript = ReactOnRails.buildConsoleReplay();

    return JSON.stringify({
      html: htmlResult,
      consoleReplayScript: consoleReplayScript,
      hasErrors: hasErrors,
    });
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

  ReactOnRails.wrapInScriptTags = function(scriptBody) {
    if (!scriptBody) {
      return '';
    }

    return '\n<script>' + scriptBody + '\n</script>';
  };

  ReactOnRails.buildConsoleReplay = function() {
    var consoleReplay = '';

    var history = console.history;
    if (history && history.length > 0) {
      history.forEach(function(msg) {
        consoleReplay += '\nconsole.' + msg.level + '.apply(console, ' +
          JSON.stringify(msg.arguments) + ');';
      });
    }

    return ReactOnRails.wrapInScriptTags(consoleReplay);
  };

  function forEachComponent(fn) {
    var els = document.getElementsByClassName('js-react-on-rails-component');
    for (var i = 0; i < els.length; i++) {
      fn(els[i]);
    };
  }

  function reactOnRailsPageLoaded() {
    forEachComponent(render);
  }

  function reactOnRailsPageUnloaded() {
    forEachComponent(unmount);
  }

  function unmount(el) {
    var domId = el.getAttribute('data-dom-id');
    var domNode = document.getElementById(domId);
    provideClientReact().unmountComponentAtNode(domNode);
  }

  function render(el) {
    var componentName = el.getAttribute('data-component-name');
    var domId = el.getAttribute('data-dom-id');
    var props = JSON.parse(el.getAttribute('data-props'));
    var trace = JSON.parse(el.getAttribute('data-trace'));
    var generatorFunction = JSON.parse(el.getAttribute('data-generator-function'));
    var expectTurboLinks = JSON.parse(el.getAttribute('data-expect-turbo-links'));

    if (!turbolinksInstalled && expectTurboLinks) {
      console.warn('WARNING: NO TurboLinks detected in JS, but it is in your Gemfile');
    }

    try {
      var domNode = document.getElementById(domId);
      if (domNode) {
        var reactElementOrRouterResult = createReactElementOrRouterResult(componentName, props,
          domId, trace, generatorFunction);
        if (isRouterResult(reactElementOrRouterResult)) {
          throw new Error('You returned a server side type of react-router error: ' +
            JSON.stringify(reactElementOrRouterResult) +
            '\nYou should return a React.Component always for the client side entry point.');
        } else {
          provideClientReact().render(reactElementOrRouterResult, domNode);
        }
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

  function createReactElementOrRouterResult(componentName, props, domId, trace, generatorFunction, location) {
    if (trace) {
      console.log('RENDERED ' + componentName + ' to dom node with id: ' + domId);
    }

    if (generatorFunction) {
      return this[componentName](props, location);
    } else {
      return React.createElement(this[componentName], props);
    }
  }

  function provideClientReact() {
    if (typeof ReactDOM === 'undefined') {
      if (React.version >= '0.14') {
        console.warn('WARNING: ReactDOM is not configured in webpack.server.rails.config.js file as an entry.\n' +
                     'See: https://github.com/shakacode/react_on_rails/blob/master/docs/webpack.md for more detailed hints.');
      }

      return React;
    }

    return ReactDOM;
  }

  function provideServerReact() {
    if (typeof ReactDOMServer === 'undefined') {
      if (React.version >= '0.14') {
        console.warn('WARNING: `react-dom/server` is not configured in webpack.server.rails.config.js file as an entry.\n' +
                     'See: https://github.com/shakacode/react_on_rails/blob/master/docs/webpack.md for more detailed hints.');
      }

      return React;
    }

    return ReactDOMServer;
  }

  function isRouterResult(reactElementOrRouterResult) {
    return !!(reactElementOrRouterResult.redirectLocation ||
    reactElementOrRouterResult.error);
  }

  // Install listeners when running on the client.
  if (typeof document !== 'undefined') {
    if (!turbolinksInstalled) {
      document.addEventListener('DOMContentLoaded', reactOnRailsPageLoaded);
    } else {
      document.addEventListener('page:before-unload', reactOnRailsPageUnloaded);
      document.addEventListener('page:change', reactOnRailsPageLoaded);
    }
  }
}.call(this));
