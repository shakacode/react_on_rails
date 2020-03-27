import React from 'react';

const SetTimeoutLoggingApp = (_props) => {
  // eslint-disable-next-line no-console
  setTimeout(() => console.error('*****TIMEOUT DONE!*****'), 5000);

  return <div>Called setTimeout.</div>;
};

export default SetTimeoutLoggingApp;
