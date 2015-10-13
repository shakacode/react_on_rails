import React from 'react';
import ReactDOM from 'react-dom';

const ReactCompat = {
  react013() {
    return React.version.match(/^0\.13/);
  },

  reactFindDOMNode() {
    if (this.react013()) {
      return React.findDOMNode;
    }

    return ReactDOM.findDOMNode;
  },
};

export default ReactCompat;
