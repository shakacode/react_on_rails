'use client';

import React from 'react';
import { createRoot, hydrateRoot } from 'react-dom/client';

const hydrateOrRender = (domEl, reactEl, prerender) => {
  if (prerender) {
    return hydrateRoot(domEl, reactEl);
  }

  const root = createRoot(domEl);
  root.render(reactEl);
  return root;
};

export default (props, _railsContext, domNodeId) => {
  const { prerender } = props;

  const reactElement = (
    <div>
      <h1 id="manual-render">Manual Render Example</h1>
      <p>If you can see this, you can register renderer functions.</p>
    </div>
  );

  hydrateOrRender(document.getElementById(domNodeId), reactElement, prerender);
};
