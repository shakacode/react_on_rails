// Simple example of a React "smart" component

import { connect, ConnectedProps } from 'react-redux';
import HelloWorld from '../components/HelloWorld';
import * as actions from '../actions/helloWorldActionCreators';
import type { HelloWorldState } from '../reducers/helloWorldReducer';

// Which part of the Redux global state does our component want to receive as props?
const mapStateToProps = (state: HelloWorldState) => ({ name: state.name });

// Create the connector
const connector = connect(mapStateToProps, actions);

// Infer the props from Redux state and actions
export type PropsFromRedux = ConnectedProps<typeof connector>;

// Don't forget to actually use connect!
// Note that we don't export HelloWorld, but the redux "connected" version of it.
// See https://github.com/reactjs/react-redux/blob/master/docs/api.md#examples
export default connector(HelloWorld);
