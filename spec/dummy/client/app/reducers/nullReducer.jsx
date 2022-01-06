// This will always get set
const initialState = {};

// Why name function the same as the reducer?
// https://github.com/gaearon/redux/issues/428#issuecomment-129223274
// Naming the function will help with debugging!
/* eslint-disable no-unused-vars */
export default function railsContextReducer(state = initialState, action) {
  return state;
}
