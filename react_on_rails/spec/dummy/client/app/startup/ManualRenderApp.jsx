import React from 'react';
import ReactDOMClient from 'react-dom/client';

export default (props, _railsContext, domNodeId) => {
  const reactElement = (
    <div>
      <h1 id="manual-render">Manual Render Example</h1>
      <p>If you can see this, you can register renderer functions.</p>
    </div>
  );

  const domNode = document.getElementById(domNodeId);
  if (props.prerender) {
    ReactDOMClient.hydrateRoot(domNode, reactElement);
  } else {
    const root = ReactDOMClient.createRoot(domNode);
    root.render(reactElement);
  }
};
