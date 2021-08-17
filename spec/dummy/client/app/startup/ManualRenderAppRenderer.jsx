import React from 'react';
import ReactDOM from 'react-dom';

export default (props, _railsContext, domNodeId) => {
  const render = props.prerender ? ReactDOM.hydrate : ReactDOM.render;

  const reactElement = (
    <div>
      <h1 id="manual-render">Manual Render Example</h1>
      <p>If you can see this, you can register renderer functions.</p>
    </div>
  );

  render(reactElement, document.getElementById(domNodeId));
};
