import { createStore, Store } from 'redux';
import helloWorldReducer, { HelloWorldState } from '../reducers/helloWorldReducer';

// Rails props interface - customize based on your Rails controller
export interface RailsProps {
  name: string;
  [key: string]: any; // Allow additional props from Rails
}

// Store type
export type HelloWorldStore = Store<HelloWorldState>;

const configureStore = (railsProps: RailsProps): HelloWorldStore =>
  createStore(helloWorldReducer, railsProps);

export default configureStore;
