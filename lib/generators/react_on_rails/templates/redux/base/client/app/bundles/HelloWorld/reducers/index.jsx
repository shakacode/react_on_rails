// This file is our manifest of all reducers for the app.
// See also /client/app/bundles/HelloWorld/store/helloWorldStore.jsx
// A real world app will like have many reducers and it helps to organize them in one file.
// `https://github.com/shakacode/react_on_rails/tree/master/docs/additional_reading/generated_client_code.md`
import helloWorldReducer from './helloWorldReducer';
import { $$initialState as $$helloWorldState } from './helloWorldReducer';

export default {
  $$helloWorldStore: helloWorldReducer,
};

export const initalStates = {
  $$helloWorldState,
};
