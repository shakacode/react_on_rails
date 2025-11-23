import { createStore } from 'redux';
import type { Store, PreloadedState } from 'redux';
import helloWorldReducer from '../reducers/helloWorldReducer';
import type { HelloWorldState } from '../reducers/helloWorldReducer';

// Rails props interface - customize based on your Rails controller
export interface RailsProps {
  name: string;
  [key: string]: any; // Allow additional props from Rails
}

// Store type
export type HelloWorldStore = Store<HelloWorldState>;

const configureStore = (railsProps: RailsProps): HelloWorldStore =>
  createStore(helloWorldReducer, railsProps as PreloadedState<HelloWorldState>);

export default configureStore;
