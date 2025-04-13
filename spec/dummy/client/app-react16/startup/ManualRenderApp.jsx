import React from 'react';
import ReactDOM from 'react-dom';

export default (props, _railsContext, domNodeId) => {
  const reactElement = (
    <div>
      <h1 id="manual-render">Manual Render Example</h1>
      <p>If you can see this, you can register renderer functions.</p>
    </div>
  );

  const domNode = document.getElementById(domNodeId);
  if (props.prerender) {
    ReactDOM.hydrate(reactElement, domNode);
  } else {
    ReactDOM.render(reactElement, domNode);
  }
};
