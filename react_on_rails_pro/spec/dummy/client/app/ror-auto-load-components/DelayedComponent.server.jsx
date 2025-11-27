'use client';

import React from 'react';

// Component that simulates a slow render by delaying for 1 second
// Used to demonstrate concurrent rendering with async_react_component
const DelayedComponent = ({ index, delayMs = 1000 }) => (
  <div style={{ padding: '10px', margin: '5px', border: '1px solid #ccc' }}>
    <strong>Component {index}</strong> - Rendered after {delayMs}ms delay
  </div>
);

// Async render function that delays for specified time before returning
export default async (props, _railsContext) => {
  const { delayMs = 1000 } = props;

  // Simulate slow server-side data fetching
  await new Promise((resolve) => setTimeout(resolve, delayMs));

  return () => <DelayedComponent {...props} />;
};
