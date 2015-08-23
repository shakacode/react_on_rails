import * as actionTypes   from '../constants/HelloWorldConstants';

export function updateName(name) {
  return {
    type: actionTypes.HELLO_WORLD_NAME_UPDATE,
    name
  };
}
