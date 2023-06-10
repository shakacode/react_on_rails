import React from 'react';
import { renderToString } from 'react-dom/server';

/**
 * TODO: Node rendering server should handle a timeout.
 */
export default async (_props, _railsContext) => {
  const delayedValue = await new Promise((resolve) => {
    setTimeout(() => {
      resolve('this value is set by setTimeout during SSR');
    }, 1);
  });
  const element = <div>Disable javascript in your browser options to confirm {delayedValue}.</div>;
  return renderToString(element);
};
