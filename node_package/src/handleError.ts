import React from 'react';
import ReactDOMServer from 'react-dom/server';
import type { ErrorOptions } from './types/index';

function handleRenderFunctionIssue(options: {e: Error; name?: string}): string {
  const { e, name } = options;

  let msg = '';

  if (name) {
    const lastLine =
      'A render function takes a single arg of props (and the location for react-router) ' +
      'and returns a ReactElement.';

    let shouldBeGeneratorError =
      `ERROR: ReactOnRails is incorrectly detecting render function to be false. The React
component '${name}' seems to be a render function.\n${lastLine}`;
    const reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
    if (reMatchShouldBeGeneratorError.test(e.message)) {
      msg += `${shouldBeGeneratorError}\n\n`;
      console.error(shouldBeGeneratorError);
    }

    shouldBeGeneratorError =
      `ERROR: ReactOnRails is incorrectly detecting renderFunction to be true, but the React
component '${name}' is not a render function.\n${lastLine}`;

    const reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;

    if (reMatchShouldNotBeGeneratorError.test(e.message)) {
      msg += `${shouldBeGeneratorError}\n\n`;
      console.error(shouldBeGeneratorError);
    }
  }

  return msg;
}

const handleError = (options: ErrorOptions): string => {
  const { e, jsCode, serverSide } = options;

  console.error('Exception in rendering!');

  let msg = handleRenderFunctionIssue(options);

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

  return "undefined";
};

export default handleError;
