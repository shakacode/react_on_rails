import * as React from 'react';
import { ErrorOptions } from 'react-on-rails/types';
import { renderToPipeableStream } from 'react-on-rails-rsc/server.node';
import generateRenderingErrorMessage from 'react-on-rails/generateRenderingErrorMessage';

const handleError = (options: ErrorOptions) => {
  const msg = generateRenderingErrorMessage(options);
  const reactElement = React.createElement('pre', null, msg);
  return renderToPipeableStream(reactElement, {
    filePathToModuleMetadata: {},
    moduleLoading: { prefix: '', crossOrigin: null },
  });
};

export default handleError;
