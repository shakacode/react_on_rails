import React from 'react';

/**
 * TODO: Node rendering server should handle a timeout.
 */
const SetTimeoutLoggingApp = (_props) => {
  // eslint-disable-next-line no-console
  const component = () => <div>Called setTimeout and returned this.</div>;
  const doIt = () => component;
  console.log('ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ');
  console.log('about to call setTimeout');
  console.log('ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ');

  const promise = setTimeout(doIt, 5000);
  return promise;
};

export default SetTimeoutLoggingApp;
