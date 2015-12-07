/* eslint-disable no-console */

import React from 'react';

const context = ((typeof window !== 'undefined') && window) ||
  ((typeof global !== 'undefined') && global) || this;

let ReactOnRails;

const turbolinksInstalled = (typeof Turbolinks !== 'undefined');

function provideClientReact() {
  if (typeof context.ReactDOM === 'undefined') {
    if (React.version >= '0.14') {
      console.warn(
        'WARNING: ReactDOM is not configured in webpack.server.rails.config.js file as an entry.\n' +
        'See: https://github.com/shakacode/react_on_rails/blob/master/docs/webpack.md for more detailed hints.');
    }

    return React;
  }

  return context.ReactDOM;
}

function provideServerReact() {
  if (typeof context.ReactDOMServer === 'undefined') {
    if (React.version >= '0.14') {
      console.warn(
        'WARNING: `react-dom/server` is not configured in webpack.server.rails.config.js file as an entry.\n' +
        'See: https://github.com/shakacode/react_on_rails/blob/master/docs/webpack.md for more detailed hints.');
    }

    return context.React;
  }

  return context.ReactDOMServer;
}

function wrapInScriptTags(scriptBody) {
  if (!scriptBody) {
    return '';
  }

  return '\n<script>' + scriptBody + '\n</script>';
}

function forEachComponent(fn) {
  const els = document.getElementsByClassName('js-react-on-rails-component');
  for (let i = 0; i < els.length; i++) {
    fn(els[i]);
  }
}

function unmount(el) {
  const domId = el.getAttribute('data-dom-id');
  const domNode = document.getElementById(domId);
  provideClientReact().unmountComponentAtNode(domNode);
}

function isRouterResult(reactElementOrRouterResult) {
  return !!(reactElementOrRouterResult.redirectLocation ||
  reactElementOrRouterResult.error);
}

function createReactElementOrRouterResult(componentName, props, domId, trace, generatorFunction, location) {
  if (trace) {
    console.log('RENDERED ' + componentName + ' to dom node with id: ' + domId);
  }

  const component = ReactOnRails.componentForName(componentName);
  if (generatorFunction) {
    return component(props, location);
  }

  return React.createElement(component, props);
}

function render(el) {
  const componentName = el.getAttribute('data-component-name');
  const domId = el.getAttribute('data-dom-id');
  const props = JSON.parse(el.getAttribute('data-props'));
  const trace = JSON.parse(el.getAttribute('data-trace'));
  const generatorFunction = JSON.parse(el.getAttribute('data-generator-function'));
  const expectTurboLinks = JSON.parse(el.getAttribute('data-expect-turbo-links'));

  if (!turbolinksInstalled && expectTurboLinks) {
    console.warn('WARNING: NO TurboLinks detected in JS, but it is in your Gemfile');
  }

  try {
    const domNode = document.getElementById(domId);
    if (domNode) {
      const reactElementOrRouterResult = createReactElementOrRouterResult(componentName, props,
        domId, trace, generatorFunction);
      if (isRouterResult(reactElementOrRouterResult)) {
        throw new Error('You returned a server side type of react-router error: ' +
          JSON.stringify(reactElementOrRouterResult) +
          '\nYou should return a React.Component always for the client side entry point.');
      } else {
        provideClientReact().render(reactElementOrRouterResult, domNode);
      }
    }
  } catch (e) {
    ReactOnRails.handleError({
      e: e,
      componentName: componentName,
      serverSide: false,
    });
  }
}

function reactOnRailsPageLoaded() {
  forEachComponent(render);
}

function reactOnRailsPageUnloaded() {
  forEachComponent(unmount);
}

const components = {};

ReactOnRails = {

  // TODO: Change to get components off the global
  componentForName(name) {
    if (components[name]) {
      return components[name];
    }

    if (!context[name]) {
      throw new Error(`Could not find component registered with name ${name}`);
    }

    console.warn(
      'WARNING: Please use ReactOnRails.registerComponent rather than adding components' +
      ' to the global namespace');
    return context[name];
  },

  // TODO
  registerCommponent(componentName, component, options) {
    components[componentName] = component;
  },

  serverRenderReactComponent(options) {
    const componentName = options.componentName;
    const domId = options.domId;
    const props = options.props;
    const trace = options.trace;
    const generatorFunction = options.generatorFunction;
    const location = options.location;
    let htmlResult = '';
    let hasErrors = false;

    try {
      const reactElementOrRouterResult = createReactElementOrRouterResult(componentName, props,
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
            const redirectLocation = reactElementOrRouterResult.redirectLocation;
            const redirectPath = redirectLocation.pathname + redirectLocation.search;
            console.log('ROUTER REDIRECT: ' + componentName + ' to dom node with id: ' + domId +
              ', redirect to ' + redirectPath);
          }
        }
      } else {
        htmlResult = provideServerReact().renderToString(reactElementOrRouterResult);
      }
    } catch (e) {
      hasErrors = true;
      htmlResult = this.handleError({
        e: e,
        componentName: componentName,
        serverSide: true,
      });
    }

    const consoleReplayScript = this.buildConsoleReplay();

    return JSON.stringify({
      html: htmlResult,
      consoleReplayScript: consoleReplayScript,
      hasErrors: hasErrors,
    });
  },

  // Passing either componentName or jsCode
  handleError(options) {
    const e = options.e;
    const componentName = options.componentName;
    const jsCode = options.jsCode;
    const serverSide = options.serverSide;

    const lineOne =
      'ERROR: You specified the option generator_function (could be in your defaults) to be\n';
    const lastLine =
      'A generator function takes a single arg of props and returns a ReactElement.';

    console.error('Exception in rendering!');

    let msg = '';
    if (componentName) {
      let shouldBeGeneratorError = lineOne +
        'false, but the React component \'' + componentName + '\' seems to be a generator function.\n' +
        lastLine;
      const reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
      if (reMatchShouldBeGeneratorError.test(e.message)) {
        msg += shouldBeGeneratorError + '\n\n';
        console.error(shouldBeGeneratorError);
      }

      shouldBeGeneratorError = lineOne +
        'true, but the React component \'' + componentName + '\' is not a generator function.\n' +
        lastLine;
      const reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;
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
      const reactElement = React.createElement('pre', null, msg);
      return provideServerReact().renderToString(reactElement);
    }
  },

  buildConsoleReplay() {
    let consoleReplay = '';

    const history = console.history;
    if (history && history.length > 0) {
      history.forEach(msg => {
        consoleReplay += '\nconsole.' + msg.level + '.apply(console, ' +
          JSON.stringify(msg.arguments) + ');';
      });
    }

    return wrapInScriptTags(consoleReplay);
  },
};

(function iife() {
  context.ReactOnRails = ReactOnRails;
  const document = context.document;

  // Install listeners when running on the client.
  if (typeof document !== 'undefined') {
    if (!turbolinksInstalled) {
      document.addEventListener('DOMContentLoaded', reactOnRailsPageLoaded);
    } else {
      document.addEventListener('page:before-unload', reactOnRailsPageUnloaded);
      document.addEventListener('page:change', reactOnRailsPageLoaded);
    }
  }
}).call(); // 'this' should be the window
