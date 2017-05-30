import * as actionTypes from '../constants/MainPageConstants';

/* eslint-disable import/prefer-default-export */
export function updateName(name) {
  return {
    type: actionTypes.MAIN_PAGE_NAME_UPDATE,
    name,
  };
}
