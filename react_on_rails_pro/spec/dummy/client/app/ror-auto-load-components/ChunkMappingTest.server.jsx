'use client';

import React from 'react';

// This is the SERVER variant - if you see this text in the browser,
// then the chunk mapping bug has been reproduced.
export default function ChunkMappingTest() {
  return (
    <div data-testid="chunk-mapping-test" data-variant="server">
      <h2>BUG: SERVER variant loaded in browser!</h2>
      <p>If you see this text, the RSC chunk mapping loaded the wrong file.</p>
      <p>The browser should have loaded ChunkMappingTest.client.jsx instead.</p>
    </div>
  );
}
