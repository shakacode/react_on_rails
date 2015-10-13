import React from 'react';

const ReactCompat = {
  react013() {
    return React.version.match(/^0\.13/);
  },

  reactFindDOMNode() {
    if (this.react013()) {
      return React.findDOMNode;
    }

    throw new Error('Not React 0.13!');
  },
};

export default ReactCompat;
