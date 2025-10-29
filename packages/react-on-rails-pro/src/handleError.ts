import * as React from 'react';
import { ErrorOptions } from 'react-on-rails/types';
import { renderToPipeableStream } from 'react-on-rails/ReactDOMServer';
import generateRenderingErrorMessage from 'react-on-rails/generateRenderingErrorMessage';

const handleError = (options: ErrorOptions) => {
  const msg = generateRenderingErrorMessage(options);
  const reactElement = React.createElement('pre', null, msg);
  return renderToPipeableStream(reactElement);
};

export default handleError;
