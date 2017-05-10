// Simple example of a React "smart" component

import { connect } from 'react-redux';
import MainPage from '../components/MainPage';
import * as actions from '../actions/mainPageActionCreators';

// Which part of the Redux global state does our component want to receive as props?
const mapStateToProps = (state) => ({ name: state.name });

// Don't forget to actually use connect!
// Note that we don't export MainPage, but the redux "connected" version of it.
// See https://github.com/reactjs/react-redux/blob/master/docs/api.md#examples
export default connect(mapStateToProps, actions)(MainPage);
