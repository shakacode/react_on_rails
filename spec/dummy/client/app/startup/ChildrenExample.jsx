import React from 'react';

const ComponentWithChildren = ({ children }) => (
  <div>
    <h1>This is component for testing passing children in from Rails</h1>
    { children }
  </div>
);

export default ComponentWithChildren;
