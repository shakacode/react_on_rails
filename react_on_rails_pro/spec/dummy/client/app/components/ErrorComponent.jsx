'use client';

import React from 'react';

const ErrorComponent = ({ error }) => {
  return (
    <div>
      <h1>Error happened while rendering RSC Page</h1>
      <p>{error?.message ?? error}</p>
    </div>
  );
};

export default ErrorComponent;
