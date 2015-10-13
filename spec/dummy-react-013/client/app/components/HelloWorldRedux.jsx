import React, { PropTypes } from 'react';
import ReactCompat from '../utils/ReactCompat';

// Super simple example of the simplest possible React component
export default class HelloWorldRedux extends React.Component {

  static propTypes = {
    helloWorldData: PropTypes.shape({
      name: PropTypes.string,
    }).isRequired,
    updateName: PropTypes.func.isRequired,
  }

  // Not necessary if we only call super, but we'll need to initialize state, etc.
  constructor(props, context) {
    super(props, context);
  }

  _handleChange() {
    const name = ReactCompat.reactFindDOMNode()(this.refs.name).value;
    this.props.updateName(name);
  }

  render() {
    const { name } = this.props.helloWorldData;

    // Same:
    // const name = this.props.helloWorldData.name;

    return (
      <div>
        <h3>
          Redux Hello, {name}!
        </h3>
        <p>
          With Redux, say hello to:
          <input type="text" ref="name" defaultValue={name} onChange={::this._handleChange} />
        </p>
      </div>
    );
  }
}
