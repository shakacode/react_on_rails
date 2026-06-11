'use client';

import React from 'react';

const TailwindProbe = () => (
  <div
    className="inline-flex items-center px-4 py-2 m-1 border-2 border-amber-400 bg-amber-100 text-amber-900 font-semibold"
    data-testid="css-probe-tailwind"
  >
    Tailwind CSS (utility classes)
  </div>
);

export default TailwindProbe;
