import React from 'react';
import ReactDOM from 'react-dom';
// Intentional cross-tree import: the React 16 dummy entries reuse the StrictMode helper from the
// React 19 `app/` tree. Keep the import path in sync if `app/strictModeSupport` is moved.
import { wrapElementInStrictMode } from '../../app/strictModeSupport';

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

  if (props.prerender) {
    ReactDOM.hydrate(reactElement, domNode);
  } else {
    ReactDOM.render(reactElement, domNode);
  }

  // Return a teardown wrapper so React on Rails unmounts this tree on Turbo/Turbolinks navigation
  // (page unload) or same-id node replacement instead of leaking it. The React 16/17 API unmounts
  // by container node rather than via a root handle.
  return { teardown: () => ReactDOM.unmountComponentAtNode(domNode) };
};
