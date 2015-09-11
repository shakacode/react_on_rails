import React from 'react';

// Super simple example of React component using React.createClass
const HelloES5 = React.createClass({

  getInitialState() {
    return this.props.helloWorldData;
  },

  _handleChange() {
    const name = React.findDOMNode(this.refs.name).value;
    this.setState({name});
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

export default HelloES5;
