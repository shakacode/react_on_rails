import React from 'react';

// Super simple example of the simplest possible React component
export default class HelloWorld extends React.Component {

  // Not necessary if we only call super, but we'll need to initialize state, etc.
  constructor(props, context) {
    super(props, context);
  }

  _handleChange() {
    const name = React.findDOMNode(this.refs.name).value;
    this.props.updateName(name);
  }

  render() {
    return (
      <div>
        <h1>
          Hello, {this.props.helloWorldData.name}!
        </h1>
        <p>
          Say hello to: <input type="text" ref="name" defaultValue={this.props.helloWorldData.name} onChange={::this._handleChange} />
        </p>
      </div>
    );
  }
}
