import React from 'react';
import ReactDOMServer from 'react-dom/server';

function handleGeneratorFunctionIssue(options) {
  const { e, name } = options;

  let msg = '';

  if (name) {
    const lastLine =
      'A generator function takes a single arg of props (and the location for react-router) ' +
      'and returns a ReactElement.';

    let shouldBeGeneratorError =
      `ERROR: ReactOnRails is incorrectly detecting generator function to be false. The React
component \'${name}\' seems to be a generator function.\n${lastLine}`;
    const reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
    if (reMatchShouldBeGeneratorError.test(e.message)) {
      msg += `${shouldBeGeneratorError}\n\n`;
      console.error(shouldBeGeneratorError);
    }

    shouldBeGeneratorError =
      `ERROR: ReactOnRails is incorrectly detecting generatorFunction to be true, but the React
component \'${name}\' is not a generator function.\n${lastLine}`;

    const reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;

    if (reMatchShouldNotBeGeneratorError.test(e.message)) {
      msg += `${shouldBeGeneratorError}\n\n`;
      console.error(shouldBeGeneratorError);
    }
  }

  return msg;
}

const handleError = (options) => {
  const { e, jsCode, serverSide } = options;

  console.error('Exception in rendering!');

  let msg = handleGeneratorFunctionIssue(options);

  if (jsCode) {
    console.error(`JS code was: ${jsCode}`);
  }

  if (e.fileName) {
    console.error(`location: ${e.fileName}:${e.lineNumber}`);
  }

  console.error(`message: ${e.message}`);
  console.error(`stack: ${e.stack}`);

  if (serverSide) {
    msg += `Exception in rendering!
${e.fileName ? `\nlocation: ${e.fileName}:${e.lineNumber}` : ''}
Message: ${e.message}

${e.stack}`;

    const reactElement = React.createElement('pre', null, msg);
    return ReactDOMServer.renderToString(reactElement);
  }
};

export default handleError;
