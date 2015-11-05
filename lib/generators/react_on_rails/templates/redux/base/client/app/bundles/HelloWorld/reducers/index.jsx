// This file is our manifest of all reducers for the app.
// See /client/app/bundles/HelloWorld/store/helloWorldStore.jsx
// A real world app will like have many reducers and it helps to organize them in one file.
// See `docs/generators/reducers.md` at https://github.com/shakacode/react_on_rails
import helloWorldReducer from './helloWorldReducer';
import { $$initialState as $$helloWorldState } from './helloWorldReducer';

export default {
  $$helloWorldStore: helloWorldReducer,
};

export const initalStates = {
  $$helloWorldState,
};
