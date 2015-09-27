import React from 'react';

// Super simple example of the simplest possible React component
class HelloWorld extends React.Component {

  // Not necessary if we only call super, but we'll need to initialize state, etc.
  constructor(props, context) {
    super(props, context);
    this.state = props.helloWorldData;
  }

  _handleChange() {
    const name = React.findDOMNode(this.refs.name).value;
    this.setState({name});
  }

  render() {
    console.log("HelloWorld demonstrating a call to console.log in spec/dummy/client/app/components/HelloWorld.jsx:18");

    const { name } = this.state;

    return (
      <div>
        <h3>
          Hello, {name}!
        </h3>
        <p>
          Say hello to:
          <input type="text" ref="name" defaultValue={name} onChange={::this._handleChange} />
        </p>
      </div>
    );
  }
}

export default HelloWorld;
