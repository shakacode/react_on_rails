import { Readable } from 'stream';
import { ErrorOptions } from 'react-on-rails/types';
import handleErrorAsString from 'react-on-rails/handleError';

const handleError = (options: ErrorOptions) => {
  const htmlString = handleErrorAsString(options);
  return Readable.from([htmlString]);
};

export default handleError;
