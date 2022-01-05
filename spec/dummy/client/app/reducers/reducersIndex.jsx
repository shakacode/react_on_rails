import helloWorldReducer from './HelloWorldReducer';
import nullReducer from './nullReducer';

// This is how you do a directory of reducers.
// The `import * as reducers` does not work for a directory, but only with a single file
export default {
  helloWorldData: helloWorldReducer,
  railsContext: nullReducer,
  modificationTarget: nullReducer,
};
