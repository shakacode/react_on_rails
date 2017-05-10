import { createStore } from 'redux';
import mainPageReducer from '../reducers/mainPageReducer';

const configureStore = (railsProps) => (
  createStore(mainPageReducer, railsProps)
);

export default configureStore;
