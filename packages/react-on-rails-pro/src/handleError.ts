import * as React from 'react';
import { Readable } from 'stream';
import { ErrorOptions } from 'react-on-rails/types';
import { renderToString } from 'react-on-rails/ReactDOMServer';
import generateRenderingErrorMessage from 'react-on-rails/generateRenderingErrorMessage';

const handleError = (options: ErrorOptions) => {
  const msg = generateRenderingErrorMessage(options);
  const reactElement = React.createElement('pre', null, msg);
  const htmlString = renderToString(reactElement);
  return Readable.from([htmlString]);
};

export default handleError;
