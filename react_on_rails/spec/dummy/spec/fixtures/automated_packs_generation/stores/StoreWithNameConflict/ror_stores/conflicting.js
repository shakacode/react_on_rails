// Store with name that conflicts with component
import { createStore } from 'redux';

const conflicting = (props, railsContext) => {
  return createStore((state = {}) => state);
};

export default conflicting;
