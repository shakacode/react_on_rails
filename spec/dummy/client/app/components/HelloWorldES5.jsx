/* eslint-disable react/prefer-es6-class */

import React from 'react';
import ReactDOM from 'react-dom';

// Super simple example of React component using React.createClass
const HelloWorldES5 = React.createClass({
  propTypes: {
    helloWorldData: React.PropTypes.object,
  },

  getInitialState() {
    return this.props.helloWorldData;
  },

  _handleChange() {
    const name = ReactDOM.findDOMNode(this.refs.name).value;
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
          <input type="text" ref="name" defaultValue={name} onChange={this._handleChange} />
        </p>
      </div>
    );
  },
});

export default HelloWorldES5;
