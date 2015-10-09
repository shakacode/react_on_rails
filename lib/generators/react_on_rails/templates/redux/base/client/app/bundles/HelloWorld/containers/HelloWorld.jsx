import React, { PropTypes } from 'react';
import HelloWorldWidget from '../components/HelloWorldWidget';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Immutable from 'immutable';
import * as helloWorldActionCreators from '../actions/helloWorldActionCreators';

function select(state) {
  // Which part of the Redux global state does our component want to receive as props?
  // Note the use of `$$` to prefix the property name because the value is of type Immutable.js
  return { $$helloWorldStore: state.$$helloWorldStore };
}

// Simple example of a React "smart" component
class HelloWorld extends React.Component {
  constructor(props, context) {
    super(props, context);
  }

  static propTypes = {
    dispatch: PropTypes.func.isRequired,

    // This corresponds to the value used in function select above.
    $$helloWorldStore: PropTypes.instanceOf(Immutable.Map).isRequired,
  }

  render() {
    const { dispatch, $$helloWorldStore } = this.props;
    const actions = bindActionCreators(helloWorldActionCreators, dispatch);

    // This uses the ES2015 spread operator to pass properties as it is more DRY
    // This is equivalent to:
    // <HelloWorldWidget $$helloWorldStore={$$helloWorldStore} actions={actions} />
    return (
      <HelloWorldWidget {...{$$helloWorldStore, actions}} />
    );
  }
}

// Don't forget to actually use connect!
// Note that we don't export HelloWorld, but the redux "connected" version of it.
// See https://github.com/rackt/react-redux/blob/master/docs/api.md#examples
export default connect(select)(HelloWorld);
