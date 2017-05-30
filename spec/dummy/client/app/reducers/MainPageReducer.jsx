import * as actionTypes from '../constants/MainPageConstants';

const initialState = {
  lastActionType: null,
  name: 'Alex',
};

// Why name function the same as the reducer?
// https://github.com/gaearon/redux/issues/428#issuecomment-129223274
// Naming the function will help with debugging!
export default function mainPageReducer(state = initialState, action) {
  const { type, name } = action;
  switch (type) {
    case actionTypes.MAIN_PAGE_NAME_UPDATE:
      return {
        lastActionType: type,
        name,
      };
    default:
      return state;
  }
}
