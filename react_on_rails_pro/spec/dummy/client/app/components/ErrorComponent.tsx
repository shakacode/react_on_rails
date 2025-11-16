'use client';

import React from 'react';

const ErrorComponent = ({ error }: { error: Error }) => {
  return (
    <div>
      <h1>Error happened while rendering RSC Page</h1>
      <p>{error.message}</p>
      <p>{error.stack}</p>
    </div>
  );
};

export default ErrorComponent;
