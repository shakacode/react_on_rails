import React, { PropTypes } from 'react';
import HelloWorldWidget from '../components/HelloWorldWidget';
import _ from 'lodash';

// Simple example of a React "smart" component
export default class HelloWorld extends React.Component {
  static propTypes = {
    name: PropTypes.string.isRequired, // this is passed from the Rails view
  };

  constructor(props, context) {
    super(props, context);

    // How to set initial state in ES6 class syntax
    // https://facebook.github.io/react/docs/reusable-components.html#es6-classes
    this.state = { name: this.props.name };

    // Uses lodash to bind all methods to the context of the object instance, otherwise
    // the methods defined here would not refer to the component's class, not the component
    // instance itself.
    _.bindAll(this, 'updateName');
  }

  updateName(name) {
    this.setState({ name });
  }

  render() {
    return (
      <div>
        <HelloWorldWidget name={this.state.name} updateName={this.updateName} />
      </div>
    );
  }
}
