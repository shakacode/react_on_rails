import React from 'react';

const SetTimeoutLoggingApp = (props) => {
  setTimeout(() => console.error("*****TIMEOUT DONE!*****"), 5000);

  return (
      <div>
        Called setTimeout.
      </div>
    );
}

export default SetTimeoutLoggingApp;
