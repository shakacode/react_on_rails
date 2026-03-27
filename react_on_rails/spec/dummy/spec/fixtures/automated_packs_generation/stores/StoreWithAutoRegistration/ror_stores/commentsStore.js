// Test store generator for auto-registration
import { createStore } from 'redux';

const commentsStore = (props, railsContext) => {
  const initialState = { comments: props.comments || [] };
  return createStore((state = initialState) => state);
};

export default commentsStore;
