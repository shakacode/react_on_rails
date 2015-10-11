import React from 'react';
import ReactDOM from 'react-dom';

const Common = {
  react013() {
    return React.version.match(/^0\.13/);
  },

  reactFindDOMNode() {
    if (this.react013()) {
      return React.FindDOMNode;
    }
    return ReactDOM.findDOMNode;
  },
};

export default Common;
