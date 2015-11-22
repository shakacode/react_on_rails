(function() {
  this.ReactOnRails = {};
  var turbolinksInstalled = (typeof Turbolinks !== 'undefined');

  ReactOnRails.serverRenderReactComponent = function(options) {
    var componentName = options.componentName;
    var domId = options.domId;
    var props = options.props;
    var trace = options.trace;
    var generatorFunction = options.generatorFunction;

    var htmlResult = '';
    var consoleReplay = '';

    try {
      var reactElement = createReactElement(componentName, props,
        domId, trace, generatorFunction);
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

  function forEachComponent(fn) {
    var els = document.getElementsByClassName('js-react-on-rails-component');
    for (var i = 0; i < els.length; i++) {
      fn(els[i]);
    };
  }

  function pageLoaded() {
    forEachComponent(render);
  }

  function pageUnloaded() {
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

  // Install listeners when running on the client.
  if (typeof document !== 'undefined') {
    if (!turbolinksInstalled) {
      document.addEventListener('DOMContentLoaded', pageLoaded);
    } else {
      document.addEventListener('page:before-unload', pageUnloaded);
      document.addEventListener('page:change', pageLoaded);
    }
  }
}.call(this));
