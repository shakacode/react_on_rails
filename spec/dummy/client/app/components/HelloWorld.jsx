import React, { PropTypes } from 'react';
import ReactDOM from 'react-dom';

// Super simple example of the simplest possible React component
class HelloWorld extends React.Component {

  static propTypes = {
    helloWorldData: PropTypes.shape({
      name: PropTypes.string,
    }).isRequired,

    error: PropTypes.any,
  };

  // Not necessary if we only call super, but we'll need to initialize state, etc.
  constructor(props, context) {
    super(props, context);
    this.state = props.helloWorldData;
  }

  _handleChange() {
    const name = ReactDOM.findDOMNode(this.refs.name).value;
    this.setState({ name });
  }

  render() {
    console.log('HelloWorld demonstrating a call to console.log in '
      + 'spec/dummy/client/app/components/HelloWorld.jsx:18');

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
