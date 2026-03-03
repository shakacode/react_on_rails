'use client';

import React from 'react';

// This is the CLIENT variant - this should be what the browser loads.
export default function ChunkMappingTest() {
  return (
    <div data-testid="chunk-mapping-test" data-variant="client">
      <h2>CORRECT: Client variant loaded in browser</h2>
      <p>This is the expected behavior - the browser loaded ChunkMappingTest.client.jsx.</p>
    </div>
  );
}
