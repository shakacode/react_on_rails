'use client';

import React from 'react';

// Client-side version of DelayedComponent (no delay needed on client)
const DelayedComponent = ({ index, delayMs = 1000 }) => (
  <div style={{ padding: '10px', margin: '5px', border: '1px solid #ccc' }}>
    <strong>Component {index}</strong> - Rendered after {delayMs}ms delay
  </div>
);

export default DelayedComponent;
