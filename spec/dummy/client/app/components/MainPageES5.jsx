/* eslint-disable react/prefer-es6-class */

import PropTypes from 'prop-types';
import React from 'react';
import createReactClass from 'create-react-class';

// Super simple example of React component using React.createClass
const MainPageES5 = createReactClass({
  propTypes: {
    mainPageData: PropTypes.object,
  },

  getInitialState() {
    return this.props.mainPageData;
  },

  setNameDomRef(nameDomNode) {
    this.nameDomRef = nameDomNode;
  },

  handleChange() {
    const name = this.nameDomRef.value;
    this.setState({ name });
  },

  render() {
    const { name } = this.state;

    return (
      <div>
        <h3>
          Hello ES5, {name}!
        </h3>
        <p>
          Say hello to:
          <input
            type="text"
            ref={this.setNameDomRef}
            defaultValue={name}
            onChange={this.handleChange}
          />
        </p>
      </div>
    );
  },
});

export default MainPageES5;
