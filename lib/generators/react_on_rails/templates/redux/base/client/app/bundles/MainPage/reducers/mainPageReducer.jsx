import { combineReducers } from 'redux';
import { MAIN_PAGE_NAME_UPDATE } from '../constants/mainPageConstants';

const name = (state = '', action) => {
  switch (action.type) {
    case MAIN_PAGE_NAME_UPDATE:
      return action.text;
    default:
      return state;
  }
};

const mainPageReducer = combineReducers({ name });

export default mainPageReducer;
