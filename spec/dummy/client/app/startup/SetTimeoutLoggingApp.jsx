import React from 'react';

const SetTimeoutLoggingApp = (props) => {
  setTimeout(() => console.log("timeout done"), 3000);
  return (
      <div>
        Called setTimeout.
      </div>
    );
}

export default SetTimeoutLoggingApp;
