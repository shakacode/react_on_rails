import { ErrorOptions } from 'react-on-rails/types';
import { renderToPipeableStream } from 'react-on-rails-rsc/server.node';
import generateRenderingErrorMessage from 'react-on-rails/generateRenderingErrorMessage';

const handleError = (options: ErrorOptions) => {
  const msg = generateRenderingErrorMessage(options);
  return renderToPipeableStream(new Error(msg), {
    filePathToModuleMetadata: {},
    moduleLoading: { prefix: '', crossOrigin: null },
  });
};

export default handleError;
