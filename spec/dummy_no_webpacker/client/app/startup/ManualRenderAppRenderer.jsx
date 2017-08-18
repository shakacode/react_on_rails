import React from 'react';
import ReactDOM from 'react-dom';

export default (_props, _railsContext, domNodeId) => {
  const reactElement = (
    <div>
      <h1>Manual Render Example</h1>
      <p>If you can see this, you can register renderer functions.</p>
    </div>
  );

  ReactDOM.render(reactElement, document.getElementById(domNodeId));
};
