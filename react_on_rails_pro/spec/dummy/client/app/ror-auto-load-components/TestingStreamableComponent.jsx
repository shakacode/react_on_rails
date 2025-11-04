'use client';

import React from 'react';

// Simple test component for streaming SSR tests
function TestingStreamableComponent({ helloWorldData }) {
  return (
    <div>
      <div>Chunk 1: Stream React Server Components</div>
      <div>Hello, {helloWorldData.name}!</div>
    </div>
  );
}

export default TestingStreamableComponent;
