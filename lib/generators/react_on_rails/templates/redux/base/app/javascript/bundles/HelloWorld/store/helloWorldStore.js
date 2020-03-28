import { createStore } from 'redux';
import helloWorldReducer from '../reducers/helloWorldReducer';

const configureStore = (railsProps) => createStore(helloWorldReducer, railsProps);

export default configureStore;
