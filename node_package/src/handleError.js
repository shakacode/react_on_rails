import React from 'react';
import ReactDOMServer from 'react-dom/server';

function handleGeneratorFunctionIssue(options) {
  const e = options.e;
  const componentName = options.componentName;
  let msg = '';

  const lineOne =
    'ERROR: You specified the option generator_function (could be in your defaults) to be\n';
  const lastLine =
    'A generator function takes a single arg of props and returns a ReactElement.';

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

  return msg;
}

export default (options) => {
  const e = options.e;
  const jsCode = options.jsCode;
  const serverSide = options.serverSide;

  console.error('Exception in rendering!');

  let msg = handleGeneratorFunctionIssue(options);

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
    return ReactDOMServer.renderToString(reactElement);
  }
};
