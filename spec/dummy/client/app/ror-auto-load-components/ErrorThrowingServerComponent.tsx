import React from 'react';

const ErrorThrowingServerComponent: React.FC = () => {
  // Randomly throw error with 50% probability
  if (Math.random() > 0.5) {
    throw new Error('Random error occurred!');
  }

  return (
    <div>
      <h2>Current Time</h2>
      <p>{new Date().toLocaleTimeString()}</p>
    </div>
  );
};

export default ErrorThrowingServerComponent;
