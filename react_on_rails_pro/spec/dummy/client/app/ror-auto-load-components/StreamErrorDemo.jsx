import React, { Suspense } from 'react';

const AlwaysFailsAsync = () => {
  if (typeof window !== 'undefined') {
    return <div>Client-side fallback</div>;
  }
  return new Promise((_resolve, reject) => {
    setTimeout(() => reject(new Error('Async component crashed during server rendering!')), 2000);
  });
};

const StreamErrorDemo = () => (
  <div style={{ fontFamily: 'sans-serif', padding: '20px' }}>
    <h1>Stream Error Demo (Issue #2402)</h1>
    <p>This component demonstrates the streaming hang bug.</p>
    <p>The header above renders immediately as part of the shell.</p>
    <hr />
    <Suspense fallback={<div style={{ color: 'orange' }}>Loading async content (will error after 2s)...</div>}>
      <AlwaysFailsAsync />
    </Suspense>
    <hr />
    <p>Footer: if you can see this, the stream completed successfully.</p>
  </div>
);

export default StreamErrorDemo;
