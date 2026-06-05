import type { Reducer } from 'redux';

import type { ReduxAppState } from '../store/reduxTypes';
import helloWorldReducer from './HelloWorldReducer';
import nullReducer from './nullReducer';

type ReduxAppReducers = {
  helloWorldData: Reducer<ReduxAppState['helloWorldData']>;
  modificationTarget: Reducer<ReduxAppState['modificationTarget']>;
  railsContext: Reducer<ReduxAppState['railsContext']>;
};

const reducers: ReduxAppReducers = {
  helloWorldData: helloWorldReducer,
  railsContext: nullReducer,
  modificationTarget: nullReducer,
};

export default reducers;
