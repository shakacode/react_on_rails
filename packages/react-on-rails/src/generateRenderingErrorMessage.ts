import type { ErrorOptions } from './types/index.ts';

function handleRenderFunctionIssue(options: ErrorOptions): string {
  const { e, name } = options;

  let msg = '';

  if (name) {
    const lastLine =
      'A Render-Function takes a single arg of props (and the location for React Router) ' +
      'and returns a ReactElement.';

    let shouldBeRenderFunctionError = `ERROR: ReactOnRails is incorrectly detecting Render-Function to be false. \
The React component '${name}' seems to be a Render-Function.\n${lastLine}`;
    const reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
    if (reMatchShouldBeGeneratorError.test(e.message)) {
      msg += `${shouldBeRenderFunctionError}\n\n`;
      console.error(shouldBeRenderFunctionError);
    }

    shouldBeRenderFunctionError = `ERROR: ReactOnRails is incorrectly detecting renderFunction to be true, \
but the React component '${name}' is not a Render-Function.\n${lastLine}`;

    const reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;

    if (reMatchShouldNotBeGeneratorError.test(e.message)) {
      msg += `${shouldBeRenderFunctionError}\n\n`;
      console.error(shouldBeRenderFunctionError);
    }
  }

  return msg;
}

const generateRenderingErrorMessage = (options: ErrorOptions): string => {
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

    return msg;
  }

  return 'undefined';
};

export default generateRenderingErrorMessage;
