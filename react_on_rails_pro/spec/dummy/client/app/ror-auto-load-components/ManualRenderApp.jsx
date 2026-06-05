'use client';

import React from 'react';
import { createRoot, hydrateRoot } from 'react-dom/client';
import { wrapElementInStrictMode } from '../strictModeSupport';

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

  const reactElement = wrapElementInStrictMode(
    <div>
      <h1 id="manual-render">Manual Render Example</h1>
      <p>If you can see this, you can register renderer functions.</p>
    </div>,
  );

  const domEl = document.getElementById(domNodeId);
  if (!domEl) {
    throw new Error(
      `Cannot hydrate ManualRenderApp because DOM element with id "${domNodeId}" was not found.`,
    );
  }

  const root = hydrateOrRender(domEl, reactElement, prerender);

  // Return a teardown wrapper so React on Rails unmounts this root on Turbo/Turbolinks navigation
  // (page unload) or same-id node replacement instead of leaking it.
  return { teardown: () => root.unmount() };
};
