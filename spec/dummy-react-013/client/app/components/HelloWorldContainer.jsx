import React from 'react';
import { connect } from 'react-redux';

import HelloWorldRedux from './HelloWorldRedux';

import * as helloWorldActions from '../actions/HelloWorldActions';

@connect(state => ({
  // This is the slice of the data, named the same as the component
  helloWorldData: state.helloWorldData,
}), helloWorldActions)

export default class HelloWorldContainer extends React.Component {
  constructor(props, context) {
    super(props, context);
  }

  render() {
    return (
      <HelloWorldRedux {...this.props} />
    );
  }
}
