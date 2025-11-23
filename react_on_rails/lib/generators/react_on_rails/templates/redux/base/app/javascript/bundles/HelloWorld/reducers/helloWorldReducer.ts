import { combineReducers } from 'redux';
import { HELLO_WORLD_NAME_UPDATE } from '../constants/helloWorldConstants';
import { HelloWorldAction } from '../actions/helloWorldActionCreators';

// State interface
export interface HelloWorldState {
  name: string;
}

// Individual reducer with TypeScript types
const name = (state: string = '', action: HelloWorldAction): string => {
  switch (action.type) {
    case HELLO_WORLD_NAME_UPDATE:
      return action.text;
    default:
      return state;
  }
};

const helloWorldReducer = combineReducers<HelloWorldState>({ name });

export default helloWorldReducer;
