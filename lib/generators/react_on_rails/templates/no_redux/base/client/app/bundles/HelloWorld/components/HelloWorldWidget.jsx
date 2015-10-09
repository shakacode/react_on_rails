import React, { PropTypes } from 'react';
import _ from 'lodash';

// Simple example of a React "dumb" component
export default class HelloWorldWidget extends React.Component {
  constructor(props, context) {
    super(props, context);

    // Uses lodash to bind all methods to the context of the object instance, otherwise
    // the methods defined here would not refer to the component's class, not the component
    // instance itself.
    _.bindAll(this, '_handleChange');
  }

  static propTypes = {
    name: PropTypes.string.isRequired,
    _updateName: PropTypes.func.isRequired,
  };

  // React will automatically provide us with the event `e`
  _handleChange(e) {
    const name = e.target.value;
    this.props._updateName(name);
  }

  render() {
    return (
      <div>
        <h3>
          Hello, {this.props.name}!
        </h3>
        <p>
          Say hello to:
          <input type="text" ref="name" value={this.props.name} onChange={this._handleChange} />
        </p>
      </div>
    );
  }
}
