import { createElement } from 'react';
import { renderToString } from './ReactDOMServer.cts';
import type { ErrorOptions } from './types/index.ts';
import generateRenderingErrorMessage from './generateRenderingErrorMessage.ts';

const handleError = (options: ErrorOptions): string => {
  const msg = generateRenderingErrorMessage(options);
  const reactElement = createElement('pre', null, msg);
  return renderToString(reactElement);
};

export default handleError;
