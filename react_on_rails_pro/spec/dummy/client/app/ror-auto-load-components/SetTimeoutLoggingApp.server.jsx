import React from 'react';
import { renderToString } from 'react-dom/server';

/**
 * TODO: Node rendering server should handle a timeout.
 */
export default async (_props, _railsContext) => {
  const delayedValuePromise = new Promise((resolve) => {
    setTimeout(() => {
      console.log('Console log from setTimeout in SetTimeoutLoggingApp.server.jsx');
    }, 1);

    setTimeout(() => {
      console.log('Console log from setTimeout100 in SetTimeoutLoggingApp.server.jsx');
      resolve('this value is set by setTimeout during SSR');
    }, 100);
  });
  console.log('Console log from SetTimeoutLoggingApp.server.jsx');

  const delayedValue = await delayedValuePromise;
  const element = <div>Disable javascript in your browser options to confirm {delayedValue}.</div>;
  return renderToString(element);
};
