// This component is used to test the caching of react_component
// This component generates random values and should NOT be rendered on the browser.
// Server-side rendering will produce different values than client-side rendering,
// causing React hydration mismatches and errors.

'use client';

import React from 'react';

const RandomValue = () => {
  const randomValue = Math.random();
  return <div>RandomValue: {randomValue}</div>;
};

export default RandomValue;
