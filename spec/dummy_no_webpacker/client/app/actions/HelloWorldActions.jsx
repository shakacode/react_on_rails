import * as actionTypes from '../constants/HelloWorldConstants';

/* eslint-disable import/prefer-default-export */
export function updateName(name) {
  return {
    type: actionTypes.HELLO_WORLD_NAME_UPDATE,
    name,
  };
}
