import React                    from 'react';
import { connect }              from 'react-redux';

import HelloWorld               from './HelloWorld';

import * as helloWorldActions   from '../actions/HelloWorldActions';

// TODO: Show some comments of what this looks like without ES7 decorator syntax

@connect(state => {
  return {
    // This is the slice of the data, named the same as the component
    helloWorldData: state.helloWorldData
  }
}, helloWorldActions)

export default class HelloWorldContainer extends React.Component {
  constructor(props, context) {
    super(props, context);
  }

  render() {
    return (
      <HelloWorld {...this.props} />
    );
  }
}
