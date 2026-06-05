import React from 'react';
import ReactDOMClient from 'react-dom/client';
import { wrapElementInStrictMode } from '../strictModeSupport';

export default (props, _railsContext, domNodeId) => {
  const reactElement = wrapElementInStrictMode(
    <div>
      <h1 id="manual-render">Manual Render Example</h1>
      <p>If you can see this, you can register renderer functions.</p>
    </div>,
  );

  const domNode = document.getElementById(domNodeId);
  if (!domNode) {
    const renderMode = props.prerender ? 'hydrate' : 'render';
    throw new Error(
      `Cannot ${renderMode} ManualRenderApp because DOM element with id "${domNodeId}" was not found.`,
    );
  }

  let root;
  if (props.prerender) {
    root = ReactDOMClient.hydrateRoot(domNode, reactElement);
  } else {
    root = ReactDOMClient.createRoot(domNode);
    root.render(reactElement);
  }

  // Return a teardown wrapper so React on Rails unmounts this root on Turbo/Turbolinks navigation
  // (page unload) or same-id node replacement instead of leaking it.
  return { teardown: () => root.unmount() };
};
