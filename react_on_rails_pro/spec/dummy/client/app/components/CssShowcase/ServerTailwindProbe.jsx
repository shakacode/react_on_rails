import React from 'react';

const ServerTailwindProbe = () => (
  <div
    className="inline-flex items-center px-4 py-2 m-1 border-2 border-red-400 bg-red-200 text-red-900 font-semibold"
    data-testid="css-probe-server-tailwind"
  >
    Tailwind CSS in Server Component
  </div>
);

export default ServerTailwindProbe;
