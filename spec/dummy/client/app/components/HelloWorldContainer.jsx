import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import HelloWorldRedux from './HelloWorldRedux';

import * as helloWorldActions from '../actions/HelloWorldActions';

function select(state) {
  // Which part of the Redux global state does our component want to receive as props?
  return { data: state.helloWorldData };
}

class HelloWorldContainer extends React.Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    data: PropTypes.object.isRequired,
  };

  constructor(props, context) {
    super(props, context);
  }

  render() {
    const { dispatch, data } = this.props;
    const actions = bindActionCreators(helloWorldActions, dispatch);

    return (
      <HelloWorldRedux {...{ actions, data }} />
    );
  }
}

// Don't forget to actually use connect!
export default connect(select)(HelloWorldContainer);
