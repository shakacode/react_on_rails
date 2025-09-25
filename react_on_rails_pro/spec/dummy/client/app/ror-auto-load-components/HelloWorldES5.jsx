/* eslint-disable react/prefer-es6-class,react/destructuring-assignment,react/no-unused-class-component-methods */

'use client';

import PropTypes from 'prop-types';
import React from 'react';
import createReactClass from 'create-react-class';

// Super simple example of React component using React.createClass
const HelloWorldES5 = createReactClass({
  propTypes: {
    helloWorldData: PropTypes.object,
  },

  getInitialState() {
    return this.props.helloWorldData;
  },

  handleChange() {
    const name = this.nameDomRef.value;
    this.setState({ name });
  },

  setNameDomRef(nameDomNode) {
    this.nameDomRef = nameDomNode;
  },

  render() {
    const { name } = this.state;

    return (
      <div>
        <h3>Hello ES5, {name}!</h3>
        <p>
          Say hello to:
          <input type="text" ref={this.setNameDomRef} defaultValue={name} onChange={this.handleChange} />
        </p>
      </div>
    );
  },
});

export default HelloWorldES5;
