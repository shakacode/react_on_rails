/* eslint-disable react/prefer-es6-class */

import React from 'react';

// Super simple example of React component using React.createClass
const HelloWorldES5 = React.createClass({
  propTypes: {
    helloWorldData: React.PropTypes.object,
  },

  getInitialState() {
    return this.props.helloWorldData;
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

export default HelloWorldES5;
